function [ output_args ] = AC_noise_measurements_sineWave( input_args )
%AC_NOISE_MEASUREMENTS_SINEWAVE Take AC noise measurements
%   Take differential noise power measurements by feeding a constant + AC current
%   apply a digital moving FFT on the sample data every N samples
%   apply a digital square bandpass on the FFT
%   digitally calculate the total power in V^2 contained in the band of interest
%   apply a digital lock-in technique to the moving FFT power data



    %   Parameters of the measurement
    samplingFrequency=50000000;
    modulationFrequency = 3000; %3kHz modulation gives 20.8 cycles in 5.2 ms measurement time
    modulationAmplitudeCurrentList=1e-9*[20 20 20 20 20 20];
    numCapturesPerPoint;
    dcCurrentList=1e-9*[0 50 100 150 200 250];
    sampleResistance=21000;
    currentSourceResistance=10530000;
    numSamples=2^10; %FFT length
    fftSpacing=2^7; %moving FFT every this number of points
    rangeA=0.1;
    rangeB=4;
    acquisitionSize=2^18-4;
    mask=[0 1.31e7; 1.56e7 3e7];
    
    %   instruments
    functionGenerator=deviceDrivers.SG382();
    functionGenerator.connect('27');
    digitizerCard=deviceDrivers.ATS850Driver(1,1);
    digitizerCard.setAcquisitionSize(acquisitionSize);
    digitizerCard.setTriggerDelay(1);
    digitizerCard.setTriggerTimeout(0);
    TC=deviceDrivers.Lakeshore335();
    TC.connect('12');
    
    %   data arrays and vectors
    data=struct('time',[],'temp',[],'current',[],'inPhasePower',[],'outOfPhasePower',[],'dcPower',[]);
    freq = 0:obj.SamplingFrequency/obj.numSamplesForAvgSpectralPower:obj.SamplingFrequency/2; %frequency vector for the fft
    [s1A, s2A]=size(mask);
    indices=-ones(1,length(freq));
    countA=0;
    for(i=1:length(freq))
        for(j=1:s1A)
            if(freq(i)>=maskA(j,1) && freq(i)<=maskA(j,2))
                countA=countA+1;
                indices(countA)=i;  
            end
        end
    end
    
    leng=floor(acquisitionSize/fftSpacing);
    movingPwrAvg=zeros(1,leng);
    refSineSubSample=zeros(1,leng);
    halfNumSamples=numSamples/2;
    startTime=clock;
    for(currentIndex=1:length(dcCurrentList)) %for all DC current biases
        for(j=1:numCapturesPerPoint) %take lots of captures for a certain DC current bias point
            [samples, refSine]=digitizer.acquireVoltSamples('A'+'B'); %capture samples on Ch A and the ref sine wave on Ch B
            
            %apply a moving FFT of length numSamples on the sample data, spaced at a length of fftSpacing
            for index=1:fftSpacing:(acquisitionSize-fftSpacing) %e.g. 1, 101, 201, ..., 261701, 261801, 261901, 262001,
                xdft=fft(samples(index:index+numSamples)); %take the fft
                xdft=xdft(1:numSamples/2+1); %consider only positive frequencies
                psdx = abs(xdft).^2; %power spectral density
                psdx(2:end-1) = 2*psdx(2:end-1); %double ever element except first and last
                powerDensity=psdx/(samplingFrequency*numSamples); %units of V^2/Hz
                
                %apply the mask / square bandpass to the fft; indices are calculated above
                for(i=1:countA)
                    powerDensity(indices(i))=0;
                end
                movingPwrAvg(j)=sum(powerDensity)*obj.SamplingFrequency/obj.numSamplesForAvgSpectralPower;
                refSineSubSample(j)=refSine(index+halfNumSamples);
            end
            [localOscillator, localOscillator90deg, omega]=fitSineWave(refSineSubSample,modulationFrequency);
            data.time(currentIndex,j)=etime(clock,startTime);
            data.temp(currentIndex,j)=TC.temperature_A;
            data.inPhasePower(currentIndex,j)=dot(localOscillator,movingPwrAvg);
            data.outOfPhasePower(currentIndex,j)=dot(localOscillator90deg,movingPwrAvg);
            data.current(currentIndex,j)=dcCurrent;
            %take the mean over an integer number of cycles to avoid biasing the mean
            data.dcPower=mean(movingPwrAvg(1:int32(2*pi*samplingFrequency/Omega*floor(leng*omega/(2*pi*samplingFrequency)))));
            %amplitude=sqrt(inPhase^2+outOfPhase^2);
            
        end
    end
    
    
    
    function [local, local90deg, omega] = fitSineWave(dataToBeFitted, refFreq)
        x = 1:lenth(dataToBeFitted);
        myfittype = fittype('b*sin(omega*x+d)','dependent',{'y'},'independent',{'x'},'coefficients',{'b','omega','d'});
        fitOptions=fitoptions('Method','NonLinearLeastSquares','StartPoint',[1,2*pi*refFreq*samplingFrequenc,0]);
        myfit = fit(x',dataToBeFitted',myfittype,fitOptions);
        local=sin(myfit.omega*x+myfit.d); %amplitude of 1
        local90deg=sin(myfit.omega*x+myfit.d+pi/2); %amplitude of 1
        omega=myfit.omega;
    end

end

