%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Keysight Digital Multimeter Device
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef (Sealed) Keysight34401A < deviceDrivers.lib.GPIB
    properties (SetAccess=private)
        value;
    end
    methods
        function obj = Keysight34401A()
        end

        function val = get.value(obj)
            val=str2double(obj.query('READ?'));
        end
    end
end