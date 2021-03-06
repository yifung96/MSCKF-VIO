%% Setup & Load
%load parameters
clear all; 
close all;
run('parameters.m');

% automatically cd to /src directory
cd(fileparts(which('#Test13/src/main.m')));

%add paths
addpath('../src')
addpath('../datasets')
addpath('plot')
addpath('functions')
addpath('functions/NonLinLS')
addpath('functions/triangulation')

%get ground truth, K, and last frame index from database
% Kitti
if ds == 0
    % need to set kitti_path to folder containing "00" and "poses"
    kitti_path = '../datasets/kitti';
    assert(exist('../datasets/kitti', 'dir') ~= 0, 'Kitti dataset not found');
    last_frame = 107; %76, 107
    K = [7.188560000000e+02 0 6.071928000000e+02
        0 7.188560000000e+02 1.852157000000e+02
        0 0 1];    
    % create cameraParams object
    cameraParams = cameraParameters('IntrinsicMatrix', K);
    cameraParams.ImageSize = [376, 1241]; 
    clear K;
    const = [-1;1;1];
% Malaga    
elseif ds == 1
    % Path containing the many files of Malaga 7.
    malaga_path = '../datasets/malaga';
    assert(exist(malaga_path, 'dir') ~= 0, 'Malaga dataset not found');
    images = dir([malaga_path ...
        '/malaga-urban-dataset-extract-07_rectified_800x600_Images']);
    left_images = images(3:2:end);
    last_frame = length(left_images);
    K = [621.18428 0 404.0076
        0 621.18428 309.05989
        0 0 1];    
    % create cameraParams object
    cameraParams = cameraParameters('IntrinsicMatrix', K);
    clear K;
    cameraParams.ImageSize = [600, 800];    
    %no ground truth available
    ground_truth = [0, 0];

% Parking
elseif ds == 2
    % Path containing images, depths and all...
    parking_path = '../datasets/parking';
    assert(exist(parking_path, 'dir') ~= 0, 'Parking dataset not found');
    last_frame = 598;
    K = load([parking_path '/K.txt']);     
    ground_truth = load([parking_path '/poses.txt']);
    ground_truth = ground_truth(:, [end-8 end]);    
    % create cameraParams object
    cameraParams = cameraParameters('IntrinsicMatrix', K);
    clear K;
    cameraParams.ImageSize = [480, 640]; 

% Swiss Alps 1 
elseif ds == 4
    % Path containing the many files of alpstrasse.
    alp_path = '../datasets/alpstrasse';
    assert(exist(alp_path, 'dir') ~= 0, 'alpstrasse dataset not found');
    last_frame = 385;
    load('calibration/cameraParams/cameraParams_iphone6.mat');    
    % create cameraParams object
    cameraParams.ImageSize = [540, 960];    
    %no ground truth available
    ground_truth = [0, 0];    

% Swiss Alps 2
elseif ds == 5
    % Path containing the many files of alpstrasse LONG.
    alp_path = '../datasets/alpstrasse';
    assert(exist(alp_path, 'dir') ~= 0, 'alpstrasse dataset not found');
    last_frame = 1360;
    load('calibration/cameraParams/cameraParams_iphone6.mat');    
    % create cameraParams object
    cameraParams.ImageSize = [540, 960];    
    %no ground truth available
    ground_truth = [0, 0];    

% Home Sweet Home    
elseif ds == 6
    % Path containing the many files of indoors.
    alp_path = '../datasets/indoor';
    assert(exist(alp_path, 'dir') ~= 0, 'indoor dataset not found');
    last_frame = 290;
    load('calibration/cameraParams/cameraParams_iphone6.mat');    
    % create cameraParams object
    cameraParams.ImageSize = [540, 960];    
    %no ground truth available
    ground_truth = [0, 0];      
    
else  
    last_frame = 1700; 
    ground_truth = [0, 0]; 
    load('calibration/cameraParams/cameraParams_iphone6.mat');  
end

%create global data object
globalData.vSet = viewSet;              % viewSet with estimated data
globalData.actualVSet = viewSet;        % viewSet with ground truth
globalData.landmarks = [];              % 3D pointcloud (Nx3 matrix)
globalData.debug = [];                  % init debug structure
globalData.scale_factor = 1;            % init scale factor

%create debug data
globalData.debug.p3p_outlier_keypoints = []; 
globalData.debug.ckeypoints_invalid = []; 
t_start = clock;
%% 	BOOTSTRAP
for i = 1:bootstrap.init.numTrials
    close all;

    globalData.vSet = viewSet;  %erase if anything in there already

    % run bootstrap: Estimating the pose of the second view relative to the first view
    [currState, globalData,viewId] = bootstrap_wrapper(cameraParams, globalData);

    if norm(globalData.vSet.Views.Location{2} - bootstrap.init.first_location) < 10.2
        break;
    elseif i == bootstrap.init.numTrials
        warning('\n\nDEBUGGER>> BOOTSTRAP failed, bad x value in bootstrap after max iterations\n\n')
    end
        
    fprintf('\n\nDEBUGGER>> BOOTSTRAP failed, run again\n\n'); 
     
end

%% Continuous operation

% initialize Kanade-Lucas-Tomasi (KLT) point tracker for keypoints and
KLT_keypointsTracker = vision.PointTracker('NumPyramidLevels', processFrame.klt.NumPyramidLevels, ...
                                'MaxBidirectionalError', processFrame.klt.MaxBidirectionalError, ...
                                'BlockSize', processFrame.klt.BlockSize, ...
                                'MaxIterations', processFrame.klt.MaxIterations);
                            
KLT_candidateKeypointsTracker = vision.PointTracker('NumPyramidLevels', processFrame.klt.NumPyramidLevels, ...
                                'MaxBidirectionalError', processFrame.klt.MaxBidirectionalError, ...
                                'BlockSize', processFrame.klt.BlockSize, ...
                                'MaxIterations', processFrame.klt.MaxIterations);                            

% initialize Tracker
I_curr = loadImage(ds, bootstrap.images(end), cameraParams);
initialize(KLT_keypointsTracker, currState.keypoints, I_curr);
initialize(KLT_candidateKeypointsTracker, currState.candidate_kp, I_curr);
                            
% Estimate remaining camera trajectory
range = (bootstrap.images(2)+1):last_frame;

% for re-bootstrap
global RE_BOOTSTRAP
RE_BOOTSTRAP = false;

for i = range
    
    % update to current frame
    prevState = currState;
    I_curr = loadImage(ds,i, cameraParameters);
    
    % run processFrame
    if not(RE_BOOTSTRAP)
        [currState, currRT, globalData] = processFrame_wrapper(I_curr, prevState, ...
                                            KLT_keypointsTracker, ...
                                            KLT_candidateKeypointsTracker, ...
                                            cameraParams, globalData);
    else
        % get base info
        I_base = loadImage(ds,i-processFrame.reboot.stepsize, cameraParameters);
        base_orient = globalData.vSet.Views.Orientation{end-(processFrame.reboot.stepsize-1)};
        base_loc = globalData.vSet.Views.Location{end-(processFrame.reboot.stepsize-1)}';
       
        % re-bootstrap
        [currState, currRT, globalData] = re_bootstrap(I_base, base_orient, base_loc, I_curr, prevState, ...
                                            KLT_keypointsTracker, ...
                                            KLT_candidateKeypointsTracker, ...
                                            cameraParams, globalData);
        RE_BOOTSTRAP = false;
    end
    orientation = currRT(:,1:3);
    location = [currRT(3,4);currRT(1,4);currRT(2,4)].*const;
    % update globalData viewset
    viewId = i - bootstrap.images(2) + 2; 
    globalData.vSet = addView(globalData.vSet, viewId, 'Orientation', orientation, 'Location', location', 'Points', currState.keypoints);
    

end
t_end = clock;
duration2 = etime(t_end, t_start);
fprintf('Duration(s) %f\n ',duration2);
save('voResultData01','globalData','duration2');
