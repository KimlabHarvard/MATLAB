%Test a filter using VNA to see whether the L or C depends on temperature

UniqueName='A2_VNA_Test_LC_Filter_warming';
start_dir='C:\Users\Artem\My Documents\Artem Data\Misc\';
tempRampRate=3; %K/min
tempWaitTime=30; %seconds
tempWindow=0.1;
tempList=fliplr([300:-25:100 90:-10:40 35:-5:10 8 6 4 3]);

cycleTime=1; %seconds
estTime=(length(tempList)*(tempWaitTime+cycleTime)+(max(tempList)-min(tempList))/tempRampRate*60)/3600;

Francois_T___VNA(UniqueName, start_dir, tempWaitTime, tempWindow, tempRampRate, tempList);