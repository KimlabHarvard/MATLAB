classdef (Sealed) AMI430  < deviceDrivers.lib.GPIBorEthernet
    %AMI430 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        field_units = 1 % 0=kilogauss, 1=Tesla
        ramp_rate_units = 0 % 0 = seconds, 1 = minutes
    end
    
    properties (SetAccess=private)
        state  %int representing the state. see state_map below
        current % read the actual current
        field % read the actual voltage
        
    end
    
    properties (Dependent)
        ramp_rate =0.001 % in Tesla per minute dependent on max_sweep_rate
        target_field % target field in Tesla
    end
    
    properties (Constant)
        max_field = 8 % max field allowed in field units default T
        max_ramp_rate = 0.01 % max sweep rate in field units default T/min
        state_map = containers.Map(1:10,...
            {'RAMPING to target field/current',...
            'HOLDING at the target field/current',...
            'PAUSED',...
            'Ramping in MANUAL UP mode',...
            'Ramping in MANUAL DOWN mode',...
            'ZEROING CURRENT (in progress)',...
            'Quench detected',...
            'At ZERO current',...
            'Heating persistent switch',...
            'Cooling persistent switch'});
    end
    
    methods
        function obj = AMI430()
            obj.DEFAULT_PORT = 7180;
        end
        
        function obj = connect(obj,address)
            %initializes with shit in the buffer. nead to read twice to clear
            %connect using the normal connect in the superclass
            connect@deviceDrivers.lib.GPIBorEthernet(obj, address)
            %clear two items fromt he buffer
            obj.read();
            obj.read();
        end
        
        function obj = set.ramp_rate(obj, val)
            assert(isnumeric(val),'ramp rate must be a number')
            assert(val <= obj.max_ramp_rate, ...
                sprintf('ramp rate set above driver limit: %g',obj.max_ramp_rate))
            
            obj.write(sprintf('CONFigure:RAMP:RATE:FIELD 1,%g,10',val));
        end
        function val = get.ramp_rate(obj)
            val = obj.query('RAMP:RATE:FIELD:1?');
        end
        
        function obj = set.target_field(obj, val)
            assert(isnumeric(val),'target field must be a number')
            assert(val <= obj.max_field,...
                sprintf('target field set above driver limit: %g',obj.max_field))
            
            obj.write(sprintf('CONFigure:FIELD:TARGet %g',val));
            
        end
        function val = get.target_field(obj)
            val = str2double(obj.query('FIELD:TARGet?'));
        end
        
        function obj = set.ramp_rate_units(obj, val)
            assert(val == 0 || val == 1,'Enter 0 for kG and 1 for Tesla')
            obj.write(sprintf('CONFigure:RAMP:RATE:UNITS %d',val));
        end
        function val = get.ramp_rate_units(obj)
            val = str2double(obj.query('RAMP:RATE:UNITS?'));
        end
        
        function obj = set.field_units(obj, val)
            assert(val == 0 || val == 1,'Enter 0 for kG and 1 for Tesla')
            obj.write(sprintf('CONFigure:FIELD:UNITS %d',val));
        end
        function val = get.field_units(obj)
            val = str2double(obj.query('FIELD:UNITS?'));
        end
        
        function val = get.field(obj)
            val = str2double(obj.query('FIELD:MAG?'));
        end
        
        function val = get.current(obj)
            val = str2double(obj.query('CURRent:MAGnet?'));
        end
        
        function val = get.state(obj)
            val = str2double(obj.query('STATE?'));
        end
        
        function val = translate_state(obj)
            val = obj.state_map(obj.state);
        end
        
        function ramp(obj)
            obj.write('RAMP');
        end
        function pause(obj)
            obj.write('PAUSE');
        end
        function zero(obj)
            obj.write('ZERO');
        end
        
        function remote(obj)
            obj.write('SYSTem:REMote')
        end
        function local(obj)
            obj.write('SYSTem:LOCal')
        end
        
        function clear(obj)
            obj.write('*CLS');
        end
        function reset(obj)
            obj.write('*RST');
        end
    end
    
end

