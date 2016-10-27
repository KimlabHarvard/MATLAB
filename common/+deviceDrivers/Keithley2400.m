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
%
% File: Kiethley2400.m
% Authors: Jesse Crossno (crossno@seas.harvard.edu)
%          Evan Walsh (evanwalsh@seas.harvard.edu)
%
% Description: Instrument driver for the Kiethley 2400 sourcemeter.
% 
classdef Keithley2400 < deviceDrivers.lib.GPIBorEthernet
    
    properties
        CurrentLimit
        VoltageLimit
        Voltage
        Current
        CurrentRange
        VoltageRange
        Measure
        output
        mode
        avg_mode
        avg_count
        NPLC
        value
    end
    
    methods
        function obj = Keithley2400()
        end        

        %get value (voltage or current) regardless of mode
        function val = get.value(obj)
            data=obj.query(':READ?');
            
            if strcmp(strtrim(obj.query(':SENSE:FUNCTION?')),'"VOLT:DC"')
                val = str2double(data(1:13));
            elseif strcmp(strtrim(obj.query(':SENSE:FUNCTION?')),'"CURR:DC"')
                val = str2double(data(15:27));
            end
        end
        
        %get mode
        function val = get.mode(obj)
            val = strtrim(obj.query(':SOURCE:FUNCTION?'));
        end
        
        %get output state (on or off)
        function val = get.output(obj)
            val = str2double(obj.query(':OUTPUT:STATE?'));
        end
            
        %get number of counts per average
        function val = get.avg_count(obj)
            val = str2double(obj.query('SENS:AVER:COUN?'));
        end
        
        %get NPLC
        function val = get.NPLC(obj)
            val = str2double(obj.query('SENS:VOLT:NPLC?'));
        end
        
        %set value (voltage or current) regardless of mode
        function obj = set.value(obj, value)
            if strcmp(strtrim(obj.query(':SOURCE:FUNCTION?')),'VOLT')
                obj.write([':SOURCE:VOLT:LEVEL ' num2str(value)]);
            elseif strcmp(strtrim(obj.query(':SOURCE:FUNCTION?')),'CURR')
                obj.write([':SOURCE:CURR:LEVEL ' num2str(value)]);
            end
        end
        
        %set mode
        function obj = set.mode(obj, mode)
            valid_modes = {'current', 'curr', 'voltage', 'volt'};
            if ~ismember(mode, valid_modes)
                error('Invalid mode');
            end
            obj.write([':SOURCE:FUNCTION ' mode]);
        end
        
        %set output state (on or off)
        function obj = set.output(obj, value)
            if isnumeric(value) || islogical(value)
                value = num2str(value);
            end
            valid_inputs = ['on', '1', 'off', '0'];
            if ~ismember(value, valid_inputs)
                error('Invalid input');
            end         
            obj.write([':OUTPUT:STATE ' value]);
        end
            
        % place in current source mode
        function CurrentMode(obj)
            obj.write('SOURce:FUNC:MODE CURR;');
        end
        
        % set current range
        function obj = set.CurrentRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:CURR:RANGE %G;',value));
        end
        
        % set current
        function obj = set.Current(obj, value)
            % Validate input
            assert(strcmp(strtrim(obj.query(':SOURCE:FUNCTION?')),'CURR'), 'Cannot set current. Not sourcing current')
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOUR:CURR:LEV:IMM:AMPL %G;',value));
        end
        
        % get voltage if sourceing voltage return source value, if sensing
        % return sense, if both return source
        function val = get.Current(obj)
            if strcmp(strtrim(obj.query(':SOURCE:FUNCTION?')),'CURR')
                val = str2double(obj.query('SOUR:CURR:LEV:AMPL?;'));
            elseif strcmp(strtrim(obj.query(':SENSE:FUNCTION?')),'"CURR:DC"')
                data=obj.query(':READ?');
                val = str2double(data(15:27));
            end
        end
        
        % set current protection
        function obj = set.CurrentLimit(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:CURR:PROT:LEV %G;',value));
        end
        
        %place in voltage source mode
        function VoltageMode(obj)
            obj.write('SOURce:FUNC:MODE VOLT;');
        end
        
        %Set voltage range
        function obj = set.VoltageRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:VOLT:RANGE %G;',value));
        end
        
        % set voltage
        function obj =set.Voltage(obj, value)
            % Validate input
            assert(strcmp(strtrim(obj.query(':SOURCE:FUNCTION?')),'VOLT'), 'Cannot set voltage. Not sourcing voltage')
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:VOLT:LEV:IMM:AMPL %G;',value));
        end
        
        % get voltage if sourceing voltage return source value, if sensing
        % return sense, if both return source
        function val = get.Voltage(obj)
            if strcmp(strtrim(obj.query(':SOURCE:FUNCTION?')),'VOLT')
                val = str2double(obj.query('SOUR:VOLT:LEV:AMPL?;'));
            elseif strcmp(strtrim(obj.query(':SENSE:FUNCTION?')),'"VOLT:DC"')
                data=obj.query(':READ?');
                val = str2double(data(1:13));
            end
        end
        
        function obj = set.avg_mode(obj, value)
            if isnumeric(value) || islogical(value)
                value = num2str(value);
            end
            valid_inputs = ['MOV', 'REP'];
            if ~ismember(value, valid_inputs)
                error('Invalid input');
            end        
            obj.write(['SENS:AVER:TCON ' value]);
        end
        
        function obj = set.avg_count(obj,value)
            if ~isnumeric(value) || value<1 || value>100
                error('Invalid input')
            end
            obj.write('SENS:AVER:COUN %G',value);
        end
        
        function obj = set.NPLC(obj,value)
            if ~isnumeric(value) || value<.01 || value>10
                error('Invalid input')
            end
            obj.write('SENS:VOLT:NPLC %G',value);
        end
        
        
        % set voltage protection
        function obj = set.VoltageLimit(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:VOLT:PROT:LEV %G;',value));
        end
        
        % Measure Current, Voltage, and Resistance
        function EnableAllMeasure(obj)
            obj.write('SENS:FUNC:CONC ON;');
            obj.write('SENS:ON;ALL;');
        end
        
        % Turn current measurement on
        function EnableCurrentMeasure(obj)
            obj.write('SENS:FUNC:ON "CURR:DC";');
        end
        
        % Turn voltage measurement on
        function EnableVoltageMeasure(obj)
            obj.write('SENS:FUNC:ON "VOLT:DC";');
        end
        
        % Turn resistance measurement on
        function EnableResistanceMeasure(obj)
            obj.write('SENS:FUNC:ON "RES";');
        end
        
        %Turn all measurements OFF
        function DisableAllMeasure(obj)
            obj.write('SENS:FUNC:OFF:ALL;');
        end
        
        % read out channel B temperature
        function val = get.Measure(obj)
            tmp = obj.query('SENS:DATA:LAT?;');
            val = str2double(tmp);
        end
        
        %ramp to value @ a rate in A/s or V/s
        function ramp2value(obj,set,rate)
            assert(isnumeric(set)&&isnumeric(rate),'values must be numeric')
            %are we in CURR or VOLT mode
            mode_str = strtrim(obj.query(':SOURCE:FUNCTION?'));
            if strcmp(mode_str,'VOLT')
                start = obj.Voltage();
            elseif strcmp(mode_str,'CURR')
                start = obj.Current();
            else
                error('cannot ramp unless if current or voltage mode')
            end
            time_per_step = 2E-2;
            total_time = abs(set-start)/rate;
            steps = abs(floor(total_time/time_per_step))+1;
            Vals = linspace(start,set,steps);
            for V=Vals(2:end)
                t=clock;
                obj.value = V;
                while etime(clock,t) < time_per_step
                end
            end
        end
    end
end
