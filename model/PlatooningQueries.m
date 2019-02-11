classdef PlatooningQueries < Simulink.IntEnumType
    
    % Copyright 2018 The MathWorks, Inc.
    
    enumeration
        VehiclesAhead(0)
    end
    methods (Static)
        function retVal = getDefaultValue()
            retVal = PlatooningQueries.VehiclesAhead;
        end
    end
end