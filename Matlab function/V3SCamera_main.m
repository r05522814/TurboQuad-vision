function V3SCamera_main(exampleNo, ipAddress)
% V3SCamera_main - This main function is simply used to call the different
% examples.
% IMPORTANT NOTE: Example 1, 4 and 5 assume that the data acquisition is running 
% as it is by default when the sensor is switched on.
%
% Inputs:
%   exampleNo - choose the example to be shown
%   ipAddress - device ip address as string (optional)

% Other m-files required: V3SCamera_example1_liveView.m,
%                         V3SCamera_example2_deviceControl.m, 
%                         V3SCamera_example3_imageAcquisition.m
%                         V3SCamera_example4_polarLiveView
%                         V3SCamera_example5_cartesianLiveView

% Subfunctions: none
% MAT-files required: none
% Toolboxes required: none

% Created: October 2014;
% Author: Jens Silva
% SICK AG, Waldkirch
% email: techsupport0905@sick.de
% Last commit: $Date: 2016-04-06 16:29:17 +0200 (Wed, 06 Apr 2016) $
% Last editor: $Author: hahneuw $ 

% Version "$Revision: 8514 $"

% Copyright note: Redistribution and use in source, with or without modification, are permitted.

%------------- BEGIN CODE --------------
%% set ip address of the device. Provide it as argument if your ip settings have been changed.
if nargin == 1
    % ipAddress = '192.168.1.10';
    ipAddress = '169.254.171.241';
end

%% run the individual examples
switch exampleNo
    case 1
        % show the live stream of incoming data
        V3SCamera_example1_liveView(ipAddress);
    case 2
        % connect and disconnect to the device
        V3SCamera_example2_deviceControl(ipAddress);
    case 3
        % control the device and use both image acquistion meachanics
        V3SCamera_example3_imageAcquisition(ipAddress);
    case 4
        % control the device and use both image acquistion meachanics
        V3SCamera_example4_polarLiveView(ipAddress);
    case 5
        % control the device and use both image acquistion meachanics
        V3SCamera_example5_cartesianLiveView(ipAddress);
end

end

