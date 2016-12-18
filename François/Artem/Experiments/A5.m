T_list = [2.7, 3:20, 22:2:50, 60:10:300];
Vg_list = [0];
Vg_limit = 5;
Vg_rampRate = 0.1;
Nmeasurements = 200;
TWaitTime = 400;
VWaitTime1 = 0;
VWaitTime2 = 0;
measurementWaitTime = 1;
SD_Rex = 10530000;
SD_Vex = 0.01;
UniqueName = 'Calibration_A5';

estimate = ...
    (((measurementWaitTime*Nmeasurements+0.6)+VWaitTime2)*length(Vg_list)+TWaitTime)*length(T_list);
fprintf('estimated to take %d days %d hours\n',floor(estimate/60/60/24),round(estimate/60/60-24*floor(estimate/60/60/24)));


data5 = Francois_Ndc_R_T__T_Vg(T_list, Vg_list, Vg_limit, Vg_rampRate,...
        Nmeasurements, TWaitTime, VWaitTime1, VWaitTime2, measurementWaitTime,...
        SD_Rex, SD_Vex, UniqueName);
clear T_list Vg_list SD_Vex Nmeasurements VWaitTime1 VWaitTime2...
    measurementWaitTime Vg_rampRate Vg_limit SD_Rex EmailJess EmailKC ...
    UniqueName B_list PID TprobeRampRate TvaporRampRate estimate