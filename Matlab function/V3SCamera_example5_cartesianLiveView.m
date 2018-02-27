function V3SCamera_example5_cartesianLiveView(ipAddress)
%% Demonstrate the API usage
%  Example 5: Cartesian Data Live View
%             This code illustrates how to configure the Cartesian 
%             data reduction and how to receive the reduced data.
%             Note that this example needs a V3S110 (AG) device. The data
%             reduction feature is not available in V3S100 (CX) devices.
%
% Inputs:
%   ipAddress - device ip address as string (optional)
% Other m-files required: RGGradient.m
% MAT-files required: none
% Toolboxes required: none

% Created: March 2016;
% Author: Uwe Hahne
% SICK AG, Waldkirch
% email: techsupport0905@sick.de
% Last commit: $Date: 2016-05-19 10:37:41 +0200 (Thu, 19 May 2016) $
% Last editor: $Author: hahneuw $ 

% Version "$Revision: 8900 $"

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

% set the ip address if not given.
if nargin == 0
    ipAddress = '192.168.1.10';
end

%% --------- Set the logger configuration --------
currPath = pwd;
LoggerConfigPath = strcat(currPath, '\..\java\resources\logging.properties');
LoggerConfiguration.activateLogging(LoggerConfigPath);
%% --------- Initialize the device control --------
% initialize control over device using the device description in sUdd.xml
currPath = pwd;
sUddPath = strcat(currPath, '\..\java\resources\V3SCameraEt.cid.processed.xml');
myDeviceFactory = javaObject('de.sick.svs.api.DeviceFactory');
myDevice = myDeviceFactory.obtainDevice(ipAddress, sUddPath);
%% --------- Connect to device --------
% connect to device
if (myDevice.isConnected() == 0)
    myDevice.connect();		
end
if (myDevice.isConnected() == 0)
    clear java;
    javarmpath('../java/lib/V3SCameraAPI.jar');
    error('Could not connect to the device, please check your settings.');    
end
%% check whether device supports polar reduction
devVariant = char(myDevice.readDeviceName());
if isempty(strfind(devVariant,'AG'))
    myDevice.disconnect();
    clear java;
    javarmpath('../java/lib/V3SCameraAPI.jar');
    error('This device does not support the Cartesian data reduction feature.');
end
%% --------- Login --------
myDevice.login(3, 'CLIENT');
%% --------- Enable Cartesian data reduction --------
myConfigurationFactory = javaObject('de.sick.svs.api.DeviceConfigurationFactory');
devConfig = myConfigurationFactory.obtainDeviceConfiguration(myDevice);
cartReduction = devConfig.getCartesianReduction();

% set sensor mounting
mountingAngle = 90;
mountingHeight = 1200;
sensorTilt = 90;
cartReduction.setSensorMounting(mountingHeight, mountingAngle, sensorTilt);

% set reduction parameter
numRows = 4;
numCols = 6;
xLimits = [-3000, -1000];
yLimits = [-1000, 1000];
zLimits = [0, 1000];

cartReduction.setNumCols(numCols);
cartReduction.setNumRows(numRows);
cartReduction.setVOIXMin(xLimits(1));
cartReduction.setVOIXMax(xLimits(2));
cartReduction.setVOIYMin(yLimits(1));
cartReduction.setVOIYMax(yLimits(2));
cartReduction.setVOIZMin(zLimits(1));
cartReduction.setVOIZMax(zLimits(2));
cartReduction.applySettings();
% enable reduction
if ~cartReduction.enable()
    error('Could not enable Cartesian reduction');
end
%% --------- Enable Cartesian data channel -------
devConfig.enableDataChannel(IDataChannel.CARTESIAN);
devConfig.disableDataChannel(IDataChannel.DEPTHMAP);
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
%% --------- Live view --------
runOnce = 0;
try
    % create figure for live view
    hf = figure;
    pos = get(hf,'Position');
    set(hf,'Position',[pos(1) pos(2) 2*pos(3) pos(4)]);
    t1 = tic;
    % while figure is open
    stop = 0;
    tmpCounter = 0;
    while ishandle(hf) && (stop == 0)
        % read currently obtained blob
        data = myTestListener.getData();
        if ~isempty(data)
            myData = data.getCopy();
            if (tmpCounter ~= myDataReceiver.getNumBlobsReceived) % assure a new blob
                tmpCounter = myDataReceiver.getNumBlobsReceived;
                if myData.getAvailableChannels().contains(IDataChannel.CARTESIAN)
                % get polar data
                cartesianData = myData.getCartesianData();

                % extract point cloud
                pointCloud = cell2mat(cartesianData.getPointCloud().toArray.cell);
                confidenceValues = cell2mat(cartesianData.getConfidenceValues().toArray.cell);
                numPoints = numel(pointCloud);
                
                X = zeros(numPoints,1);
                Y = zeros(numPoints,1);
                Z = zeros(numPoints,1);

                for i = 1:numPoints
                    X(i) = pointCloud(i).x;
                    Y(i) = pointCloud(i).y;
                    Z(i) = pointCloud(i).z;
                end
                % plot point cloud
                clf;
                hf = subplot(1,2,1);
                pointSize = 50;
                scatter3(X,Y,Z,pointSize,confidenceValues,'filled');
                title('Reduced point cloud');
                view(45,18);
                xlabel('X');
                xlim(xLimits);
                ylabel('Y');
                ylim(yLimits);
                zlabel('Z');
                zlim(zLimits);
                caxis([0 100])
                colormap(hf, RGGradient(256,100));
                c = colorbar;
                c.Label.String = 'Confidence (in %)';
                c.Location = 'westoutside';

                % plot bar chart
                hf = subplot(1,2,2);
                zMap = reshape(Z,numCols,numRows)';
                h = bar3(zMap);
                for k = 1:length(h)
                    zdata = h(k).ZData;
                    h(k).CData = zdata;
                    h(k).FaceColor = 'interp';
                end
                title('Cartesian data bars');
                view(-45,25);
                xlabel('Columns');
                ylabel('Rows');
                zlabel('Z');
                zlim(zLimits);
                colormap(hf,'jet');
            
                drawnow
                stop = runOnce;
                end
                
            else
                pause(0.1);
            end
        else
            pause(0.1);
            t2 = toc(t1);
            % if data is never received exit
            if (t2 - t1) > 1000
                break
            end
        end
    end
catch ME
    myDataReceiver.stopListening();
    cartReduction.disable();
    devConfig.enableDataChannel(IDataChannel.DEPTHMAP);
    devConfig.disableDataChannel(IDataChannel.CARTESIAN);
    rethrow(ME);
end
%% --------- Stop listening --------
myDataReceiver.stopListening();

if ~cartReduction.disable()
    error('Could not disable Cartesian reduction');
end

%% --------- Reset data channel --------
devConfig.enableDataChannel(IDataChannel.DEPTHMAP);
devConfig.disableDataChannel(IDataChannel.CARTESIAN);

%% --------- Logout --------
myDevice.logout();



%% --------- Disconnect device --------
myDevice.disconnect();

if (runOnce == 1)
    while ishandle(hf)
        pause(1);
    end
end

%% -------- Clean dynamic classpath ----------
clear java;
javarmpath('../java/lib/V3SCameraAPI.jar');

end
