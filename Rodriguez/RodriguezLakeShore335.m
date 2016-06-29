classdef RodriguezLakeShore335 < Lakeshore335
    %RODRIGUEZLAKESHORE335 Summary of this class goes here
    %   Made by Artem Talanov June 2016
    %   Control a specific Lakeshore335 with specific PID needs at certain
    %   temperature ranges.  Select the correct PID setting by
    %   interpolating between calibrated PID setting points.
    
    properties (Access=private)
        %vector of temps, and calculated P's I's and D's for PID loop
        %for heater 1
        temps1=  [0  5   10  20  35  60  100 150 210 290 400];
        P1=   10*[30 30  30  30  30  30  30  30  30  30  30]
        I1=   10*[30 30  30  30  30  30  30  30  30  30  30];
        D1=   0*[30 30  30  30  30  30  30  30  30  30  30];
        
        
        temps2=  [0  5   10  20  35  60  100 150 210 290 400];
        P2=   10*[30 30  30  30  30  30  30  30  30  30  30]
        I2=   10*[30 30  30  30  30  30  30  30  30  30  30];
        D2=   0*[30 30  30  30  30  30  30  30  30  30  30];
        
        %range transition temperatures
        %above lowLimit use medium range
        %above med limit use high range etc
        %heater1
        lowLimit1=0;
        medLimit1=10;
        
        %heater 2
        lowLimit2=0;
        medLimit2=10;
    end
    
    methods
        
        function adjustHeater1ToTemp(obj,val)
            obj.PID1=[interp1(obj.temps1, obj.P1, val), interp1(obj.temps1, obj.I1, val), interp1(obj.temps1, obj.D1, val)];
            if(val<obj.lowLimit1)
                obj.range1=1;
            elseif(val<obj.medLimit1)
                obj.range1=2;
            else
                obj.range1=3;
            end
        end
        
        function adjustHeater2ToTemp(obj,val)
            obj.PID2=[interp1(obj.temps2, obj.P2, val), interp1(obj.temps2, obj.I2, val), interp1(obj.temps2, obj.D2, val)];
            if(val<obj.lowLimit2)
                obj.range1=1;
            elseif(val<obj.medLimit2)
                obj.range1=2;
            else
                obj.range1=3;
            end
        end    

    end
    
end

