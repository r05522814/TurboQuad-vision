%% 
%  This code is used to take different categories of pictires 
%  and save to differnet folders for later training usage  
%  version 2017/12/03

clear('cam');
clear variables; clc;

%% Select camera

% webcamlist
select_camera = 2;
% 1:Integrated Camera on the laptop , 2: IP webcam

%% Initiate chosen webcame
switch select_camera
    case 1  % Integrated Camera on the laptop
        cam = webcam('Integrated Camera'); % cam = webcam(1) 
        
    
    case 2  % IP webcam
        URL = 'http://169.254.171.242/cgi-bin/stream.cgi?type=jpeg&mode=live&session_id=0&fps=100&stream=0&prio=high&token=3012-00&frame=1.mjpg';
        cam = ipcam(URL);
end
preview_img = preview(cam);
% cam.AvailableResolutions



%% Dealing with folder path
% folder_path ='../MATLAB/Acquiring_photo';
currentfolder = pwd;
folder_path = fullfile(currentfolder, 'test_photo');

% Check if the folder is exist
if (~isdir(folder_path))  
    mkdir(folder_path); % creat the folder
    disp('main folder is not exist, create one');
% else
%     disp('folder is exist');
end

%%

keyboardinput = 1; % initilization

prompt = ['Select the category\n'...
          '1:Asphalt 2:Floor 3:Grass 4:Gravel 5:Stairs \n'...
          'z or x:Exit\n'];

while(keyboardinput ~= 'z'  || ishandle(preview_img))

    keyboardinput = input(prompt,'s');
    switch keyboardinput
        case '1'
            fprintf('Asphalt selected\n\n');
            image_category = 'Asphalt ';
            image_folder_path = fullfile(folder_path,'Asphalt');
            
        case '2'
            fprintf('Floor selected\n\n');
            image_category = 'Pavement ';
            image_folder_path = fullfile(folder_path,'Pavement');
            
        case '3'
            fprintf('Grass selected\n\n');
            image_category = 'Grass ';
            image_folder_path = fullfile(folder_path,'Grass');

            
        case '4'
            fprintf('Gravel selected\n\n');
            image_category = 'Gravel ';
            image_folder_path = fullfile(folder_path,'Gravel');

            
        case '5'
            fprintf('Step selected\n\n');
            image_category = 'Step ';
            image_folder_path = fullfile(folder_path,'Step');
            
        case '6'
            fprintf('Stairs selected\n\n');
            image_category = 'Stairs ';
            image_folder_path = fullfile(folder_path,'Stairs');
        case '7'
            fprintf('Others selected\n\n');
            image_category = 'Others ';
            image_folder_path = fullfile(folder_path,'Others');
            
        case {'z','Z','x','X'}
            fprintf('End capture\n\n');
            break;
            
        otherwise
            fprintf('Invalid input\n\n');
            continue;
    end
    
    % Split each photo to corresponding folder
    if (~isdir(image_folder_path))  
        mkdir(image_folder_path); % creat the folder
        disp('Category folder is not exist, create one');
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
        img_origin = snapshot(cam);
        img = imresize(img_origin, [720, 1280]);  %[rows,cols] = [480,640]
        % img_count = img_count + 1;

        imagesc(img);
        axis off;
        drawnow;
        
        % calculate number of pictures already exist in the folder
        % .jpg and .png are considered
        pic_num_jpg = numel( dir([image_folder_path '/*.jpg']) );
        pic_num_png = numel( dir([image_folder_path '/*.png']) );
        pic_num = pic_num_jpg + pic_num_png;
        
        title_str = [image_category, num2str(pic_num + 1),' '];
        title(sprintf([title_str,char(datetime)]));

        disp(title_str); % show on command window

        baseFileName = sprintf([title_str,'.jpg']); % e.g. "Img 1.jpg"
        fullFileName = fullfile(image_folder_path, baseFileName);
        
        imwrite(img,fullFileName);
        

        
        try keyboard_pressed = waitforbuttonpress; 
        % mouse click = 0; keyboard pressed = 1
        catch
            warning('Waitforbuttonpress figure exit');
            keyboard_pressed = 1;
        end
    end
    
    if ishandle(captured_img)
        close(captured_img);
    end

end

%%
clear('cam');
close all;