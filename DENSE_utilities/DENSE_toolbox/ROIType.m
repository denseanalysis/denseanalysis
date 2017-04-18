classdef ROIType < handle & matlab.mixin.Heterogeneous

    properties (SetAccess = 'private')
        CData
        Description
        Closed
        Curved
        NLines
        Tag
        Type
    end

    methods
        function self = ROIType(tag, desc, nlines, type, cdata, clsd, crvd)
            self.CData = cdata;
            self.Description = desc;
            self.Closed = clsd;
            self.Curved = crvd;
            self.NLines = nlines;
            self.Tag = tag;
            self.Type = type;
        end
    end

    methods (Sealed)
        function res = findobj(varargin)
            res = findobj@handle(varargin{:});
        end
    end

    methods (Static)
        function pos = drawContour(hax)
        end
    end
end
