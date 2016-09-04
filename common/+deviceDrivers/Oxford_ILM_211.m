% CLASS Oxford_IPS_120_10 - Instrument driver for the Oxford
% superconducting magnet controller IPS 120-10 at Harvard

% Author: Jesse Crossno (crossno@seas.harvard.edu)


classdef (Sealed) Oxford_ILM_211 < deviceDrivers.lib.GPIB
    properties (SetAccess = private)
        level
        status
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

        function val = get.level(obj)
            val = obj.query('R1');
            %val = str2double(val(2:end));
        end
        
        function remoteMode(obj)
            obj.query('C3');
        end

 
    end
end