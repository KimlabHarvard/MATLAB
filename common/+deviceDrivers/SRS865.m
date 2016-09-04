% CLASS SRS865 - Instrument driver for the SRS 865 lock-in

% Original Author for SR830: Colm Ryan (colm.ryan@bbn.com)
% Editor for SR865: Evan Walsh (evanwalsh@seas.harvard.edu)

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

classdef (Sealed) SRS865 < deviceDrivers.lib.GPIB
    
    properties
        timeConstant % time constant for the filter in seconds
        inputCoupling % 'AC' or 'DC'
        sineAmp % output amplitude of the sin output (0.004 to 5.000V)
        sineFreq % reference frequency (Hz)
        intFreq % internal frequency (Hz) 
        DC % DC voltage offset for the sine output
        sens 
        harm %1...99
        refsource %int,ext,dual,chop
    end

    properties (SetAccess=private)
        R % read magnitude of signal
        theta % read angle of signal
        X % read X value of signal
        Y % read Y value of signal
        XNoise % read XNoise value of signal
        YNoise % read YNoise value of signal
    end

    properties(Constant)
        timeConstantMap = containers.Map(num2cell(0:21), num2cell(kron(10.^(-6:4), [1, 3])));
        inputCouplingMap = containers.Map({'AC', 'DC'}, {uint32(0), uint32(1)});
        scanIntervalMap = containers.Map(num2cell(0:16), {.008, .016, .031, .078, .155, .469, .938, 1.875, 4.688, 9.375, 28.12, 56.25, 112.5, 337, 675, 1350, 2700});
        sensMap = containers.Map({1,5e-1,2e-1,1e-1,5e-2,2e-2,1e-2,5e-3,2e-3,1e-3,5e-4,2e-4,1e-4,5e-5,2e-5,1e-5,...
            5e-6,2e-6,1e-6,5e-7,2e-7,1e-7,5e-8,2e-8,1e-8,5e-9,2e-9,1e-9},num2cell(0:27));
    end
    
    methods
        function obj = SRS865()
        end
        
        function val = get.sens(obj)
            inverseMap = invertMap(obj.sensMap);

            dbl=str2double(obj.query('SCAL?'));
            while isempty(dbl)
                dbl=str2double(obj.query('SCAL?'));
            end

            val = inverseMap(dbl);
        end
        function obj = set.sens(obj, value)
            assert(isKey(obj.sensMap, value),'sensitivity must be 1, 2, or 5 times some power -9 to 0')
            obj.write('SCAL %E', obj.sensMap(value));
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
        
        %Input coupling
        function val = get.inputCoupling(obj)
            inverseMap = invertMap(obj.inputCouplingMap);
            val = inverseMap(uint32(str2double(obj.query('ICPL?'))));
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
            assert(isnumeric(value) && (value >= 0.001) && (value <= 2500000), 'Oops! The reference frequency must be between 1 mHz and 2.5 MHz');
            obj.write('FREQ %E',value);
        end
        
        %Internal frequency
        function val = get.intFreq(obj)
            val = str2double(obj.query('FREQINT?'));
        end
        function obj = set.intFreq(obj, value)
            assert(isnumeric(value) && (value >= 0.001) && (value <= 2500000), 'Oops! The internal frequency must be between 1 mHz and 2.5 MHz');
            obj.write('FREQINT %E',value);
        end
        
        %Sine output amplitude
        function val = get.sineAmp(obj)
            val = str2double(obj.query('SLVL?'));
        end
        function obj = set.sineAmp(obj, value)
            assert(isnumeric(value) && (value >= 0.000000001) && (value <= 2.000000000), 'Oops! The sine amplitude must be between 1 nV and 2 V');
            obj.write('SLVL %E',value);
        end
        
        %Sine output DC Offset
        function val = get.DC(obj)
            val = str2double(obj.query('SOFF?'));
        end
        function obj = set.DC(obj, value)
            assert(isnumeric(value) && (value >= -5.000000000) && (value <= 5.000000000), 'Oops! The DC offset must be between -5 V and 5 V');
            obj.write('SOFF %E',value);
        end
        
        %Harmonic
        function val = get.harm(obj)
            val = str2double(obj.query('HARM?'));
        end
        function obj = set.harm(obj, value)
            assert(ceil(value) == floor(value) && (value >= 1) && (value <= 99), 'Oops! The reference harmonic must be an integer = 1...99');
            obj.write('HARM %E',value);
        end
        
        %Ref source 0=internal, 1=external, 2=dual, 3=chop
        function val = get.refsource(obj)
            val = str2double(obj.query('RSRC?'));
        end
        function obj = set.refsource(obj, value)
            assert(ceil(value) == floor(value) && (value >= 0) && (value <= 3), 'Oops! The reference source must be an integer = 0...3');
            obj.write('RSRC %E',value);
        end
        
        
        %Getter for X and Y at the same point in time
        function [X, Y] = get_XY(obj)
            values = textscan(obj.query('SNAP? 0,1'), '%f', 'Delimiter', ',');
            X = values{1}(1);
            Y = values{1}(2);
        end
        
        %Getter for R and theta at the same point in time
        function [R, theta] = snapRtheta(obj)
            str = obj.query('SNAP? 2,3');
            while isempty(str)
                str = obj.query('SNAP? 2,3');
            end
            commaPos = strfind(str,',');
            R = str2double(str(1:commaPos));
            theta = str2double(str(commaPos:end));
%             values = textscan(obj.query('SNAP? 2,3'), '%f', 'Delimiter', ',');
%             R = values{1}(1);
%             theta = values{1}(2);
        end
        
        %Getter for X and Y Noise at the same point in time
        function [XNoise, YNoise] = get_XYNoise(obj)
            values = textscan(obj.query('SNAP? 10,11'), '%f', 'Delimiter', ',');
            XNoise = values{1}(1);
            YNoise = values{1}(2);
        end        
        
        %Getter for signal magnitude
        function R = get.R(obj)
            R = str2double(obj.query('OUTP? 2'));
        end
        
        %Getter for signal angle
        function theta = get.theta(obj)
            theta = str2double(obj.query('OUTP? 3'));
        end
        
        %Getter for signal X
        function X = get.X(obj)
            X = str2double(obj.query('OUTP? 0'));
        end
        
        %Getter for signal Y
        function Y = get.Y(obj)
            Y = str2double(obj.query('OUTP? 1'));
        end

        %Getter for signal XNoise
        function X = get.XNoise(obj)
            X = str2double(obj.query('OUTP? 10'));
        end
        
        %Getter for signal YNoise
        function Y = get.YNoise(obj)
            Y = str2double(obj.query('OUTP? 11'));
        end        
        
        function auto_phase(obj)
            obj.write('APHS');
        end
        
        function enable_scan(obj)
            obj.write('SCNENBL ON')
        end
        
        function run_scan(obj)
            obj.write('SCNRUN')
        end
        
        function scan_time_set(obj, value)
            assert(isnumeric(value) && (value >= 0) && (value <= 1728000), 'Oops! The scan time must be between 0 and 1728000 s (20 days)');
            obj.write('SCNSEC %E',value);
        end
        
        function scan_interval_set(obj, value)
            assert(isnumeric(value) && (value >= .008) && (value <= 2700), 'Oops! The scan interval must be between 8 ms and 2700 s (45 min)');
            inverseMap = invertMap(obj.scanIntervalMap);
            mapKeys = keys(inverseMap);
            [~, index] = min(abs(value - cell2mat(mapKeys)));
            obj.write('SCNINRVL %d', inverseMap(mapKeys{index}));
        end
        
        function DC_scan_set(obj)
            obj.write('SCNPAR REFDc')
        end
        
        function DC_scan_begin_set(obj, value)
            assert(isnumeric(value) && (value >= -5) && (value <= 5), 'Oops! The DC voltage must be between -5 V and 5 V');
            obj.write('SCNDC BEGin, %E',value);
        end
        
        function DC_scan_end_set(obj, value)
            assert(isnumeric(value) && (value >= -5) && (value <= 5), 'Oops! The DC voltage must be between -5 V and 5 V');
            obj.write('SCNDC END, %E',value);
        end
        
        function clrbuff(obj)
           obj.write('SDC'); 
        end
        
        function decreaseSens(obj)
            sens_number = str2double(obj.query('SCAL?'));
            obj.write('SCAL %E', sens_number-1);
        end
        function increaseSens(obj)
            sens_number = str2double(obj.query('SCAL?'));
            obj.write('SCAL %E', sens_number+1);
        end
        
    end
    
end

