classdef Keithley2000 < deviceDrivers.lib.GPIBorEthernet
    %KEITHLEY2000 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods

        function val = fetch(obj)
            val=str2double(obj.query('FETCh?'));
        end
        
        function val = read(obj)
            val=str2double(obj.query('READ?'));
        end
    end
    
end

