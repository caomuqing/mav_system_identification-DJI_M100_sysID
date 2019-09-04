% 
% In order to run this script you need matlab_rosbag package
% https://github.com/bcharrow/matlab_rosbag (source)
% https://github.com/bcharrow/matlab_rosbag/releases (binary)
% 
% In case you face the follosing linking error
% matlab_rosbag-0.5.0-mac64/rosbag_wrapper.mexmaci64,
% 6): Symbol not found: __ZTISt16invalid_argument
% try this re-compiled binary
% https://cmu.app.box.com/s/9hs153nwa19uqvzboglkz7y84r6jzzxg    or
% https://dl.dropboxusercontent.com/u/12446150/matlab_rosbag-0.5.0-mac64_matlabR2015a.zip
% Tested platform: Mac EI Capitan 10.11.6 with MATLAB R2016a
%

clear all
path(path, '../read_bags');
path(path, '../helper_functions');

% two experiments are needed to validate the identification
bagfile_exp1 =  '../bags/m100exp005.bag';
bagfile_exp2 =  '../bags/m100exp006.bag';


topic_imu = '/dji_sdk/imu';
topic_vcdata = '/raven/command/roll_pitch_yawrate_thrust';

bag1 = ros.Bag(bagfile_exp1);
bag2 = ros.Bag(bagfile_exp2);
%%
% *First experriment info:*
bag1.info

%%
% *Second experiment info:*
bag2.info


%% Prepare datasets
Experiment1.IMU = readImu(bag1, topic_imu);
Experiment1.RCData = readCommnadRollPitchYawRateThrust(bag1, topic_vcdata);
Experiment2.IMU = readImu(bag2, topic_imu);
Experiment2.RCData = readCommnadRollPitchYawRateThrust(bag2, topic_vcdata);

% Write the quaternions properly

Experiment1.IMU.q = [Experiment1.IMU.q(4,:); Experiment1.IMU.q(1,:); ...
    Experiment1.IMU.q(2,:); Experiment1.IMU.q(3,:)];
Experiment2.IMU.q = [Experiment2.IMU.q(4,:); Experiment2.IMU.q(1,:); ...
    Experiment2.IMU.q(2,:); Experiment2.IMU.q(3,:)];

%time from 0
Experiment1.RCData.t = Experiment1.RCData.t - Experiment1.RCData.t(1);
Experiment1.IMU.t = Experiment1.IMU.t - Experiment1.IMU.t(1);


Experiment2.RCData.t = Experiment2.RCData.t - Experiment2.RCData.t(1);
Experiment2.IMU.t = Experiment2.IMU.t - Experiment2.IMU.t(1);


%========================================================
%RCDATA interpolation with respect to IMU,
%Exp1
%========================================================

cmd_roll_intp=interp1(Experiment1.RCData.t,Experiment1.RCData.roll,Experiment1.IMU.t,'spline');
cmd_pitch_intp=interp1(Experiment1.RCData.t,Experiment1.RCData.pitch,Experiment1.IMU.t,'spline');
cmd_yawrate_intp=interp1(Experiment1.RCData.t,Experiment1.RCData.yaw_rate,Experiment1.IMU.t,'spline');
cmd_thrust_intp=interp1(Experiment1.RCData.t,Experiment1.RCData.thrust(3,:),Experiment1.IMU.t,'spline');

Experiment1.IMU.q=[Experiment1.IMU.q(1,:);Experiment1.IMU.q(2,:);Experiment1.IMU.q(3,:);Experiment1.IMU.q(4,:)];

Experiment1.RCData.roll=cmd_roll_intp;
Experiment1.RCData.pitch=cmd_pitch_intp;
Experiment1.RCData.yaw_rate=cmd_yawrate_intp;
Experiment1.RCData.verti_vel=cmd_thrust_intp;

Experiment1.RCData.t=zeros(1,size(cmd_roll_intp,2));
Experiment1.RCData.t=Experiment1.IMU.t;

%Exp2

cmd_roll_intp=interp1(Experiment2.RCData.t,Experiment2.RCData.roll,Experiment2.IMU.t,'spline');
cmd_pitch_intp=interp1(Experiment2.RCData.t,Experiment2.RCData.pitch,Experiment2.IMU.t,'spline');
cmd_yawrate_intp=interp1(Experiment2.RCData.t,Experiment2.RCData.yaw_rate,Experiment2.IMU.t,'spline');
cmd_thrust_intp=interp1(Experiment2.RCData.t,Experiment2.RCData.thrust(3,:),Experiment2.IMU.t,'spline');

Experiment2.IMU.q=[Experiment2.IMU.q(1,:);Experiment2.IMU.q(2,:);Experiment2.IMU.q(3,:);Experiment2.IMU.q(4,:)];

Experiment2.RCData.roll=cmd_roll_intp;
Experiment2.RCData.pitch=cmd_pitch_intp;
Experiment2.RCData.yaw_rate=cmd_yawrate_intp;
Experiment2.RCData.verti_vel=cmd_thrust_intp;

Experiment2.RCData.t=zeros(1,size(cmd_roll_intp,2));
Experiment2.RCData.t=Experiment2.IMU.t;


Experiment1.rpy_imu = quat2rpy(Experiment1.IMU.q);
Experiment2.rpy_imu = quat2rpy(Experiment2.IMU.q);

% For DJI M100 platform.
%Please have a look "DJI_M100_regression for more detail.
k_pitch = 1;%0.000844; 
k_roll  = 1;%0.000865;
k_thrust = 0.0019965;
k_yaw = 0.002235;
%DJI vc channel, 1=pitch, 2=roll, 3=vertical velocity, 4=yaw_rate.


Experiment1.roll_cmd    = (Experiment1.RCData.roll)...
    *k_roll;
Experiment1.pitch_cmd   = (Experiment1.RCData.pitch)...
    *k_pitch;
Experiment1.thrust_cmd  = (Experiment1.RCData.verti_vel)...
    *k_thrust;%stick velocity command.

Experiment2.roll_cmd    = (Experiment2.RCData.roll)...
    *k_pitch;
Experiment2.pitch_cmd   = (Experiment2.RCData.pitch)...
    *k_roll;
Experiment2.thrust_cmd  = (Experiment2.RCData.verti_vel)...
    *k_thrust;


%%
% *Plot position from experiment 1*
close all;
%%
% *Plot attitude from experiment 1*
figure(2);
title('Experiment 1 Data');
subplot(2,1,1);
plot(Experiment1.IMU.t, Experiment1.rpy_imu(1,:)*180/pi, ...
    Experiment1.RCData.t, Experiment1.roll_cmd*180/pi, ...
    'g--', 'linewidth', 2);

xlabel('time');
legend('y','y_{ref}');
ylabel('roll [deg]');
title('roll from IMU');

subplot(2,1,2);
plot(Experiment1.IMU.t, Experiment1.rpy_imu(2,:)*180/pi, ...
    Experiment1.RCData.t, Experiment1.pitch_cmd*180/pi, ...
    'g--', 'linewidth', 2);

xlabel('time');
ylabel('pitch [deg]');
title('pitch from IMU');




%%
% *Plot position from experiment 2*
figure(4);
%%
% *Plot attitude from experiment 2*
title('Experiment 2 Data');
subplot(2,1,1);
plot(Experiment2.IMU.t, Experiment2.rpy_imu(1,:)*180/pi, ...
    Experiment2.RCData.t, Experiment2.roll_cmd*180/pi,...
    'g--', 'linewidth', 2);

legend('y','y_{ref}');
xlabel('time');
ylabel('roll [deg]');
title('roll from IMU');

subplot(2,1,2);
plot(Experiment2.IMU.t, Experiment2.rpy_imu(2,:)*180/pi, ...
    Experiment2.RCData.t, Experiment2.pitch_cmd*180/pi, ...
    'g--', 'linewidth', 2);

xlabel('time');
ylabel('pitch [deg]');
title('pitch from IMU');

%% Identification of roll system

%Control parameters

delay=[]; NaN; % [] menas no time delay or NaN for enabling delay estimation.
np=2; % 1 or 2 for the order of dynamics system.

%% The length of data may vary.
%Experiment1.t = (Experiment1.IMU.t + Experiment1.RCData.t)/2;
Experiment1.t = Experiment1.RCData.t;
Experiment1.u1 = Experiment1.roll_cmd;
Experiment1.y1 = Experiment1.rpy_imu(1,:);
Experiment1.Ts = mean(diff(Experiment1.t));


%%
% *get rid of first and last 10 seconds (to remove ground and transient effects)*
Experiment1.u1 = Experiment1.u1(Experiment1.t>10 & ...
    Experiment1.t < Experiment1.t(end)-10);
Experiment1.y1 = Experiment1.y1(Experiment1.t>10 &...
    Experiment1.t < Experiment1.t(end)-10);
%Experiment1.t = Experiment1.t(Experiment1.t>10 & Experiment1.t < Experiment1.t(end)-10);


[roll,lag_roll]=xcorr(Experiment1.u1,Experiment1.y1);

[~,I_roll]=max(roll);
time_sync_roll=lag_roll(I_roll);


roll_data1 = iddata(Experiment1.y1',Experiment1.u1',Experiment1.Ts, ...
    'ExperimentName', 'FireFlySysID_1', 'InputName','roll_{cmd}', ...
    'OutputName','roll', 'InputUnit','rad', 'OutputUnit','rad', ...
    'TimeUnit','Second');

roll_data1 = detrend(roll_data1);


%% The length of data may vary.
Experiment2.t = Experiment2.RCData.t;
Experiment2.u1 = Experiment2.roll_cmd;
Experiment2.y1 = Experiment2.rpy_imu(1,:);
Experiment2.Ts = mean(diff(Experiment2.t));


%get rid of first and last 10 seconds (to remove ground and transient effects)
Experiment2.u1 = Experiment2.u1(Experiment2.t>10 &...
    Experiment2.t < Experiment2.t(end)-10);
Experiment2.y1 = Experiment2.y1(Experiment2.t>10 &...
    Experiment2.t < Experiment2.t(end)-10);

roll_data2 = iddata(Experiment2.y1',Experiment2.u1',Experiment2.Ts,...
    'ExperimentName', 'FireFlySysID_2', 'InputName','roll_{cmd}',...
    'OutputName','roll', 'InputUnit','rad', 'OutputUnit','rad',...
    'TimeUnit','Second');

roll_data2 = detrend(roll_data2);   


%%
% *At this point we have 3 options!*
% 
% # Estimate a model from both experiments - but cannot validate it on independent dataset
% # Estimate a model from Exp1 and validate it on data from Exp2
% # Estimate a model from Exp2 and validate it on data from Exp1
%For now we choose the best model from options 2 and 3


%Assume 1st  order system  
%np = 2;
nz = 0;

%Generate model using Experiment1 and validate the model with Experiment2
roll_estimated_tf1 = tfest(roll_data1,np, nz,delay);

[~, fit1, ~] = compare(roll_data2, roll_estimated_tf1);

%Generate model using Experiment2 and validate the model with Experiment1
roll_estimated_tf2 = tfest(roll_data2,np, nz,delay);

[~, fit2, ~] = compare(roll_data1, roll_estimated_tf2);

if fit1>fit2
    %We pick the first Identification
    roll_estimated_tf = roll_estimated_tf1;
    disp('The roll model is estimated using experiment 1 and validated on data from experiment 2');
    figure;
    compare(roll_data2, roll_estimated_tf1);
    disp(strcat('The roll model fits the validation data with **',...
        num2str(fit1), '** %'));
else
    %We pick the second Identification
    roll_estimated_tf = roll_estimated_tf2;
    disp('The roll model is estimated using experiment 2 and validated on data from experiment 1');
    figure;
    compare(roll_data1, roll_estimated_tf2);
    disp(strcat('The roll model fits the validation data with **',...
        num2str(fit2), '** %'));
end


%% Identification of Pitch System
Experiment1.u2 = Experiment1.pitch_cmd;
Experiment1.y2 = Experiment1.rpy_imu(2,:);

%get rid of first and last 10 seconds (to remove ground and transient effects)
Experiment1.u2 = Experiment1.u2(Experiment1.t>10 &...
    Experiment1.t < Experiment1.t(end)-10);
Experiment1.y2 = Experiment1.y2(Experiment1.t>10 &...
    Experiment1.t < Experiment1.t(end)-10);
Experiment1.t = Experiment1.t(Experiment1.t>10 &...
    Experiment1.t < Experiment1.t(end)-10);

pitch_data1 = iddata(Experiment1.y2',Experiment1.u2',Experiment1.Ts,...
    'ExperimentName', 'FireFlySysID_1', 'InputName','pitch_{cmd}',...
    'OutputName','pitch', 'InputUnit','rad', 'OutputUnit','rad',...
    'TimeUnit','Second');

%remove any trend in the data
pitch_data1 = detrend(pitch_data1);

Experiment2.u2 = Experiment2.pitch_cmd;
Experiment2.y2 = Experiment2.rpy_imu(2,:);


%get rid of first and last 10 seconds (to remove ground and transient effects)
Experiment2.u2 = Experiment2.u2(Experiment2.t>10 &...
    Experiment2.t < Experiment2.t(end)-10);
Experiment2.y2 = Experiment2.y2(Experiment2.t>10 &...
    Experiment2.t < Experiment2.t(end)-10);
Experiment2.t = Experiment2.t(Experiment2.t>10 &...
    Experiment2.t < Experiment2.t(end)-10);

pitch_data2 = iddata(Experiment2.y2',Experiment2.u2',Experiment2.Ts, ...
    'ExperimentName', 'FireFlySysID_2', 'InputName','pitch_{cmd}',...
    'OutputName','pitch', 'InputUnit','rad', 'OutputUnit','rad', ...
    'TimeUnit','Second');
pitch_data2 = detrend(pitch_data2);   


%%
% *At this point we have 3 options!*
% 
% # Estimate a model from both experiments - but cannot validate it on independent dataset
% # Estimate a model from Exp1 and validate it on data from Exp2
% # Estimate a model from Exp2 and validate it on data from Exp1
%For now we choose the best model from options 2 and 3
  
%Assume 1st order system
%np = 2;
nz = 0;

%Generate model using Experiment1 and validate the model with Experiment2
pitch_estimated_tf1 = tfest(pitch_data1,np, nz,delay);

[~, fit1, ~] = compare(pitch_data2, pitch_estimated_tf1);

%Generate model using Experiment2 and validate the model with Experiment1
pitch_estimated_tf2 = tfest(pitch_data2,np, nz,delay);

[~, fit2, ~] = compare(pitch_data1, pitch_estimated_tf2);

if fit1>fit2
    %We pick the first Identification
    pitch_estimated_tf = pitch_estimated_tf1;
    disp('The pitch model is estimated using experiment 1 and validated on data from experiment 2');
    figure;
    compare(pitch_data2, pitch_estimated_tf1);
    disp(strcat('The pitch model fits the validation data with **', ...
        num2str(fit1), '** %'));
else
    %We pick the second Identification
    pitch_estimated_tf = pitch_estimated_tf2;
    disp('The pitch model is estimated using experiment 2 and validated on data from experiment 1');
    figure;
    compare(pitch_data1, pitch_estimated_tf2);
    disp(strcat('The pitch model fits the validation data with **', ...
        num2str(fit2), '** %'));
end



%% Estimate the Whole System as 2-input 2-output MIMO System
% *The purpose here is to see of there is coupling*

Experiment2.Ts = Experiment1.Ts;    
Data1 = iddata([Experiment1.y1', Experiment1.y2'], ...
    [Experiment1.u1', Experiment1.u2'], Experiment1.Ts, ...
    'ExperimentName', 'FireFlySysID_1', ...
    'InputName',{'roll_{cmd}','pitch_{cmd}'},...
    'OutputName',{'roll','pitch'}', ...
    'InputUnit',{'rad', 'rad'},...
    'OutputUnit',{'rad', 'rad'},...
    'TimeUnit','Second');


                          
Data2 = iddata([Experiment2.y1', Experiment2.y2'], ...
    [Experiment2.u1', Experiment2.u2'], Experiment2.Ts, ...
    'ExperimentName', 'FireFlySysID_2', ...
    'InputName',{'roll_{cmd}','pitch_{cmd}'},...
    'OutputName',{'roll','pitch'}', ...
    'InputUnit',{'rad', 'rad'},...
    'OutputUnit',{'rad', 'rad'}, ...
    'TimeUnit','Second');


MergedData = merge(Data1, Data2);

%np = 2;
nz = 0;
Full_estimated_tf = tfest(MergedData, np,nz);

figure;
bodemag(Full_estimated_tf);


%%% Estimated Transfer Functions

disp('Roll estimated transfer function is: ');
tf(roll_estimated_tf)

if(np==1)
    roll_params=getpvec(roll_estimated_tf);
    roll_gain=roll_params(1)/roll_params(2);
    roll_tau=1/roll_params(2);
    fprintf('roll tau=%.3f, gain=%.3f\n',roll_tau,roll_gain);
elseif(np==2)
    roll_params=getpvec(roll_estimated_tf);
    roll_omega=sqrt(roll_params(3));
    roll_gain=roll_params(1)/roll_params(3);
    roll_damping=roll_params(2)/(2*roll_omega);
    fprintf('roll omega=%.3f, gain=%.3f damping=%.3f\n',roll_omega,roll_gain,roll_damping);
end



figure('Name','System analysis (roll)');
subplot(311);
bode(roll_estimated_tf); grid;
title('Roll bode plot');

subplot(312);
%rlocusplot(roll_estimated_tf); grid;
title('Roll RootLucas plot');

subplot(313);
step(roll_estimated_tf); grid;
title('Roll step response plot');

disp('Pitch estimated transfer function is: ');
tf(pitch_estimated_tf)

if(np==1)
    pitch_params=getpvec(pitch_estimated_tf);
    pitch_gain=pitch_params(1)/pitch_params(2);
    pitch_tau=1/pitch_params(2);
    fprintf('pitch tau=%.3f, gain=%.3f\n',pitch_tau, pitch_gain);
elseif(np==2)
    pitch_params=getpvec(pitch_estimated_tf);
    pitch_omega=sqrt(pitch_params(3));
    pitch_gain=pitch_params(1)/pitch_params(3);
    pitch_damping=pitch_params(2)/(2*pitch_omega);
    fprintf('pitch omega=%.3f, gain=%.3f damping=%.3f\n',pitch_omega,pitch_gain,pitch_damping);
end



figure('Name','System analysis (pitch)');
subplot(311);
bode(pitch_estimated_tf); grid;
title('Pitch bode plot');

subplot(312);
%rlocusplot(pitch_estimated_tf); grid;
title('Pitch RootLucas plot');

subplot(313);
step(pitch_estimated_tf); grid;
title('Pitch step response plot');
