classdef eventdata < handle
    properties (Enumeration)
        WindowButtonMotionFcn
        WindowButtonDownFcn
        WindowButtonUpFcn
    end

    methods
        function self = eventdata()
        end
    end
end
