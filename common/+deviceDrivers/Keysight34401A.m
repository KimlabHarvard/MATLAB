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
        
        %varargin can be range or range, resolution
        %eg set_mode('volt', 1, 1E-4)
        function set_mode(obj,mode, varargin)
            options = ['VOLT' 'VOLTAGE', 'VOLT:AC', 'VOLTAGE:AC',...
                'VOLT:DC', 'VOLTAGE:DC', 'RES', 'RESISTANCE',...
                'FRES', 'FRESISTANCE'];
            assert(any(ismember(upper(mode),options)),...
                'possible modes are VOLT, VOLT:AC, VOLT:DC, RES, and FRES');
            switch nargin
                case 2
                    obj.write(['CONF:' upper(mode)]);
                case 3
                    range = varargin{1};
                    if isnumeric(range)
                        range = num2str(range);
                    end
                    obj.write(['CONF:' upper(mode) range]);
                case 4
                    range = varargin{1};
                    if isnumeric(range)
                        range = num2str(range);
                    end
                    res = varargin{2};
                    if isnumeric(res)
                        res = sprintf('%g',res);
                    end
                    obj.write(['CONF:' upper(mode) ' ' range ',' res]);
                otherwise
                    error('max number of arguments = 3 | mode, range, and resolution');
            end
        end
    end
end