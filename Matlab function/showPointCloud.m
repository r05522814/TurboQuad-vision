function showPointCloud(pointCloud, data)
% showPointCloud - This function shows a 3D point cloud and its
% corresponding distance map.
%
% Inputs:
%   pointCloud - nx3 matrix containing the world coordinates in 
%       (x,y,z)-format in mm for each of the n data points.
%   data - single data frame
%
% Other m-files required: none
% Subfunctions: 
%       getMapFromBuffer.m
%       fscatter3.m (optional)
% MAT-files required: none
% Toolboxes required: none

% Created: April 2016;
% Author: Uwe Hahne
% SICK AG, Waldkirch
% email: techsupport0905@sick.de
% Last commit: $Date: 2016-05-19 10:37:41 +0200 (Thu, 19 May 2016) $
% Last editor: $Author: hahneuw $ 

% Version "$Revision: 8900 $"

%------------- BEGIN CODE --------------

%% get camera parameters
cameraParams = data.getCameraParameters();
numRows      = cameraParams.getNumberOfRows();
numCols      = cameraParams.getNumberOfColumns();

% get range map
distanceMapBuffer = data.getDistanceData();
distanceMap = double(getMapFromBuffer(distanceMapBuffer,numRows,numCols));
% filter out invalid pixels
distanceMap(distanceMap > 7500) = 0;

% plot the distance map
figure(1);
clf;
h = subplot(1,2,1);
imagesc(distanceMap);
title('Distance map');
pos = get(h,'Position');
set(h,'Position',[pos(1) 5*pos(2) pos(3) 0.5*pos(4)]); 
xlabel('x-coordinates in pixels');
ylabel('y-coordinates in pixels');

% plot the corresponding point cloud
h = subplot(1,2,2);
% Alternative plots:
% scatter3:
% pointSize = 1;
% scatter3(pointCloud(:,1), pointCloud(:,2),...
%     pointCloud(:,3), pointSize, pointCloud(:,3), 'x');

% plot3:
%plot3(pointCloud(:,1), pointCloud(:,2),...
%    pointCloud(:,3), 'x');

% showPointCloud (since Matlab2014b):
%showPointCloud(pointCloud);

% using external tool fscatter3:
% fscatter3(pointCloud(:,1), pointCloud(:,2),...
%      pointCloud(:,3), distanceMap(:));
 
fscatter3(pointCloud(:,1), pointCloud(:,2),...
     pointCloud(:,3), pointCloud(:,3), jet); 
% fscatter3(x,y,z,z,jet);
% along z axis, colormap using jet distribution

view(-180,90);
title('Point cloud');
pos = get(h,'Position');
set(h,'Position',[pos(1) 3.5*pos(2) 1.5*pos(3) 0.5*pos(4)]); 

set(gca,'zdir','reverse');
set(gca,'ydir','reverse');
xlabel('x-coordinates in mm');
ylabel('y-coordinates in mm');
zlabel('z-coordinates in mm');
axis equal
grid on
title('3D point cloud');

end
