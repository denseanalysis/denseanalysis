classdef ROIType < matlab.mixin.Heterogeneous
    methods (Abstract, Static)
        res = cdata()
        res = description()
        res = isclosed()
        res = iscurved()
        res = nlines()
        res = tag()
        res = type()
    end
end
