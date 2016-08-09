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
% File: Kiethley2450.m
% Authors: Jesse Crossno (crossno@seas.harvard.edu)
%          Evan Walsh (evanwalsh@seas.harvard.edu)
%
% Description: Instrument driver for the Kiethley 2450 sourcemeter.
%
classdef Keithley2450 < deviceDrivers.lib.GPIBorEthernet
    
    properties
        voltage %this should be removed, unclear whether source or sense
        current %this should be removed, unclear whether source or sense
        resistance
        output
        sense_mode
        source_mode
        NPLC
        limitTripped % 0 = no Trip, 1 = Voltage overload, 2 = Current overload
    end
    
    %the properties for limits and ranges depends on the sens/source mode
    properties (Dependent)
      source_limit
      source_range
      sense_range
      readback %boolean, whether instrument records the measured or configured source value
      sourceVoltage
      sourceCurrent
      senseVoltage
      senseCurrent
   end
    
    methods
        function obj = Keithley2450()
        end
        
        function set.readback(obj, value)
            if isnumeric(value) || islogical(value)
                value = num2str(value);
            end
            valid_inputs = ['on', 'ON', '1', 'off', 'OFF', '0'];
            if ~ismember(value, valid_inputs)
                error('Invalid input');
            end
            myMode=obj.source_mode;
            if(strcmp(myMode,'CURR'))
                obj.write([':SOURce:CURRage:READ:BACK' value]);
            elseif(strcmp(myMode,'VOLT'))
                obj.write([':SOURce:VOLTage:READ:BACK' value]);
            else
                error(['received unexpected source mode', mode]);
            end
        end
        
        function val = get.readback(obj)
            myMode=obj.source_mode;
            if(strcmp(myMode,'CURR'))
                val=obj.query(':SOURce:CURRage:READ:BACK?');
            elseif(strcmp(myMode,'VOLT'))
                val=obj.query(':SOURce:VOLTage:READ:BACK?');
            else
                error(['received unexpected source mode', mode]);
            end
        end
        
        %get mode
        function val = get.sense_mode(obj)
            val = strtrim(obj.query('SENS:FUNCTION?'));
            val = val(2:end-1); %remove surrounding "s
        end
        
        %set mode
        function obj = set.sense_mode(obj, mode)
            assert(ischar(mode),'mode must be a string')
            valid_modes = {'current', 'curr', 'voltage', 'volt','resistance','res'};
            if ~ismember(lower(mode), valid_modes)
                error('Invalid mode');
            end
            obj.write(['SENS:FUNCTION "' mode,'"']);
        end
        
        %get mode
        function val = get.source_mode(obj)
            val = strtrim(obj.query('SOUR:FUNCTION?'));
        end
        
        %set mode
        function obj = set.source_mode(obj, mode)
            assert(ischar(mode),'mode must be a string')
            valid_modes = {'current', 'curr', 'voltage', 'volt'};
            if ~ismember(lower(mode), valid_modes)
                error('Invalid mode');
            end
            obj.write(['SOUR:FUNCTION ' mode]);
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
            valid_inputs = ['on', 'ON', '1', 'off', 'OFF', '0'];
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
        
        % set source limit
        function obj = set.source_limit(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            %find the current source mode
            mode = obj.source_mode;
            if strcmp(mode,'VOLT')
                obj.write(sprintf('SOUR:VOLT:ILIM %G;',value));
            elseif strcmp(mode,'CURR')
                obj.write(sprintf('SOUR:CURR:VLIM %G;',value));
            else
                error(['received unexpected source mode', mode]);
            end
        end
        
        % get source limit
        function val = get.source_limit(obj)
            %find the current source mode
            mode = obj.source_mode;
            if strcmp(mode,'VOLT')
                val = obj.query(sprintf('SOUR:VOLT:ILIM?'));
            elseif strcmp(mode,'CURR')
                val = obj.query(sprintf('SOUR:CURR:VLIM?'));
            else
                error(['received unexpected source mode', mode]);
            end
        end
        
        % set source range
        function obj = set.source_range(obj, value)
            % Validate input
            assert(isnumeric(value) || strcmp(value,'auto'), 'Invalid input');
            %find the current source mode
            mode = obj.source_mode;
            if strcmp(value,'auto')
                obj.write(['SOUR:', mode, ':RANG:AUTO ON'])
            else
                obj.write(['SOUR:', mode, sprintf(':RANG %G;',value)]);
            end
        end
        
        % get source range
        function val = get.source_range(obj)
            %find source mode
            mode = obj.source_mode;
            val = str2double(obj.query(['SOUR:' mode, ':RANG?']));
        end
        
        % set sense range
        function obj = set.sense_range(obj, value)
            % Validate input
            assert(isnumeric(value) || strcmp(value,'auto'), 'Invalid input');
            %find the current source mode
            mode = obj.sense_mode;
            if strcmp(value,'auto')
                obj.write(['SENS:', mode, ':RANG:AUTO ON'])
            else
                obj.write(['SENS:', mode, sprintf(':RANG %G;',value)]);
            end
        end
        
        % get sense range
        function val = get.sense_range(obj)
            %find source mode
            mode = obj.sense_mode;
            val = str2double(obj.query(['SENS:' mode, ':RANG?']));
        end
        
        % set current
        function obj = set.current(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOUR:CURR %G;',value));
            warning('you should set sourceCurrent or senseCurrent to avoid ambiguities');
        end
        
        %set source current
        function obj = set.sourceCurrent(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            %verify source mode is voltage
            mySourceMode=obj.source_mode;
            assert(strcmp(mySourceMode,'CURR'),['attempted to set source current when source mode is ',mySourceMode]);
            obj.write(sprintf('SOUR:CURR %G;',value));
        end
        
        function obj = set.senseCurrent(obj, ~)
            warning('you should not be setting the sense current.  that is just stupid');
        end
        
        %get mode
        function val = get.current(obj)
            val = str2double(obj.query(':MEAS:CURR?'));
            warning('you should get sourceCurrent or senseCurrent to avoid ambiguities');
        end
        
        %get source current
        function val = get.sourceCurrent(obj)
            %verify source mode is voltage
            mySourceMode=obj.source_mode;
            assert(strcmp(mySourceMode,'CURR'),['attempted to measure source current when source mode is ',mySourceMode]);
            val = str2double(obj.query(':SOUR:CURR?'));
        end
        
        %get sense current
        function val = get.senseCurrent(obj)
            %verify source mode is voltage
            mySenseMode=obj.sense_mode;
            assert(strcmp(mySenseMode,'CURR:DC'),['attempted to measure sense current when sense mode is ',mySourceMode]);
            val = str2double(obj.query(':MEAS:CURR?'));
        end
        
        % set voltage
        function obj = set.voltage(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOUR:VOLT %G;',value));
            warning('you should set sourceCurrent or senseCurrent to avoid ambiguities');
        end
        
         % set source voltage
        function obj = set.sourceVoltage(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            %verify source mode is voltage
            mySourceMode=obj.source_mode;
            assert(strcmp(mySourceMode,'VOLT:DC'),['attempted to set source voltage when source mode is ',mySourceMode]);
            obj.write(sprintf('SOUR:VOLT %G;',value));
        end
        
        % set source voltage
        function obj = set.senseVoltage(obj, ~)
            warning('you should not be setting the sense voltage.  that is just stupid');
        end
        
        %get voltage
        function val = get.voltage(obj)
            val = str2double(obj.query(':MEAS:VOLT?'));
            warning('you should get sourceCurrent or senseCurrent to avoid ambiguities');
        end
        
        %get sense voltage
        function val = get.senseVoltage(obj)
            %verify source mode is voltage
            mySenseMode=obj.sense_mode;
            assert(strcmp(mySenseMode,'VOLT:DC'),['attempted to measure sense voltage when sense mode is ',mySenseMode]);
            val = str2double(obj.query(':MEAS:VOLT?'));
        end
        
        %get source voltage
        function val = get.sourceVoltage(obj)
            %verify source mode is voltage
            mySourceMode=obj.source_mode;
            assert(strcmp(mySourceMode,'VOLT:DC'),['attempted to measure source voltage when source mode is ',mySourceMode]);
            val = str2double(obj.query(':SOUR:VOLT?'));
        end
        
        %not sure if this works?
        function [force, sense] = measureForceAndSense(obj)
            myString=obj.query(':READ? READ, SOUR');
            mySplitString=strsplit(myString,',');
            force=mySplitString(2);
            sense=mySplitString(1);
        end
        
        function setFourWireVoltSense(obj, value)
            if isnumeric(value) || islogical(value)
                value = num2str(value);
            end
            valid_inputs = ['ON', '1', 'OFF', '0'];
            if ~ismember(value, valid_inputs)
                error('Invalid input');
            end
            obj.write([':SENSe:VOLT:RSENse ' value]);
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
