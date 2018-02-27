function pointCloud = getPointCloudFromData(data)
% getPointCloudFromData - This function transforms the
% data (distance and camera parameters) received from the V3S100 
% device into a 3D point cloud.
%
% Inputs:
%   data - single data frame
% Outputs:
%   pointCloud - nx3 matrix containing the world coordinates in 
%       (x,y,z)-format in mm for each of the n data points.
%
% Other m-files required: none
% Subfunctions: getMapFromBuffer.m
% MAT-files required: none
% Toolboxes required: none

% Created: October 2014;
% Author: Jens Silva
% SICK AG, Waldkirch
% email: techsupport0905@sick.de
% Last commit: $Date: 2016-04-06 16:29:17 +0200 (Wed, 06 Apr 2016) $
% Last editor: $Author: hahneuw $ 

% Version "$Revision: 8514 $"

%------------- BEGIN CODE --------------

%% get camera parameters
cameraParams = data.getCameraParameters();
numRows      = cameraParams.getNumberOfRows();
numCols      = cameraParams.getNumberOfColumns();
cx           = cameraParams.getCenter().x();
cy           = cameraParams.getCenter().y();
fx           = cameraParams.getFocalLength().x();
fy           = cameraParams.getFocalLength().y();
f2rc         = cameraParams.getFocalToRayCross();
corrParams   = cameraParams.getCorrection();
k1           = corrParams.getK1();
k2           = corrParams.getK2();

% get range map
distanceMapBuffer = data.getDistanceData();
distanceMap = double(getMapFromBuffer(distanceMapBuffer,numRows,numCols));
% filter out invalid pixels
distanceMap(distanceMap > 7500) = 0;

% transform to 3D with real camera params
noPixels = numCols * numRows;

pointCloud = zeros(noPixels,3);
%%% convert matrix format of distmap to xyz-coordinate-format
if size(distanceMap,2) ~= 3
    % convert
    distanceMapXYZ = convertDistmapToXYZformat(distanceMap);
else
    % no conversion
    distanceMapXYZ = distanceMap;
end

% prepare for 3D point cloud computation
uvd = [distanceMapXYZ(:,1), distanceMapXYZ(:,2), ones(noPixels,1)];

% for each pixel compute
for i = 1:noPixels
    % Get depth and x and y on image plane
    row = uvd(i,2);
    col = uvd(i,1);
    depth = distanceMapXYZ(i,3);

    xp = (cx - col) / fx;
    yp = (cy - row) / fy;

    % Correction of the lens distortion
    r2 = (xp * xp + yp * yp);
    r4 = r2 * r2;
    k = 1 + k1 * r2 + k2 * r4;
    xp = xp * k;
    yp = yp * k;

    % Calculation of the distances
    s0 = sqrt(double(xp*xp + yp*yp + 1.0));

    % Calculation of the Cartesian coordinates
    xCoord = xp * depth / s0;
    yCoord = yp * depth / s0;
    zCoord = depth / s0 - f2rc;

    % Store data in point cloud data structure
    pointCloud(i,1) = xCoord;
    pointCloud(i,2) = yCoord;
    pointCloud(i,3) = zCoord;
end

function distanceMapXYZ = convertDistmapToXYZformat(distanceMap)
    % simply rewrite distmap to xyz-format
    rows = size(distanceMap,1);
    cols = size(distanceMap,2);
    distanceMapXYZ = distanceMap(:);
    yIndices = (1:rows)';
    xIndices = (1:cols)';

    xIndices = kron(xIndices, ones(rows, 1));
    yIndices = repmat(yIndices, cols, 1);
    distanceMapXYZ = [xIndices, yIndices, distanceMapXYZ];
end

end