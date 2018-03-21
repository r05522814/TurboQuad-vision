%% 
%  This code is used to take different categories of pictires 
%  and save to differnet folders for later training usage  
%  version 2018.03.19
%  including RGB and depth data

clear('cam');
clear variables; clc; close all;
% javarmpath('../java/lib/V3SCameraAPI.jar');
clear java;

pitch_angle = -30; % define pitch of depth camera, horizontal as zero, +:up, -:down (deg)
camera_height = 320; % define the z-dir offset of the camera center (mm)

%% Initiate chosen webcame
% webcamlist
select_camera = 2;
% 1:Integrated Camera on the laptop , 2: IP webcam
switch select_camera
    case 1  % Integrated Camera on the laptop
        cam = webcam('Integrated Camera'); % cam = webcam(1) 
        
    
    case 2  % IP webcam
        URL = 'http://169.254.171.242/cgi-bin/stream.cgi?type=jpeg&mode=live&session_id=0&fps=100&stream=0&prio=high&token=3012-00&frame=1.mjpg';
        cam = ipcam(URL);
end
preview_img = preview(cam);
% cam.AvailableResolutions

%% Initiate depth camera

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

% --------- Start continuous image acquisition --------
if (~myDevice.isImageAcquisitionStarted())
    myDevice.startImageAcquisition();
%     disp 'Restart ImageAcquisition...'
end
if (~myDataReceiver.isListening())
    myDataReceiver.startListening();
%     disp 'Restart Listening...'
end


%% Dealing with folder path
% folder_path ='../MATLAB/Acquiring_photo';
currentfolder = pwd;
folder_path_RGB = fullfile(currentfolder, 'test_photo_RGB');

% Check if the folder is exist
if (~isdir(folder_path_RGB))  
    mkdir(folder_path_RGB); % creat the folder
    disp('RGB main folder does not exist, create one');
end


%%

keyboardinput = 1; % initilization

prompt = ['\nSelect the category\n'...
          '1:Asphalt 2:Floor 3:Grass 4:Gravel 5:Stairs \n'...
          'z or x:Exit\n'];

while(keyboardinput ~= 'z'  || ishandle(preview_img))

    keyboardinput = input(prompt,'s');
    % Split each photo to corresponding folder
    switch keyboardinput
        case '1'
            fprintf('Asphalt selected\n\n');
            image_category = 'Asphalt';
            RGB_category_path = fullfile(folder_path_RGB,'Asphalt');
            
        case '2'
            fprintf('Floor selected\n\n');
            image_category = 'Pavement';
            RGB_category_path = fullfile(folder_path_RGB,'Pavement');         

        case '3'
            fprintf('Grass selected\n\n');
            image_category = 'Grass';
            RGB_category_path = fullfile(folder_path_RGB,'Grass');

            
        case '4'
            fprintf('Gravel selected\n\n');
            image_category = 'Gravel';
            RGB_category_path = fullfile(folder_path_RGB,'Gravel');
          
        case '5'
            fprintf('Step selected\n\n');
            image_category = 'Step';
            RGB_category_path = fullfile(folder_path_RGB,'Step');
            
        case '6'
            fprintf('Stairs selected\n\n');
            image_category = 'Stairs';
            RGB_category_path = fullfile(folder_path_RGB,'Stairs');

        case '7'
            fprintf('Others selected\n\n');
            image_category = 'Others';
            RGB_category_path = fullfile(folder_path_RGB,'Others');
            
        case {'z','Z','x','X'}
            fprintf('End capture\n\n');
            break;
            
        otherwise
            fprintf('Invalid input\n\n');
            continue;
    end
    
    if (~isdir(RGB_category_path))  
        mkdir(RGB_category_path); % creat the folder
        disp('RGB category folder is not exist, create one');
    end

    
    % Click mouse to get a snapshot; click any button to exit
    disp('Click mouse to get a snapshot');
    disp('Press any button to exit');
    
    captured_img = figure;
    
    try keyboard_pressed = waitforbuttonpress; 
    catch
        warning('Wait for buttonpress figure exit');
        keyboard_pressed = 1;
    end
        
    while(keyboard_pressed == 0 && ishandle(captured_img))
        
        %-----calculate number of pictures already exist in the folder-----
        % .jpg and .png are considered
        pic_num_jpg = numel( dir([RGB_category_path '/*.jpg']) );
        pic_num_png = numel( dir([RGB_category_path '/*.png']) );
        pic_num = pic_num_jpg + pic_num_png;
        
        % -----acqiring image-----
        % =====RGB image=====
        RGB_src = snapshot(cam);
        % resize the image
%         RGB_src = imresize(RGB_src, [720, 1280]);  %[rows,cols] = [480,640]

        % =====depth image=====
        myData = myTestListener.getData();
        depthMapData = myData.getDepthMapData(); 
        
        distanceMap = double(getMapFromBuffer(depthMapData.getDistanceData(),numRows,numCols));
        intensityMap = double(getMapFromBuffer(depthMapData.getIntensityData(),numRows,numCols));
        confidenceMap = double(getMapFromBuffer(depthMapData.getConfidenceData(),numRows,numCols));
        
        % ===Coordinate transformation===
        pointCloud_bodyframe = getPointCloudFromData(depthMapData);
        Rotation_bodyWRTworld = rotx(-pitch_angle) * rotx(90) * rotz(90); % consider flipping upside down 
%         Rotation_bodyWRTworld = rotx(pitch_angle) * rotx(-90) * rotz(-90); % consider orign settings
        pointCloud_worldframe = Rotation_bodyWRTworld \ pointCloud_bodyframe';
        pointCloud_worldframe = pointCloud_worldframe';
        pointCloud_worldframe = pointCloud_worldframe + camera_height;
        
        % ===flip the map===
        distanceMap = flip(flip(distanceMap,1),2);  % horizontal and vertical flip
        
        
        % -----show the captured image-----
        % =====depth image=====
        subplot(2,1,1)
        colormap(jet)
        imagesc(distanceMap,[0 4000]);
        title('distance map')
        axis equal;
        axis off;

        % =====RGB image=====
        subplot(2,1,2);
        imagesc(RGB_src);
        axis equal;
        axis off;
        drawnow;

        title_str = [image_category,' ',char(datestr(now,'mmdd-HHMMSS')),'-', num2str(pic_num + 1)];
        title(sprintf(title_str));
        disp(title_str); % show on command window

        % -----save the data-----
        baseFileName_RGB = sprintf([title_str,'.jpg']); % e.g. "Img 1.jpg"
        baseFileName_depth = sprintf([title_str,'.mat']);
        fullFileName_RGB = fullfile(RGB_category_path, baseFileName_RGB);
        fullFileName_depth = fullfile(RGB_category_path, baseFileName_depth);
        imwrite(RGB_src,fullFileName_RGB);
        
        depthdataoutput.maps = cat(3,distanceMap,intensityMap,confidenceMap);
        depthdataoutput.points = pointCloud_worldframe;
        save(fullFileName_depth,'depthdataoutput');
        
        
        try keyboard_pressed = waitforbuttonpress; 
        % mouse click = 0; keyboard pressed = 1
        catch
            warning('figure exit');
            keyboard_pressed = 1;
        end
    end
    
    if ishandle(captured_img)
        close(captured_img);
    end

end

%% Disconnect device

if (myDataReceiver.isListening())
    myDataReceiver.stopListening();
end
if (myDevice.isConnected())
    myDevice.disconnect	
    if (~myDevice.isConnected())
        disp 'Disconnected successfully'
    end
end

clear('cam');
close all;