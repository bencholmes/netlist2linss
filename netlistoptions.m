classdef netlistoptions
    %NETLISTOPTIONS A set of options for netlist2linss
    
    properties
        Ts = [];            % Sample period.
        UseValues = true;   % Whether to take values from netlist.
    end
    
    methods
        % Set Sample Period
        function obj = set.Ts(obj, Ts)
            % Check sample period is a scalar.
            if ~isscalar(Ts)
                error('Sampling period must be scalars.');
            end
            obj.Ts = Ts;
        end
        
        % Set whether to take values from netlist
        function obj = set.UseValues(obj, UseValues)
            % Check to see if boolean.
            if ~isboolean(UseValues)
                error('UseValues must be true/false.');
            end
            obj.UseValues = UseValues;
        end
    end
    
end

