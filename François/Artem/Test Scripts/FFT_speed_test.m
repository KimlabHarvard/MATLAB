%suppose we are sampling at 1000 MS/samples per second, giving a bandwidth of 0 to 500 MHz
samplingFrequency=1e9;
sampleTimeSeconds=1;


data=-1+2*rand(1,samplingFrequency*sampleTimeSeconds); %9.5 s to generate 1G data points


FFTblockSize=2^11;

numBlocks=floor(samplingFrequency*sampleTimeSeconds/FFTblockSize);

fftResults=zeros(numBlocks,FFTblockSize/2+1);

tic
for j=0:numBlocks-1
    index=j*FFTblockSize;
    xdft=fft(data(index+1:index+FFTblockSize));
    xdft2=xdft(1:FFTblockSize/2+1);
    fftResults(j+1,:)=(abs(xdft2).^2);
    %mysum=mysum+psdx;
    %count=count+1;
    %correct is sum(abs(xdft).^2)/1024^2
    %if(count==obj.numGroupsPerCapture)
    %    break;
    %end
end
toc

% 22.3 seconds to FFT 1s of data samples at 1 GS/s in blocks of size 2^20
% 20.19,20.01 seconds to FFT 1s of data samples at 1 GS/s in blocks of size 2^10