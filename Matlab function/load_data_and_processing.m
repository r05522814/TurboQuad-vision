clear variaables; clc;

depth_data = importdata('dataoutput_20180306_1.mat');
points = depth_data.points;
maps = depth_data.maps;


numRows = size(maps,1);
numCols = size(maps,2);


tic
intensity_threshold = 0.01; % 0.01
confidence_threshold = 0.05;

% filter out invalid pixels according to confidence map
intensity_array = reshape(maps(:, :, 2), 1,[]);
confidence_array = reshape(maps(:, :, 3), 1,[]);
% (1,1) -> (2,1) -> ... -> (144,1) -> (1,2) -> (2,2) -> ... -> (176,1)...
% the same arrangment as points cloud

% normalize confidence to [0,1]
intensity_array = mat2gray(intensity_array);
confidence_array = mat2gray(confidence_array);

intensity_filtered_index = find(intensity_array < intensity_threshold);
confidence_filtered_index = find(confidence_array < confidence_threshold);
 
filtered_index = union(intensity_filtered_index,confidence_filtered_index);

points_trim = points;
filtered_points = points(filtered_index,:);
points_trim(filtered_index,:) = 0;

try
fscatter3(filtered_points(:,1), filtered_points(:,2),...
     filtered_points(:,3), filtered_points(:,3), gray); 
catch
end
fscatter3(points_trim(:,1), points_trim(:,2),...
     points_trim(:,3), points_trim(:,3), jet); 
% along z axis, colormap using jet colormap distribution 



xlabel('x');
ylabel('y');
zlabel('z');
title(['World frame,Filtered points : ',num2str(numel(filtered_index)/(numRows*numCols)*100),'%']);
axis equal;

toc
