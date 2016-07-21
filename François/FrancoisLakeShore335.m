classdef FrancoisLakeShore335 < deviceDrivers.Lakeshore335
    %RODRIGUEZLAKESHORE335 Summary of this class goes here
    %   Made by Artem Talanov June 2016
    %   Control a specific Lakeshore335 with specific PID needs at certain
    %   temperature ranges.  Select the correct PID setting by
    %   interpolating between calibrated PID setting points.
    
    properties (Access=private)
        %vector of temps, and calculated P's I's and D's for PID loop
        %for heater 1
        temps1= [0   10  15  20  60  100 150 210 290 400];
        P1=0.75*[700 450 300 290 340 270 240 200 175 175]
        I1=     [300 300 300 132 46  22  19  17  16  16];
        D1=   0*[30  30  30  30  30  30  30  30  30  30];
        
        
        temps2=  [0  5   10  20  35  60  100 150 210 290 400];
        P2=   8.5*[30 30  30  30  30  30  30  30  30  30  30]
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
        medLimit2=5;
    end
    
    methods 
        function val=measureTempAWithPolynomialInterpolation(obj)
            tempInSensorUnits=str2double(obj.query('SRDG? A')); %gives temperature in sensor units
            val=obj.polynomialInterpolation(tempInSensorUnits);
            
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
    
    methods%(Access=private)
        %to be used with the Si diode supplied with the Francois Fridge
        function temp = polynomialInterpolation(~, v)
            if (v>1.15) %1.15 to 1.6
                v=v-1.375;
                coef=[10.569656301248722, -38.41285376331595, 65.21469409476227, -175.39736208370945, 523.5219240269608, 2097.261811269148, -24212.130952419015, -3013.358781023545, 154398.90478547194];
                poly=[1 v v^2 v^3 v^4 v^5 v^6 v^7 v^8];
                temp=dot(poly,coef);
            elseif (v>1.11) %1.11 to 1.15
                v=v-1.13;
                coef=[23.60732492317715, -75.07828864148611, 3058.1105161858313, -185178.94873075854, 5.026299824587362e+06, 2.8230487022378813e+07, -3.940978248034703e+09, 5.1112054279905876e+10];
                poly=[1 v v^2 v^3 v^4 v^5 v^6 v^7];
                temp=dot(poly,coef);
            elseif (v>1.09) %1.09 to 1.11
                v=v-1.1;
                coef=[33.431065635773705, 569.8247114729255, 3206.475597498838, 114571.0556211262,  5.425008392815264e+06, 2.941435944619293e+07, -4.812150053573365e+09];
                poly=[1 v v^2 v^3 v^4 v^5 v^6];
                temp=dot(poly,coef);
            else %% .5124 to 1.09
                v=v-0.8;
                coef=[192.31611274874008, -465.69616580085, -108.54565443688381, -121.55022281769561, 56.49043831470216, -2333.6550647762947, -12096.478588565218, 11191.788797894207, 76667.06931382559];
                poly=[1 v v^2 v^3 v^4 v^5 v^6 v^7 v^8];
                temp=dot(poly,coef);
            end
        end
        
        %to be used with X108541 Lakeshore Cernox Sensor
        function temp = polynomialInterpolationX108541(obj,tempInSensorUnits)
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

