alazarLoadLibrary();

digitizer = ATS850Driver(1,1);

digitizer.configureDefault();

fid=fopen('testdata.bin','a+');


%digitizer.prepStreamDataChA(1000, 1, 1);

[dataA, dataB] = digitizer.acquireDataSamplesSingleChannel(262144-4, 1);

%h = plot(dataA(1,:));

while(true)
    [dataA, dataB] = digitizer.acquireDataSamplesSingleChannel(262144-4, 1);
    fwrite(fid, dataA, 'uint8');
   % h.YData=dataA(1,1:150);
end