function [map_params, planning_params, opt_params, gp_params, ...
    training_data, gt_data, testing_data] = ...
    load_params_and_data_ros(dim_x_env, dim_y_env)
% Loads default parameters + training data for RA-L19 IPP algorithms.

% Map resolution [m/cell]
map_params.res_x = 0.25;
map_params.res_y = 0.25;
% Map dimensions [cells]
map_params.dim_x = dim_x_env/map_params.res_x;
map_params.dim_y = dim_y_env/map_params.res_y;
% Position of map in the environment [m]
map_params.pos_x = -dim_x_env / 2;
map_params.pos_y = -dim_y_env / 2;

% Number of points in the 3D lattice
planning_params.lattice_points_x = 3;
planning_params.lattice_points_y = 3;

% Trajectory optimization references
planning_params.max_vel = 1.5;        % [m/s]
planning_params.max_acc = 3.0;        % [m/s^2]

% Robot initial measurement pose [x,y,yaw] [m,m,rad]
planning_params.meas_pose_init = [0, 0, pi/2];

% Achievement distance before a point is considered reached [m].
planning_params.achievement_dist = 0.1;

% Frequency at which to send commands - simulate motion/covariance update
planning_params.control_freq = 0.5;   % [Hz]
% Frequency at which to take measurements
planning_params.meas_freq = 0.25;    % [Hz]

% Number of control points for a polynomial (start point fixed).
planning_params.control_points = 4;

% Total time budget for informative planning [s].
planning_params.time_budget = 180;

% Objective function for informative planning.
% 'uncertainty_adaptive'/'uncertainty_rate_adaptive'/'renyi_adaptive'
% 'uncertainty'/'uncertainty_rate'/'renyi'
planning_params.obj_func = 'uncertainty';
% Renyi objective function only: uncertainty measure for alpha parameter.
planning_params.renyi_uncertainty = 'Aopt';

% Threshold for adaptive planning - only regions above this value are
% considered "interesting" and used when computing information gain.
planning_params.lower_thres = 30;
% Design parameter for uncertainty-aware adaptive planning
planning_params.beta = 0;

% Optimization/CMA-ES related parameters
opt_params.max_iters = 10;
opt_params.opt_method = 'cmaes'; % 'fmc'/cmaes'/'none'/'bo'
% Covariances in each search dimension
opt_params.cov_x = 1;
opt_params.cov_y = 1;

% GP-related parameters
gp_params.hyp_trained = hyp_trained;
gp_params.N_gauss = 9; %N_gauss;
gp_params.inf_func = inf_func;
gp_params.mean_func = mean_func;
gp_params.inf_func = inf_func;
gp_params.cov_func = cov_func;
gp_params.lik_func = lik_func;
% Whether to account for robot's pose uncertainty in GP field mapping.
gp_params.use_modified_kernel = 1;
% Whether to account for robot's pose uncertainty in prediction - objective function.
gp_params.use_modified_kernel_prediction = 1;

% Ground truth data - scale for this environment.
gt_data.X_gt(:,1) = X_gt(:,1) + map_params.pos_x;
gt_data.X_gt(:,2) = X_gt(:,2) + map_params.pos_y;
gt_data.Y_gt = Y_gt;
% Testing data - same resolution as ground truth
testing_data.X_test = gt_data.X_gt;
% Training data - estimated and real (ground truth)
training_data.X_train = [];
training_data.P_train = zeros(3,3,200);
training_data.X_train_gt = [];
training_data.Y_train = [];

end