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

classdef (Sealed) SRS830 < deviceDrivers.lib.GPIB
    
    properties
        timeConstant % time constant for the filter in seconds
        inputCoupling % 'AC' or 'DC'
        sinePhase % output phase in deg
        sineAmp % output amplitude of the sin output (0.004 to 5.000V)
        sineFreq % reference frequency (Hz)
        bufferRate % if using buffer, rate in Hz to record data
        bufferMode %'loop' reads continuously, 'shot' reads until full.
        sens %sensitivity
    end
    
    properties (SetAccess=private)
        R % read magnitude of signal
        theta % read angle of signal
        X % read X value of signal
        Y % read Y value of signal
        bufferPoints %number of data points currently stored in buffer
    end
    
    properties(Constant)
        timeConstantMap = containers.Map(num2cell(0:19), num2cell(kron(10.^(-6:3), [10, 30])));
        inputCouplingMap = containers.Map({'AC', 'DC'}, {0,1});%uint32(0), uint32(1)});
        bufferRateMap = containers.Map(num2cell(2.^(-4:9)),num2cell(0:13))
        bufferModeMap = containers.Map({'loop','LOOP','Loop','shot','SHOT','Shot'},{1,1,1,0,0,0})
        sensMap = containers.Map({2E-9,5E-9,1E-8,2E-8,5E-8,1E-7,2E-7,5E-7,1E-6,...
            2E-6,5E-6,1E-5,2E-5,5E-5,1E-4,2E-4,5E-4,1E-3,2E-3,5E-3,1E-2, ...
            2E-2,5E-2,1E-1,2E-1,5E-1,1},num2cell(0:26))
    end
    
    methods
        
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
        
        %Set the buffer rate
        function val = get.bufferRate(obj)
            inverseMap = invertMap(obj.bufferRateMap);
            val = inverseMap(str2double(obj.query('SRAT?')));
        end
        function obj = set.bufferRate(obj, value)
            assert(isKey(obj.bufferRateMap, value),'buffer rate must be a power of 2 between 2^-4 and 2^9')
            obj.write('SRAT %E', obj.bufferRateMap(value));
        end
        
        %Set the buffer Mode
        function val = get.bufferMode(obj)
            val = str2double(obj.query('SEND?'));
        end
        function obj = set.bufferMode(obj, value)
            assert(isKey(obj.bufferModeMap, value),'buffer mode must be "loop" or "shot"')
            obj.write('SEND %d', obj.bufferModeMap(value));
        end
        
        %start the buffer recording
        function bufferStart(obj)
            obj.write('STRT')
        end
        %pause the buffer
        function bufferPause(obj)
            obj.write('PAUS')
        end
        %clear the buffer
        function bufferReset(obj)
            obj.write('REST')
        end
        %check the number of points recorded into the buffer
        function val = get.bufferPoints(obj)
            val = str2double(obj.query('SPTS?'));
        end
        %grab buffer data
        function data = getBufferData(obj, channel, start_bin, len)
            if ~exist('start_bin','var')
                start_bin=0;
            end
            if~exist('len','var')
                len = obj.bufferPoints();
            end
            assert(isnumeric(start_bin)&&isnumeric(len)&&start_bin>=0&&len>=1,...
                'starting_bin and length must be non-negative integers')
            assert(channel == 0 || channel == 1,'Channel must be 0 or 1')
            str = strcat(',',obj.query(sprintf('TRCA?%d,%d,%d',channel,start_bin,len)));
            commaPos = strfind(str,',');
            data = zeros(length(commaPos-1),1);
            for i=1:length(commaPos)-1
                data(i) = str2double(str(commaPos(i):commaPos(i+1)));
            end
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
        function ramp2V(obj,Vset)
            CurrentV = str2double(obj.query('SLVL?'));
            DeltaV = Vset-CurrentV;
            %if the difference is greater than 1mv, ramp slowly
            if abs(DeltaV)>0.001
                for j=1:floor(abs(DeltaV*1000))                   
                    CurrentV=CurrentV+0.001*sign(DeltaV);
                    obj.write('SLVL %E',CurrentV);
                end
            end
            obj.write('SLVL %E',Vset);
        end
        
        function [X,Y] = snapXY(obj)
            str = obj.query('SNAP?1,2');
            commaPos = strfind(str,',');
            X = str2double(str(1:commaPos));
            Y = str2double(str(commaPos:end));
        end
        
        %Getter for the current signal level in any flavour
        function [X, Y, R, theta] = get_signal(obj)
            values = textscan(obj.query('SNAP ? 1,2,3,4'), '%f', 'Delimiter', ',');
            X = values{1}(1);
            Y = values{1}(2);
            R = values{1}(3);
            theta = values{1}(4);
        end
        
        %Getter for the current signal level in any flavour
        function [X, Y, R, theta] = get_signal2(obj)
            values = textscan(obj.query('SNAP ? 1,2,3,4'), '%f', 'Delimiter', ',');
            values = textscan(obj.query('SNAP ? 1,2,3,4'), '%f', 'Delimiter', ',');
            values = textscan(obj.query('SNAP ? 1,2,3,4'), '%f', 'Delimiter', ',');
            values = textscan(obj.query('SNAP ? 1,2,3,4'), '%f', 'Delimiter', ',');
            values = textscan(obj.query('SNAP ? 1,2,3,4'), '%f', 'Delimiter', ',');
            X = values{1}(1);
            Y = values{1}(2);
            R = values{1}(3);
            theta = values{1}(4);
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
        
        %an auto sensitivity function with includes hysteresis
        function autoSens(obj,lowerBound,upperBound)
        if ~exist('lowerBound','var')
            lowerBound = 0.25;
        end
        if ~exist('upperBound','var')
            upperBound = 0.75;
        end
        
        val = obj.R;
        while (val > obj.sens*upperBound) || val < obj.sens*lowerBound
            if val > obj.sens*upperBound
                obj.decreaseSens();
            elseif val < obj.sens*lowerBound
                obj.increaseSens()
            end
            pause(obj.timeConstant*4)
            val = obj.R;
        end
    end
    end
    
end

