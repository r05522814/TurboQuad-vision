function V3SCamera_example2_deviceControl(ipAddress)
%% Demonstrate the API usage
% Example 2: Device control
%             This code illustrates how to connect to the device in order
%             to obtain access to its control functions, e.g. manually
%             triggering the image acquisition.
%             The specific control commands are shown in example 3.
% Inputs:
%   ipAddress - device ip address as string (optional)
% Other m-files required: none
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

% set the ip address if not given.
if nargin == 0
    ipAddress = '192.168.1.10';
end

%% --------- Set the logger configuration --------
currPath = pwd;
LoggerConfigPath = strcat(currPath, '\..\java\resources\logging.properties');
LoggerConfiguration.activateLogging(LoggerConfigPath);

%% --------- Initialize the device control --------
%%% initialize control over device using the device description in sUdd.xml
currPath = pwd;
sUddPath = strcat(currPath, '\..\java\resources\V3SCameraEt.cid.processed.xml');
myDeviceFactory = javaObject('de.sick.svs.api.DeviceFactory');
myDevice = myDeviceFactory.obtainDevice(ipAddress, sUddPath);


%% --------- Connect to device --------
if (myDevice.isConnected() == 0)
    disp('Connecting with device...');
    ok = myDevice.connect();
    if ok == false
        clear java;
        javarmpath('../java/lib/V3SCameraAPI.jar');
        error('Could not connect to device');
    end
end
if (myDevice.isConnected())
    disp('done.');
    % the image acquisition is started by default. It can be stopped manually
    autoStart = myDevice.isImageAcquisitionStarted();
    if (autoStart)        
        disp('Stopping image acquisition.');
        myDevice.stopImageAcquisition();
        % see example 3 how to trigger single image acquisition.
        
        % the image acquistion is restarted before disconnecting from
        % the device in order to bring the device back to default
        disp('Restarting image acquisition.');
        myDevice.startImageAcquisition();
    end
else
    disp('failed.');
    return;
end

%% --------- Device control --------
% Further device control code can be added here
disp('No code added, yet. Nothing will happen.')

%% --------- Disconnect device --------
myDevice.disconnect();

%% -------- Clean dynamic classpath ----------
clear java;
javarmpath('../java/lib/V3SCameraAPI.jar');

end