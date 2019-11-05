clf; clear variables; close all; clc;

URL = 'http://169.254.88.7/cgi-bin/stream.cgi?type=jpeg&mode=live&session_id=0&fps=100&stream=0&prio=high&token=805-00&frame=1.mjpg';
ipcam = ipcam(URL);


% cam = webcam('Integrated Camera'); % cam = webcam(1) 
enable_video = 0;  

%% Video settings
if enable_video == 1

    % set the playing speed of the video
    video_play_frame_rate = 1;
    
    video_filename = ['test',...
                      '.avi'];
    writerObj = VideoWriter(video_filename);
    writerObj.FrameRate = 1* 30 * video_play_frame_rate ;  % set playing frame rate
    open(writerObj);   
end
%%

% preview(cam);


h = figure;
set(gcf,'name','Live view');

while ishandle(h)
    
    src = snapshot(ipcam);
%     subplot(2,2,1);

    % show the image 
%     imagesc(img);
%     img = flip(src,1);
    image(src);
    img_size = size(src);
    title(['Acquiring image, size = ',num2str(img_size(2)),' * ',num2str(img_size(1))]);
    axis off
    
    
    if enable_video == 1
%         videoFrame = getframe(gcf);
%         writeVideo(vidWriter, Image);
        writeVideo(writerObj, src);
        hold off; 
    end
    
end
%%
clf;close all;
clear ipcam;

if enable_video == 1
    close(writerObj);
    fprintf('video finished\n');
end



%%
% closePreview(cam);
% clear cam;