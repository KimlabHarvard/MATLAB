% CLASS SG382 - Instrument driver for the SG382

% modified by Jonah Waissman, Kim group, Harv.U., Jun.'16

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
        enableN
        enableBNC
        ampN
        ampBNC
        freq
        modenable
        modtype
        modfunc
        modrate
        modAMdepth        
    end
    
    properties(Constant)
        enableNMap = containers.Map({'off', 'on'}, {0,1});
        enableBNCMap = containers.Map({'off', 'on'}, {0,1});
        modenableMap = containers.Map({'off', 'on'}, {0,1});
    end
    
    
    methods
        function obj = SG382()
        end
        
        function val = get.enableN(obj)
            inverseMap = invertMap(obj.enableNMap);
            val = inverseMap(str2num(obj.query('ENBR?'))); %uint32(
        end
        
        function obj = set.enableN(obj, value)
            assert(isKey(obj.enableNMap, value), 'Oops! enable N must be one of "off" or "on"');
            obj.write('ENBR %d', obj.enableNMap(value));
        end
        
        function val = get.enableBNC(obj)
            inverseMap = invertMap(obj.enableNMap);
            val = inverseMap(str2num(obj.query('ENBL?'))); %uint32(
        end
        function obj = set.enableBNC(obj, value)
            assert(isKey(obj.enableBNCMap, value), 'Oops! enable BNC must be one of "off" or "on"');
            obj.write('ENBL %d', obj.enableBNCMap(value));
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
        
        
        function val = get.freq(obj)
            val = str2double(obj.query('FREQ?'));
        end
        function obj = set.freq(obj, value)
            assert(isnumeric(value),'frequency must by numeric')
            obj.write('FREQ %E', value);
        end
        
        function val = get.modenable(obj)
            inverseMap = invertMap(obj.modenablemap);
            val = inverseMap(str2num(obj.query('MODL?'))); 
        end
        
        %ModType: 0-AM, 1-FM, 2-phaseM, 3-sweep, 4-Pulse,
        %5-Blank, 6-IQ
        function val = get.modtype(obj)
            val = str2double(obj.query('TYPE?'));
        end
        function obj = set.modtype(obj, value) 
            assert(ceil(value) == floor(value) && value>=0 && value<=6,'Mod.Type must be integer from 0 to 6 ')
            obj.write('TYPE %d', value);
        end
        
        %ModFunc: 0-sine, 1-ramp, 2-triangle, 3-square, 4-noise, 5-external
        function val = get.modfunc(obj)
            val = str2double(obj.query('MFNC?'));
        end
        function obj = set.modfunc(obj, value) 
            assert(ceil(value) == floor(value) && value>=0 && value<=5,'Mod.Func must be integer from 0 to 5 ')
            obj.write('MFNC %d', value);
        end
       

        %Modulation rate
        function val = get.modrate(obj)
            val = str2double(obj.query('RATE?'));
        end
        function obj = set.modrate(obj, value) 
            assert(isnumeric(value) && value>=0,'Modulation rate must be positive number (Hz)')
            obj.write('RATE %d', value);
        end
        
        
        %ModDepth in percent 0-100
        function val = get.modAMdepth(obj)
            val = str2double(obj.query('ADEP?'));
        end
        function obj = set.modAMdepth(obj, value) 
            assert(isnumeric(value) && value>=0 && value<=100,'AM modulation depth must be from 0 to 100 (percent) ')
            obj.write('ADEP %d', value);
        end
    end
    
end

