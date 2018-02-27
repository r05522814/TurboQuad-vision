function V3SCamera_example4_polarLiveView(ipAddress)
%% Demonstrate the API usage
%  Example 4: Polar Data Live View
%             This code illustrates how to configure the polar 2D 
%             data reduction and how to receive the reduced data.
%             Note that this example needs a V3S110 (AG) device. The data
%             reduction feature is not available in V3S100 (CX) devices.
%
% Inputs:
%   ipAddress - device ip address as string (optional)
% Other m-files required: none
% MAT-files required: none
% Toolboxes required: none

% Created: July 2015;
% Author: Jens Silva
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
    error('This device does not support the polar data reduction feature.');
end

%% --------- Login --------
myDevice.login(3, 'CLIENT');
%% --------- Enable polar data reduction --------
myConfigurationFactory = javaObject('de.sick.svs.api.DeviceConfigurationFactory');
devConfig = myConfigurationFactory.obtainDeviceConfiguration(myDevice);

polarReduction = devConfig.getPolar2DReduction();
if ~polarReduction.enable()
    error('Could not enable polar 2D reduction');
end
    
%% --------- Enable polar data channel --------
devConfig.enableDataChannel(IDataChannel.POLAR2D);
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
try
    % create figure for live view
    h = figure;
    t1 = tic;
    % while figure is open
    while ishandle(h)
        % read currently obtained blob
        data = myTestListener.getData();
        if ~isempty(data)
            myData = data.getCopy();
            if myData.getAvailableChannels().contains(IDataChannel.POLAR2D)
                % get polar data
                polarData = myData.getPolar2DData();

                % extract key values
                angleFirstScanPoint = polarData.getAngleOfFirstDataPoint();
                angularResolution   = polarData.getAngularResolution();
                scanDists           = polarData.getFloatData();
                numScans            = scanDists.size();
                scanDists           = cell2mat(scanDists.toArray.cell);
                confidenceData      = polarData.getConfidenceData();
                confidenceData      = cell2mat(confidenceData.toArray.cell);

                % compute polar scan line
                polarScanLine       = zeros(numScans,3);
                polarScanLine(:,1)  = (0:numScans-1)';
                polarScanLine(:,2)  = scanDists;    
                polarScanLine(:,3)  = angleFirstScanPoint + polarScanLine(:,1) *  angularResolution;

                % transform to cartesian scan line
                cartScanLine        = zeros(numScans,2);
                cartScanLine(:,1)   = polarScanLine(:,2) .* cosd(polarScanLine(:,3));
                cartScanLine(:,2)   = polarScanLine(:,2) .* sind(polarScanLine(:,3));

                % plot scan line and confidence values            
                clf;
                h = subplot(1,2,1);
                plot(cartScanLine(:,2),cartScanLine(:,1))
                hold on;
                plot(cartScanLine(:,2),cartScanLine(:,1),'b.')
                plot([0 cartScanLine(1,2)], [0 cartScanLine(1,1)], 'y');
                plot([0 cartScanLine(end,2)], [0 cartScanLine(end,1)], 'c');
                axis([-8000,8000,0,8000])
                title('Polar 2D scan line')
                legend('Scan line','Sectors','ROI borders','location','southoutside')
                pos = get(h,'Position');
                set(h,'Position',[pos(1) 3.5*pos(2) pos(3) 0.5*pos(4)]);
                xlabel('x-coordinates in mm');
                ylabel('y-coordinates in mm');
                % plot the corresponding point cloud
                h = subplot(1,2,2);
                plot(1:numScans,confidenceData)
                hold on
                plot(1:numScans,confidenceData,'b.')
                axis([1,numScans,0,100])
                title('Confidence per sector')
                pos = get(h,'Position');
                set(h,'Position',[pos(1) 3.5*pos(2) pos(3) 0.5*pos(4)]);
                xlabel('x-coordinates in sectors');
                ylabel('y-coordinates in %');
                hold off;
                drawnow


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
    polarReduction.disable();
    rethrow(ME);
end

%% --------- Reset data channel --------
devConfig.enableDataChannel(IDataChannel.DEPTHMAP);
devConfig.disableDataChannel(IDataChannel.POLAR2D);

if ~polarReduction.disable()
    error('Could not disable polar 2D reduction');
end

%% --------- Logout --------
myDevice.logout();

%% --------- Stop listening --------
myDataReceiver.stopListening();

%% --------- Disconnect device --------
myDevice.disconnect();


%% -------- Clean dynamic classpath ----------
clear java;
javarmpath('../java/lib/V3SCameraAPI.jar');

end
