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
% Description: Instrument driver for the Kiethley 2450 sourcemeter.
%
classdef Keithley2450 < deviceDrivers.lib.GPIBorEthernet
    
    properties
        voltage
        current
        resistance
        currentLimit
        voltageLimit
        currentRange
        voltageRange
        resistanceRange
        output
        measMode
        sourceMode
        NPLC
        limitTripped % 0 = no Trip, 1 = Voltage overload, 2 = Current overload
    end
    
    methods
        function obj = Keithley2450()
        end
        
        %get mode
        function val = get.measMode(obj)
            val = strtrim(obj.query(':FUNCTION?'));
        end
        
        %set mode
        function obj = set.measMode(obj, mode)
            valid_modes = {'current', 'curr', 'voltage', 'volt','resistance','res'};
            if ~ismember(mode, valid_modes)
                error('Invalid mode');
            end
            obj.write([':FUNCTION ' mode]);
        end
        
        %get mode
        function val = get.sourceMode(obj)
            val = strtrim(obj.query('SOUR:FUNC?'));
        end
        
        %set mode
        function obj = set.sourceMode(obj, mode)
            valid_modes = {'current', 'curr', 'voltage', 'volt'};
            if ~ismember(mode, valid_modes)
                error('Invalid mode');
            end
            obj.write(['SOUR:FUNC ' mode]);
        end
        
        %get output state (on or off)
        function val = get.output(obj)
            val = str2double(obj.query(':OUTPUT?'));
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
            obj.write([':OUTPUT ' value]);
        end
        
        %get NPLC
        function val = get.NPLC(obj)
            val = str2double(obj.query('SENS:VOLT:NPLC?'));
        end
        
        function obj = set.NPLC(obj,value)
            if ~isnumeric(value) || value<.01 || value>10
                error('Invalid input')
            end
            obj.write(':NPLC %G',value);
        end
        
        
        % set current range
        function obj = set.currentRange(obj, value)
            % Validate input
            assert(isnumeric(value) || strcmp(value,'auto'), 'Invalid input');
            if strcmp(value,'auto')
                obj.write('CURR:RANG:AUTO ON')
            else
                obj.write(sprintf('CURR:RANG %G;',value));
            end
        end
        
        % get current range
        function val = get.currentRange(obj)
            val = str2double(obj.query('CURR:RANG?'));
        end
        
        % set current range
        function obj = set.voltageRange(obj, value)
            % Validate input
            assert(isnumeric(value) || strcmp(value,'auto'), 'Invalid input');
            if strcmp(value,'auto')
                obj.write('VOLT:RANG:AUTO ON')
            else
                obj.write(sprintf('VOLT:RANG %G;',value));
            end
        end
        
        % get current range
        function val = get.voltageRange(obj)
            val = str2double(obj.query('VOLT:RANG?'));
        end
        
        % set current range
        function obj = set.resistanceRange(obj, value)
            % Validate input
            assert(isnumeric(value) || strcmp(value,'auto'), 'Invalid input');
            if strcmp(value,'auto')
                obj.write('CURR:RANG:AUTO ON')
            else
                obj.write(sprintf('RES:RANG %G;',value));
            end
        end
        
        % get current range
        function val = get.resistanceRange(obj)
            val = str2double(obj.query('RES:RANG?'));
        end
        
        % set current
        function obj = set.current(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOUR:CURR %G;',value));
        end
        
        %get mode
        function val = get.current(obj)
            val = str2double(obj.query(':MEAS:CURR?'));
        end
        
        % set current protection
        function obj = set.currentLimit(obj, value)
            % Validate input
            assert(isnumeric(value) && abs(value) <= 1.05, 'Invalid input');
            %voltage limit is maximum applied voltage while in current mode
            obj.write(sprintf('SOUR:VOLT:ILIM %G;',value));
        end
        
        % set voltage
        function obj = set.voltage(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOUR:VOLT %G;',value));
        end
        
        %get mode
        function val = get.voltage(obj)
            val = str2double(obj.query(':MEAS:VOLT?'));
        end
        
        % set voltage protection
        function obj = set.voltageLimit(obj, value)
            % Validate input
            assert(isnumeric(value) && abs(value) <= 210, 'Invalid input');
            %voltage limit is maximum applied voltage while in current mode
            obj.write(sprintf('SOUR:CURR:VLIM %G;',value));
        end
        
        function val = get.limitTripped(obj)
            if str2double(obj.query('SOUR:VOLT:TRIP?'))
                val = 1;
            elseif str2double(obj.query('SOUR:CURR:TRIP?'))
                val = 2;
            else
                val=0;
            end
        end       
    end
end
