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
        amp
        freq
    end
    
    methods

         function val = get.amp(obj)
             val = str2double(obj.query('AMPR?'));
         end
         function obj = set.amp(obj, value)
             assert(isnumeric(value),'amplitude must by numeric')
             obj.write('AMPR %d', value);
         end
         function val = get.freq(obj)
             val = str2double(obj.query('FREQ?'));
         end
         function obj = set.freq(obj, value)
             assert(isnumeric(value),'amplitude must by numeric')
             obj.write('FREQ %E', value);
         end
    end
    
end

