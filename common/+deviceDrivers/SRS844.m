% CLASS SRS844 - Instrument driver for the SRS 844 lock-in

% Author: Colm Ryan (colm.ryan@bbn.com)
% Modified from SR830 driver by Jonah Waissman, Kim Group, Harvard Univ.,
% 6/2016

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

classdef (Sealed) SRS844 < deviceDrivers.lib.GPIB
    
    properties
        timeConstant % time constant for the filter in seconds
        inputImpedance % '50' or '1M'
        refMode % 'external' or 'internal'
        twoFMode % 'off' or 'on'
        sinePhase % output phase in deg
%         sineAmp % RF Lockin has fixed internal reference amplitude;
%         external amplitude fixed in separate driver
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
    
    properties(Constant) %see page 4-2 of 844 manual for commands
        timeConstantMap = containers.Map(num2cell(0:17), num2cell(kron(10.^(-6:2), [100, 300])));
        % 844 does not choose 
%         inputCouplingMap = containers.Map({'AC', 'DC'}, {0,1});%uint32(0), uint32(1)});
        inputImpedanceMap = containers.Map({'50', '1M'}, {0,1});
        refModeMap = containers.Map({'external', 'internal'}, {0,1});
        twoFModeMap = containers.Map({'off', 'on'}, {0,1});
        bufferRateMap = containers.Map(num2cell(2.^(-4:9)),num2cell(0:13))
        bufferModeMap = containers.Map({'loop','LOOP','Loop','shot','SHOT','Shot'},{1,1,1,0,0,0})
        sensMap = containers.Map({100E-9,300E-9,100E-8,300E-8,100E-7,300E-7,...
            100E-6,300E-6,100E-5,300E-5,100E-4,300E-4,100E-3,300E-3, ...
            1},num2cell(0:14))
    end
    
    methods
        
        %Sensitivity
        function val = get.sens(obj)
            inverseMap = invertMap(obj.sensMap);
            val = inverseMap(str2double(obj.query('SENS?')));
        end
        function obj = set.sens(obj, value)
            assert(isKey(obj.sensMap, value),'sensitivity must be 1 or 3 times some power -7 to 0')
            obj.write('SENS %E', obj.sensMap(value));
        end
        
        %Filter time constant
        function val = get.timeConstant(obj)
            val = obj.timeConstantMap(str2double(obj.query('OFLT?'))); %uint32(
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
        
        %Input coupling replaced by input impedance (below)
%         %Input coupling
%         function val = get.inputCoupling(obj)
%             inverseMap = invertMap(obj.inputCouplingMap);
%             val = inverseMap(uint32(obj.query('ICPL?')));
%         end
%         function obj = set.inputCoupling(obj, value)
%             assert(isKey(obj.inputCouplingMap, value), 'Oops! the input coupling must be one of "AC" or "DC"');
%             obj.write('ICPL %d', obj.inputCouplingMap(value));
%         end
        
        %Input impedance
        function val = get.inputImpedance(obj)
            inverseMap = invertMap(obj.inputImpedanceMap);
            val = inverseMap(str2num(obj.query('INPZ?'))); %uint32(
        end
        function obj = set.inputImpedance(obj, value)
            assert(isKey(obj.inputImpedanceMap, value), 'Oops! the input impedance must be one of "50" or "1M"');
            obj.write('INPZ %d', obj.inputImpedanceMap(value));
        end
        
        %Reference mode
        function val = get.refMode(obj)
            inverseMap = invertMap(obj.refModeMap);
            val = inverseMap(str2num(obj.query('FMOD?'))); %uint32(
        end
        function obj = set.refMode(obj, value)
            assert(isKey(obj.refModeMap, value), 'Oops! the reference mode must be one of "external" or "internal"');
            obj.write('FMOD %d', obj.refModeMap(value));
        end
        
        %Reference frequency (note that internal ref is a square wave)
        function val = get.sineFreq(obj)
            val = str2double(obj.query('FREQ?'));
        end
        function obj = set.sineFreq(obj, value)
%              assert(get, 'Oops! The reference mode must be internal to set the frequency');
            assert(isnumeric(value) && (value >= 25000) && (value <= 200000000), 'Oops! The reference frequency must be between 25kHz and 200MHz');
            obj.write('FREQ %E',value);
        end
        
         %Harmonic 2f detection
        function val = get.twoFMode(obj)
            inverseMap = invertMap(obj.twoFModeMap);
            val = inverseMap(str2num(obj.query('HARM?'))); %uint32(
        end
        function obj = set.twoFMode(obj, value)
            assert(isKey(obj.twoFModeMap, value), 'Oops! the twoF mode must be one of "off" or "on"');
            obj.write('HARM %d', obj.twoFModeMap(value));
        end
        
        % RF Lockin has fixed internal reference amplitude (external
        % reference needs separate driver)
%         %Sine output amplitude
%         function val = get.sineAmp(obj)
%             val = str2double(obj.query('SLVL?'));
%         end
%         function obj = set.sineAmp(obj, value)
%             assert(isnumeric(value) && (value >= 0.004) && (value <= 5.000), 'Oops! The sine amplitude must be between 0.004V and 5V');
%             obj.write('SLVL %E',value);
%         end
%         function ramp2V(obj,Vset)
%             CurrentV = str2double(obj.query('SLVL?'));
%             DeltaV = Vset-CurrentV;
%             %if the difference is greater than 1mv, ramp slowly
%             if abs(DeltaV)>0.001
%                 for j=1:floor(abs(DeltaV*1000))                   
%                     CurrentV=CurrentV+0.001*sign(DeltaV);
%                     obj.write('SLVL %E',CurrentV);
%                 end
%             end
%             obj.write('SLVL %E',Vset);
%         end
        
        function [X,Y] = snapXY(obj)
            str = obj.query('SNAP?1,2');
            commaPos = strfind(str,',');
            X = str2double(str(1:commaPos));
            Y = str2double(str(commaPos:end));
        end
        
        function [R,theta] = snapRtheta(obj) %R in V = 3, for dBm use 4 (pg.4-25 of manual)
            str = obj.query('SNAP?3,5');
            commaPos = strfind(str,',');
            R = str2double(str(1:commaPos));
            theta = str2double(str(commaPos:end));
        end
        
        %Getter for the current signal level in any flavour
        function [X, Y, R, theta] = get_signal(obj)
            values = textscan(obj.query('SNAP ? 1,2,3,5'), '%f', 'Delimiter', ',');
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
    end
    
end

