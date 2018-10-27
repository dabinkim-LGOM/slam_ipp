% SLAMTB_GRAPH  A graph-SLAM algorithm with simulator and graphics.
%
%   This script performs multi-robot, multi-sensor, multi-landmark 6DOF
%   graph-SLAM with simulation and graphics capabilities.
%
%   Please read slamToolbox.pdf and courseSLAM.pdf in the root directory
%   thoroughly before using this toolbox.
%
%   - Beginners should not modify this file, just edit USERDATA_GRAPH.M and
%   enter and/or modify the data you wish to simulate.
%
%   See also USERDATAGRAPH, SLAMTB.
%
%   Also consult slamToolbox.pdf and courseSLAM.pdf in the root directory.

%   Created and maintained by
%   Copyright 2008, 2009, 2010 Joan Sola @ LAAS-CNRS.
%   Copyright 2011, 2012, 2013 Joan Sola.
%   Copyright 2015-     Joan Sola @ IRI-UPC-CSIC.
%   Programmers (for parts of the toolbox):
%   Copyright David Marquez and Jean-Marie Codol @ LAAS-CNRS
%   Copyright Teresa Vidal-Calleja @ ACFR.
%   See COPYING.TXT for full copyright license.

%% OK we start here

% clear workspace and declare globals
clear
global Map    

% UAV workspace dimensions [m]
dim_x_env = 12;
dim_y_env = 12;
dim_z_env = 5;

%% I. Specify user-defined options
userData_graph_gp_3d;

%% II. Initialize all data structures from user-defined data
% SLAM data
[Rob,Sen,Raw,Lmk,Obs,Trj,Frm,Fac,Tim] = createGraphStructures(...
    Robot,...
    Sensor,...
    Time,...
    Opt);

% Pre-allocate all relative-motion robots:
factorRob = Rob;

% Simulation data
[SimRob,SimSen,SimLmk,SimOpt] = createSimStructures(...
    Robot,...
    Sensor,...      % all user data
    World,...
    SimOpt);

% Field mapping data and parameters
[planning_params, map_params, gp_params, ...
    training_data, gt_data, testing_data] = ...
    load_params_and_data(dim_x_env,dim_y_env,dim_z_env);
dim_x = map_params.dim_x;
dim_y = map_params.dim_y;
dim_z = map_params.dim_z;

% Lattice for 3D grid search
[lattice_env] = create_lattice(map_params, planning_params);
% GP field map
field_map = [];

% Number of time frames between each measurement.
measurement_frame_interval = 5; 

% Planning parameters
% First measurement, at current robot pose
goal_pose = Rob.state.x(1:3)';
% Reference speed [m/s]
speed = 0.1;

% Graphics handles.
[MapFig,SenFig,FldFig]          = createGraphicsStructures(...
    Rob, Sen, Lmk, Obs,...      % SLAM data
    Trj, Frm, Fac, ...
    SimRob, SimSen, SimLmk,...  % Simulator data
    testing_data.X_test, ...       % Field data
    FigOpt);                    % User-defined graphic options

% Clear user data - not needed anymore
clear Robot Sensor World Time   % clear all user data

%% III. Initialize data logging
% TODO.

%% IV. Startup 
% TODO: Possibly put in initRobots and createFrames, createFactors, createTrj...
for rob = [Rob.rob]
    
    % Reset relative motion robot
    factorRob(rob) = resetMotion(Rob(rob));
    
    % Add first keyframe with absolute factor
    Rob(rob).state.P = 1e-6 * eye(7); % Give 1cm error
    [Rob(rob),Lmk,Trj(rob),Frm(rob,:),Fac] = addKeyFrame(...
        Rob(rob),       ...
        Lmk,            ...
        Trj(rob),       ...
        Frm(rob,:),     ...
        Fac,            ...
        factorRob(rob), ...
        'absolute');
    
    for sen = Rob(rob).sensors
        
        % Initialize new landmarks
        ninits = Opt.init.nbrInits(1);
        for i = 1:ninits
            
            % Observe simulated landmarks
            Raw(sen) = simObservation(SimRob(rob), SimSen(sen), SimLmk, SimOpt) ;
            
            % Init new lmk
            fac = find([Fac.used] == false, 1, 'first');
            
            % Compute and allocate lmk
            [Lmk,Obs(sen,:),Frm(rob,Trj(rob).head),Fac(fac),lmk] = initNewLmk(...
                Rob(rob),   ...
                Sen(sen),   ...
                Raw(sen),   ...
                Lmk,        ...
                Obs(sen,:), ...
                Frm(rob,Trj(rob).head), ...
                Fac(fac),        ...
                Opt) ;
            
            if isempty(lmk)
                break
            end
            
        end
        
    end % end process sensors
    
    
end

%% V. Main loop
for currentFrame = Tim.firstFrame : Tim.lastFrame
    
    dy = goal_pose(2) - SimRob.state.x(2);
    dx = goal_pose(1) - SimRob.state.x(1);
    dz = goal_pose(3) - SimRob.state.x(3);
    
    theta = atan2(dy,dx);

    %SimRob.con.u(1:3) = speed*[cos(theta), sin(theta), 0];
    %Rob.con.u(1:3) = speed*[cos(theta), sin(theta), 0];
    SimRob.con.u(1:3) = speed*[dx,dy,dz];
    Rob.con.u(1:3) = speed*[dx,dy,dz];
    
    % 1. SIMULATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Simulate robots
    for rob = [SimRob.rob]

        % Robot motion
        SimRob(rob) = simMotion(SimRob(rob),Tim);
        
        % Simulate sensor observations
        for sen = SimRob(rob).sensors

            % Observe simulated landmarks
            Raw(sen) = simObservation(SimRob(rob), SimSen(sen), SimLmk, SimOpt) ;

        end % end process sensors

    end % end process robots

    

    % 2. ESTIMATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % 2.a. Robot motion prediction

    % Process robots
    for rob = [Rob.rob]

        % Robot motion
        % NOTE: in a regular, non-simulated SLAM, this line is not here and
        % noise just comes from the real world. Here, the estimated robot
        % is noised so that the simulated trajectory can be made perfect
        % and act as a clear reference. The noise is additive to the
        % control input 'u'.
        Rob(rob).con.u = ...
            SimRob(rob).con.u + Rob(rob).con.uStd.*randn(size(Rob(rob).con.uStd));
        
        Rob(rob) = simMotion(Rob(rob),Tim);
        
        % Integrate odometry for relative motion factors
        factorRob(rob).con.u = Rob(rob).con.u;
        factorRob(rob) = integrateMotion(factorRob(rob),Tim);
        
    end
    
    % Advance time
    Map.t = Map.t + Tim.dt;
    
    
    % 2.b. Graph construction and solving
    
    if mod(currentFrame - Tim.firstFrame + 1, Opt.map.kfrmPeriod) == 0
            
        % Process robots
        for rob = [Rob.rob]
            
            % Add key frame
            [Rob(rob),Lmk,Trj(rob),Frm(rob,:),Fac] = addKeyFrame(...
                Rob(rob),       ...
                Lmk,            ...
                Trj(rob),       ...
                Frm(rob,:),     ...
                Fac,            ...
                factorRob(rob), ...
                'motion');
            
            % Process sensor observations
            for sen = Rob(rob).sensors
                
                % Observe knowm landmarks
                [Rob(rob),Sen(sen),Lmk,Obs(sen,:),Frm(rob,Trj(rob).head),Fac] ...
                    = addKnownLmkFactors( ...
                    Rob(rob),   ...
                    Sen(sen),   ...
                    Raw(sen),   ...
                    Lmk,        ...
                    Obs(sen,:), ...
                    Frm(rob,Trj(rob).head), ...
                    Fac,        ...
                    Opt) ;
                
                % Initialize new landmarks
                ninits = Opt.init.nbrInits(1 + (currentFrame ~= Tim.firstFrame));
                for i = 1:ninits

                    % Init new lmk
                    [Lmk,Obs(sen,:),Frm(rob,Trj(rob).head),Fac,lmk] = initNewLmk(...
                        Rob(rob),   ...
                        Sen(sen),   ...
                        Raw(sen),   ...
                        Lmk,        ...
                        Obs(sen,:), ...
                        Frm(rob,Trj(rob).head), ...
                        Fac,        ...
                        Opt) ;
                    
                    if isempty(lmk) % Did not find new lmks
                        break
                    end
                    
                end % for i = 1:ninits
                
            end % end process sensors
            
        end % end process robots
        
        % Solve graph
        [Rob,Sen,Lmk,Obs,Frm,Fac] = solveGraph(Rob,Sen,Lmk,Obs,Frm,Fac,Opt);
        
        % Reset odometer and sync robot with graph
        for rob = [Rob.rob]
            
            % Update robots with Frm info
            Rob(rob) = frm2rob(Rob(rob),Frm(rob,Trj(rob).head));
            
            % Reset motion robot
            factorRob(rob) = resetMotion(Rob(rob));
      
        end
        
    end
    
    % 3. SENSING + GP UPDATE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (mod(currentFrame,measurement_frame_interval) == 0 && ...
            ~isempty(Map.pr) && ...
            pdist([Rob.state.x(1:3)'; goal_pose]) < planning_params.achievement_dist)
        
        for rob = [Rob.rob]
            
            [field_map, training_data] = ...
                take_measurement_at_point(Rob(rob), SimRob(rob), field_map, .....
                training_data, gt_data, testing_data, gp_params, map_params);
            
        end
        
        % 4. PLANNING
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [~, max_ind] = max(field_map.cov);
        [max_i, max_j, max_k] = ...
            ind2sub([dim_y, dim_x, dim_z], max_ind);
        goal_pose = ...
            grid_to_env_coordinates([max_j, max_i, max_k], map_params);
        disp(['Next goal: ', num2str(goal_pose)])
        
    end
    
    
    % 5. VISUALIZATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if currentFrame == Tim.firstFrame ...
            || currentFrame == Tim.lastFrame ...
            || mod(currentFrame,FigOpt.rendPeriod) == 0


        % Figure of the Map:
        MapFig = drawMapFig(MapFig,  ...
            Rob, Sen, Lmk,  ...
            Trj, Frm, Fac, ...
            SimRob, SimSen, ...
            FigOpt);
        
        % Figure of the Field:
        if mod(currentFrame,measurement_frame_interval) == 0 && ~isempty(Map.pr)
            FldFig = drawFldFig(FldFig,  ...
                Rob, Lmk, ...
                SimRob, ...
                field_map.mean, field_map.cov, ...
                FigOpt);
        end
        
        if FigOpt.createVideo
            makeVideoFrame(MapFig, ...
                sprintf('map-%04d.png',currentFrame), ...
                FigOpt, ExpOpt);
        end
        
        % Figures for all sensors
        for sen = [Sen.sen]
            SenFig(sen) = drawSenFig(SenFig(sen), ...
                Sen(sen), Raw(sen), Obs(sen,:), ...
                FigOpt);
            
            if FigOpt.createVideo
                makeVideoFrame(SenFig(sen), ...
                    sprintf('sen%02d-%04d.png', sen, currentFrame),...
                    FigOpt, ExpOpt);
            end
            
        end

        % Do draw all objects
        drawnow;
        
    end
    
    % 5. DATA LOGGING
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TODO: do something here to collect data for post-processing or
    % plotting. Think about collecting data in files using fopen, fwrite,
    % etc., instead of creating large Matlab variables for data logging.

end

%% VI. Post-processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Enter post-processing code here



% ========== End of function - Start GPL license ==========


%   # START GPL LICENSE

%---------------------------------------------------------------------
%
%   This file is part of SLAMTB, a SLAM toolbox for Matlab.
%
%   SLAMTB is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   SLAMTB is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with SLAMTB.  If not, see <http://www.gnu.org/licenses/>.
%
%---------------------------------------------------------------------

%   SLAMTB is Copyright:
%   Copyright (c) 2008-2010, Joan Sola @ LAAS-CNRS,
%   Copyright (c) 2010-2013, Joan Sola,
%   Copyright (c) 2014-2015, Joan Sola @ IRI-UPC-CSIC,
%   SLAMTB is Copyright 2009 
%   by Joan Sola, Teresa Vidal-Calleja, David Marquez and Jean Marie Codol
%   @ LAAS-CNRS.
%   See on top of this file for its particular copyright.

%   # END GPL LICENSE

