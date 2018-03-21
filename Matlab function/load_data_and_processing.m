%% This code process the point cloud to become the elevation grid map
% Use elevstion grid to find the best path using shortest weighted algorithm 



clear variables; clc; close all;

%% parameter settings

enable_point_cloud = 0;  % plot 3D points distribution using fscatter3
enable_surf_plot = 1;
% intensity_threshold = 0.01; % 0.01
confidence_threshold = 0.5;
height_offset = 320; % z-dir offset between camera frame and world frame (mm)

elevationgrid_Xrange = [150 4000]; % forward direction, mm
elevationgrid_Yrange = [-1500 1500]; % side direction, mm
elevationgrid_sidelength = 100; % side legth of the grid, mm
gridmap_initial_value = 500;
gridmap_unseen_area_value = 700; % assign unseen area with a high value


%% import data
depth_data = importdata('dataoutput_20180306.mat');
points = depth_data.points;
points = points + [0, 0, height_offset];


maps = depth_data.maps;

numRows = size(maps,1);
numCols = size(maps,2);


%% Filtering points using confidence map

% filter out invalid pixels according to confidence map
% reshape map to array
intensity_array = reshape(maps(:, :, 2), 1,[]);
confidence_array = reshape(maps(:, :, 3), 1,[]);
% (1,1) -> (2,1) -> ... -> (144,1) -> (1,2) -> (2,2) -> ... -> (176,1)...
% the same arrangment as points cloud

% normalize confidence to [0,1]
intensity_array = mat2gray(intensity_array);
confidence_array = mat2gray(confidence_array);

% combine position info and intesity and confidence info,
% [x,y,z,intensity,confidence], 25344*3
points_allinfo = [points,intensity_array',confidence_array'];


% intensity_filtered_index = find(points_allinfo(:,4) < intensity_threshold);
filtered_index = find(points_allinfo(:,5) < confidence_threshold);

% intensity_filtered_index = find(intensity_array < intensity_threshold);
% confidence_filtered_index = find(confidence_array < confidence_threshold);
 
% filtered_index = union(intensity_filtered_index,filtered_index);

filtered_points = points_allinfo(filtered_index,(1:3)); 
points_trim = points_allinfo(:,(1:3)); % replication
points_trim(filtered_index,:) = 0;



%% Plot the points cloud 
figure(1)
colormap(jet);
% ------using fscatter3 to plot the 3D points------
if enable_point_cloud == 1
    tic
    disp('plotting 3D points distribution using fscatter3...');
    try
    fscatter3(filtered_points(:,1), filtered_points(:,2),...
         filtered_points(:,3), filtered_points(:,3), gray); 
    catch
    end
    fscatter3(points_trim(:,1), points_trim(:,2),...
         points_trim(:,3), points_trim(:,3), jet); 
    xlabel('x (mm)');
    ylabel('y (mm)');
    zlabel('z (mm)');
    title(['World frame, threshold = ',num2str(confidence_threshold),...
        ',Filtered points : ',num2str(numel(filtered_index)/(numRows*numCols)*100),'%']);
    axis equal;
    % along z axis, colormap using jet colormap distribution 
    toc
end

% using matlab 'sortrows' function, which is quick sort(stable)
% sort wrt y and then sort wrt x
% points_allinfo_sort = sortrows(points_allinfo,2);  % sort wrt y
% points_allinfo_sort = sortrows(points_allinfo_sort,1);  % sort wrt x

% ------convert 3D points to elevation grid------

tic
disp('convert 3D points to elevation grid');
%     figure(2)
%     colormap(jet);

% define index
x_ind = elevationgrid_Xrange(1):elevationgrid_sidelength:elevationgrid_Xrange(2);
y_ind = elevationgrid_Yrange(1):elevationgrid_sidelength:elevationgrid_Yrange(2);;

% initialize grid map
grid_map = ones(numel(x_ind)-1, numel(y_ind)-1,2);
grid_map(:,:,1) = grid_map(:,:,1) * gridmap_initial_value;

% iteratively calculate each grid
for i = 1:numel(x_ind)-1
    for j = 1:numel(y_ind)-1

        ind = x_ind(i)<points_allinfo(:,1) & points_allinfo(:,1)<x_ind(i+1) &...
              y_ind(j)<points_allinfo(:,2) & points_allinfo(:,2)<y_ind(j+1) ;

        if isempty(points_allinfo(ind,3))
            grid_map(i,j) = gridmap_unseen_area_value;
        else
            grid_map(i,j,1) = mean(points_allinfo(ind,3));
            grid_map(i,j,2) = var(points_allinfo(ind,3));
        end

    end
end

grid_map = imgaussfilt(grid_map,1);

toc

if enable_surf_plot == 1
    disp('plotting 3D elevation grid...');
    [grid_x,grid_y] = meshgrid(x_ind(1:end-1),y_ind(1:end-1));

    % plot the grid map
    surf(grid_x', grid_y', grid_map(:,:,1));
    xlabel('x (mm)');
    ylabel('y (mm)');
    zlabel('z (mm)');
    title(['World frame, threshold = ',num2str(confidence_threshold),...
        ',Filtered points : ',num2str(numel(filtered_index)/(numRows*numCols)*100),'%']);
    axis equal;

    toc
end

%% 2D Top view of elevation grid

% grid_map(:,:,1) => mean elevation
% grid_map(:,:,2) => variance


figure
colormap(jet);

imagesc(elevationgrid_Xrange, elevationgrid_Yrange, grid_map(:,:,1)'); 
set(gca,'YDir','normal'); % reset imagesc origin from left-up to left-down

xlabel('x (mm)');
ylabel('y (mm)');
title('Top view of elevation grid');
% rescale the axis
% xt = get(gca, 'XTick');                                 % 'XTick' Values
% yt = get(gca, 'YTick');                                 % 'XTick' Values
% set(gca, 'XTick', xt, 'XTickLabel', xt*100)  % Relabel 'XTick' With 'XTickLabel' Values
% set(gca, 'YTick', yt, 'YTickLabel', (yt-size(grid_map,2)/2)*100)    % Relabel 'XTick' With 'XTickLabel' Values


%% generate cost map and use dijkstra algorithm to search for lowest weighted path
% clear variables; clc; close all;
% 
% x = 0:1:5;
% y = 0:1:6;
% 
% z = ones(numel(y)-1,numel(x)-1);
% z(round(1:end-1),1:end) = 40;
% [grid_x,grid_y] = meshgrid(x(1:end-1),y(1:end-1));

% ele_map(:,:,1) = grid_x;
% ele_map(:,:,2) = grid_y;
% ele_map(:,:,3) = z;


% ele_map = [1 4 7 10; 2 5 8 11; 3 6 9 12]




elevation_map = grid_map(:,:,1)';

cost_map = zeros(numel(elevation_map),numel(elevation_map));

row_size = size(elevation_map,1);
col_size = size(elevation_map,2);

for col_ind = 1:(col_size-1)
    
%     cost_map( (col_ind-1)*row_size+1:col_ind*row_size ,  (col_ind)*row_size+1:(col_ind+1)*row_size)...
%         = ele_map(:,col_ind+1);
    
    cost_map( (col_ind-1)*row_size+1:col_ind*row_size ,  (col_ind)*row_size+1:(col_ind+1)*row_size)...
        = repmat(elevation_map(:,col_ind+1)',row_size,1);

%     temp = repmat(elevation_map(:,2)',row_size,1);
%     cost_map(1:3,4:6) = temp;
%     
    
    
end


adjacency_map = (cost_map ~= 0);

[costs,paths] = dijkstra(adjacency_map, cost_map, 15, 1000 );

elevation_map(paths) = -100;

figure
cmap = jet(max(elevation_map(:)));
cmap(1,:) = 0;
colormap(cmap);

imagesc(elevationgrid_Xrange, elevationgrid_Yrange, elevation_map); 
set(gca,'YDir','normal'); % reset imagesc origin from left-up to left-down

xlabel('x (mm)');
ylabel('y (mm)');
title('Elevation grid with path');
colorbar


% G = graph(cost_map,'upper');
% LWidths = 2*G.Edges.Weight/max(G.Edges.Weight);
% h = plot(G,'XData',grid_x(:),'YData',grid_y(:),'EdgeLabel',G.Edges.Weight,'LineWidth',LWidths);
% highlight(h, paths, 'EdgeColor', 'r' , 'NodeColor','r','LineWidth',2);









