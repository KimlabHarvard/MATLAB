% CLASS SRS830 - Instrument driver for the SRS 830 lock-in

% Author: Colm Ryan (colm.ryan@bbn.com)

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

classdef SG382 < deviceDrivers.lib.GPIBorEthernet
    
    properties
        ampN
        ampBNC_RMS
        ampBNC_dBm
        amp_N_dBm
        ampBNC
        freq
        AM_modulationDepthPercentage; %in percentage points
        modulationRate
    end
    
    methods
        function obj = SG382()
        end
        
        function val = get.ampN(obj)
            val = str2double(obj.query('AMPR?'));
        end
        function obj = set.ampN(obj, value)
            assert(isnumeric(value),'amplitude must by numeric')
            obj.write('AMPR %d', value);
        end
        function val = get.ampBNC(obj)
            val = str2double(obj.query('AMPL?'));
        end
        function obj = set.ampBNC(obj, value)
            assert(isnumeric(value),'amplitude must by numeric')
            obj.write('AMPL %d', value);
        end
        function val = get.ampBNC_RMS(obj)
            val = str2double(obj.query('AMPL? RMS'));
        end
        function obj = set.ampBNC_RMS(obj, value)
            assert(isnumeric(value),'amplitude must by numeric')
            obj.write('AMPL %f RMS', value);
        end
        function val = get.ampBNC_dBm(obj)
            val = str2double(obj.query('AMPL?'));
        end
        function obj = set.ampBNC_dBm(obj, value)
            assert(isnumeric(value),'amplitude must by numeric')
            obj.write('AMPL %f', value);
        end
        function val = get.amp_N_dBm(obj)
            val = str2double(obj.query('AMPR?'));
        end
        function obj = set.amp_N_dBm(obj, value)
            assert(isnumeric(value),'amplitude must by numeric')
            obj.write('AMPR %f', value);
        end
        function val = get.freq(obj)
            val = str2double(obj.query('FREQ?'));
        end
        function obj = set.freq(obj, value)
            assert(isnumeric(value),'amplitude must by numeric')
            obj.write('FREQ %E', value);
        end
        function val = get.modulationRate(obj)
            val = str2double(obj.query('RATE?'));
        end
        function obj = set.modulationRate(obj, value)
            assert(isnumeric(value),'modulation rate must by numeric')
            obj.write('RATE %f', value);
        end
        function val=get.AM_modulationDepthPercentage(obj)
            val = str2double(obj.query('ADEP?'));
        end
        function obj=set.AM_modulationDepthPercentage(obj, value)
            assert(isnumeric(value),'AM modulation must by numeric')
            obj.write('ADEP %f', value);
        end
        
    end
    
end

