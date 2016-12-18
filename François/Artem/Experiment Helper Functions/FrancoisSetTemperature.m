    %set temperature and wait for thermal stabilitzation
    function FrancoisSetTemperature(lakeshore, finalTemp, temperatureTolerance)
        keeplooping=true;%can pause program and set this to true if needed
        startingTemp=lakeshore.temperatureA;
        tempController.setPoint1=finalTemp; 
        count=0;
        if(finalTemp>startingTemp)%we are warming
            fprintf('warming to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA<finalTemp-temperatureTolerance)
                if(mod(count,10)==0)
                    fprintf('current temp is %f K\n', tempController.temperatureA);
                end
                count=count+1;
                pause(1);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        else%we are cooling
            fprintf('cooling to %f K\n', finalTemp)
            while(keeplooping && tempController.temperatureA>finalTemp+temperatureTolerance)
                if(mod(count,10)==0)
                    fprintf('current temp is %f K\n', tempController.temperatureA);
                end
                count=count+1;
                pause(1);
            end
            fprintf('temp of %f K reached\n', finalTemp)
        end
        %if(i>1)
            pause(tempWaitTime);
        %end
    end

