clf; clear variables; close all; clc;

URL = 'http://169.254.171.242/cgi-bin/stream.cgi?type=jpeg&mode=live&session_id=0&fps=100&stream=0&prio=high&token=3012-00&frame=1.mjpg';
cam = ipcam(URL);


% cam = webcam('Integrated Camera'); % cam = webcam(1) 


%%

% preview(cam);


h = figure;

while ishandle(h)
    src = snapshot(cam);
%     subplot(2,2,1);

    % show the image 
%     imagesc(img);
%     img = flip(src,1);
    image(src);
    img_size = size(src);
    title(['Acquiring image, size = ',num2str(img_size(2)),' * ',num2str(img_size(1))]);
    axis off
end

clf;close all;
clear cam;




%%
% closePreview(cam);
% clear cam;