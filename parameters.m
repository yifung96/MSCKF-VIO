% Parameters File

%********* dataset ***********
% possible ds values:
% 0: KITTI, 1: Malaga, 2: Parking
% 4: Swiss Alps One 5: Swiss Alps Two 6: Home Sweet Home)
ds = 0;

%********* plot parameters ************
plotParams.plot_on = true;          % Turn off plotting for speed
plotParams.record_video = false; 
plotParams.video_framerate = 5; 
plotParams.plot_p3p_outliers = true; 
plotParams.plot_invalid_ckeypoints = true;

%********* debugging (printouts) *********
debug.print_tracking = false;                                                %for Tracking in processFrame
debug.print_p3p = false;                                                     %for p3p in processFrame (inlier and delta_loc)
debug.print_triangulation = false;                                           % for alpha value based triangulation in processFrame
debug.print_new_landmarks = false;                                           % for nbr of new landmarks in triangulation
debug.print_new_features = false;                                            % for detection of new keypoints
debug.print_lsqnonlin = false;

% interruption after each frame
debug.keyboard_interrupt = false; 



%*********tuning parameters***************

%*********** params for all datasets BOOTSTRAP *****************   
       
% BOOTSTRAP images
bootstrap.init.numTrials = 100;                                     % NO TUNING bootstrap init nbr trials (run bootstrap max numTrial times)
bootstrap.init.first_location = [1, 0, 0];                          % bootstrap is accepted if close to this location
bootstrap.images = [1,3];                                           % used bootstrap frames

% feature detection method
bootstrap.det_method = 'harris';                                    % harris or fast, feature detection method        
    bootstrap.harris.min_quality = 1e-6; %TUNE                      % 0.001 init
    bootstrap.fast.min_quality = 0.01;

% selectUniform / nonMaxSupression
bootstrap.select_by_nonMax = true;
% nonMaxSupression
bootstrap.select_keypoints.delta = 6;  %TUNE                        % online: 8
bootstrap.select_keypoints.viaMatrix_method = false;                 %true for matrix filling approach, false for keypoints_loc method
bootstrap.select_keypoints.nbr_pts = 800; %TUNE                    
% selectUniform
bootstrap.harris.num_points = 500;                                  % 10000 init
bootstrap.fast.num_points = 20000;

% feature matching/tracking method 
bootstrap.use_KLT = true;

% KLT method             
bootstrap.klt.NumPyramidLevels = 5;                                 % online 5 % TODO: nbr was mentioned in lecture
bootstrap.klt.MaxBidirectionalError = 0.3;                          %5 % if inf, is not calculated
bootstrap.klt.BlockSize = [31 31];
bootstrap.klt.MaxIterations = 2000;

%FEATURE MATCHING method
bootstrap.desc_method = 'HOG';                                      % HOG or auto, descriptor method
bootstrap.match.max_ration = 0.6;                                   %(0,1)
bootstrap.match.match_threshold = 10;                               %(0,100)

% BOOTSTRAP LOOP
bootstrap.loop.numTrials = 50;

% estimate fundamental matrix (eFm)
bootstrap.eFm.numTrials = 20;                                      %nbr of estimateFundamentalMatrix runs
bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
bootstrap.eFm.ransac.distanceThreshold = 0.05; 
% bootstrap.eFm.ransac.confidence = 99.99999999999999;
bootstrap.eFm.ransac.inlierRatio = 0.7;

% landmark filter
bootstrap.triang.radius_threshold = 60;
bootstrap.triang.min_distance_threshold = 2; 
bootstrap.triang.num_landmarks_bootstrap = 600; %TUNE
bootstrap.triang.rep_e_threshold = inf; 
bootstrap.triang.min_landmark_ratio = 0.70; %0.72;                 % LOOP in bootstrap
bootstrap.triang.usegrid = false;

% TODO: here params for candidate kp search in bootstrap
bootstrap.is_close.delta = 6;                                      % currently meaningless

%*********** params for all datasets PROCESS FRAME ****************************************

% KLT point Tracker
processFrame.klt.NumPyramidLevels = bootstrap.klt.NumPyramidLevels;
processFrame.klt.MaxBidirectionalError = bootstrap.klt.MaxBidirectionalError; %5 % if inf, is not calculated
processFrame.klt.BlockSize = bootstrap.klt.BlockSize;
processFrame.klt.MaxIterations = bootstrap.klt.MaxIterations;

% isClose fct
processFrame.is_close.delta = 6; %TUNE

% run p3p and ransac for 3D-2D localization
processFrame.localization.numTrials = 3;

% ransac inside of runP3PandRANSAC
processFrame.p3p_ransac.num_iteration = 1000;
processFrame.p3p_ransac.pixel_tolerance = 3;                        % 2 init, better
processFrame.p3p_ransac.min_inlier = 8;
processFrame.p3p.max_delta_loc = 10;                                % max allowed step in loc

% triangulation
processFrame.triang.alpha_threshold = [deg2rad(3), deg2rad(40)];    % 20 init
processFrame.triang.rep_e_threshold = 10;                           %init 3 % max allowed reprojection error in triangulation
processFrame.triang.radius_threshold = 250;                         % max allowable radius from cam (not scaled) 
processFrame.triang.min_distance_threshold = 1;                     % min z-distance in front of cam (not scaled)  
processFrame.triang.max_landmarks_per_bin = 10; 
processFrame.triang.min_landmarks_threshold = 60; 
processFrame.triang.usegrid = true;

% detect new candidate kp
processFrame.max_candidate_keypoints = 2000;                        %no new keypoints are added if above max 
processFrame.det_method = bootstrap.det_method;

% harris
processFrame.harris.min_quality_process = 1e-6;
processFrame.harris.filter_size = 5;                                %must be odd

% selectUniform / NonMaxSupression
processFrame.select_by_nonMax = true;

% nonMaxSupression
processFrame.select_keypoints.delta = 6;                            % online: 8
processFrame.select_keypoints.nbr_pts = 500;
processFrame.select_keypoints.viaMatrix_method = true;              %true for matrix filling approach, false for keypoints_loc method    
processFrame.select_keypoints.sparseMatrix = true;                  %use sparse matrix, only useful if viaMatrix_method==true

% selectUniform
processFrame.harris.num_points = 600;

% re-bootstrap
processFrame.reboot.landmark_trigger = 150;
processFrame.reboot.stepsize = 3;                                   %bootstrap over 'stepsize' images-difference
processFrame.reboot.eFm.ransac.inlierRatio = 0.7;
processFrame.reboot.triang.radius_threshold = 60;
processFrame.reboot.triang.min_distance_threshold = 2;
processFrame.reboot.triang.rep_e_threshold = inf;
processFrame.reboot.triang.min_landmark_ratio = 0.30;
processFrame.reboot.triang.usegrid = false;
processFrame.reboot.triang.max_landmarks_per_bin = 10;

%***********PARAMETER DATASET SPECIFIC**************

switch(ds)
    %*********************************************************************
    %******  INDOOR ****************************************************    
    case 6
        
        %*********** BOOTSTRAP ******************************************
        % BOOTSTRAP images
        bootstrap.init.first_location = [0, 0, 1];                          % bootstrap is accepted if close to this location
        bootstrap.init.first_location = bootstrap.init.first_location./norm(bootstrap.init.first_location);
        bootstrap.images = [1,4];                                           % used bootstrap frames
        
        % feature detection method
        bootstrap.harris.min_quality = 1e-5; %TUNE                      % 0.001 init
            
        % nonMaxSupression
        bootstrap.select_keypoints.delta = 8;  %TUNE                        % online: 8
        bootstrap.select_keypoints.nbr_pts = 800; %TUNE                    
                
        % KLT method             
        bootstrap.klt.MaxBidirectionalError = 0.3;                          %5 % if inf, is not calculated
                
        % estimate fundamental matrix (eFm)
        bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
        bootstrap.eFm.ransac.distanceThreshold = 0.6;                      % LARGER THAN OTHER DATASETS
        bootstrap.eFm.ransac.inlierRatio = 0.55;                            
             
        % landmark filter
        bootstrap.triang.radius_threshold = 250;
        bootstrap.triang.min_distance_threshold = 2; 
        bootstrap.triang.max_landmarks_per_bin = 10; 
        bootstrap.triang.min_landmark_ratio = 0.60; %0.72;                 % LOOP in bootstrap
        bootstrap.triang.usegrid = false;
        
        %*********** PROCESS FRAME ****************************************

        % isClose fct
        processFrame.is_close.delta = 8; %TUNE

        % ransac inside of runP3PandRANSAC
        processFrame.p3p_ransac.num_iteration = 600;
        processFrame.p3p_ransac.pixel_tolerance = 10;                        % 2 init, better
        processFrame.p3p_ransac.min_inlier = 3;

        % triangulation
        processFrame.triang.alpha_threshold = [deg2rad(3), deg2rad(40)];    % 20 init
        processFrame.triang.rep_e_threshold = 20;                          %init 3 % max allowed reprojection error in triangulation
        processFrame.triang.radius_threshold = 250;                         % max allowable radius from cam (not scaled) 
        processFrame.triang.min_distance_threshold = 2;                   % min z-distance in front of cam (not scaled)  
        processFrame.triang.max_landmarks_per_bin = 10; 
        processFrame.triang.min_landmarks_threshold = 105;                 % triangulate again when #landmarks < min_landmarks_threshold
        processFrame.triang.usegrid = true;

        
        % detect new candidate kp
        processFrame.max_candidate_keypoints = 500;                        %no new keypoints are added if above max 
            
        % harris
        processFrame.harris.min_quality_process = 1e-5;
        processFrame.harris.filter_size = 5;                                %must be odd

        % nonMaxSupression
        processFrame.select_keypoints.delta = processFrame.is_close.delta;                            % online: 8
        processFrame.select_keypoints.nbr_pts = 500;
        
        % re-bootstrap
        processFrame.reboot.landmark_trigger = 40;
        processFrame.reboot.stepsize = 2;                                   %bootstrap over 'stepsize' images-difference
        processFrame.reboot.eFm.ransac.inlierRatio = 0.7;
        processFrame.reboot.triang.radius_threshold = 250;
        processFrame.reboot.triang.min_distance_threshold = 2;
        processFrame.reboot.triang.min_landmark_ratio = 0.15;
        processFrame.reboot.triang.usegrid = false;
    
    %*********************************************************************
    %******  ALPSTRASSE 1 ****************************************************    
    case 4
        
        %*********** BOOTSTRAP ******************************************
        % BOOTSTRAP images
        bootstrap.init.first_location = [0, 0, 1];                          % bootstrap is accepted if close to this location
        bootstrap.init.first_location = bootstrap.init.first_location./norm(bootstrap.init.first_location);
        bootstrap.images = [1,3];                                           % used bootstrap frames
        
        % feature detection method
        bootstrap.harris.min_quality = 1e-4; %TUNE                      % 0.001 init
            
        % nonMaxSupression
        bootstrap.select_keypoints.delta = 8;  %TUNE                        % online: 8
        bootstrap.select_keypoints.nbr_pts = 800; %TUNE                    
                
        % KLT method             
        bootstrap.klt.MaxBidirectionalError = 0.3;                          %5 % if inf, is not calculated
                
        % estimate fundamental matrix (eFm)
        bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
        bootstrap.eFm.ransac.distanceThreshold = 0.6;                      % LARGER THAN OTHER DATASETS
        bootstrap.eFm.ransac.inlierRatio = 0.55;                            
             
        % landmark filter
        bootstrap.triang.radius_threshold = 250;
        bootstrap.triang.min_distance_threshold = 2; 
        bootstrap.triang.max_landmarks_per_bin = 10; 
        bootstrap.triang.min_landmark_ratio = 0.60; %0.72;                 % LOOP in bootstrap
        bootstrap.triang.usegrid = false;
        
        %*********** PROCESS FRAME ****************************************

        % isClose fct
        processFrame.is_close.delta = 12; %TUNE

        % ransac inside of runP3PandRANSAC
        processFrame.p3p_ransac.num_iteration = 600;
        processFrame.p3p_ransac.pixel_tolerance = 10;                        % 2 init, better
        processFrame.p3p_ransac.min_inlier = 3;

        % triangulation
        processFrame.triang.alpha_threshold = [deg2rad(3), deg2rad(40)];    % 20 init
        processFrame.triang.rep_e_threshold = 20;                          %init 3 % max allowed reprojection error in triangulation
        processFrame.triang.radius_threshold = 250;                         % max allowable radius from cam (not scaled) 
        processFrame.triang.min_distance_threshold = 10;                   % min z-distance in front of cam (not scaled)  
        processFrame.triang.max_landmarks_per_bin = 6; 
        processFrame.triang.min_landmarks_threshold = 105;                 % triangulate again when #landmarks < min_landmarks_threshold
        processFrame.triang.usegrid = true;

        
        % detect new candidate kp
        processFrame.max_candidate_keypoints = 800;                        %no new keypoints are added if above max 
            
        % harris
        processFrame.harris.min_quality_process = 1e-3;
        processFrame.harris.filter_size = 5;                                %must be odd

        % nonMaxSupression
        processFrame.select_keypoints.delta = processFrame.is_close.delta;                            % online: 8
        processFrame.select_keypoints.nbr_pts = 500;
        
        % re-bootstrap
        processFrame.reboot.landmark_trigger = 40;
        processFrame.reboot.stepsize = 3;                                   %bootstrap over 'stepsize' images-difference
        processFrame.reboot.eFm.ransac.inlierRatio = 0.7;
        processFrame.reboot.triang.radius_threshold = 250;
        processFrame.reboot.triang.min_distance_threshold = 2;
        processFrame.reboot.triang.min_landmark_ratio = 0.15;
        processFrame.reboot.triang.usegrid = false;
        
    %*********************************************************************
    %******  ALPSTRASSE 2 ****************************************************    
    case 5
        
        %*********** BOOTSTRAP ******************************************
        % BOOTSTRAP images
        bootstrap.init.first_location = [0, 0, 1];                          % bootstrap is accepted if close to this location
        bootstrap.init.first_location = bootstrap.init.first_location./norm(bootstrap.init.first_location);
        bootstrap.images = [766 768];                                       % used bootstrap frames
        
        % feature detection method
        bootstrap.harris.min_quality = 1e-4; %TUNE                      % 0.001 init
            
        % nonMaxSupression
        bootstrap.select_keypoints.delta = 8;  %TUNE                        % online: 8
        bootstrap.select_keypoints.nbr_pts = 800; %TUNE                    
                
        % KLT method             
        bootstrap.klt.MaxBidirectionalError = 0.3;                          %5 % if inf, is not calculated
                
        % estimate fundamental matrix (eFm)
        bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
        bootstrap.eFm.ransac.distanceThreshold = 0.6;                      % LARGER THAN OTHER DATASETS
        bootstrap.eFm.ransac.inlierRatio = 0.55;                            
             
        % landmark filter
        bootstrap.triang.radius_threshold = 250;
        bootstrap.triang.min_distance_threshold = 2; 
        bootstrap.triang.max_landmarks_per_bin = 10; 
        bootstrap.triang.min_landmark_ratio = 0.60; %0.72;                 % LOOP in bootstrap
        bootstrap.triang.usegrid = false;
        
        %*********** PROCESS FRAME ****************************************

        % isClose fct
        processFrame.is_close.delta = 12; %TUNE

        % ransac inside of runP3PandRANSAC
        processFrame.p3p_ransac.num_iteration = 600;
        processFrame.p3p_ransac.pixel_tolerance = 10;                        % 2 init, better
        processFrame.p3p_ransac.min_inlier = 3;

        % triangulation
        processFrame.triang.alpha_threshold = [deg2rad(3), deg2rad(40)];    % 20 init
        processFrame.triang.rep_e_threshold = 20;                          %init 3 % max allowed reprojection error in triangulation
        processFrame.triang.radius_threshold = 250;                         % max allowable radius from cam (not scaled) 
        processFrame.triang.min_distance_threshold = 10;                   % min z-distance in front of cam (not scaled)  
        processFrame.triang.max_landmarks_per_bin = 6; 
        processFrame.triang.min_landmarks_threshold = 105;                 % triangulate again when #landmarks < min_landmarks_threshold
        processFrame.triang.usegrid = true;

        
        % detect new candidate kp
        processFrame.max_candidate_keypoints = 800;                        %no new keypoints are added if above max 
            
        % harris
        processFrame.harris.min_quality_process = 1e-3;
        processFrame.harris.filter_size = 5;                                %must be odd

        % nonMaxSupression
        processFrame.select_keypoints.delta = processFrame.is_close.delta;                            % online: 8
        processFrame.select_keypoints.nbr_pts = 500;
        
        % re-bootstrap
        processFrame.reboot.landmark_trigger = 40;
        processFrame.reboot.stepsize = 2;                                   %bootstrap over 'stepsize' images-difference
        processFrame.reboot.eFm.ransac.inlierRatio = 0.7;
        processFrame.reboot.triang.radius_threshold = 250;
        processFrame.reboot.triang.min_distance_threshold = 2;
        processFrame.reboot.triang.min_landmark_ratio = 0.15;
        processFrame.reboot.triang.usegrid = false;
        
        
        %*********************************************************************
    %******  MALAGA  ****************************************************    
    case 1
        
        %*********** BOOTSTRAP ******************************************
        
        % BOOTSTRAP images
        bootstrap.init.first_location = [-0.2, 0.2, 1];                          % bootstrap is accepted if close to this location
        bootstrap.init.first_location = bootstrap.init.first_location./norm(bootstrap.init.first_location);
        bootstrap.images = [1,3];                                           % used bootstrap frames
        
        % feature detection method
        bootstrap.harris.min_quality = 1e-6; %TUNE                      % 0.001 init
            
        % nonMaxSupression
        bootstrap.select_keypoints.delta = 6;  %TUNE                        % online: 8
        bootstrap.select_keypoints.nbr_pts = 800; %TUNE                    
                
        % KLT method             
        bootstrap.klt.MaxBidirectionalError = 0.3;                          %5 % if inf, is not calculated
                
        % estimate fundamental matrix (eFm)
        bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
        bootstrap.eFm.ransac.distanceThreshold = 0.6;                      % LARGER THAN OTHER DATASETS
        bootstrap.eFm.ransac.inlierRatio = 0.7;                            
             
        % landmark filter
        bootstrap.triang.radius_threshold = 60;
        bootstrap.triang.min_distance_threshold = 2; 
        bootstrap.triang.max_landmarks_per_bin = 10; 
        bootstrap.triang.min_landmark_ratio = 0.70; %0.72;                 % LOOP in bootstrap
        bootstrap.triang.usegrid = false;
        
        %*********** PROCESS FRAME ****************************************

        % isClose fct
        processFrame.is_close.delta = 12; %TUNE

        % ransac inside of runP3PandRANSAC
        processFrame.p3p_ransac.num_iteration = 600;
        processFrame.p3p_ransac.pixel_tolerance = 10;                        % 2 init, better
        processFrame.p3p_ransac.min_inlier = 3;

        % triangulation
        processFrame.triang.alpha_threshold = [deg2rad(3), deg2rad(40)];    % 20 init
        processFrame.triang.rep_e_threshold = 20;                          %init 3 % max allowed reprojection error in triangulation
        processFrame.triang.radius_threshold = 60;                         % max allowable radius from cam (not scaled) 
        processFrame.triang.min_distance_threshold = 10;                   % min z-distance in front of cam (not scaled)  
        processFrame.triang.max_landmarks_per_bin = 10; 
        processFrame.triang.min_landmarks_threshold = 105;                 % triangulate again when #landmarks < min_landmarks_threshold
        processFrame.triang.usegrid = false;

        
        % detect new candidate kp
        processFrame.max_candidate_keypoints = 800;                        %no new keypoints are added if above max 
            
        % harris
        processFrame.harris.min_quality_process = 1e-4;
        processFrame.harris.filter_size = 5;                                %must be odd

        % nonMaxSupression
        processFrame.select_keypoints.delta = processFrame.is_close.delta;                            % online: 8
        processFrame.select_keypoints.nbr_pts = 500;
        
        % re-bootstrap
        processFrame.reboot.landmark_trigger = 40;
        processFrame.reboot.stepsize = 3;                                   %bootstrap over 'stepsize' images-difference
        processFrame.reboot.eFm.ransac.inlierRatio = 0.7;
        processFrame.reboot.triang.radius_threshold = 80;
        processFrame.reboot.triang.min_distance_threshold = 2;
        processFrame.reboot.triang.min_landmark_ratio = 0.15;
        processFrame.reboot.triang.usegrid = false;

   
    %*********************************************************************
    %******  PARKING  ****************************************************    
    case 2
        
        %*********** BOOTSTRAP ******************************************
        
        % BOOTSTRAP images
        bootstrap.init.first_location = [1, 0, 0];                          % bootstrap is accepted if close to this location
        bootstrap.images = [1,3];                                           % used bootstrap frames
        
        % feature detection method
        bootstrap.harris.min_quality = 1e-4; %TUNE                      % 0.001 init
            
        % nonMaxSupression
        bootstrap.select_keypoints.delta = 8;  %TUNE                        % online: 8                 %true for matrix filling approach, false for keypoints_loc method
        bootstrap.select_keypoints.nbr_pts = 800; %TUNE
        
        % KLT method             
        bootstrap.klt.MaxBidirectionalError = 0.3;                          %5 % if inf, is not calculated
        
        % estimate fundamental matrix (eFm)
        bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
        bootstrap.eFm.ransac.distanceThreshold = 0.5; 
        bootstrap.eFm.ransac.inlierRatio = 0.7;
             
        % landmark filter
        bootstrap.triang.radius_threshold = 80;
        bootstrap.triang.min_distance_threshold = 2; 
        bootstrap.triang.max_landmarks_per_bin = 10; 
        bootstrap.triang.min_landmark_ratio = 0.50; %0.72;                 % LOOP in bootstrap                                   % currently meaningless
        bootstrap.triang.usegrid = false;
        
        %*********** PROCESS FRAME ****************************************

        % isClose fct
        processFrame.is_close.delta = 8; %TUNE
        
        % ransac inside of runP3PandRANSAC
        processFrame.p3p_ransac.num_iteration = 600;
        processFrame.p3p_ransac.pixel_tolerance = 3;                        % 2 init, better
        processFrame.p3p_ransac.min_inlier = 8;

        % triangulation
        processFrame.triang.alpha_threshold = [deg2rad(3), deg2rad(40)];    % 20 init
        processFrame.triang.rep_e_threshold = 10;                           %init 3 % max allowed reprojection error in triangulation
        processFrame.triang.radius_threshold = 80;                         % max allowable radius from cam (not scaled) 
        processFrame.triang.min_distance_threshold = 2;                     % min z-distance in front of cam (not scaled)  
        processFrame.triang.min_landmarks_threshold = 80;                   % triangulate again when #landmarks < min_landmarks_threshold
        processFrame.triang.max_landmarks_per_bin = 10; 
        processFrame.triang.usegrid = true;
        
        % detect new candidate kp
        processFrame.max_candidate_keypoints = 500;                        %no new keypoints are added if above max 
            
        % harris
        processFrame.harris.min_quality_process = 1e-4;
        processFrame.harris.filter_size = 5; 
        
        % nonMaxSupression
        processFrame.select_keypoints.delta = 8;                            % online: 8
        processFrame.select_keypoints.nbr_pts = 100;
        
        % re-bootstrap
        processFrame.reboot.landmark_trigger = 15;
        processFrame.reboot.stepsize = 3;                                   %bootstrap over 'stepsize' images-difference
        processFrame.reboot.eFm.ransac.inlierRatio = 0.7;
        processFrame.reboot.triang.radius_threshold = 80;
        processFrame.reboot.triang.min_distance_threshold = 1;
        processFrame.reboot.triang.min_landmark_ratio = 0.50;
        processFrame.reboot.triang.usegrid = false;
        
        %******************************************************************
        %******  KITTI  *************************************************** 
    case 0
        
        %*********** BOOTSTRAP ******************************************
        
        % BOOTSTRAP images
        bootstrap.init.first_location = [0, 0, 1];                          % bootstrap is accepted if close to this location
        bootstrap.images = [1,3];                                           % used bootstrap frames
        
        % feature detection method
        bootstrap.harris.min_quality = 1e-6; %TUNE                          % 0.001 init

        % nonMaxSupression
        bootstrap.select_keypoints.delta = 3;  %TUNE                        % online: 8
        bootstrap.select_keypoints.nbr_pts = 800; %TUNE                    
                
        % KLT method                                          
        bootstrap.klt.MaxBidirectionalError = 0.3 ;                         %5 % if inf, is not calculated

        % estimate fundamental matrix (eFm)
        bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
        bootstrap.eFm.ransac.distanceThreshold = 0.7; 
        bootstrap.eFm.ransac.inlierRatio = 0.7;
             
        % landmark filter
        bootstrap.triang.radius_threshold = 60;
        bootstrap.triang.min_distance_threshold = 1; 
        bootstrap.triang.max_landmarks_per_bin = 20; 
        bootstrap.triang.min_landmark_ratio = 0.60; %0.72;                 % LOOP in bootstrap
        
        %*********** PROCESS FRAME ****************************************
        
        % isClose fct
        processFrame.is_close.delta = 10; %TUNE
        
        % ransac inside of runP3PandRANSAC
        processFrame.p3p_ransac.num_iteration = 1000;
        processFrame.p3p_ransac.pixel_tolerance = 2.5;                        % 2 init, better
        processFrame.p3p_ransac.min_inlier = 3;

        % triangulation
        processFrame.triang.alpha_threshold = [deg2rad(2), deg2rad(60)];   % 20 init
        processFrame.triang.rep_e_threshold = 20;                          %init 3 % max allowed reprojection error in triangulation
        processFrame.triang.radius_threshold = 60;                         % max allowable radius from cam (not scaled) 
        processFrame.triang.min_distance_threshold = 3;                    % min z-distance in front of cam (not scaled)  
        processFrame.triang.max_landmarks_per_bin = 10; 
        processFrame.triang.min_landmarks_threshold = 100;                 % triangulate again when #landmarks < min_landmarks_threshold

        % detect new candidate kp
        processFrame.max_candidate_keypoints = 1000;                        %no new keypoints are added if above max 
            
        % harris
        processFrame.harris.min_quality_process = 1e-5;

        % nonMaxSupression
        processFrame.select_keypoints.delta = 15;                           % online: 8
        processFrame.select_keypoints.nbr_pts = 200;
        
        processFrame.reboot.landmark_trigger = 45;
        processFrame.reboot.stepsize = 3;                                   %bootstrap over 'stepsize' images-difference
        processFrame.reboot.eFm.ransac.inlierRatio = 0.7;
        processFrame.reboot.triang.radius_threshold = 200;
        processFrame.reboot.triang.min_distance_threshold = 2;
        processFrame.reboot.triang.min_landmark_ratio = 0.30;
        
    %*********************************************************************
    %******  CUSTOM_1  ****************************************************    
    otherwise
        
        %*********** BOOTSTRAP ******************************************
        
        % BOOTSTRAP images
        bootstrap.init.first_location = [0, 0, 1];                          % bootstrap is accepted if close to this location
        bootstrap.images = [1,6];                                           % used bootstrap frames
        
        % feature detection method
        bootstrap.harris.min_quality = 1e-6; %TUNE                      % 0.001 init
            
        % nonMaxSupression
        bootstrap.select_keypoints.delta = 6;  %TUNE                        % online: 8
        bootstrap.select_keypoints.nbr_pts = 800; %TUNE                    
                
        % KLT method             
        bootstrap.klt.MaxBidirectionalError = 0.3;                          %5 % if inf, is not calculated
                
        % estimate fundamental matrix (eFm)
        bootstrap.eFm.ransac.numTrials = 1000;                             %ransac inside of estimateFundamentalMatrix
        bootstrap.eFm.ransac.distanceThreshold = 0.6;                      % LARGER THAN OTHER DATASETS
        bootstrap.eFm.ransac.inlierRatio = 0.7;                            
             
        % landmark filter
        bootstrap.triang.radius_threshold = 60;
        bootstrap.triang.min_distance_threshold = 2; 
        bootstrap.triang.max_landmarks_per_bin = 10;
        bootstrap.triang.min_landmark_ratio = 0.70; %0.72;                 % LOOP in bootstrap
        
        %*********** PROCESS FRAME ****************************************

        % isClose fct
        processFrame.is_close.delta = 6; %TUNE

        % ransac inside of runP3PandRANSAC
        processFrame.p3p_ransac.num_iteration = 300;
        processFrame.p3p_ransac.pixel_tolerance = 3;                        % 2 init, better
        processFrame.p3p_ransac.min_inlier = 8;

        % triangulation
        processFrame.triang.alpha_threshold = [deg2rad(3), deg2rad(40)];    % 20 init
        processFrame.triang.rep_e_threshold = 20;                           %init 3 % max allowed reprojection error in triangulation
        processFrame.triang.radius_threshold = 250;                         % max allowable radius from cam (not scaled) 
        processFrame.triang.min_distance_threshold = 0.1;                   % min z-distance in front of cam (not scaled)  
        processFrame.triang.max_landmarks_per_bin = 10;
        processFrame.triang.min_landmarks_threshold = 70;                   % triangulate again when #landmarks < min_landmarks_threshold
            
        % detect new candidate kp
        processFrame.max_candidate_keypoints = 1000;                        %no new keypoints are added if above max 
            
        % harris
        processFrame.harris.min_quality_process = 1e-7;
        processFrame.harris.filter_size = 5;                                %must be odd

        % nonMaxSupression
        processFrame.select_keypoints.delta = 15;                            % online: 8
        processFrame.select_keypoints.nbr_pts = 500;
                            
end