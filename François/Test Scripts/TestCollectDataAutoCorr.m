alazarLoadLibrary();

digitizer = deviceDrivers.ATS850Driver(1,1);

digitizer.configureDefault();

fid=fopen('testdata.bin','a+');

maxSamples=262144-4;
numSamples=maxSamples;

datas=[];
for(i=1:10)
    [dataA, dataB] = digitizer.acquireDataSamples(numSamples, 1);
    datas=[datas dataA];
end

histogram(datas,0:256);
var(datas)/50/25000000