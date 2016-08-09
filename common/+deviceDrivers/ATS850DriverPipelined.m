classdef ATS850DriverPipelined < handle
    %ATS850 Driver for AlazarTech ATS850 Digitizer card
    %Written by Artem Talanov (avtalanov@gmail.com) June 2016
    %
    %
    %To use
    % 1)initialize with constructor, ATS850Drive(1,1)
    %   the 1 and 1 are the system  ID and board ID
    %   running the constructor auto-initializes to defaults
    %   the defaults are the following:
    %   50 megasamples/second (this driver does not allow changing this)
    %   
    %   trigger: channel A, rising or falling through 0V
    %   trigger delay: 0 cycles
    %   trigger timeout: 1 cycle
    %   channel configuation: AC, 1V input range for both channels
    %
    % 2)set needed parameters by running the following methods
    %        -setTriggerOperation
    %        -setTriggerDelay
    %        -setTriggerTimeout
    %        -configureChannel, for both A and B
    %
    % 3)collect data. for some data collection you have to set the
    %   acquitiosn size before calling the function for data collection
    
   
    
    properties (SetAccess = protected)
        systemID;
        boardID;
        boardHandle;
        channelARange;
        channelBRange;
        numSamples;
        bytesPerBuffer;
        samplesPerBuffer;
        
        pBuffer;
        
        
        %used for acquiring spectral voltage power
        numSamplesForAvgSpectralPower;
        myNumCaptures;
        numGroupsPerCapture;

        %for pipelining functionality
        pipelineStatus; % 0=not started, 1=started
        
        myDataASamples;
        myDataBSamples;
        myDataA;
        myDataB;
        
        %if true, add on 4 datapoints to the end
        maxSamplesOn;
    end
    
    properties (Access=public, Constant)
        bitsPerSample=8;
        codeZero=bitshift(1,8-1)-0.5; %127.5
        codeRange=bitshift(1,8-1)-0.5; %127.5
        maxSamplesPerRecord=2^18-4;
        bytesPerSample=1; %= floor((double(bitsPerSample) + 7) / double(8));
        numRecords=1; %set to one because no need for splitting a long record into shorter records
        
        SamplingFrequency=50000000;
        maxSamples=2^18;
        
        InputRange2mV=0.002;
        InputRange4mV=0.004;
        InputRange5mV=0.005;
        InputRange8mV=0.008;
        InputRange10mV=0.01;
        InputRange20mV=0.02;
        InputRange40mV=0.04;
        InputRange50mV=0.05;
        InputRange80mV=0.08;
        InputRange100mV=0.1;
        InputRange200mV=0.2;
        InputRange400mV=0.4;
        InputRange500mV=0.5;
        InputRange800mV=0.8;
        InputRange1V=1;
        InputRange2V=2;
        InputRange4V=4;
        InputRange5V=5;
    end
    
    methods (Access=private)
        %convert range number to actual range in volts
        function rangeVolts=convertToRange(~, rangeNumber)
            switch(rangeNumber)
                case hex2dec('00000001')
                    rangeVolts=.02;
                case hex2dec('00000002')
                    rangeVolts=.04;
                case hex2dec('00000003')
                    rangeVolts=.05;
                case hex2dec('00000004')
                    rangeVolts=.08;
                case hex2dec('00000005')
                    rangeVolts=.1;
                case hex2dec('00000006')
                    rangeVolts=.2;
                case hex2dec('00000007')
                    rangeVolts=.4;
                case hex2dec('00000008')
                    rangeVolts=.5;
                case hex2dec('00000009')
                    rangeVolts=.8;
                case hex2dec('0000000A')
                    rangeVolts=1;
                case hex2dec('0000000B')
                    rangeVolts=2;
                case hex2dec('0000000C')
                    rangeVolts=4;
                case hex2dec('0000000D')
                    rangeVolts=5;
                case hex2dec('0000000E')
                    rangeVolts=8;
                case hex2dec('0000000F')
                    rangeVolts=10;
                case hex2dec('00000010')
                    rangeVolts=20;
                case hex2dec('00000011')
                    rangeVolts=40;
                case hex2dec('00000012')
                    rangeVolts=16;
                case hex2dec('00000020')
                    rangeVolts=0; %hifi
                case hex2dec('00000021')
                    rangeVolts=0; %INPUT_RANGE_PM_1_V_25
                case hex2dec('00000025')
                    rangeVolts=0; %INPUT_RANGE_PM_2_V_5   
                case hex2dec('00000028')
                    rangeVolts=.125;
                case hex2dec('00000030')
                    rangeVolts=.25;
            end
        end
        
         %convert range number to actual range in volts
        function rangeNumber=convertToRangeNumber(~, range)
            switch(range)
                case .02
                    rangeNumber=hex2dec('00000001');
                case .04
                    rangeNumber=hex2dec('00000002');
                case .05
                    rangeNumber=hex2dec('00000003');
                case .08
                    rangeNumber=hex2dec('00000004');
                case .1
                    rangeNumber=hex2dec('00000005');
                case .2
                    rangeNumber=hex2dec('00000006');
                case .4
                    rangeNumber=hex2dec('00000007');
                case .5
                    rangeNumber=hex2dec('00000008');
                case .8
                    rangeNumber=hex2dec('00000009');
                case 1
                    rangeNumber=hex2dec('0000000A');
                case 2
                    rangeNumber=hex2dec('0000000B');
                case 4
                    rangeNumber=hex2dec('0000000C');
                case 5
                    rangeNumber=hex2dec('0000000D');
                otherwise
                    rangeNumber=-1;
            end
        end
        
        %convert the myDatASamples as bit numbers to myDataA in volts
        function pipeline_convertSamplesToVolts(obj, channelMask)
            if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B'))
                fprintf('Channel mask is incorrect');
                return;
            end
            
            if(channelMask=='A')
                obj.myDataA=(double(obj.myDataASamples)-obj.codeZero)/obj.codeRange*obj.channelARange; %cast dataA to double
                obj.myDataB=0;
            elseif(channelMask=='B')
                obj.myDataB=(double(obj.myDataBSamples)-obj.codeZero)/obj.codeRange*obj.channelBRange; %cast dataA to double
                obj.myDataA=0;
            else
                obj.myDataA=(double(obj.myDataASamples)-obj.codeZero)/obj.codeRange*obj.channelARange; %cast dataA to double
                obj.myDataB=(double(obj.myDataBSamples)-obj.codeZero)/obj.codeRange*obj.channelBRange; %cast dataA to double
            end
        end
        
        %begin capture
        function pipeline_startCapture(obj)
            % Arm the board system to begin the acquisition
            retCode = AlazarStartCapture(obj.boardHandle);
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarStartCapture failed -- %s\n', errorToText(retCode));
                return;
            end;
        end
        
        %check to see if busy
        function val = pipeline_isBusy(obj)
            val=AlazarBusy(obj.boardHandle);
        end
        
        %part of the pipeline; call this function to pull data from buffer and store in obj.myDataA and obj.myDataB
        function pipeline_pullBuffer(obj, channelMask)
            obj.myDataASamples=0;
            obj.myDataBSamples=0;
            record=1;
            if(channelMask=='A')
                channels=obj.CHANNEL_A;
                %obj.myDataB=0;
            elseif(channelMask=='B')
                channels=obj.CHANNEL_B;
                %obj.myDataA=0;
            else
                channels=[obj.CHANNEL_A, obj.CHANNEL_B];
            end
            for channelId=channels
                % Transfer one full record from on-board memory to our buffer
                %Error: obj.numSamples is equal to 229376=
                [retCode, ~, bufferOut] = AlazarRead(obj.boardHandle, channelId, obj.pBuffer, obj.bytesPerSample, record, 0, obj.numSamples); %7.3 ms
                if retCode ~= obj.ApiSuccess
                    fprintf('Error: AlazarRead record %u failed -- %s\n', record, errorToText(retCode));
                else
                    %bytesTransferred = bytesTransferred + obj.bytesPerRecord;

                    % TODO: Process sample data in this buffer.
                    %
                    % NOTE:
                    %
                    % While you are processing this buffer, the board is already
                    % filling the next available buffer(s).
                    %
                    % You MUST finish processing this buffer and post it back to the
                    % board before the board fills all of its available DMA buffers
                    % and on-board memory.
                    %
                    % Records are arranged in the buffer as follows: R0A, R1A, R2A ... RnA, R0B,
                    % R1B, R2B ...
                    % with RXY the record number X of channel Y
                    %
                    % Sample code are stored as 8-bit values.
                    %
                    % Sample codes are unsigned by default. As a result:
                    % - a sample code of 0x00 represents a negative full scale input signal.
                    % - a sample code of 0x80 represents a ~0V signal.
                    % - a sample code of 0xFF represents a positive full scale input signal.

                    %if obj.bytesPerSample == 1
                        setdatatype(bufferOut, 'uint8Ptr', 1, obj.samplesPerBuffer);
                    %else
                    %    setdatatype(bufferOut, 'uint16Ptr', 1, samplesPerBuffer);
                    %end
                    
                    if(~obj.maxSamplesOn)
                        if(channelId==obj.CHANNEL_A)
                            obj.myDataASamples=bufferOut.Value;
                        end

                        if(channelId==obj.CHANNEL_B)
                            obj.myDataBSamples=bufferOut.Value;
                        end
                    else
                        if(channelId==obj.CHANNEL_A)
                            obj.myDataASamples=[bufferOut.Value 0 0 0 0];
                        end

                        if(channelId==obj.CHANNEL_B)
                            obj.myDataBSamples=[bufferOut.Value 0 0 0 0];
                        end
                        
                        obj.myDataASamples(end-3:end)=obj.myDataASamples(10000:10003);
                        obj.myDataASamples(end-3:end)=obj.myDataASamples(10000:10003);
                    end
                    
                end

            end
        end
    end
    
    methods
        
        %the pipeline
        %obj.setAcquisitionSize or obj.setAcquisionSizeForSpectral....
        %obj.startCapture
        %wait
        
        
        %loop:
        %   obj.pullBuffer
        %   obj.startCapture
        %   myProcessedData=obj.processBuffer(FFT, etc) %process data that was just pulled from buffer, then clear the b
        %end loop
 
        function obj = ATS850DriverPipelined(systemId, boardId)
            alazarLoadLibrary();
            assert(isscalar(systemId)&&isnumeric(systemId)&&isscalar(boardId)&&isnumeric(boardId),'boardID and systemID must be numeric scalars!');
            obj.systemID=systemId;
            obj.boardID=boardId;
            obj.boardHandle=AlazarGetBoardBySystemID(systemId,boardId);
            obj.configureDefault();
            obj.pipelineStatus=0;
        end
        
        
        
        %configure the board for default data-taking
        %see manual/examples for what this does
        function configureDefault(obj)
            %define the clock to be internal and 50 MSPS
            retCode=AlazarSetCaptureClock(obj.boardHandle, obj.INTERNAL_CLOCK, obj.SAMPLE_RATE_50MSPS, obj.CLOCK_EDGE_RISING, 0);
            if retCode ~= obj.ApiSuccess
            fprintf('Error: AlazarSetCaptureClock failed -- %s\n', errorToText(retCode));
                return
            end
            
            obj.setTriggerOperation('J_or_K','A','positive',0,'A','negative',0);
            obj.setTriggerDelay(0);
            obj.setTriggerTimeout(1);
            obj.configureChannel('A', 'AC', 1, 50);
            obj.configureChannel('B', 'AC', 1, 1000000);
            
            retCode=AlazarConfigureAuxIO(obj.boardHandle, obj.AUX_OUT_TRIGGER, 0); %set default aux IO to trigger as internal clock
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarConfigureAuxIO failed -- %s\n', errorToText(retCode));
                return;
            end
        end
        
        %operation: 'J' 'K' 'J_or_K' 'J_and_K' 'J_xor_K' 'J_and_not_K' 'not_J_and_K'
        %jSource, source of trigger engine J: 'disable' 'A' 'B' 'external'
        %jSlope, 'positive' or 'negative'
        %jLevel, integer from 0 to 255 indicating level of trigger, 127.5 = 0 V
        %kSource, source of trigger engine J: 'disable' 'A' 'B' 'external_TTL'
        %kSlope, 'positive' or 'negative'
        %kLevel, integer from 0 to 255 indicating level of trigger, 127.5 = 0 V
        function setTriggerOperation(obj,operation,jSource,jSlope,jLevel,kSource,kSlope,kLevel)
            switch(operation)
                case 'J' 
                    myOp=obj.TRIG_ENGINE_OP_J;
                case 'K' 
                    myOp=obj.TRIG_ENGINE_OP_K;
                case 'J_or_K' 
                    myOp=obj.TRIG_ENGINE_OP_J_OR_K;
                case 'J_and_K' 
                    myOp=obj.TRIG_ENGINE_OP_J_AND_K;
                case 'J_xor_K' 
                    myOp=obj.TRIG_ENGINE_OP_J_XOR_K;
                case 'J_and_not_K' 
                    myOp=obj.TRIG_ENGINE_OP_J_AND_NOT_K;
                case 'not_J_and_K' 
                    myOp=obj.TRIG_ENGINE_OP_NOT_J_AND_K;
                otherwise
                    fprintf(strcat('Error: Incorrect Trigger Operation: ',num2str(operation)));
                    return
            end
            
            switch(jSource)
                case 'disable' 
                    myJSource=obj.TRIG_DISABLE;
                case 'A' 
                    myJSource=obj.TRIG_CHAN_A;
                case 'B' 
                    myJSource=obj.TRIG_CHAN_B;
                case 'external_1V' 
                    myJSource=obj.TRIG_EXTERNAL;                 
                case 'external_5V'
                    myJSource=obj.TRIG_EXTERNAL;
                otherwise
                    fprintf(strcat('Error: Incorrect Trigger J Source: ',num2str(jSource)));
                    return
            end
            
            switch(jSlope)
                case 'positive' 
                    myJSlope=obj.TRIGGER_SLOPE_POSITIVE;
                case 'negative' 
                    myJSlope=obj.TRIGGER_SLOPE_NEGATIVE;
                otherwise
                    fprintf(strcat('Error: Incorrect Trigger J Slope: ',num2str(jSlope)));
                    return
            end
            
            if(jLevel>255 || jLevel<0)
                fprintf(strcat('Error: Incorrect Trigger J Level: ',num2str(jLevel)));
                    return
            end
            
            switch(kSource)
                case 'disable' 
                    myKSource=obj.TRIG_DISABLE;
                case 'A' 
                    myKSource=obj.TRIG_CHAN_A;
                case 'B' 
                    myKSource=obj.TRIG_CHAN_B;
                case 'external_1V' 
                    myKSource=obj.TRIG_EXTERNAL;
                case 'external_5V'
                    myKSource=obj.TRIG_EXTERNAL;
                otherwise
                    fprintf(strcat('Error: Incorrect Trigger K Source: ',num2str(jSource)));
                    return
            end
            
            switch(kSlope)
                case 'positive' 
                    myKSlope=obj.TRIGGER_SLOPE_POSITIVE;
                case 'negative'
                    myKSlope=obj.TRIGGER_SLOPE_NEGATIVE;
                otherwise
                    fprintf(strcat('Error: Incorrect Trigger J Slope: ',num2str(kSlope)));
                    return
            end
            
            if(kLevel>255 || kLevel<0)
                fprintf(strcat('Error: Incorrect Trigger K Level: ',num2str(kLevel)));
                    return
            end
            
            retCode=AlazarSetTriggerOperation(obj.boardHandle, myOp, obj.TRIG_ENGINE_J, myJSource, myJSlope ,jLevel, obj.TRIG_ENGINE_K, myKSource, myKSlope ,kLevel);
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarSetTriggerOperation failed -- %s\n', errorToText(retCode));
                return
            end
            
            if(strcmp(jSource,'external_1V'))
                retCode=AlazarSetExternalTrigger(obj.boardHandle, obj.DC_COUPLING, obj.ETR_1V);
                if retCode ~= obj.ApiSuccess
                    fprintf('Error: AlazarSetExternalTrigger failed -- %s\n', errorToText(retCode));
                    return
                end
            end
            if(strcmp(jSource,'external_5V'))
                retCode=AlazarSetExternalTrigger(obj.boardHandle, obj.DC_COUPLING, obj.ETR_5V);
                if retCode ~= obj.ApiSuccess
                    fprintf('Error: AlazarSetExternalTrigger failed -- %s\n', errorToText(retCode));
                    return
                end
            end
        end
        
        %set the trigger delay in number of sample clocks
        function setTriggerDelay(obj, delay)
            retCode=AlazarSetTriggerDelay(obj.boardHandle, delay);
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarSetTriggerDelay failed -- %s\n', errorToText(retCode));
                return;
            end
        end
        
        %set the trigger timeout in number of sample clocks
        function setTriggerTimeout(obj, timeout)
            retCode=AlazarSetTriggerTimeOut(obj.boardHandle, timeout); %trigger timeout is one clock cycle, might need to change later
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarSetTriggerTimeOut failed -- %s\n', errorToText(retCode));
                return;
            end
        end
        
        %channel: 'A' or 'B'
        %coupling: 'AC' or 'DC'
        %range: in volts
        %impedance: 50 or 1,000,000
        function configureChannel(obj, channel, coupling, range, impedance)
            myRange=obj.convertToRangeNumber(range);
            if(myRange==-1)
                fprintf('Error: invalid Channel range of %f',inputRangeA);
                return
            end
            
            switch(impedance)
                case 50
                    myImpedance=obj.IMPEDANCE_50_OHM;
                case 1000000
                    myImpedance=obj.IMPEDANCE_1M_OHM;
                otherwise
                    fprintf(strcat('Error: Incorrect impedance: ',num2str(impedance)));
                    return
            end
            
            switch(channel)
                case 'A'
                    myChannel=obj.CHANNEL_A;
                    obj.channelARange=range;
                case 'B'
                    myChannel=obj.CHANNEL_B;
                    obj.channelBRange=range;
                otherwise
                    fprintf(strcat('Error: Incorrect Channel: ',num2str(channel)));
                    return
            end
            
            switch(coupling)
                case 'DC' 
                    myCoupling=obj.DC_COUPLING;
                case 'AC' 
                    myCoupling=obj.AC_COUPLING;
                otherwise
                    fprintf(strcat('Error: Incorrect Ch Coupling: ',num2str(coupling)));
                    return
            end
            

            retCode=AlazarInputControl(obj.boardHandle, myChannel, myCoupling, myRange, myImpedance);
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarInputControl failed for Channel A -- %s\n', errorToText(retCode));
                return
            end
        end
        
        %sets up number of samples and record to take
        %run this just before acquiring the samples
        %function setAcquisitionSize(obj,numSamples, numRecords)  
        function setAcquisitionSize(obj,numSamples)  %numRecords is set to 1 always
            if(numSamples>obj.maxSamplesPerRecord && numSamples~=obj.maxSamples)
                disp('Attempted to collect too many samples per record.');
                return;
            end
            
            if(numSamples==obj.maxSamples)
                obj.maxSamplesOn=1;
                numSamples=numSamples-4;
            else
                obj.maxSamplesOn=0;
            end
            
            obj.numSamples=numSamples;
            %obj.numRecords=numRecords;
            
            %obj.bytesPerRecord = double(obj.bytesPerSample) * numSamples;
            
            % The buffer must be at least 16 samples larger than the transfer size
            %samplesPerBuffer = numSamples + 16;
            obj.samplesPerBuffer = numSamples;
            obj.bytesPerBuffer = obj.samplesPerBuffer * obj.bytesPerSample;
            
            % Set the number of samples per record
            retCode = AlazarSetRecordSize(obj.boardHandle, 0, numSamples);
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarSetRecordSize failed -- %s\n', errorToText(retCode));
                return;
            end
            
            % Set the number of records in the acquisition
            retCode = AlazarSetRecordCount(obj.boardHandle, obj.numRecords);
            if retCode ~= obj.ApiSuccess
                fprintf('Error: AlazarSetRecordCount failed -- %s\n', errorToText(retCode));
                return;
            end
            
            obj.pBuffer = AlazarAllocBuffer(obj.boardHandle, obj.bytesPerBuffer + 16);
            if obj.pBuffer == 0
                obj.fprintf('Error: AlazarAllocBufferU16 %u bytes failed\n', obj.bytesPerBuffer);
                return
            end
        end
        
        %not pipelined
        %acquire uint8 data from channels A and B
        %channelMask should be 'A' 'B' or 'A'+'B'
        %returns a numRecords x numSamples matrix for dataA and B
        function [dataA, dataB] = acquireDataSamples(obj, channelMask)
            if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B'))
                fprintf('Channel mask is incorrect');
                return;
            end
            pipeline_startCapture(); 
            %while board is busy collecting data, wait
            while (obj.pipeline_isBusy())%5.2 msec
                %pause(0.001);
            end
            obj.pipeline_pullBuffer(channelMask);
            dataB=obj.myDataBSamples;
            dataA=obj.myDataASamples;
        end
        
        %acquire real voltage data from channel
        function [dataAVolts, dataBVolts] = acquireVoltSamples(obj, channelMask)
            if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B'))
                fprintf('Channel mask is incorrect');
                return;
            end
            
            if(channelMask=='A')
                [dataA, ~] = obj.acquireDataSamples(channelMask);
                dataAVolts=(double(dataA)-obj.codeZero)/obj.codeRange*obj.channelARange; %cast dataA to double
                dataBVolts=0;
            elseif(channelMask=='B')
                [~, dataB] = obj.acquireDataSamples(channelMask);
                dataBVolts=(double(dataB)-obj.codeZero)/obj.codeRange*obj.channelBRange; %cast dataA to double
                dataAVolts=0;
            else %26 msec
                [dataA, dataB] = obj.acquireDataSamples(channelMask);
                dataAVolts=(double(dataA)-obj.codeZero)/obj.codeRange*obj.channelARange;
                dataBVolts=(double(dataB)-obj.codeZero)/obj.codeRange*obj.channelBRange;

            end
        end
        
        function setSizeSpectralVoltagePower(obj, numSamples, numAvg)
            if(numSamples>obj.maxSamples)
                fprintf('Error: attempted to acquire too many samples, %f samples',numSamples);
                return;
            end
            obj.numGroupsPerCapture=min(floor(obj.maxSamples/numSamples),numAvg); %the number of groups to be captured; dont capture more than needed
            obj.myNumCaptures=1; %how many captures of numGroupsPerCapture are needed to collect all requested groups, which is numAvg
            obj.setAcquisitionSize(obj.numGroupsPerCapture*numSamples);
            obj.numSamplesForAvgSpectralPower=numSamples;
            if(numAvg/floor(obj.maxSamples/numSamples)>1)
                fprintf('tried to acquire too many samples for pipeline to be effective; reducing your sample size');
            end;
        end
        
        function pipeline_startSpectralPipeline(obj)
            obj.pipeline_startCapture();
            obj.pipelineStatus=1;
        end
        
        function pipeline_endSpectralPipeline(obj)
            obj.pipeline_pullBuffer('A');
            obj.myDataA=0;
            obj.myDataB=0;
            obj.pipelineStatus=0;
        end
        
        %acquire spectral noise power in units of W/Hz, specify number
        %of samples in the FFT and the number of FFT's to take and average
        %call setSizeSpectralVoltagePower before calling this function
        function [freq, dataAPwr, dataBPwr, rawAData, rawBData] = pipeline_acquireAvgSpectralVoltagePower(obj, channelMask)
            %if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B')||strcmp(channelMask,'A-B')||strcmp(channelMask,'B-A'))
            if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B'))
                fprintf('Channel mask is incorrect');
                return;
            end
            if(obj.pipelineStatus==0)
                fprintf('Pipeline has not been started. Call pipeline_startSpectralPipeline())');
                return;
            end
            %bob=0;
            while(obj.pipeline_isBusy())
                %pause(0.001);
                %bob=bob+1;
            end
            %bob
            obj.pipeline_pullBuffer(channelMask);
            obj.pipeline_startCapture();
            obj.pipeline_convertSamplesToVolts(channelMask);
            count=0;
            %obj.myNumCaptures
            %obj.numGroupsPerCapture
            %obj.numSamplesForAvgSpectralPower
            if(channelMask=='A')
                mysum=zeros(1,obj.numSamplesForAvgSpectralPower/2+1);
                rawBData=0;
                dataA = obj.myDataA;
                for j=0:obj.numGroupsPerCapture-1
                    index=j*obj.numSamplesForAvgSpectralPower;
                    voltages=dataA(index+1:index+obj.numSamplesForAvgSpectralPower);
                    xdft=fft(voltages);  
                    xdft=xdft(1:obj.numSamplesForAvgSpectralPower/2+1);
                    psdx=(abs(xdft).^2);                        
                    mysum=mysum+psdx;
                    count=count+1;
                    %correct is sum(abs(xdft).^2)/1024^2
                    if(count==obj.numGroupsPerCapture)
                        break;
                    end
                end
                %double every element except the first and last
                mysum(2:end-1) = 2*mysum(2:end-1);
                
                dataAPwr=mysum/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);%this is good
                
                %these two match and are correct now
                %myvar=var(dataA)
                %mypwr=sum(dataAPwr)*50000000/1024
                rawAData=dataA;
                dataBPwr=0;
            elseif(channelMask=='B')
                mysum=zeros(1,obj.numSamplesForAvgSpectralPower/2+1);
                rawAData=0;
                dataB=obj.myDataB;
                for j=0:obj.numGroupsPerCapture-1
                    index=j*obj.numSamplesForAvgSpectralPower;
                    voltages=dataB(index+1:index+obj.numSamplesForAvgSpectralPower);
                    xdft=fft(voltages);  
                    xdft=xdft(1:obj.numSamplesForAvgSpectralPower/2+1);
                    psdx=(abs(xdft).^2);                        
                    mysum=mysum+psdx;
                    count=count+1;
                    if(count==obj.numGroupsPerCapture)
                        break;
                    end
                end
                %double every element except the first and last
                mysum(2:end-1) = 2*mysum(2:end-1);
                %not sure about this factor of 2 here
                dataBPwr=mysum/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);
                dataAPwr=0;
                rawBData=dataB;
            elseif(channelMask=='A'+'B')
                mysumB=zeros(1,obj.numSamplesForAvgSpectralPower/2+1);
                mysumA=mysumB;
                dataA=obj.myDataA;
                dataB=obj.myDataB;
                for j=0:obj.numGroupsPerCapture-1
                    index=j*obj.numSamplesForAvgSpectralPower;    

                    voltagesA=dataA(index+1:index+obj.numSamplesForAvgSpectralPower);
                    voltagesB=dataB(index+1:index+obj.numSamplesForAvgSpectralPower);
                    xdftA=fft(voltagesA);  
                    xdftB=fft(voltagesB);
                    xdftA=xdftA(1:obj.numSamplesForAvgSpectralPower/2+1);
                    xdftB=xdftB(1:obj.numSamplesForAvgSpectralPower/2+1);
                    psdxA=(abs(xdftA).^2);  
                    psdxB=(abs(xdftB).^2);  
                    mysumA=mysumA+psdxA;
                    mysumB=mysumB+psdxB;
                    count=count+1;
                    if(count==obj.numGroupsPerCapture)
                        break;
                    end
                end
                mysumA(2:end-1) = 2*mysumA(2:end-1);
                mysumB(2:end-1) = 2*mysumB(2:end-1);
                dataAPwr=mysumA/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);
                dataBPwr=mysumB/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);
                rawAData=dataA;
                rawBData=dataB;
            elseif(strcmp(channelMask,'A-B'))
                %TODO
                fprintf('THIS CODE IS NOT YET COMPELTED!!! ERROR!!');
                mysumB=zeros(1,obj.numSamplesForAvgSpectralPower/2+1);
                mysumA=mysumB;
                dataA=obj.myDataA;
                dataB=obj.myDataB;
                for j=0:obj.numGroupsPerCapture-1
                    index=j*obj.numSamplesForAvgSpectralPower;    

                    voltagesA=dataA(index+1:index+obj.numSamplesForAvgSpectralPower);
                    voltagesB=dataB(index+1:index+obj.numSamplesForAvgSpectralPower);
                    xdftA=fft(voltagesA);  
                    xdftB=fft(voltagesB);
                    xdftA=xdftA(1:obj.numSamplesForAvgSpectralPower/2+1);
                    xdftB=xdftB(1:obj.numSamplesForAvgSpectralPower/2+1);
                    psdxA=(abs(xdftA).^2);  
                    psdxB=(abs(xdftB).^2);  
                    mysumA=mysumA+psdxA;
                    mysumB=mysumB+psdxB;
                    count=count+1;
                    if(count==obj.numGroupsPerCapture)
                        break;
                    end
                end
                mysumA(2:end-1) = 2*mysumA(2:end-1);
                mysumB(2:end-1) = 2*mysumB(2:end-1);
                dataAPwr=mysumA/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);
                dataBPwr=mysumB/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);
                rawAData=dataA;
                rawBData=dataB;
            elseif(strcmp(channelMask,'B-A'))
                %TODO
                fprintf('THIS CODE IS NOT YET COMPELTED!!! ERROR!!');
                mysumB=zeros(1,obj.numSamplesForAvgSpectralPower/2+1);
                mysumA=mysumB;
                dataA=obj.myDataA;
                dataB=obj.myDataB;
                for j=0:obj.numGroupsPerCapture-1
                    index=j*obj.numSamplesForAvgSpectralPower;    

                    voltagesA=dataA(index+1:index+obj.numSamplesForAvgSpectralPower);
                    voltagesB=dataB(index+1:index+obj.numSamplesForAvgSpectralPower);
                    xdftA=fft(voltagesA);  
                    xdftB=fft(voltagesB);
                    xdftA=xdftA(1:obj.numSamplesForAvgSpectralPower/2+1);
                    xdftB=xdftB(1:obj.numSamplesForAvgSpectralPower/2+1);
                    psdxA=(abs(xdftA).^2);  
                    psdxB=(abs(xdftB).^2);  
                    mysumA=mysumA+psdxA;
                    mysumB=mysumB+psdxB;
                    count=count+1;
                    if(count==obj.numGroupsPerCapture)
                        break;
                    end
                end
                mysumA(2:end-1) = 2*mysumA(2:end-1);
                mysumB(2:end-1) = 2*mysumB(2:end-1);
                dataAPwr=mysumA/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);
                dataBPwr=mysumB/(count*obj.SamplingFrequency*obj.numSamplesForAvgSpectralPower);
                rawAData=dataA;
                rawBData=dataB;
            end 
            
            %convert from volts^2 to W
            dataAPwr=dataAPwr/50;
            dataBPwr=dataBPwr/50;
            freq = 0:obj.SamplingFrequency/obj.numSamplesForAvgSpectralPower:obj.SamplingFrequency/2;
            
        end
        
        %calculate the total avg noise power in units of W
        %channelMask should be 'A' 'B' or 'A'+'B'
        function [pwrA, pwrB, rawAData, rawBData] = totalVoltagePwr(obj, channelMask)
            if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B'))
                fprintf('Channel mask is incorrect');
                return;
            end
            if(channelMask=='A')
                [dataA, ~]=obj.acquireVoltSamples(channelMask);
                pwrA=var(dataA)/50;
                pwrB=0;
            elseif(channelMask=='B')
                [~, dataB]=obj.acquireVoltSamples(channelMask);
                pwrA=0;
                pwrB=var(dataB)/50; 
            else
                [dataA, dataB,]=obj.acquireVoltSamples(channelMask);
                pwrA=var(dataA)/50;
                pwrB=var(dataB)/50; 
            end
            rawAData=dataA;
            rawBData=dataB;
 
        end
        
        %returns the total power in units of W by converting to FFT, applying spectral
        %mask, and integrating
        %the applied mask is the mask in which the frequencies are removed
        %mask should be in the form of a Nx2 vector
        %N is the number of bands to remove
        %first number in pair is lower bound, second is upper bound
        %call setSizeSpectralVoltagePower before calling this function
        function [totalPowerA, totalPowerB, rawAData, rawBData] = pipeline_acquireTotalAvgVoltagePowerWithSpectralMask(obj, maskA, maskB, channelMask)
            %if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B'||strcmp(channelMask,'A-B')||strcmp(channelMask,'B-A')))
            if(~(channelMask=='A' || channelMask=='B' || channelMask=='A'+'B'))
                fprintf('Channel mask is incorrect');
                return;
            end
            
            [s1A, s2A]=size(maskA);
            if(s2A ~= 2)
                fprintf('Incorrect input for mask A');
                return;
            end
            
            [s1B, s2B]=size(maskB);
            if(s2B ~= 2)
                fprintf('Incorrect input for mask B');
                return;
            end
            
            
            if(channelMask=='A')
                [freq, dataAPwr, ~, rawAData, rawBData] = pipeline_acquireAvgSpectralVoltagePower(obj, channelMask);
            elseif(channelMask=='B')
                [freq, ~, dataBPwr, rawAData, rawBData] = pipeline_acquireAvgSpectralVoltagePower(obj, channelMask);
            elseif(channelMask=='A'+'B')
                 [freq, dataAPwr, dataBPwr, rawAData, rawBData] = pipeline_acquireAvgSpectralVoltagePower(obj, channelMask); %33msec
            elseif(strcmp(channelMask,'A-B'))
                [freq, dataAPwr, ~, rawAData, rawBData] = pipeline_acquireAvgSpectralVoltagePower(obj, channelMask);
            elseif(strcmp(channelMask,'B-A'))
                [freq, ~, dataBPwr, rawAData, rawBData] = pipeline_acquireAvgSpectralVoltagePower(obj, channelMask);
            end
            
            %TODO: finish this function for A-B and B-A
            
            %the rest of this function takes one msec or less to complete
            %for both channels 
            %find indices of freq that should be masked
            indicesA=-ones(1,length(freq));
            indicesB=indicesA;
            countA=0;
            countB=0;
            for(i=1:length(freq))
                for(j=1:s1A)
                    if(freq(i)>=maskA(j,1) && freq(i)<=maskA(j,2))
                        countA=countA+1;
                        indicesA(countA)=i;  
                    end
                end
                for(j=1:s1B)
                    if(freq(i)>=maskB(j,1) && freq(i)<=maskB(j,2))
                        countB=countB+1;
                        indicesB(countB)=i;
                    end
                end
            end
            
            %apply mask to dataAPwr
            
            if(channelMask=='A')
                for(i=1:countA)
                    dataAPwr(indicesA(i))=0;
                end
                totalPowerA=sum(dataAPwr)*obj.SamplingFrequency/obj.numSamplesForAvgSpectralPower;
                totalPowerB=0;
            elseif(channelMask=='B')
                for(i=1:countB-1)
                    dataBPwr(indicesB(i))=0;
                end
                totalPowerB=sum(dataBPwr)*obj.SamplingFrequency/obj.numSamplesForAvgSpectralPower;
                totalPowerA=0;
            else
                for(i=1:countA-1)
                    dataAPwr(indicesA(i))=0;
                end
                for(i=1:countB-1)
                    dataBPwr(indicesB(i))=0;
                end
                totalPowerA=sum(dataAPwr)*obj.SamplingFrequency/obj.numSamplesForAvgSpectralPower;
                totalPowerB=sum(dataBPwr)*obj.SamplingFrequency/obj.numSamplesForAvgSpectralPower; 
            end
        end  %end function acquireTotalAvgVoltagePowerWithSpectralMask
    end %end methods

    
    properties (Hidden=true, Constant)
        ApiSuccess                              = int32(512);
        ApiFailed                               = int32(513);
        ApiAccessDenied                         = int32(514);
        ApiDmaChannelUnavailable                = int32(515);
        ApiDmaChannelInvalid                    = int32(516);
        ApiDmaChannelTypeError                  = int32(517);
        ApiDmaInProgress                        = int32(518);
        ApiDmaDone                              = int32(519);
        ApiDmaPaused                            = int32(520);
        ApiDmaNotPaused                         = int32(521);
        ApiDmaCommandInvalid                    = int32(522);
        ApiDmaManReady                          = int32(523);
        ApiDmaManNotReady                       = int32(524);
        ApiDmaInvalidChannelPriority            = int32(525);
        ApiDmaManCorrupted                      = int32(526);
        ApiDmaInvalidElementIndex               = int32(527);
        ApiDmaNoMoreElements                    = int32(528);
        ApiDmaSglInvalid                        = int32(529);
        ApiDmaSglQueueFull                      = int32(530);
        ApiNullParam                            = int32(531);
        ApiInvalidBusIndex                      = int32(532);
        ApiUnsupportedFunction                  = int32(533);
        ApiInvalidPciSpace                      = int32(534);
        ApiInvalidIopSpace                      = int32(535);
        ApiInvalidSize                          = int32(536);
        ApiInvalidAddress                       = int32(537);
        ApiInvalidAccessType                    = int32(538);
        ApiInvalidIndex                         = int32(539);
        ApiMuNotReady                           = int32(540);
        ApiMuFifoEmpty                          = int32(541);
        ApiMuFifoFull                           = int32(542);
        ApiInvalidRegister                      = int32(543);
        ApiDoorbellClearFailed                  = int32(544);
        ApiInvalidUserPin                       = int32(545);
        ApiInvalidUserState                     = int32(546);
        ApiEepromNotPresent                     = int32(547);
        ApiEepromTypeNotSupported               = int32(548);
        ApiEepromBlank                          = int32(549);
        ApiConfigAccessFailed                   = int32(550);
        ApiInvalidDeviceInfo                    = int32(551);
        ApiNoActiveDriver                       = int32(552);
        ApiInsufficientResources                = int32(553);
        ApiObjectAlreadyAllocated               = int32(554);
        ApiAlreadyInitialized                   = int32(555);
        ApiNotInitialized                       = int32(556);
        ApiBadConfigRegEndianMode               = int32(557);
        ApiInvalidPowerState                    = int32(558);
        ApiPowerDown                            = int32(559);
        ApiFlybyNotSupported                    = int32(560);
        ApiNotSupportThisChannel                = int32(561);
        ApiNoAction                             = int32(562);
        ApiHSNotSupported                       = int32(563);
        ApiVPDNotSupported                      = int32(564);
        ApiVpdNotEnabled                        = int32(565);
        ApiNoMoreCap                            = int32(566);
        ApiInvalidOffset                        = int32(567);
        ApiBadPinDirection                      = int32(568);
        ApiPciTimeout                           = int32(569);
        ApiDmaChannelClosed                     = int32(570);
        ApiDmaChannelError                      = int32(571);
        ApiInvalidHandle                        = int32(572);
        ApiBufferNotReady                       = int32(573);
        ApiInvalidData                          = int32(574);
        ApiDoNothing                            = int32(575);
        ApiDmaSglBuildFailed                    = int32(576);
        ApiPMNotSupported                       = int32(577);
        ApiInvalidDriverVersion                 = int32(578);
        ApiWaitTimeout                          = int32(579);
        ApiWaitCanceled                         = int32(580);
        ApiBufferTooSmall                       = int32(581);
        ApiBufferOverflow                       = int32(582);
        ApiInvalidBuffer                        = int32(583);
        ApiInvalidRecordsPerBuffer              = int32(584);
        ApiDmaPending                           = int32(585);
        ApiLockAndProbePagesFailed              = int32(586);
        ApiWaitAbandoned                        = int32(587);
        ApiWaitFailed                           = int32(588);
        ApiTransferComplete                     = int32(589);
        ApiPllNotLocked                         = int32(590);
        ApiNotSupportedInDualChannelMode        = int32(591);
        ApiNotSupportedInQuadChannelMode        = int32(592);
        ApiFileIoError                          = int32(593);
        ApiInvalidClockFrequency                = int32(594);
        ApiInvalidSkipTable                     = int32(595);
        ApiInvalidDspModule                     = int32(596);
        ApiDESOnlySupportedInSingleChannelMode  = int32(597);
        ApiInconsistentChannel                  = int32(598);
        ApiDspFiniteRecordsPerAcquisition       = int32(599);
        ApiNotEnoughNptFooters                  = int32(600);
        ApiInvalidNptFooter                     = int32(601);
        ApiOCTIgnoreBadClockNotSupported        = int32(602);
        %ApiError1                              = int32(603);
        %ApiError2                              = int32(604);
        ApiOCTNoTriggerDetected                 = int32(605);
        ApiOCTTriggerTooFast                    = int32(606);
        ApiNetworkError                         = int32(607);

        %--------------------------------------------------------------------------
        % Board types
        %--------------------------------------------------------------------------

        ATS_NONE        = int32(0);
        ATS850          = int32(1);
        ATS310          = int32(2);
        ATS330          = int32(3);
        ATS855          = int32(4);
        ATS315          = int32(5);
        ATS335          = int32(6);
        ATS460          = int32(7);
        ATS860          = int32(8);
        ATS660          = int32(9);
        ATS665          = int32(10);
        ATS9462         = int32(11);
        ATS9434         = int32(12);
        ATS9870         = int32(13);
        ATS9350         = int32(14);
        ATS9325         = int32(15);
        ATS9440         = int32(16);
        ATS9410         = int32(17);
        ATS9351         = int32(18);
        ATS9310         = int32(19);
        ATS9461         = int32(20);
        ATS9850         = int32(21);
        ATS9625         = int32(22);
        ATG6500         = int32(23);
        ATS9626         = int32(24);
        ATS9360         = int32(25);
        AXI8870         = int32(26);
        ATS9370         = int32(27);
        ATU7825         = int32(28);
        ATS9373         = int32(29);
        ATS9416         = int32(30);
        ATS_LAST        = int32(31);



        %--------------------------------------------------------------------------
        % Input Control
        %--------------------------------------------------------------------------




        %--------------------------------------------------------------------------
        % Trigger Control
        %--------------------------------------------------------------------------



        %--------------------------------------------------------------------------
        % Auxiliary I/O and LED Control
        %--------------------------------------------------------------------------



        %--------------------------------------------------------------------------
        % Get/Set Parameters
        %--------------------------------------------------------------------------

        NUMBER_OF_RECORDS           =   hex2dec('10000001');
        PRETRIGGER_AMOUNT           =   hex2dec('10000002');
        RECORD_LENGTH               =   hex2dec('10000003');
        TRIGGER_ENGINE              =   hex2dec('10000004');
        TRIGGER_DELAY               =   hex2dec('10000005');
        TRIGGER_TIMEOUT             =   hex2dec('10000006');
        SAMPLE_RATE                 =   hex2dec('10000007');
        CONFIGURATION_MODE          =   hex2dec('10000008');
        DATA_WIDTH                  =   hex2dec('10000009');
   %     SAMPLE_SIZE                 =   DATA_WIDTH;
        AUTO_CALIBRATE              =   hex2dec('1000000A');
        TRIGGER_XXXXX               =   hex2dec('1000000B');
        CLOCK_SOURCE                =   hex2dec('1000000C');
        CLOCK_SLOPE                 =   hex2dec('1000000D');
        IMPEDANCE                   =   hex2dec('1000000E');
        INPUT_RANGE                 =   hex2dec('1000000F');
        COUPLING                    =   hex2dec('10000010');
        MAX_TIMEOUTS_ALLOWED        =   hex2dec('10000011');
        ATS_OPERATING_MODE          =   hex2dec('10000012');
        CLOCK_DECIMATION_EXTERNAL   =   hex2dec('10000013');
        LED_CONTROL                 =   hex2dec('10000014');
        ATTENUATOR_RELAY            =   hex2dec('10000018');
        EXT_TRIGGER_COUPLING        =   hex2dec('1000001A');
        EXT_TRIGGER_ATTENUATOR_RELAY    =  hex2dec('1000001C');
        TRIGGER_ENGINE_SOURCE       =   hex2dec('1000001E');
        TRIGGER_ENGINE_SLOPE        =   hex2dec('10000020');
        SEND_DAC_VALUE              =   hex2dec('10000021');
        SLEEP_DEVICE                =   hex2dec('10000022');
        GET_DAC_VALUE               =   hex2dec('10000023');
        GET_SERIAL_NUMBER           =   hex2dec('10000024');
        GET_FIRST_CAL_DATE          =   hex2dec('10000025');
        GET_LATEST_CAL_DATE         =   hex2dec('10000026');
        GET_LATEST_TEST_DATE        =   hex2dec('10000027');
        SEND_RELAY_VALUE            =   hex2dec('10000028');
        GET_LATEST_CAL_DATE_MONTH   =   hex2dec('1000002D');
        GET_LATEST_CAL_DATE_DAY     =   hex2dec('1000002E');
        GET_LATEST_CAL_DATE_YEAR    =   hex2dec('1000002F');
        GET_PCIE_LINK_SPEED         =   hex2dec('10000030');
        GET_PCIE_LINK_WIDTH         =   hex2dec('10000031');
        SETGET_ASYNC_BUFFSIZE_BYTES =   hex2dec('10000039');
        SETGET_ASYNC_BUFFCOUNT      =   hex2dec('10000040');
        SET_DATA_FORMAT             =   hex2dec('10000041');
        GET_DATA_FORMAT             =   hex2dec('10000042');
        DATA_FORMAT_UNSIGNED        =   0;
        DATA_FORMAT_SIGNED          =   1;
        SET_SINGLE_CHANNEL_MODE     =   hex2dec('10000043');
        GET_SAMPLES_PER_TIMESTAMP_CLOCK    =   hex2dec('10000044');
        GET_RECORDS_CAPTURED        =   hex2dec('10000045');
        GET_MAX_PRETRIGGER_SAMPLES  =   hex2dec('10000046');
        SET_ADC_MODE                =   hex2dec('10000047');
        ADC_MODE_DEFAULT            = 0;
        ADC_MODE_DES                = 1;
        ADC_MODE_DES_WIDEBAND       = 2;
        ADC_MODE_RESET_ENABLE       = hex2dec('8001');
        ADC_MODE_RESET_DISABLE      = hex2dec('8002');
        ECC_MODE                    =   hex2dec('10000048');
        ECC_DISABLE                 =   0;
        ECC_ENABLE                  =   1;
        GET_AUX_INPUT_LEVEL         =   hex2dec('10000049');
        AUX_INPUT_LOW               =   0;
        AUX_INPUT_HIGH              =   1;
        EXT_TRIGGER_IMPEDANCE       =   hex2dec('10000065');
        EXT_TRIG_50_OHMS            =     0;
        EXT_TRIG_300_OHMS           =     1;
        GET_CHANNELS_PER_BOARD      =     hex2dec('10000070');
        GET_CPF_DEVICE              =     hex2dec('10000071');
        PACK_MODE                   =     hex2dec('10000072');
        PACK_DEFAULT                =     0;
        PACK_8_BITS_PER_SAMPLE      = 1;
        PACK_12_BITS_PER_SAMPLE     = 2;
        GET_FPGA_TEMPERATURE        =    hex2dec('10000080');
        API_FLAGS                   = hex2dec('10000090');
        API_ENABLE_TRACE            = 1;

        MEMORY_SIZE                 =   hex2dec('1000002A');
        MEMORY_SIZE_MSAMPLES        =   hex2dec('1000004A');
        BOARD_TYPE                  =   hex2dec('1000002B');
        ASOPC_TYPE                  =   hex2dec('1000002C');
        GET_BOARD_OPTIONS_LOW       =   hex2dec('10000037');
        GET_BOARD_OPTIONS_HIGH      =   hex2dec('10000038');
        OPTION_STREAMING_DMA        =   uint32(2^0);
        OPTION_AVERAGE_INPUT        =   uint32(2^1);
        OPTION_EXTERNAL_CLOCK       =   uint32(2^1);
        OPTION_DUAL_PORT_MEMORY     =   uint32(2^2);
        OPTION_180MHZ_OSCILLATOR    =   uint32(2^3);
        OPTION_LVTTL_EXT_CLOCK      =   uint32(2^4);
        OPTION_SW_SPI               =    uint32(2^5);
        OPTION_ALT_INPUT_RANGES     =     uint32(2^6);
        OPTION_VARIABLE_RATE_10MHZ_PLL    =     uint32(2^7);
        OPTION_2GHZ_ADC             = uint32(2^8);
        OPTION_DUAL_EDGE_SAMPLING   = uint32(2^9);
        OPTION_OEM_FPGA             = uint32(2^47);

        TRANSFER_OFFET                  =   hex2dec('10000030');
        TRANSFER_LENGTH                 =   hex2dec('10000031');
        TRANSFER_RECORD_OFFSET          =   hex2dec('10000032');
        TRANSFER_NUM_OF_RECORDS         =   hex2dec('10000033');
        TRANSFER_MAPPING_RATIO          =   hex2dec('10000034');
        TRIGGER_ADDRESS_AND_TIMESTAMP   = hex2dec('10000035');
        MASTER_SLAVE_INDEPENDENT        =   hex2dec('10000036');

        TRIGGERED                           =   hex2dec('10000040');
        BUSY                                =   hex2dec('10000041');
        WHO_TRIGGERED                       =   hex2dec('10000042');
        GET_ASYNC_BUFFERS_PENDING           =   hex2dec('10000050');
        GET_ASYNC_BUFFERS_PENDING_FULL      =    hex2dec('10000051');
        GET_ASYNC_BUFFERS_PENDING_EMPTY     =   hex2dec('10000052');
        ACF_SAMPLES_PER_RECORD              =   hex2dec('10000060');
        ACF_RECORDS_TO_AVERAGE              =   hex2dec('10000061');
        ACF_MODE                            =   hex2dec('10000062');

                                        % Internal sample rates
        SAMPLE_RATE_1KSPS           =   hex2dec('00000001');
        SAMPLE_RATE_2KSPS           =   hex2dec('00000002');
        SAMPLE_RATE_5KSPS           =   hex2dec('00000004');
        SAMPLE_RATE_10KSPS          =   hex2dec('00000008');
        SAMPLE_RATE_20KSPS          =   hex2dec('0000000A');
        SAMPLE_RATE_50KSPS          =   hex2dec('0000000C');
        SAMPLE_RATE_100KSPS         =   hex2dec('0000000E');
        SAMPLE_RATE_200KSPS         =   hex2dec('00000010');
        SAMPLE_RATE_500KSPS         =   hex2dec('00000012');
        SAMPLE_RATE_1MSPS           =   hex2dec('00000014');
        SAMPLE_RATE_2MSPS           =   hex2dec('00000018');
        SAMPLE_RATE_5MSPS           =   hex2dec('0000001A');
        SAMPLE_RATE_10MSPS          =   hex2dec('0000001C');
        SAMPLE_RATE_20MSPS          =   hex2dec('0000001E');
        SAMPLE_RATE_25MSPS          =   hex2dec('00000021');
        SAMPLE_RATE_50MSPS          =   hex2dec('00000022');
        SAMPLE_RATE_100MSPS         =   hex2dec('00000024');
        SAMPLE_RATE_125MSPS         =   hex2dec('00000025');
        SAMPLE_RATE_160MSPS         =   hex2dec('00000026');
        SAMPLE_RATE_180MSPS         =   hex2dec('00000027');
        SAMPLE_RATE_200MSPS         =   hex2dec('00000028');
        SAMPLE_RATE_250MSPS         =   hex2dec('0000002B');
        SAMPLE_RATE_400MSPS         =   hex2dec('0000002D');
        SAMPLE_RATE_500MSPS         =   hex2dec('00000030');
        SAMPLE_RATE_800MSPS         =   hex2dec('00000032');
        SAMPLE_RATE_1GSPS           =   hex2dec('00000035');
        SAMPLE_RATE_1000MSPS        =   hex2dec('00000035');
        SAMPLE_RATE_1200MSPS        =   hex2dec('00000037');
        SAMPLE_RATE_1500MSPS        =   hex2dec('0000003A');
        SAMPLE_RATE_1600MSPS        =   hex2dec('0000003B');
        SAMPLE_RATE_1800MSPS        =   hex2dec('0000003D');
        SAMPLE_RATE_2000MSPS        =   hex2dec('0000003F');
        SAMPLE_RATE_2GSPS           =   hex2dec('0000003F');
        SAMPLE_RATE_2400MSPS        =   hex2dec('0000006A');
        SAMPLE_RATE_3000MSPS        =   hex2dec('00000075');
        SAMPLE_RATE_3GSPS           =   hex2dec('00000075');
        SAMPLE_RATE_3600MSPS        =   hex2dec('0000007B');
        SAMPLE_RATE_4000MSPS        =   hex2dec('00000080');
        SAMPLE_RATE_4GSPS           =   hex2dec('00000080');
        SAMPLE_RATE_USER_DEF        =   hex2dec('00000040');

                                        % Decimation
        DECIMATE_BY_8               =   hex2dec('00000008');
        DECIMATE_BY_64              =   hex2dec('00000040');

                                        % Input impedances
        IMPEDANCE_1M_OHM            =   hex2dec('00000001');
        IMPEDANCE_50_OHM            =   hex2dec('00000002');
        IMPEDANCE_75_OHM            =   hex2dec('00000004');
        IMPEDANCE_300_OHM           =   hex2dec('00000008');
        IMPEDANCE_600_OHM           =   hex2dec('0000000A');

                                        % Clock sources
        INTERNAL_CLOCK              =   hex2dec('00000001');
        EXTERNAL_CLOCK              =   hex2dec('00000002');
        FAST_EXTERNAL_CLOCK         =   hex2dec('00000002')';
        MEDIMUM_EXTERNAL_CLOCK      =   hex2dec('00000003')';
        MEDIUM_EXTERNAL_CLOCK       =   hex2dec('00000003')';
        SLOW_EXTERNAL_CLOCK         =   hex2dec('00000004')';
        EXTERNAL_CLOCK_AC           =   hex2dec('00000005')';
        EXTERNAL_CLOCK_DC           =   hex2dec('00000006')';
        EXTERNAL_CLOCK_10MHz_REF    =   hex2dec('00000007')';
        INTERNAL_CLOCK_DIV_5        =   hex2dec('000000010')';
        MASTER_CLOCK                =   hex2dec('000000011')';

                                        % Clock edges
        CLOCK_EDGE_RISING           =   hex2dec('00000000');
        CLOCK_EDGE_FALLING          =   hex2dec('00000001');

                                        % Input ranges
        INPUT_RANGE_PM_20_MV        =   hex2dec('00000001');
        INPUT_RANGE_PM_40_MV        =   hex2dec('00000002');
        INPUT_RANGE_PM_50_MV        =   hex2dec('00000003');
        INPUT_RANGE_PM_80_MV        =   hex2dec('00000004');
        INPUT_RANGE_PM_100_MV       =   hex2dec('00000005');
        INPUT_RANGE_PM_200_MV       =   hex2dec('00000006');
        INPUT_RANGE_PM_400_MV       =   hex2dec('00000007');
        INPUT_RANGE_PM_500_MV       =   hex2dec('00000008');
        INPUT_RANGE_PM_800_MV       =   hex2dec('00000009');
        INPUT_RANGE_PM_1_V          =   hex2dec('0000000A');
        INPUT_RANGE_PM_2_V          =   hex2dec('0000000B');
        INPUT_RANGE_PM_4_V          =   hex2dec('0000000C');
        INPUT_RANGE_PM_5_V          =   hex2dec('0000000D');
        INPUT_RANGE_PM_8_V          =   hex2dec('0000000E');
        INPUT_RANGE_PM_10_V         =   hex2dec('0000000F');
        INPUT_RANGE_PM_20_V         =   hex2dec('00000010');
        INPUT_RANGE_PM_40_V         =   hex2dec('00000011');
        INPUT_RANGE_PM_16_V         =   hex2dec('00000012');
        INPUT_RANGE_HIFI            =   hex2dec('00000020');
        INPUT_RANGE_PM_1_V_25       =   hex2dec('00000021');
        INPUT_RANGE_PM_2_V_5        =   hex2dec('00000025');
        INPUT_RANGE_PM_125_MV       =   hex2dec('00000028');
        INPUT_RANGE_PM_250_MV       =   hex2dec('00000030');

                                        % Input coupling
        AC_COUPLING                 =   hex2dec('00000001');
        DC_COUPLING                 =   hex2dec('00000002');

                                        % Trigger engines
        TRIG_ENGINE_J               =   hex2dec('00000000');
        TRIG_ENGINE_K               =   hex2dec('00000001');

                                        % Trigger engine operations
        TRIG_ENGINE_OP_J            =   hex2dec('00000000');
        TRIG_ENGINE_OP_K            =   hex2dec('00000001');
        TRIG_ENGINE_OP_J_OR_K       =   hex2dec('00000002');
        TRIG_ENGINE_OP_J_AND_K      =   hex2dec('00000003');
        TRIG_ENGINE_OP_J_XOR_K      =   hex2dec('00000004');
        TRIG_ENGINE_OP_J_AND_NOT_K  =   hex2dec('00000005');
        TRIG_ENGINE_OP_NOT_J_AND_K  =   hex2dec('00000006');

                                        % Trigger engine sources
        TRIG_CHAN_A                 =   hex2dec('00000000');
        TRIG_CHAN_B                 =   hex2dec('00000001');
        TRIG_EXTERNAL               =   hex2dec('00000002');
        TRIG_DISABLE                =   hex2dec('00000003');
        TRIG_CHAN_C                 =   hex2dec('00000004');
        TRIG_CHAN_D                 =   hex2dec('00000005');
        TRIG_CHAN_E                 =   hex2dec('00000006');
        TRIG_CHAN_F                 =   hex2dec('00000007');
        TRIG_CHAN_G                 =   hex2dec('00000008');
        TRIG_CHAN_H                 =   hex2dec('00000009');
        TRIG_CHAN_I                 =   hex2dec('0000000A');
        TRIG_CHAN_J                 =   hex2dec('0000000B');
        TRIG_CHAN_K                 =   hex2dec('0000000C');
        TRIG_CHAN_L                 =   hex2dec('0000000D');
        TRIG_CHAN_M                 =   hex2dec('0000000E');
        TRIG_CHAN_N                 =   hex2dec('0000000F');
        TRIG_CHAN_O                 =   hex2dec('00000010');
        TRIG_CHAN_P                 =   hex2dec('00000011');
        TRIG_PXI_STAR               =   hex2dec('00000100');

                                        % Trigger slopes
        TRIGGER_SLOPE_POSITIVE      =   hex2dec('00000001');
        TRIGGER_SLOPE_NEGATIVE      =   hex2dec('00000002');

                                        % Input channels
        CHANNEL_ALL                 =   hex2dec('00000000');
        CHANNEL_A                   =   hex2dec('00000001');
        CHANNEL_B                   =   hex2dec('00000002');
        CHANNEL_C                   =   hex2dec('00000004');
        CHANNEL_D                   =   hex2dec('00000008');
        CHANNEL_E                   =   hex2dec('00000010');
        CHANNEL_F                   =   hex2dec('00000012');
        CHANNEL_G                   =   hex2dec('00000014');
        CHANNEL_H                   =   hex2dec('00000018');
        CHANNEL_I                   =   hex2dec('00000100');
        CHANNEL_J                   =   hex2dec('00000200');
        CHANNEL_K                   =   hex2dec('00000400');
        CHANNEL_L                   =   hex2dec('00000800');
        CHANNEL_M                   =   hex2dec('00001000');
        CHANNEL_N                   =   hex2dec('00002000');
        CHANNEL_O                   =   hex2dec('00004000');
        CHANNEL_P                   =   hex2dec('00008000');

                                        % Master/Slave Configuration
        BOARD_IS_INDEPENDENT        =   hex2dec('00000000');
        BOARD_IS_MASTER             =   hex2dec('00000001');
        BOARD_IS_SLAVE              =   hex2dec('00000002');
        BOARD_IS_LAST_SLAVE         =   hex2dec('00000003');

                                        % LED states
        LED_OFF                     =   hex2dec('00000000');
        LED_ON                      =   hex2dec('00000001');

                                        % Attenuator Relay
        AR_X1                       =   hex2dec('00000000');
        AR_DIV40                    =   hex2dec('00000001');

                                        % External trigger ranges
        ETR_DIV5                    =   hex2dec('00000000');
        ETR_X1                      =   hex2dec('00000001');
        ETR_5V                      =   hex2dec('00000000');
        ETR_1V                      =   hex2dec('00000001');
        ETR_TTL                     =   hex2dec('00000002');
        ETR_2V5                     =   hex2dec('00000003');

                                        % Device Sleep state
        POWER_OFF                   =   hex2dec('00000000');
        POWER_ON                    =   hex2dec('00000001');

                                        % Software Events control
        SW_EVENTS_OFF               =   hex2dec('00000000');
        SW_EVENTS_ON                =   hex2dec('00000001');

                                          % TimeStamp Value Reset Control
        TIMESTAMP_RESET_FIRSTTIME_ONLY  = hex2dec('00000000');
        TIMESTAMP_RESET_ALWAYS          = hex2dec('00000001');

                                         % DAC Names used by API AlazarDACSettingAdjust
        ATS460_DAC_A_GAIN            =   hex2dec('00000001');
        ATS460_DAC_A_OFFSET          =   hex2dec('00000002');
        ATS460_DAC_A_POSITION        =   hex2dec('00000003');
        ATS460_DAC_B_GAIN            =   hex2dec('00000009');
        ATS460_DAC_B_OFFSET          =   hex2dec('0000000A');
        ATS460_DAC_B_POSITION        =   hex2dec('0000000B');
        ATS460_DAC_EXTERNAL_CLK_REF  =   hex2dec('00000007');

                                         % DAC Names Specific to the ATS660
        ATS660_DAC_A_GAIN            =   hex2dec('00000001');
        ATS660_DAC_A_OFFSET          =   hex2dec('00000002');
        ATS660_DAC_A_POSITION        =   hex2dec('00000003');
        ATS660_DAC_B_GAIN            =   hex2dec('00000009');
        ATS660_DAC_B_OFFSET          =   hex2dec('0000000A');
        ATS660_DAC_B_POSITION        =   hex2dec('0000000B');
        ATS660_DAC_EXTERNAL_CLK_REF  =   hex2dec('00000007');

                                        % DAC Names Specific to the ATS665
        ATS665_DAC_A_GAIN            =   hex2dec('00000001');
        ATS665_DAC_A_OFFSET          =   hex2dec('00000002');
        ATS665_DAC_A_POSITION        =   hex2dec('00000003');
        ATS665_DAC_B_GAIN            =   hex2dec('00000009');
        ATS665_DAC_B_OFFSET          =   hex2dec('0000000A');
        ATS665_DAC_B_POSITION        =   hex2dec('0000000B');
        ATS665_DAC_EXTERNAL_CLK_REF  =   hex2dec('00000007');

                                        % Error return values
        SETDAC_INVALID_SETGET       = 660;
        SETDAC_INVALID_CHANNEL      = 661;
        SETDAC_INVALID_DACNAME      = 662;
        SETDAC_INVALID_COUPLING     = 663;
        SETDAC_INVALID_RANGE        = 664;
        SETDAC_INVALID_IMPEDANCE    = 665;
        SETDAC_BAD_GET_PTR          = 667;
        SETDAC_INVALID_BOARDTYPE    = 668;

        CSO_DUMMY_CLOCK_DISABLE              = 0;
        CSO_DUMMY_CLOCK_TIMER                = 1;
        CSO_DUMMY_CLOCK_EXT_TRIGGER          = 2;
        CSO_DUMMY_CLOCK_TIMER_ON_TIMER_OFF   = 3;

                                        % AUX outputs
        AUX_OUT_TRIGGER             =    0;
        AUX_OUT_PACER               =    2;
        AUX_OUT_BUSY                =    4;
        AUX_OUT_CLOCK               =    6;
        AUX_OUT_RESERVED            =    8;
        AUX_OUT_CAPTURE_ALMOST_DONE =    10;
        AUX_OUT_AUXILIARY           =    12;
        AUX_OUT_SERIAL_DATA         =    14;
        AUX_OUT_TRIGGER_ENABLE      =    16;

                                        % AUX inputs
        AUX_IN_TRIGGER_ENABLE       =    1;
        AUX_IN_DIGITAL_TRIGGER      =    3;
        AUX_IN_GATE                 =    5;
        AUX_IN_CAPTURE_ON_DEMAND    =    7;
        AUX_IN_RESET_TIMESTAMP      =    9;
        AUX_IN_SLOW_EXTERNAL_CLOCK  =    11;
        AUX_IN_AUXILIARY            =    13;
        AUX_IN_SERIAL_DATA          =    15;

        AUX_INPUT_AUXILIARY         =    13;
        AUX_INPUT_SERIAL_DATA       =    15;

        STOS_OPTION_DEFER_START_CAPTURE     = 1;

        SSM_DISABLE = 0;
        SSM_ENABLE  = 1;

        %--------------------------------------------------------------------------
        % User-programmable FPGA
        %--------------------------------------------------------------------------
                                        % AlazarCoprocessorDownload
        CPF_OPTION_DMA_DOWNLOAD       = 1;

                                        % User-programmable FPGA device types
        CPF_DEVICE_UNKNOWN            = 0;
        CPF_DEVICE_EP3SL50            = 1;
        CPF_DEVICE_EP3SE260           = 2;

                                        % Framework defined registers
        CPF_REG_SIGNATURE             = 0;
        CPF_REG_REVISION              = 1;
        CPF_REG_VERSION               = 2;
        CPF_REG_STATUS                = 3;

        % Constants to be used in the Application when dealing with Custom FPGAs
        FPGA_GETFIRST               =   hex2dec('FFFFFFFF');
        FPGA_GETNEXT                =   hex2dec('FFFFFFFE');
        FPGA_GETLAST                =   hex2dec('FFFFFFFC');

        %--------------------------------------------------------------------------
        % AutoDMA Control
        %--------------------------------------------------------------------------

                                        % AutoDMA flags
        ADMA_EXTERNAL_STARTCAPTURE  =   hex2dec('00000001');
        ADMA_ENABLE_RECORD_HEADERS  =   hex2dec('00000008');
        ADMA_SINGLE_DMA_CHANNEL     =   hex2dec('00000010');
        ADMA_ALLOC_BUFFERS          =   hex2dec('00000020');
        ADMA_TRADITIONAL_MODE       =   hex2dec('00000000');
        ADMA_CONTINUOUS_MODE        =   hex2dec('00000100');
        ADMA_NPT                    =   hex2dec('00000200');
        ADMA_TRIGGERED_STREAMING    =   hex2dec('00000400');
        ADMA_FIFO_ONLY_STREAMING    =   hex2dec('00000800');
        ADMA_INTERLEAVE_SAMPLES     =   hex2dec('00001000');
        ADMA_GET_PROCESSED_DATA     =   hex2dec('00002000');
        ADMA_ENABLE_RECORD_FOOTERS  =   hex2dec('00010000');

                                        % AutoDMA header constants
        ADMA_CLOCKSOURCE            =   hex2dec('00000001');
        ADMA_CLOCKEDGE              =   hex2dec('00000002');
        ADMA_SAMPLERATE             =   hex2dec('00000003');
        ADMA_INPUTRANGE             =   hex2dec('00000004');
        ADMA_INPUTCOUPLING          =   hex2dec('00000005');
        ADMA_IMPUTIMPEDENCE         =   hex2dec('00000006');
        ADMA_EXTTRIGGERED           =   hex2dec('00000007');
        ADMA_CHA_TRIGGERED          =   hex2dec('00000008');
        ADMA_CHB_TRIGGERED          =   hex2dec('00000009');
        ADMA_TIMEOUT                =   hex2dec('0000000A');
        ADMA_THISCHANTRIGGERED      =   hex2dec('0000000B');
        ADMA_SERIALNUMBER           =   hex2dec('0000000C');
        ADMA_SYSTEMNUMBER           =   hex2dec('0000000D');
        ADMA_BOARDNUMBER            =   hex2dec('0000000E');
        ADMA_WHICHCHANNEL           =   hex2dec('0000000F');
        ADMA_SAMPLERESOLUTION       =   hex2dec('00000010');
        ADMA_DATAFORMAT             =   hex2dec('00000011');
    end
    
end