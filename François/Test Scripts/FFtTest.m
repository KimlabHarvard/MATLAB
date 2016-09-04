squarethenavg=zeros(1,10000);
avgthensqr=zeros(1,10000);
voltagez=[];

for(k=1:1000)
    voltagez(k,1:10000)=ones(1,10000)*10+10*rand(1,10000);
    avgthensqr=avgthensqr+voltagez(k,:);
    squarethenavg=squarethenavg+(voltagez(k,:)).^2;
    if(rem(k,50)==0)
        k
    end
end

avgthensqr=avgthensqr/1000;
avgthensqr=avgthensqr.^2;
squarethenavg=squarethenavg/1000;
plot(1:10000,avgthensqr,1:10000,squarethenavg+30);
var(avgthensqr)
var(squarethenavg) %slightly more noise


N=2^22; %num samples
%Fs=10000; %sampling freq
Fs=5000000000; %5 GHz
t=(0:N-1)/Fs;

%data=cos(t*2*pi*400)+cos(t*2*pi*630)+cos(t*2*pi*700);
data= 1*wgn(1,N,1)/70;
%plot(t,data)
dft=fft(data);
%dft(2:end-1) = 2*dft(2:end-1);
freq=Fs*((-N/2:N/2-1))/N;
deltaF=Fs/N;;
autocorr=var(data);
fftPwr=sum(abs(dft).^2)/N^2;
%plot(freq,dft);

%subsample the data at 50 MHz

% Fs2=50000000; %50 MHz
% data2=downsample(data,100);
% N2=length(data2);
% dft2=fft(data2);
% freq2=Fs2*((-N2/2:N2/2-1))/N2;
% deltaF2=Fs2/N2;
% autocorr2=var(data2);
% fftPwr2=sum(abs(dft2).^2)/N2^2;
% autocorr/autocorr2
% fftPwr/fftPwr2





%=665;
%limitIndex=int32(fLimit/deltaF);
%figure(1)

%dft(limitIndex:N-limitIndex)=0;
%dft=[dft(N/2+1:end) dft(1:N/2)];
%plot(Fs*((-N/2:N/2-1))/N,dft,Fs*((-N/2:N/2-1))/N,imag(dft));
%grid on; xlim([-1000,1000]);
%plot(t,data)

%choppedData=ifft(dft);
%plot(t,choppedData,t,cos(t*2*pi*400)+cos(t*2*pi*630),t,cos(t*2*pi*400)+cos(t*2*pi*630)+cos(t*2*pi*700));
%xlim([0 0.01])