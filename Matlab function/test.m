clear variables; clc;

x = [0,1,2;3,4,5;6,7,8];
a = reshape(x,1,[])

a = mat2gray(a)
noise = find(a<=0.5)
a(noise) = 0

b = [1,3];
x
x(b,:) = 0


% y = [0,0,1,1];
% z = [0,1,2,3];

% cat(3,x,y,z)



% fscatter3(x,y,z,z,jet);
% along z axis, colormap using jet distribution

% pointSize = 50;
% scatter3(x,y,z, pointSize, z, 'x');


% plot3(x, y, z,'markeredgecolor', c);

% pcshow([x',y',z'])


%%
clear variables; clc;
angle = 90/180*pi;
a = [1,0,0];
b = [0,2,0];
c = [0,0,3];

% R_x = [    1          0           0; 
%            0 cos(angle) -sin(angle); 
%            0 sin(angle)  cos(angle); ];
%      
% R_y = [ cos(angle)     0 sin(angle); 
%                  0     1          0; 
%         -sin(angle)    0 cos(angle); ]; 
%     
% R_z = [ cos(angle) -sin(angle)     0; 
%         sin(angle)  cos(angle)     0;
%                  0          0      1  ];
     
R =  rotx(90) * rotx(90) * rotz(90);  % new coordinate project on the old one     
             
a_1 = R \ c'

% case 'x'
%     rotatM = [1 0 0; 0 cos(angle) -sin(angle); 0 sin(angle) cos(angle);];
% case 'y'
%     rotatM = [cos(angle) 0 sin(angle);0 1 0;-sin(angle) 0 cos(angle);];
% case 'z'
%     rotatM = [cos(angle) -sin(angle) 0; sin(angle) cos(angle) 0; 0 0 1;];

%%
depth_data = importdata('dataoutput.mat');
points = depth_data.points;
maps = depth_data.maps;

%%
R = 10000;

C = 10000*10^(-12)


f = 1/(2*pi*R*C)
%%
a = [1 2 3];
a_i = find(a<3 )

b = [1 2 3 4];
b_i = find(b<4)


a_i






























