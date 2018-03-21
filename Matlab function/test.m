clear variables; clc;


%% 

s = [1 1 1 2 5 5 5 8 9 9];
t = [2 3 4 5 6 7 8 9 10 11];
G = graph(s,t);
plot(G)

d = distances(G)

%%
clear variables; clc;
tic
W = [.41 .99 .51 .32 .15 .45 .38 .32 .36 .29 .21];
DG = sparse([6 1 2 2 3 4 4 5 5 6 1],[2 6 3 5 4 1 6 3 4 3 5],W)

h = view(biograph(DG,[],'ShowWeights','on'))
[dist,path,pred] = graphshortestpath(DG,1,4)
toc


%%
x = [0,1,2;3,4,5;6,7,8]


a = x + [0,0,1]
% a = reshape(x,1,[])
% 
% a = mat2gray(a)
% noise = find(a<=0.5)
% a(noise) = 0
% 
% b = [1,3];
% x
% x(b,:) = 0


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
%% Curve fitting
fitting_fn = fittype('a*x*x + b*x ');

grid_map_rot90 = rot90(grid_map(:,:,1)); % due to the matix indexing, rotate map
fitting_weight = max(grid_map_rot90) - grid_map_rot90;

flip_grid_y = flip(grid_y,1);

[fit1,gof,fitinfo] = fit(grid_x(:),flip_grid_y(:),fitting_fn,...
                            'StartPoint',[0 0],...
                            'weight',fitting_weight(:));
                        
                        
residuals = fitinfo.residuals;
I = abs( residuals) > 1 * std( residuals );
outliers = excludedata(grid_x(:),flip_grid_y(:),'indices',I);

fit2 = fit(grid_x(:),flip_grid_y(:),fitting_fn,'StartPoint',[0 0],...
           'Exclude',outliers);                        
                        
% figure
% plot(grid_x(:),flip_grid_y(:),'k.');
hold on
plot_fitted_curve_1 = plot(fit1,'k-');
plot_fitted_curve_2 = plot(fit2,'r-');
set(plot_fitted_curve_1,'linewidth',5);
% set(plot_fitted_curve_2,'linewidth',5);


%%
I = imread('file01.png');
I2 = flipdim(I ,2);           %# horizontal flip
I3 = flipdim(I ,1);           %# vertical flip
I4 = flipdim(I3,2);    %# horizontal+vertical flip
subplot(2,2,1), imshow(I)
subplot(2,2,2), imshow(I2)
subplot(2,2,3), imshow(I3)
subplot(2,2,4), imshow(I4)

%%
clc;clear all;

% x = -2:0.25:2;
% y = x;
% [X,Y] = meshgrid(x,y)
% F = X.*exp(-X.^2-Y.^2);
% 
% surf(X,Y,F);
%%
X = [0,0,0,0,1,1,1,1];
Y = [0,1,2,3,0,1,2,3];
F = [0,10,1,2,3,8,2,3];





A = [X;Y;F]'

ind = -1<A(:,1) & A(:,1)<1

D = [mean(A(ind,3)), var(A(ind,3))]


% 
% 
% A_t = [A,F']
% % 
% B = sortrows(A,2)
% 
% C = sortrows(B,1)

% 
% tic
% figure(1)
% 
% X = reshape(X,[4 2]);
% Y = reshape(Y,[4 2]);
% F = reshape(F,[4 2]);
% 
% surf(X,Y,F);
% toc
% 
% figure(2)
% fscatter3(X(:),Y(:),F(:),F(:));
% 
% toc

%%
clear variables; clc;
xdata = (0:0.1:2)';
y0 = xdata .^ 2;


% Response-dependent Gaussian noise
gnoise = y0.*randn(size(y0));

% Salt-and-pepper noise
spnoise = zeros(size(y0));
p = randperm(length(y0));
sppoints = p(1:round(length(p)/5));
spnoise(sppoints) = 5*sign(y0(sppoints));

ydata = y0 ;
% + gnoise + spnoise;



% 
% f = fittype('a*sin(b*x)');

f = fittype('a*x');

% f_opt = fitoptions(f);
f_weight = [1 1 1 1 10 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];

[fit1,gof,fitinfo] = fit(xdata,ydata,f,'StartPoint',0,...
   'weight',f_weight);


fit1

residuals = fitinfo.residuals;
I = abs( residuals) > 1.5 * std( residuals );
outliers = excludedata(xdata,ydata,'indices',I);
% 
% fit2 = fit(xdata,ydata,f,'StartPoint',[1 1],...
%            'Exclude',outliers);
% 
% 
% fit3 = fit(xdata,ydata,f,'StartPoint',[1 1],'Robust','on');


plot(fit1,'r-',xdata,ydata,'k.',outliers,'m*')
hold on
% plot(fit2,'c--')
% plot(fit3,'b:')
xlim([0 2*pi])
% legend( 'Data', 'Data excluded from second fit', 'Original fit',...
%     'Fit with points excluded', 'Robust fit' )
hold off

%%
clear variables; clc; clf
x = 0:1:10;
y = 0:1:15;

z = ones(numel(y)-1,numel(x)-1);

z(1:end/2,1:end) = 400;


[grid_x,grid_y] = meshgrid(x(1:end-1),y(1:end-1));


f = fittype('a*x^2 + b*x');


[fit1,gof,fitinfo] = fit(grid_x(:),grid_y(:),f, ...
                       'StartPoint',[0 0],...
                       'weight',z(:));

fitinfo.residuals;

plot(fit1,'r-',grid_x(:),grid_y(:),'k.')

%%

clear variables; clc; clf
x = [1 2 3 5 7 10]';
y = [109 149 149 191 213 224]';

plot(x,y,'ko');
xlabel('Incubation (days), x'); ylabel('Biochemical oxygen demand (mg/l), y');

w = [1 1 10 10 10 10]';

modelFun = @(a,x) a(1).*x.*x + a(2).*x;
start = [240; .5];

nlm = fitnlm(x,y,modelFun,start);
xx = linspace(0,12)';
line(xx,predict(nlm,xx),'linestyle','--','color','k')

wnlm = fitnlm(x,y,modelFun,start,'Weight',w)
line(xx,predict(wnlm,xx),'color','b')

%%

clear variables; clc; clf
x = 0:1:10;
y = 0:1:15;
w = ones(numel(y)-1,numel(x)-1);

w(1:round(end/2),1:end) = 10;

[grid_x,grid_y] = meshgrid(x(1:end-1),y(1:end-1));

f_grid_y = flip(grid_y,1);

modelFun = @(a,x) a(1).*x.*x + a(2).*x;
start = [0 0];

nlm = fitnlm(grid_x(:),f_grid_y(:),modelFun,start);
xx = linspace(0,10)';

plot(grid_x(:),f_grid_y(:),'k.');


line(xx,predict(nlm,xx),'linestyle','--','color','k')

wnlm = fitnlm(grid_x(:),f_grid_y(:),modelFun,start,'Weight',w(:));
line(xx,predict(wnlm,xx),'color','b')

%% test mouse input
while(1)
%     keyboard_pressed = 1;
    try keyboard_pressed = waitforbuttonpress; 
    catch
        warning('Wait for buttonpress figure exit');
%         keyboard_pressed = 1;
    end
%     if keyboard_pressed == 0
%     end
    disp(keyboard_pressed);

end
%%
clear variables; clc; close all;
A=[9 24 6 12 6;
	0 33 24 0 12;
	0 0 13 14 12;
	0 0 0 0 1];
imagesc(A);
cmap = jet(max(A(:)));

% Make values [0,1) black:
cmap(1,:) = 0;
colormap(cmap);
colorbar


















