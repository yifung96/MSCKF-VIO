function [F,best_sample] = estimateFundamental_RANSAC(matchedPoints_0, matchedPoints_1,distanceThreshold,numTrials)
%ESTIMATEFUNDAMENTAL_RANSAC should do the same as estimateFundamentalMatrix
% Input: point correspondences
%  - matchedPoints_0(N,3): homogeneous coordinates of 2-D points in image 1
%  - matchedPoints_1(N,3): homogeneous coordinates of 2-D points in image 2
%  - distanceThreshold: distance to epipolar line to be inlier
%  - numTrials: nbr of runs in ransac
%
% Output:
%  - F(3,3) : fundamental matrix
%  - best_sample: bool array: inlier or not
%

%change orientation
matchedPoints_0 = [matchedPoints_0.Location ones(length(matchedPoints_0.Location),1)]';
matchedPoints_1 = [matchedPoints_1.Location ones(length(matchedPoints_1.Location),1)]';

%start ransac
samp = 8;
max_num_inliers = 0;

for i = 1:numTrials
    [matched_0_sampled, idx] = datasample(matchedPoints_0, samp, 2, 'Replace', false);
    matched_1_sampled = matchedPoints_1(:,idx);
    
    % Normalized 8-point algorithm
    % Call the normalized 8-point algorithm on inputs x1,x2
    Fn = fundamentalEightPoint_normalized(matched_0_sampled,matched_1_sampled);

    % Check the epipolar constraint x2(i).' * F * x1(i) = 0 for all points i.
    error = distPoint2EpipolarLine(Fn,matchedPoints_0,matchedPoints_1);
    inliers = error < distanceThreshold;
    num_inliers = nnz(inliers);
    
    % found better solution?
    if num_inliers > max_num_inliers
        max_num_inliers = num_inliers;
        best_sample = inliers;
    end
end

% recompute with all inliers
F = fundamentalEightPoint_normalized(matchedPoints_0(:,best_sample),matchedPoints_1(:,best_sample));


