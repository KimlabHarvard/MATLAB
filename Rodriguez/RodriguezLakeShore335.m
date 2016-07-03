classdef RodriguezLakeShore335 < deviceDrivers.Lakeshore335
    %RODRIGUEZLAKESHORE335 Summary of this class goes here
    %   Made by Artem Talanov June 2016
    %   Control a specific Lakeshore335 with specific PID needs at certain
    %   temperature ranges.  Select the correct PID setting by
    %   interpolating between calibrated PID setting points.
    
    properties (Access=private)
        %vector of temps, and calculated P's I's and D's for PID loop
        %for heater 1
        temps1= [0   5   10  20  35  60  100 150 210 290 400];
        P1=     [225 225 225 225 375 325 225 240 200 175 175]
        I1=     [145 145 145 145 105 43  22  19  17  16  16];
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
        medLimit1=9;
        
        %heater 2
        lowLimit2=0;
        medLimit2=9;
    end
    
    methods 
        function val=measureTempBWithPolynomialInterpolation(obj)
            tempInSensorUnits=str2double(obj.query('SRDG? B')); %gives temperature in sensor units
            val=obj.chebyshevInterpolation(tempInSensorUnits);
            
            %need to convert this to a temperature by a polynomial
            %interpolation
        end
    end
    
    methods(Access=protected)
        function adjustHeater1ToTemp(obj,val)
            %val is the correct temp here
            pid=[interp1(obj.temps1, obj.P1, val), interp1(obj.temps1, obj.I1, val), interp1(obj.temps1, obj.D1, val)];
            %the interpolation above is correct
            obj.PID1=pid;
            obj.PID1
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
    
    methods(Access=private)
        function temp = chebyshevInterpolation(obj,tempInSensorUnits)
            if (tempInSensorUnits>=235.1)
                zl=2.34626109356;
                zu=3.05034108905;
                z=log10(tempInSensorUnits);
                k=((z-zl)-(zu-z))/(zu-zl);
                coef=[5.872114 -6.694314 2.693842 -0.841628 0.202332 -0.031255 -0.000914 0.002411 -0.001440];
                poly=cos((0:8)*acos(k));
                temp=dot(poly,coef);
            elseif (tempInSensorUnits>=96.58)
                zl=1.95382559091;
                zu=2.40085793449;
                z=log10(tempInSensorUnits);
                k=((z-zl)-(zu-z))/(zu-zl);
                coef=[43.767153 -38.110437 7.407506 -0.719088 0.082445 0.004051 -0.008891];
                poly=cos((0:6)*acos(k));
                temp=dot(poly,coef);
            else  %if (tempInSensorUnits>=37.91)
                zl=1.57429959892;
                zu=2.01938136565;
                z=log10(tempInSensorUnits);
                k=((z-zl)-(zu-z))/(zu-zl);
                coef=[177.934996 -126.735415 21.467813 -3.105422 0.653925 -0.125659 0.013574];
                poly=cos((0:6)*acos(k));
                temp=dot(poly,coef);
            end
        end
    end
    
end

