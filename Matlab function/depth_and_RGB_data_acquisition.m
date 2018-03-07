
%------------- BEGIN CODE --------------
clf; clear variables; close all; clc;
% javarmpath('../java/lib/V3SCameraAPI.jar');
clear java;


%% Parameter settings

% depth camera
enable_continuous_acquiring = 1; % 1:continuously acquiring data points, 0:dealing only one frame
enable_show_only_distance_map = 1; % 1:show only distance map, 2:show 3 maps
enable_compute_points_cloud_map = 0; % 1:show points in 3D view

% intensity_threshold = 0.0; %0.01 , data points in intensity map below the value are deleted 
confidence_threshold = 0.25; %0.05 , data points in confidence map below the value are deleted 
pitch_angle = -30; % define horizontal as zero, +:up, -:down 
flip_camera = 1; % if flip camera upside-down, switch to 1



% IP camera
% webcamlist

URL = 'http://169.254.171.242/cgi-bin/stream.cgi?type=jpeg&mode=live&session_id=0&fps=100&stream=0&prio=high&token=3012-00&frame=1.mjpg';
ipcam = ipcam(URL);

% preview_img = preview(cam);
% cam.AvailableResolutions
%% --------- Settings --------
% import the jar
javaaddpath('../java/lib/V3SCameraAPI.jar');
% just a check if the jar has been successfully added to the classpath
myClasspath = javaclasspath('-dynamic');
ok = strfind(cell2mat(myClasspath), 'V3SCameraAPI.jar');
if isempty(ok)
    error('Could not add V3SCameraAPI.jar to classpath');
end

import de.sick.svs.api.*;
ipAddress = '169.254.171.241';

% --------- Set the logger configuration --------
currPath = pwd;
LoggerConfigPath = strcat(currPath, '\..\java\resources\logging.properties');
LoggerConfiguration.activateLogging(LoggerConfigPath);

% --------- Initialize the device control --------
% initialize control over device using the device description in sUdd.xml
% currPath = pwd;
sUddPath = strcat(currPath, '\..\java\resources\V3SCameraEt.cid.processed.xml');
myDeviceFactory = javaObject('de.sick.svs.api.DeviceFactory');
myDevice = myDeviceFactory.obtainDevice(ipAddress, sUddPath);

% --------- Connect to device --------
% connect to device
if (~myDevice.isConnected())
    myDevice.connect();	
    if (myDevice.isConnected())
        disp('Depth camera connected');
    end
    % the image acquisition is started by default. It can be stopped manually
    if myDevice.isImageAcquisitionStarted()
        myDevice.stopImageAcquisition();
%         disp('Stopping image acquisition.');
    end
end


% --------- Initialize the data receiver --------
% create the raw data receiver object
myDataReceiverFactory = javaObject('de.sick.svs.api.DataReceiverFactory');
myDataReceiver = myDataReceiverFactory.obtainDataReceiver(ipAddress);

% create the listener object for the parsed data
myTestListener = javaObject('de.sick.svs.api.MatlabDataListener');

% add listener to data receiver
myDataReceiver.addListener(myTestListener);
% start data reception
myDataReceiver.startListening();

disp 'Listening for data has been started'

% --------- Get image size information --------
% receive one single blob to get the image size information
% as the data acquisition has been stopped trigger a single image

myDevice.triggerSingleImageAcquisition();
dataReceived = 0;
while(dataReceived == 0)
    pause(0.05) % waiting until the data is transferred
    % Note that usually 50 milliseconds is a good waiting time, 
    % but if some other system task (e.g. garbage collector) is 
    % interfering with the data receiver, it might take up to 
    % 1.5 seconds until the next frame is received.
    data = myTestListener.getData(); 
    if ~isempty(data)
        dataReceived = 1;
    end
end
myData = data.getDepthMapData();
cameraParams = myData.getCameraParameters();
numRows = cameraParams.getNumberOfRows();
numCols = cameraParams.getNumberOfColumns();

depthMapData = myData.getDepthMapData(); 

%% --------- Demo viewer settings --------

% --------- Start continuous image acquisition --------
if (~myDevice.isImageAcquisitionStarted())
    myDevice.startImageAcquisition();
    disp 'Restart ImageAcquisition...'
end
if (~myDataReceiver.isListening())
    myDataReceiver.startListening();
    disp 'Restart Listening...'
end

 

% Continuous acquiring
if enable_continuous_acquiring == 1
    
    % variable settings for this demo viewer; adjust for better visualization
%     dlims = [0 4000]; % appropriate limits for distance % [0 7500]
%     ilims = [0 3000]; % resp. intensity
%     clims = [0 65000]; % resp. confidence

%     disp 'Close figure window to stop live view'
    % create figure for live view
    live_view_window = figure;
    set(gcf,'name','Live view','Position', [100 100 700 800]);
    % while figure is open
    while ishandle(live_view_window)
        % read currently obtained blob
        myData = myTestListener.getData();
        %if (myData.getAvailableDataChannels())
        depthMapData = myData.getDepthMapData();       
              
        if enable_show_only_distance_map == 1
            % Show only one data
           
            buffer = depthMapData.getDistanceData();

            % convert buffer into matlab matrix
            distanceMap = getMapFromBuffer(buffer,numRows,numCols);

            lims = [0 4000];
%             % variable settings for this demo viewer; adjust for better visualization
%             dlims = [0 4000]; % appropriate limits for distance % [0 7500]
%             ilims = [0 3000]; % resp. intensity
%             clims = [0 65000]; % resp. confidence

            % draw the data
            if flip_camera == 1
                distanceMap = flip(flip(distanceMap,1),2);  % horizontal and vertical flip
            end
                   
            subplot(2,1,1)
            colormap(jet)
            imagesc(distanceMap,lims);
            title('Live view of selected map')
            axis equal;
            axis off;   
            
            % webcame
            subplot(2,1,2);
            RGB_src = snapshot(ipcam);
            imagesc(RGB_src);
            title('RGB image');
            axis equal;
            axis off;
            drawnow;

        else
            % Show all  data
            % get map
            distanceMap = double(getMapFromBuffer(depthMapData.getDistanceData(),numRows,numCols));
            intensityMap = double(getMapFromBuffer(depthMapData.getIntensityData(),numRows,numCols));
            confidenceMap = double(getMapFromBuffer(depthMapData.getConfidenceData(),numRows,numCols));
            if flip_camera == 1
                distanceMap = flip(flip(distanceMap,1),2);  % horizontal and vertical flip
                intensityMap = flip(flip(intensityMap,1),2);
                confidenceMap = flip(flip(confidenceMap,1),2);
            end
            subplot(2,2,1);
            imagesc(distanceMap,dlims);
            title('Distance');
    %         colorbar;
            axis off;
            subplot(2,2,2);
            imagesc(intensityMap,ilims);
            title('Intensity');
    %         colorbar;
            axis off;
            subplot(2,2,3);
            imagesc(confidenceMap,clims);
            title('Confidence');
    %         colorbar;
            axis off;
            
            % webcame
            subplot(2,2,4);
            RGB_src = snapshot(ipcam);
            imagesc(RGB_src);
            title('RGB image');
            axis off;

            drawnow

        end
    end

end


% stop the data reception
if (myDataReceiver.isListening())
    myDataReceiver.stopListening();
end

%% --------- Point cloud transformation --------
% take the last data received and transform the contained distance map to a 
% 3D point cloud

   
tic;
pointCloud_bodyframe = getPointCloudFromData(depthMapData); 
disp('Computing points cloud from last frame...');
% showPointCloud(pointCloud, depthMapData);


% get map
distanceMap = double(getMapFromBuffer(depthMapData.getDistanceData(),numRows,numCols));
intensityMap = double(getMapFromBuffer(depthMapData.getIntensityData(),numRows,numCols));
confidenceMap = double(getMapFromBuffer(depthMapData.getConfidenceData(),numRows,numCols));
% filter out invalid pixels
distanceMap(distanceMap > 7500) = 0;


% rotate wrt x-axis, and then rotate wrt z-axis (euler angle)
% the first is the pitch
if flip_camera == 1
    Rotation_bodyWRTworld = rotx(-pitch_angle) * rotx(90) * rotz(90);

% Rotation_bodyWRTworld = eye(3); % Identity matrix
else
    Rotation_bodyWRTworld = rotx(-30) * rotx(-90) * rotz(-90);
end

pointCloud_worldframe = Rotation_bodyWRTworld \ pointCloud_bodyframe';
pointCloud_worldframe = pointCloud_worldframe';

% filter out invalid pixels according to confidence map
% intensity_array = reshape(intensityMap, 1,[]);
confidence_array = reshape(confidenceMap, 1,[]);
% (1,1) -> (2,1) -> ... -> (144,1) -> (1,2) -> (2,2) -> ... -> (176,1)...
% the same arrangment as points cloud

% normalize confidence to [0,1]
% intensity_array = mat2gray(intensity_array);
confidence_array = mat2gray(confidence_array);

% intensity_filtered_index = find(intensity_array < intensity_threshold);
filtered_index = find(confidence_array < confidence_threshold);

% filtered_index = union(intensity_filtered_index,filtered_index);

pointCloud_worldframe_trim = pointCloud_worldframe;
filtered_points = pointCloud_worldframe(filtered_index,:);
pointCloud_worldframe_trim(filtered_index,:) = 0;

toc

if enable_compute_points_cloud_map == 1
    try
    fscatter3(filtered_points(:,1), filtered_points(:,2),...
         filtered_points(:,3), filtered_points(:,3), gray); 
    catch
    end
    fscatter3(pointCloud_worldframe_trim(:,1), pointCloud_worldframe_trim(:,2),...
         pointCloud_worldframe_trim(:,3), pointCloud_worldframe_trim(:,3), jet); 
    % along z axis, colormap using jet colormap distribution 



    xlabel('x');
    ylabel('y');
    zlabel('z');
    title(['World frame,Filtered points : ',num2str(numel(filtered_index)/(numRows*numCols)*100),'%']);
    axis equal;

    disp('done');

    toc
end
%% --------- Data output --------

dataoutput.maps = cat(3,distanceMap,intensityMap,confidenceMap);
% To extract the individual channels.
% Channel_1 = Mapdata(:, :, 1);
% Channel_2 = Mapdata(:, :, 2);
% Channel_3 = Mapdata(:, :, 3);
dataoutput.points = pointCloud_worldframe;

%% --------- Disconnect device --------
% Depth camera
% disconnect with device
if (myDevice.isConnected())
    myDevice.disconnect	
    if (~myDevice.isConnected())
        disp 'Disconnected successfully'
    end
end



% IP camera
clear('cam');


%% -------- Clean dynamic classpath ----------
% javarmpath('../java/lib/V3SCameraAPI.jar');
% clear java;

