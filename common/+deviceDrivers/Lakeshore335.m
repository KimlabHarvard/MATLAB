% Class Lakeshore335 - Instrument driver for the Lakeshore 335 Temperature Controller

% Original Author: Colm Ryan (cryan@bbn.com)

% Copyright 2015 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef Lakeshore335 < deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.GPIBorVISA
    properties
		leds
        PID1
        rampRate1
        range1
        setPoint1
        PID2
        rampRate2
        range2
        setPoint2
    end
    properties (SetAccess=private)
        temperatureA
        temperatureB
    end

	methods
        
        %Get and receive temperature setpoints
        function val = get.setPoint1(obj)
			val = str2double(obj.query('SETP? 1'));
        end
		function set.setPoint1(obj, val)
            assert(isnumeric(val),'set point must be numeric')
			%Artem: I am changing this from %d to %f
            obj.write(sprintf('SETP 1,%f', val));
            obj.adjustHeater1ToTemp(obj,val);
        end
        function val = get.setPoint2(obj)
			val = str2double(obj.query('SETP? 2'));
        end
        function set.setPoint2(obj, val)
            assert(isnumeric(val),'set point must be numeric')
            %Artem: I am changing this from %d to %f
			obj.write(sprintf('SETP 2,%f', val));
            obj.adjustHeater2ToTemp(obj,val);
        end

        %Get and receive PID setting
        function val = get.PID1(obj)
			PID_str = obj.query('PID? 1');
            commaPos = strfind(PID_str,',');
            P = str2double(PID_str(1:commaPos(1)));
            I = str2double(PID_str(commaPos(1):commaPos(2)));
            D = str2double(PID_str(commaPos(2):end));
            val = [P I D];
        end
		function set.PID1(obj,PID)
            assert(length(PID)==3, 'specify PID at list [P,I,D]')
            P=PID(1);
            I=PID(2);
            D=PID(3);
            assert(isnumeric(P)&&isnumeric(I)&&isnumeric(D),'PID values must be numeric')
			obj.write(sprintf('PID 1,%d,%d,%d',P,I,D));
        end
        function val = get.PID2(obj)
			PID_str = obj.query('PID? 2');
            commaPos = strfind(PID_str,',');
            P = str2double(PID_str(1:commaPos(1)));
            I = str2double(PID_str(commaPos(1):commaPos(2)));
            D = str2double(PID_str(commaPos(2):end));
            val = [P I D];
        end
		function set.PID2(obj,PID)
            assert(length(PID)==3, 'specify PID at list [P,I,D]')
            P=PID(1);
            I=PID(2);
            D=PID(3);
            assert(isnumeric(P)&&isnumeric(I)&&isnumeric(D),'PID values must be numeric')
			obj.write(sprintf('PID 2,%d,%d,%d',P,I,D));
        end
        
        %Get and receive Ramp rates
        function val = get.rampRate1(obj)
			str = obj.query('RAMP? 1');
            val = str2double(str(3:end));
        end
		function set.rampRate1(obj, rate)
            assert(isnumeric(rate),'ramp rate must be numeric')
			obj.write(sprintf('RAMP 1,1,%d', rate));
        end
        function val = get.rampRate2(obj)
			str = obj.query('RAMP? 2');
            val = str2double(str(3:end));
        end
		function set.rampRate2(obj, rate)
            assert(isnumeric(rate),'ramp Rate must be numeric')
			obj.write(sprintf('RAMP 2,1,%d', rate));
        end
 
        %Get and receive Range
        function val = get.range1(obj)
			val = str2double(obj.query('RANGE? 1'));
        end
		function set.range1(obj, range)
            assert(range==0||range==1||range==2||range==3, ...
                'range must be numeric. 0=OFF, 1=LOW, 2=MED, 3=HIGH')
			obj.write(sprintf('RANGE 1,%d', range));
        end
        function val = get.range2(obj)
			val = str2double(obj.query('RANGE? 2'));
        end
		function set.range2(obj, range)
            assert(range==0||range==1||range==2||range==3, ...
                'range must be numeric. 0=OFF, 1=LOW, 2=MED, 3=HIGH')
			obj.write(sprintf('RANGE 2,%d', range));
        end
        
        %read channel A and B temperature
        function val = get.temperatureA(obj)
            val = str2double(obj.query('KRDG? A'));
        end
        function val = get.temperatureB(obj)
            val = str2double(obj.query('KRDG? B'));
        end
		
		%Getter/setter for front-panel LEDs as boolean
		function val = get.leds(obj)
			val = logical(str2double(obj.query('LEDS?')));
		end

		function set.leds(obj,val)
			obj.write(sprintf('LEDS %d', val));
		end

		function val = get_temperature(obj, chan)
			%Get current temperature in Kelvin for a specified channel
			assert(chan == 'A' || chan == 'B', 'Channel must be "A" or "B"');
			val = str2double(obj.query(sprintf('KRDG? %c', chan)));
		end

		function [val, temp] = get_curve_val(obj, curve, index)
			%Get a calibration curve tuple for a curve at a specified index
			strs = strsplit(obj.query(sprintf('CRVPT? %d,%d', curve, index)), ',');
			val = str2double(strs{1});
			temp = str2double(strs{2});
		end

		function set_curve_val(obj, curve, index, val, temp)
			%Set a calibration curve (val, temp) tuple for a curve at a specified index
			obj.write(sprintf(strcat('CRVPT %f,%f,%f,%f'), curve, index, val, temp));
        end
        
        %this function written by Artem Talanov
        %name and serialNumber are strings
        %for format, 1=mV/K, 2=V/K, 3=Ohm/K, 4=log(Ohm)/K
        %limitValue specifies the curve temp limit in kelvin
        %coefficient specifies curve temperature coefficient, 1=negative,
        %2=positive
        function set_curve_header(obj, curve, name, serialNumber, format, limitValue, coefficient)
			%Set a calibration curve header
			obj.write(sprintf(strcat('CRVHDR %d,', name, ',',serialNumber, ',%d,%d,%d'), curve, format, limitValue, coefficient));
	        end
        
        %this function written by Artem Talanov
        function val= readSensorUnitsInput(obj, channel)
            assert(channel == 'A' || channel == 'B', 'Channel must be "A" or "B"');
			val = str2double(obj.query(sprintf('SRDG? %c', channel)));
        end
        
        %this function written by Artem Talanov
        function setInputCurveNumber(obj, curve, channel)
            assert(channel == 'A' || channel == 'B', 'Channel must be "A" or "B"');
            obj.write(sprintf(strcat('INCRV ', channel,', %d'), curve));
        end
        
        function PID = autoTune(obj,chan,mode,displayProgress)
            assert(chan==1||chan==2,'channel must be set to 1 or 2')
            assert(mode==0||mode==1||mode==2,'mode must be numeric. 0=P, 1=PI, 2=PID')
            assert(displayProgress==0||displayProgress==1,'displayProgress should be 0 or 1')
            obj.write(sprintf('ATUNE %d,%d',chan,mode))
            pause(1);
            status = obj.autoTuneStatus();
            stage = 0;
            pause on
            if displayProgress == 1
                h=waitbar(0,'auto tuning');
            end
            while status(1) == 1 &&status(3)==0
                if stage ~= status(4)
                    stage = status(4);
                    if displayProgress ==1
                        waitbar(stage/10,h,sprintf('auto tuning step %d or 10',stage));
                    end
                end
                pause(1)
                status = obj.autoTuneStatus();
            end
            assert(status(3)==0,sprintf('error occured in autoTune at stage %d',status(4)))
            if chan==1
                PID = obj.PID1();
            else
                PID = obj.PID2();
            end
            if displayProgress ==1
                close(h);
            end
        end
        
        function status = autoTuneStatus(obj)
            status_str = obj.query('TUNEST?');
            state = str2double(status_str(1)); %0=no active tuning, 1=active tuning
            output = str2double(status_str(3)); %current heater being tuned, 1 or 2
            error = str2double(status_str(5)); %0= no error, 1=error
            stage = str2double(status_str(7:end)); %shows current stage of autotune process
                                                   %if errored shows stage when error occured
            status = [state,output,error,stage];
        end
            
    end
    
    methods (Access=protected)
        function adjustHeater1ToTemp(obj,val)
            %no implementation in this class
            %overload in subclasses
        end
        
        function adjustHeater2ToTemp(obj,val)
            %no implementation in this class
            %overload in subclasses
        end
    end

end
