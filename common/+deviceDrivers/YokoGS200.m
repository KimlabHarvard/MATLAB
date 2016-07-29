% CLASS YokoGS200 - Instrument driver for the Yokogawa GS200 DC source

% Author: Blake Johnson (bjohnson@bbn.com)

% Copyright 2013 Raytheon BBN Technologies
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

classdef (Sealed) YokoGS200 < deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.GPIBorEthernet
    properties (Access = public)
        output
        range
        mode % 'current', or 'voltage'
        value
    end
    
    methods
        function setSourceCurrent(obj,myCurrent)
            assert(isnumeric(myCurrent),'current must be numeric');
            obj.write(':SOURCE:FUNCTION current');
            %set the range to the proper value
            ranges = 1e-3*[1, 10, 100, 200];
            index=1;
            while(ranges(index)<myCurrent)
                index=index+1;
            end
            obj.write([':SOURCE:RANGE ' num2str(ranges(index))]);
            obj.write([':SOURCE:LEVEL ' num2str(myCurrent)]);
        end
        
        function setSourceVoltage(obj,myVoltage)
            assert(isnumeric(myCurrent),'current must be numeric');
            obj.write(':SOURCE:FUNCTION current');
            %set the range to the proper value
            ranges = [1e-3, 10e-3, 100e-3, 200e-3, 1, 10, 30];
            index=1;
            while(ranges(index)<myCurrent)
                index=index+1;
            end
            obj.write([':SOURCE:RANGE ' num2str(ranges(index))]);
            obj.write([':SOURCE:LEVEL ' num2str(myVoltage)]);
        end
        
        function obj = YokoGS200()
            obj.DEFAULT_PORT = 7655;
        end
        
        % getters
        function val = get.value(obj)
            val = str2double(obj.query(':SOURCE:LEVEL?'));
        end
        function val = get.mode(obj)
            val = strtrim(obj.query(':SOURCE:FUNCTION?'));
        end
        function val = get.output(obj)
            val = str2double(obj.query(':OUTPUT?'));
        end
        function val = get.range(obj)
            val = str2double(obj.query(':SOURCE:RANGE?'));
        end
        
        % setters
        function obj = set.value(obj, value)
            obj.write([':SOURCE:LEVEL ' num2str(value)]);
        end
        function obj = set.mode(obj, mode)
            valid_modes = {'current', 'curr', 'voltage', 'volt'};
            if ~ismember(mode, valid_modes)
                error('Invalid mode');
            end
            obj.write([':SOURCE:FUNCTION ' mode]);
        end
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
        
        %ramp to value V @ a rate in V/s defaults to 0.1
        function ramp2V(obj,Vset,rate)
            assert(isnumeric(Vset)&&isnumeric(rate),'values must be numeric')
            time_per_step = 2E-2;
            Vstart = obj.value;
            total_time = abs(Vset-Vstart)/rate;
            steps = abs(floor(total_time/time_per_step))+1;
            Vs = linspace(Vstart,Vset,steps);
            for V=Vs(2:end)
                t=clock;
                obj.value = V;
                while etime(clock,t) < time_per_step
                end
            end
        end

        function obj = set.range(obj, range)
            valid_ranges = [1e-3, 10e-3, 100e-3, 200e-3, 1, 10, 30];
            if ~isnumeric(range)
                range = str2double(range);
            end
            if ~ismember(range, valid_ranges)
                error('Invalid range: %f', range);
            end
            
            obj.write([':SOURCE:RANGE ' num2str(range)]);
        end
    end
end