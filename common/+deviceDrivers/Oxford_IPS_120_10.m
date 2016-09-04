% CLASS Oxford_IPS_120_10 - Instrument driver for the Oxford
% superconducting magnet controller IPS 120-10 at Harvard

% Author: Jesse Crossno (crossno@seas.harvard.edu)


classdef (Sealed) Oxford_IPS_120_10 < deviceDrivers.lib.GPIB
    properties (Access = public)
        sweepRate % in Tesla per minute
        targetField %target field in Tesla
        switchHeater % 0=OFF, 1=ON
        maxField = 14 %max field allowed in Tesla
        maxSweepRate = 0.5 % max sweep rate in T/min
    end
    
    properties (SetAccess=private)
        status  %15 char string representing system status
        measuredCurrent % read the actual current
        measuredField % read the actual voltage
        persistentField % read persistent field value
    end
    
    
    methods
        %supersede gpib connect and create gpib using EOS char 'CR'
        function connect(obj, address)
            if ~obj.isConnected
                if ischar(address)
                    address = str2double(address);
                end
                
                % create a GPIB object
                if ~isempty(obj.interface)
                    fclose(obj.interface);
                    delete(obj.interface);
                end
                
                obj.interface = gpib(obj.vendor, obj.boardIndex, address);
                obj.interface.InputBufferSize = obj.buffer_size;
                obj.interface.OutputBufferSize = obj.buffer_size;
                obj.interface.EOSMode = 'read&write';
                obj.interface.EOSCharCode = 'CR';
                fopen(obj.interface);
            end
        end
        
        %Current or voltage source mode
        function val = get.status(obj)
            val = obj.query('X');
        end
        
        function val = get.sweepRate(obj)
            val = obj.query('R9');
            val = str2double(val(2:end));
        end
        
        function val = get.targetField(obj)
            val = obj.query('R8');
            val = str2double(val(2:end));
        end
        
         function val = get.persistentField(obj)
            val = obj.query('R18');
            val = str2double(val(2:end));
        end
        
        function val = get.switchHeater(obj)
            state = obj.status();
            if state(9)==0 || state(9)==2
                val = 0;
            elseif state(9) == 1
                val = 1;
            else
                error('switch heater fault')
            end
        end
        function obj = set.sweepRate(obj,val)
            assert(isnumeric(val), 'Oops! You need to program a numeric value.');
            obj.query(['T',num2str(val)]);
        end
        
        function obj = set.targetField(obj,val)
            assert(isnumeric(val), 'Oops! You need to program a numeric value.');
            obj.query(['J',num2str(val)]);
        end
        function obj = set.switchHeater(obj,val)
            assert(val==0 || val==1, 'Oops! switch heater needs to be 0 or 1.');
            obj.query(['H',num2str(val)]);
        end
        
        
        function val = get.measuredCurrent(obj)
            val = obj.query('R7');
            val = str2double(val(2:end));
        end
        function val = get.measuredField(obj)
            val = obj.query('R7');
            val = str2double(val(2:end));
        end
        
        function remoteMode(obj)
            obj.query('C3');
        end
        
        function hold(obj)
            obj.query('A0')
        end
        
        function goToTargetField(obj)
            assert(isnumeric(obj.targetField), 'Oops! need to set a target field.');
            assert(isnumeric(obj.maxField), 'Oops! not safe to operate without maxField set.');
            assert(isnumeric(obj.maxSweepRate), 'Oops! not safe to operate without maxSweepRate set.');
            assert(isnumeric(obj.sweepRate), 'Oops! need to set a sweep rate.');
            assert(abs(obj.targetField) < obj.maxField, 'magnet field set too high!');
            assert(abs(obj.sweepRate) < obj.maxSweepRate,'sweep rate set too high!');

            obj.query('A1');
        end
        
        function goToZero(obj)
            assert(isnumeric(obj.sweepRate), 'Oops! need to set a sweep rate.');
            assert(isnumeric(obj.maxSweepRate), 'Oops! not safe to operate without maxSweepRate set.');
            assert(abs(obj.sweepRate) < obj.maxSweepRate,'sweep rate set too high!');
            
            obj.query('A2');
        end
        
        function holdField(obj)
            obj.query('A0');
        end
        
        
        function rampToField(obj,field,sweepRate)
            assert(isnumeric(obj.maxField), 'Oops! not safe to operate without maxField set.');
            assert(isnumeric(obj.maxSweepRate), 'Oops! not safe to operate without maxSweepRate set.');
            assert(abs(obj.targetField) < obj.maxField, 'magnet field set too high!');
            assert(abs(obj.sweepRate) < obj.maxSweepRate,'sweep rate set too high!');
            
            obj.remoteMode();
            obj.sweepRate = sweepRate;
            obj.targetField = field;
            obj.switchHeater = 1;
            obj.goToTargetField();
        end
 
    end
end