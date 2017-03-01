    biasController=deviceDrivers.YokoGS200();
    biasController.connect('18');
    assert(strcmp(biasController.mode,'VOLT'),'wrong bias source mode');
    
    dmm=deviceDrivers.Keysight34401A();
    dmm.connect('6');
    
    dmm.initiate;
    biasController.ramp2V(0,5);
    
    startTime=clock;
    n=1;
    
    clear t;
    clear vndc;
    
    while(true)
        t(n)=etime(clock,startTime);
        vndc(n)=dmm.fetch;
        dmm.initiate;
        plot(t,vndc);
        pause(0.1);
        n=n+1;
    end
    
    dmm.disconnect;
    biasController.disconnect;