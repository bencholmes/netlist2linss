classdef netlistoptions < handle
    %NETLISTOPTIONS A set of options for netlist2linss
    
    properties
        Ts;         % Sample period.
        UseValues;  % Whether to take values from netlist.
    end
    
    methods
        function obj = netlistoptions()
            % Assign default values
            obj.Ts = [];            
            obj.UseValues = true;
        end
        
        % Set Sample Period
        function set.Ts(obj, Ts)
            % Check sample period is a scalar.
            if ~isempty(Ts) && ~isscalar(Ts)
                error('Sampling period must be scalar.');
            end
            obj.Ts = Ts;
        end
        
        % Set whether to take values from netlist
        function set.UseValues(obj, UseValues)
            % Check to see if boolean.
            if UseValues~=true && UseValues ~=false
                error('UseValues must be true/false.');
            end
            obj.UseValues = UseValues;
        end
    end
    
end

