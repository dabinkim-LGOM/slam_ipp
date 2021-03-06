close all;

% Function to generate 3-D Gaussian random field for a given mesh.

% Environment parameters.
dim_x_env = 5;
dim_y_env = 5;
dim_z_env = 4;
res_x = 0.25;
res_y = 0.25;
res_z = 1;

% Correlation function parameters.
corr.name = 'gauss';
corr.c0 = [3,3,3];
corr.sigma = 100;

% Create the random field.
x = linspace(0,dim_x_env,dim_x_env/res_x);
y = linspace(0,dim_y_env,dim_y_env/res_y);
z = linspace(0,dim_z_env,dim_z_env/res_z);
[X,Y,Z] = meshgrid(x,y,z); mesh = [X(:) Y(:) Z(:)];
F = randomfield(corr,mesh);
% Scale.
F = rescale(F, 0, 40);
ground_truth = F;

% Visualize the random field.
scatter3(mesh(:,1), mesh(:,2), mesh(:,3), 100, ground_truth, 'filled')
h_cb = colorbar;
ylabel(h_cb, 'Temp. (deg)')
axis equal
xlabel('x (m)')
ylabel('y (m)')
zlabel('z (m)')

save('ground_truth_3d_small10.mat', 'mesh', 'ground_truth')