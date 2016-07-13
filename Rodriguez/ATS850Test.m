AlazarDefs

boardHandle=AlazarGetBoardBySystemID(1,1);

AlazarSetLED(boardHandle,LED_OFF);

[kind, boardHandle] = AlazarGetBoardKind(boardHandle);%why doesnt this work? kind should return 1 for the ATS850

pMemorySizeInSamples=0;
pBitsPerSample=0;
[retCode, boardHandle, pMemorySizeInSamples, pBitsPerSample] = AlazarGetChannelInfo(boardHandle, 0,0);

samplesPerSec = 50000000.0;
AlazarSetCaptureClock(boardHandle, INTERNAL_CLOCK, SAMPLE_RATE_50MSPS, CLOCK_EDGE_RISING, 0);

AlazarInputControl( boardHandle, CHANNEL_A, AC_COUPLING, INPUT_RANGE_PM_200_MV, IMPEDANCE_50_OHM);

%AlazarSetBWLimit(boardHandle, CHANNEL_B, 0); %this also fails for some reason, code 513

AlazarSetTriggerOperation( ...
        boardHandle,        ... % HANDLE -- board handle
        TRIG_ENGINE_OP_J,   ... % U32 -- trigger operation
        TRIG_ENGINE_J,      ... % U32 -- trigger engine id
        TRIG_CHAN_A,        ... % U32 -- trigger source id
        TRIGGER_SLOPE_POSITIVE, ... % U32 -- trigger slope id
        150,                ... % U32 -- trigger level from 0 (-range) to 255 (+range)
        TRIG_ENGINE_K,      ... % U32 -- trigger engine id
        TRIG_DISABLE,       ... % U32 -- trigger source id for engine K
        TRIGGER_SLOPE_POSITIVE, ... % U32 -- trigger slope id
        128                 ... % U32 -- trigger level from 0 (-range) to 255 (+range)
        );
    
AlazarSetTriggerDelay(boardHandle, 0);
AlazarSetTriggerTimeOut(boardHandle, 1); %trigger timeout is one clock cycle
AlazarConfigureAuxIO(boardHandle, AUX_OUT_TRIGGER, 0); %set default aux IO to trigger as internal clock


Copy_of_acquireData(boardHandle)

