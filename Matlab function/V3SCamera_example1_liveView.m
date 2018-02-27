function V3SCamera_example1_liveView(ipAddress)
%% Demonstrate the API usage
%  Example 1: Live view
%             This code assumes that the sensor is still sending images.
%             By default this is the case after it has been switched on.
%             If the image acquisition has been stopped it needs to be
%             started again for this script to work correctly. 
%             See example 3 "Image Acquisition".
%
% Inputs:
%   ipAddress - device ip address as string (optional)
% Other m-files required: getMapFromBuffer.m, getPointCloudFromData.m
% MAT-files required: none
% Toolboxes required: none

% Created: October 2014;
% Author: Uwe Hahne
% SICK AG, Waldkirch
% email: techsupport0905@sick.de
% Last commit: $Date: 2016-04-20 13:03:26 +0200 (Wed, 20 Apr 2016) $
% Last editor: $Author: hahneuw $ 

% Version "$Revision: 8641 $"

% Copyright note: Redistribution and use in source, with or without modification, are permitted.

%------------- BEGIN CODE --------------

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

% variable settings for this demo viewer; adjust for better visualization
dlims = [0 7500]; % appropriate limits for distance in mm
ilims = [0 3000]; % resp. intensity
clims = [0 65000]; % resp. confidence
selectedImage = 1; %1 = distance, 2 = intensity, 3 = confidence

switch selectedImage
case 1 
    disp 'Distance image has been selected'
case 2
    disp 'Intensity image has been selected'
case 3
    disp 'Confidence image has been selected'
end

% set the ip address if not given.
if nargin == 0
    ipAddress = '192.168.1.10';
end

%% --------- Set the logger configuration --------
currPath = pwd;
LoggerConfigPath = strcat(currPath, '\..\java\resources\logging.properties');
LoggerConfiguration.activateLogging(LoggerConfigPath);

%% --------- Data receiver --------
% create the raw data receiver object by using factory pattern
myDataReceiverFactory = javaObject('de.sick.svs.api.DataReceiverFactory');
myDataReceiver = myDataReceiverFactory.obtainDataReceiver(ipAddress);

% create the listener object for the parsed data
myTestListener = javaObject('de.sick.svs.api.MatlabDataListener');

% add listener to data receiver
myDataReceiver.addListener(myTestListener);
% start data reception
myDataReceiver.startListening();
if ~(myDataReceiver.isListening())
    clear java;
    javarmpath('../java/lib/V3SCameraAPI.jar');
    error('Data receiver could not connect or start listening');
end
try
    % --------- Get image size information --------
    % receive one single blob to get the image size information
    dataReceived = 0;
    waitingForDataCounter = 0;
    maxWait = 3; % maximum waiting time in seconds
    pauseTime = 0.1;
    while(dataReceived == 0 && waitingForDataCounter < (maxWait/pauseTime))
        data = myTestListener.getData();
        if ~isempty(data)
            myData = data.getCopy();
            if myData.getAvailableChannels().contains(IDataChannel.DEPTHMAP)
                dataReceived = 1;
            else
                error('Received different data format.');
            end
        else
            pause(pauseTime);
            waitingForDataCounter = waitingForDataCounter + 1;
        end
    end
    if (waitingForDataCounter == (maxWait/pauseTime))    
        error('Did not receive any data.');
    end
    cameraParams = myData.getDepthMapData().getCameraParameters();
    numRows = cameraParams.getNumberOfRows();
    numCols = cameraParams.getNumberOfColumns();

    % --------- Live view --------
    % create figure for live view
    h=figure;
    disp 'Close figure window to stop live view'
    % while figure is open
    while ishandle(h)
        % read currently obtained blob
        myData = myTestListener.getData().getCopy();
        %if (myData.getAvailableDataChannels())
        depthMapData = myData.getDepthMapData();
        % show selected data
        switch selectedImage
            case 1 % get distances            
                buffer = depthMapData.getDistanceData();
                lims = dlims;
                titleSuffix = 'Distance';
            case 2 % get intensities
                buffer = depthMapData.getIntensityData();
                lims = ilims;
                titleSuffix = 'Intensity';
            case 3 % get confidence
                buffer = depthMapData.getConfidenceData();            
                lims = clims;
                titleSuffix = 'Confidence';
        end
        % convert buffer into matlab matrix
        map = getMapFromBuffer(buffer,numRows,numCols);

        % draw the data
        imagesc(map,lims);
        title(['Live view of selected map: ' titleSuffix]);
        axis off
        drawnow
    end
catch ME
    disp('Error catched.');
    myDataReceiver.stopListening();
    rethrow(ME);
end
% --------- Stop listening --------
myDataReceiver.stopListening();

%% --------- Point cloud transformation --------
% take the last data received and transform the contained distance map to a 
% 3D point cloud
disp('Computing point cloud from last frame...');
tic;
pointCloud = getPointCloudFromData(depthMapData);
disp('...done');
toc
disp('Showing distance map and point cloud from last frame in new figure.');
showPointCloud(pointCloud, depthMapData);


%% -------- Clean dynamic classpath ----------
clear java;
javarmpath('../java/lib/V3SCameraAPI.jar');

end