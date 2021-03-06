% input:
    %N step of:
        % accelerations
        % position
        % velocities
        % global yaw atan2(ty-y(k),tx-x(k)); %yaw 
        % global pitch atan2(z(k),sqrt((ty-y(k))^2+(tx-x(k))^2));% pitch 
    % obstacle position
    % radius of the obstacle
    % initial pose of the flyover
    % final pose of the flyover
    % time_step

%output:
    %minimum distance to the obstacle
    % average error respect to the desired path
    % average of accelerations
    % snap: fourth derivative of camera trajectory
    % jerk: third derivative of global angles

function metrics(traj, obst_x, obst_y, obst_z,radius, initial_pose, final_pose, time_step, shot_duration)

[n_variables N] = size(traj);
u = [traj(1,:); traj(2,:); traj(3,:)];
pose = [traj(4,:); traj(5,:); traj(6,:)];
vel = [traj(7,:); traj(8,:); traj(9,:)];
yaw = traj(12,:);
pitch = traj(13,:);

for i=1:N
   if yaw(i)<0
       yaw=yaw+2*pi;
   end
   while(yaw(i)>2*pi)
       yaw(i)=yaw(i)-2*pi;
   end
end

for i=1:N
   if pitch(i)<0
       pitch=pitch+2*pi;
   end
   while(pitch(i)>2*pi)
       pitch(i)=pitch(i)-2*pi;
   end
end

%% minimum distance to obstacle
min_dist = inf;
for i=1:N
     dist = norm((pose((1:3),i)-[obst_x;obst_y;obst_z]))-radius;
     if min_dist>dist
         min_dist = dist;
     end
end
fprintf('The minimum distance to the obstacle: %d \n', min_dist);
%% average error respect to the desired path
desired_path = [];
path_error = [];

for k=1:N
   next_pose = initial_pose+(final_pose-initial_pose)*((k-1)*time_step)/shot_duration;
   desired_path = [desired_path next_pose'];
   path_error = [path_error norm(pose(:,k)-desired_path(:,k))^2];
end

mean_average_error = sqrt(mean(path_error));
fprintf('The average error to the desired path: %d \n', mean_average_error);

%% sumatory of accelerations
accel= [];
for k=2:N
    accel = [accel (u(1,k)^2+u(2,k)^2+u(3,k)^2)];
end

accel = mean(sqrt(accel));
fprintf('acceleration average: %d \n', accel);

%% snap: second derivative of accelerations (fourth derivative of camera trajectory)
st_derivative_accel = [];
nd_derivative_accel = [];

snap= [];
% second derivative
for k=2:N-1
    snap = [snap ((u(1,k+1)-2*u(1,k)+u(1,k-1))^2+(u(2,k+1)-2*u(2,k)+u(2,k-1))^2+(u(3,k+1)-2*u(3,k)+u(3,k-1))^2)/(time_step^4)];
end

snap = mean(sqrt(snap));
fprintf('snap: %d \n', snap);


%% jerk (third derivative of global angles)
st_derivative_yaw = [];
st_derivative_pitch = [];
nd_derivative_yaw = [];
nd_derivative_pitch = [];
rd_derivative_yaw = [];
rd_derivative_pitch = [];

%first derivative
for k=2:N
  st_derivative_yaw  = [st_derivative_yaw (yaw(k)-yaw(k-1))/time_step];
  st_derivative_pitch  = [st_derivative_pitch (pitch(k)-pitch(k-1))/time_step];
end
%second derivative
for k=2:N-1
  nd_derivative_yaw  = [nd_derivative_yaw (st_derivative_yaw(k)-st_derivative_yaw(k-1))/time_step];
  nd_derivative_pitch  = [nd_derivative_pitch (st_derivative_pitch(k)-st_derivative_pitch(k-1))/time_step];
end
%third derivative
for k=2:N-3
  rd_derivative_yaw  = [rd_derivative_yaw (nd_derivative_yaw(k)-nd_derivative_yaw(k-1))/time_step];
  rd_derivative_pitch  = [rd_derivative_pitch (nd_derivative_pitch(k)-nd_derivative_pitch(k-1))/time_step];
end

jerk_yaw = mean(abs(rd_derivative_yaw));
jerk_pitch = mean(abs(rd_derivative_pitch));
fprintf('jerk of the global yaw: %d \n',jerk_yaw)
fprintf('jerk of the global pitch: %d \n', jerk_pitch)


end
