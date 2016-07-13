alazarLoadLibrary();

digitizer = deviceDrivers.ATS850Driver(1,1);

digitizer.configureDefault();

fid=fopen('testdata.bin','a+');

maxSamples=262144-4;
numSamples=256*32; %256
N=numSamples;
Fs=50000000;
numAvg=500;

fgh=true;
while(true)

    numCapturesPerFullCapture=floor(maxSamples/numSamples);
    totalNumberOfFullCaptures=floor(numAvg/numCapturesPerFullCapture)+1;
    
    sum=zeros(1,numSamples/2+1);
    count=0;
    
    for i=1:totalNumberOfFullCaptures
        [dataA, dataB] = digitizer.acquireVoltsDataSamples(maxSamples, 1);
        %fwrite(fid, dataA, 'uint8');
        for j=0:numCapturesPerFullCapture-1
            index=j*numSamples;
            voltages=dataA(index+1:index+numSamples);
            xdft=fft(voltages);
            xdft=xdft(1:N/2+1);
            psdx = (1/(Fs*N)) * abs(xdft).^2/50;
            psdx(2:end-1) = 2*psdx(2:end-1);
            sum=sum+psdx;
            freq = 0:Fs/length(voltages):Fs/2;
            count=count+1;
            if(count==numAvg)
                break;
            end
        end
        if(count==numAvg)
            break;
        end
    end
    
    
    
    
    %Y = fft(dataA);
%     Y=fft(sum/numAvg);
%     P2 = abs(Y/L);
%     P1 = P2(1:L/2+1);
%     P1(2:end-1) = 2*P1(2:end-1);
%     f = Fs*(0:(L/2))/L;
%     


        %h=semilogy(freq,psdx);
        

    plotdata=sum/numAvg;
    
    if(fgh)
        h=semilogy(freq,plotdata);
        fgh=false;
        xlabel('f(Hz)');
        ylabel('Power (W/Hz)');
        title('200K, Cold Attenuator -> BNC cable -> DC block -> 15 MHZ LPF -> amp -> 1f MHz LP Filter -> digitizer');
    else
        h.YData=plotdata;
    end
    grid on;
    xlim([0,25000000])
    ylim([0.0000000000000001,0.0000000000001]);
    drawnow;
    
    

end
