digitizerCard=deviceDrivers.ATS850Driver(1,1);
digitizerCard.setTriggerTimeout(0); %infinite timeout
range=0.04;
triggerLevelVoltsTop=2.5;
numSamples=1024;
numAvg=255;
fftMask=[0 1.31e7; 1.56e7 3e7];
        triggerLevelVoltsBottom=0.32;
        triggerRangeVolts=4;
        triggerLevelCodeTop=128+127*triggerLevelVoltsTop/triggerRangeVolts;
        triggerLevelCodeBottom=128+127*triggerLevelVoltsBottom/triggerRangeVolts;
            digitizerCard.configureChannel('A', 'AC', range, 50);
    digitizerCard.configureChannel('B', 'DC', 4, 1000000);
        digitizerCard.setTriggerOperation('J_or_K','B','positive',triggerLevelCodeTop,'B','negative',triggerLevelCodeBottom); %160 works for range of 1, so does 130
        digitizerCard.setSizeSpectralVoltagePower(numSamples,numAvg);
        digitizerCard.setTriggerDelay(350000);
        digitizerCard.setTriggerTimeout(0);

triggerLevelVoltsTop=2.5;
triggerLevelVoltsBottom=0.32; %.32
triggerRangeVolts=4;
triggerLevelCodeTop=128+127*triggerLevelVoltsTop/triggerRangeVolts;
triggerLevelCodeBottom=128+127*triggerLevelVoltsBottom/triggerRangeVolts;
digitizerCard.setTriggerOperation('J_or_K','B','positive',triggerLevelCodeTop,'B','negative',triggerLevelCodeBottom); %160 works for range of 1, so does 130



for i=1:10
    tic
    [x,y]=digitizerCard.acquireVoltSamples('A'+'B');
    %mean(y) %126.1 and 197.3 with a B range of 1
    toc
    %-0.0552 and 4.92
end
figure(1);
plot(y);
