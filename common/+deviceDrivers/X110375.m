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

classdef (Sealed) X110375 < deviceDrivers.lib.GPIB
    
    properties
        timeConstant = 0.3 % time constant for the filter in seconds
        inputCoupling = 'AC' % 'AC' or 'DC'
        sinePhase = 0 % output phase in deg
        sineAmp = 1 % output amplitude of the sin output (0.004 to 5.000V)
        sineFreq = 17.777% reference frequency (Hz)
        sens = 5E-6 %sensitivity
        Tmap
        Rex
    end
    
    properties (SetAccess=private)
        R % read magnitude of signal
        theta % read angle of signal
        X % read X value of signal
        Y % read Y value of signal
        temperature % read out using R
    end
    
    properties(Constant)
        timeConstantMap = containers.Map(num2cell(0:19), num2cell(kron(10.^(-6:3), [10, 30])));
        inputCouplingMap = containers.Map({'AC', 'DC'}, {0,1});%uint32(0), uint32(1)});
        sensMap = containers.Map({2E-9,5E-9,1E-8,2E-8,5E-8,1E-7,2E-7,5E-7,1E-6,...
            2E-6,5E-6,1E-5,2E-5,5E-5,1E-4,2E-4,5E-4,1E-3,2E-3,5E-3,1E-2, ...
            2E-2,5E-2,1E-1,2E-1,5E-1,1},num2cell(0:26))
    end
    
    methods
        function obj = X110375(Rex,address)
            assert(isnumeric(Rex),'please pass the value for the seies resistance on the lockin');
            obj.Rex = Rex;
            curve = load('X110375_curve.mat');
            obj.Tmap = containers.Map(curve.X110375_curve.interpolated(:,1),curve.X110375_curve.interpolated(:,2));
            obj.connect(address);
            obj.timeConstant = 0.3;
            obj.inputCoupling = 'AC';
            obj.sinePhase = 0;
            obj.sineAmp = 1;
            obj.sineFreq = 17.777;
            obj.sens = 5E-5;
        end
        %Filter time constant
        function val = get.sens(obj)
            inverseMap = invertMap(obj.sensMap);
            val = inverseMap(str2double(obj.query('SENS?')));
        end
        function obj = set.sens(obj, value)
            assert(isKey(obj.sensMap, value),'sensitivity must be 2, 5, or 10 times some power -9 to -1')
            obj.write('SENS %E', obj.sensMap(value));
        end
        
        %Filter time constant
        function val = get.timeConstant(obj)
            val = obj.timeConstantMap(uint32(str2double(obj.query('OFLT?'))));
        end
        function obj = set.timeConstant(obj, value)
            inverseMap = invertMap(obj.timeConstantMap);
            mapKeys = keys(inverseMap);
            [~, index] = min(abs(value - cell2mat(mapKeys)));
            obj.write('OFLT %d', inverseMap(mapKeys{index}));
        end
        
        %Filter time constant
        function val = get.sinePhase(obj)
            val = str2double(obj.query('PHAS?'));
        end
        function obj = set.sinePhase(obj, value)
            assert(isnumeric(value) && (value >= -180) && (value <= 180), 'Oops! The output phase must be between -180 and +180 deg');
            obj.write('PHAS %E',value);
        end
        
        %Input coupling
        function val = get.inputCoupling(obj)
            inverseMap = invertMap(obj.inputCouplingMap);
            val = inverseMap(uint32(obj.query('ICPL?')));
        end
        function obj = set.inputCoupling(obj, value)
            assert(isKey(obj.inputCouplingMap, value), 'Oops! the input coupling must be one of "AC" or "DC"');
            obj.write('ICPL %d', obj.inputCouplingMap(value));
        end
        
        %Reference frequency
        function val = get.sineFreq(obj)
            val = str2double(obj.query('FREQ?'));
        end
        function obj = set.sineFreq(obj, value)
            assert(isnumeric(value) && (value >= 0.0001) && (value <= 102000), 'Oops! The reference frequency must be between 0.0001Hz and 102kHz');
            obj.write('FREQ %E',value);
        end
        
        %Sine output amplitude
        function val = get.sineAmp(obj)
            val = str2double(obj.query('SLVL?'));
        end
        function obj = set.sineAmp(obj, value)
            assert(isnumeric(value) && (value >= 0.004) && (value <= 5.000), 'Oops! The sine amplitude must be between 0.004V and 5V');
            obj.write('SLVL %E',value);
        end
        
        %Getter for signal magnitude
        function R = get.R(obj)
            R = str2double(obj.query('OUTP ? 3'));
        end
        
        %Getter for signal angle
        function theta = get.theta(obj)
            theta = str2double(obj.query('OUTP ? 4'));
        end
        
        %Getter for signal X
        function X = get.X(obj)
            X = str2double(obj.query('OUTP ? 1'));
        end
        
        %Getter for signal Y
        function Y = get.Y(obj)
            Y = str2double(obj.query('OUTP ? 2'));
        end
        
        function auto_phase(obj)
            obj.write('APHS');
        end
        
        function auto_gain(obj)
            obj.write('AGAN');
        end
        
        function decreaseSens(obj)
            sens_number = str2double(obj.query('SENS?'));
            obj.write('SENS %E', sens_number+1);
        end
        function increaseSens(obj)
            sens_number = str2double(obj.query('SENS?'));
            obj.write('SENS %E', sens_number-1);
        end
        
        function val = get.temperature(obj)
            res = obj.R();
            if res > obj.sens*0.75
                pause on
                while res > obj.sens*0.75
                    obj.decreaseSens();
                    pause(obj.timeConstant*3)
                    res = obj.R();
                end
            end
            if res < obj.sens*0.1
                pause on
                while res < obj.sens*0.1
                    obj.increaseSens();
                    pause(obj.timeConstant*3)
                    res = obj.R();
                end
            end
            res = res*obj.Rex/obj.sineAmp;
            %round to 4 significant figures
            res = round(res,-floor(log10(res))+3);
            val = obj.Tmap(res);
        end
    end
    
end

