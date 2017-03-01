    %set temperature and wait for thermal stabilitzation
    function FrancoisSetTemperature(lakeshore, finalTemp, temperatureTolerance)
        keeplooping=true;%can pause program and set this to true if needed
        startingTemp=lakeshore.temperatureA;
        lakeshore.setPoint1=finalTemp; 
        count=0;
        if(finalTemp>startingTemp)%we are warming
            fprintf('warming to %f K\n', finalTemp)
            while(keeplooping && lakeshore.temperatureA<finalTemp-temperatureTolerance)
            %while(true)
                if(mod(count,1)==10)
                    fprintf('current temp is %f K\n', lakeshore.temperatureA);
                end
                count=count+1;
                pause(.3);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        else%we are cooling
            fprintf('cooling to %f K\n', finalTemp)
            %while(true)
            while(keeplooping && lakeshore.temperatureA>finalTemp+temperatureTolerance)
                if(mod(count,1)==10)
                    fprintf('current temp is %f K\n', lakeshore.temperatureA);
                end
                count=count+1;
                pause(.3);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        end
    end

