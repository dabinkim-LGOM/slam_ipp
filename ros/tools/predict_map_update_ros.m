function field_map = predict_map_update_ros(pos, Rob_P, field_map, ...
    training_data, testing_data, map_params, gp_params)
% Predicts grid map update at an unvisited robot position
% using GP regression.
% --
% Inputs:
% pos: target [x,y] robot position [m] - env. coordinates
% Rob_P: robot position covariance [2x2]
% field_map: current GP field map (mean + covariance)
% ---
% Outputs:
% field_map
% ---
% M Popovic 2019
%

dim_x = map_params.dim_x;
dim_y = map_params.dim_y;

% Update training data.
training_data.X_train = [training_data.X_train; pos];
% Take maximum likelihood measurement based on current field map state.
training_data.Y_train = [training_data.Y_train; ...
    interp2(reshape(testing_data.X_test(:,1),dim_y,dim_x), ...
    reshape(testing_data.X_test(:,2),dim_y,dim_x), ...
    reshape(field_map.mean,dim_y,dim_x), ...
    pos(1), pos(2), 'spline')];

% Do GP regression and update the field map.
if (gp_params.use_modified_kernel_prediction)
    gp_params.cov_func = {@covUI, gp_params.cov_func, gp_params.N_gauss, Rob_P};
end
[ymu, ys, ~, ~, ~ , ~] = gp(gp_params.hyp_trained, ...
    gp_params.inf_func, gp_params.mean_func, gp_params.cov_func, gp_params.lik_func, ...
    training_data.X_train, training_data.Y_train, testing_data.X_test);
field_map.mean = ymu;
field_map.cov = ys;

end