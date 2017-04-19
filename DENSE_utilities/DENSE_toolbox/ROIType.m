classdef ROIType < handle & matlab.mixin.Heterogeneous

    properties (SetAccess = 'private')
        CData
        Closed
        Color = 'b'
        Curved
        Description
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
        function tf = mask(X, Y, C)
            tf = maskGeneral(X, Y, C);
        end
    end

    methods
        function [pos, iscls, iscrv, iscrn] = drawContour(self, hax, varargin)
            h = getcline(hax, ...
                'IsClosed', self.Closed, ...
                'IsCurved', self.Curved, ...
                'Color',    self.Color, ...
                varargin{:});

            pos     = h.Position;
            iscls   = h.IsClosed;
            iscrv   = h.IsCurved;
            iscrn   = h.IsCorner;
            delete(h);
        end
    end
end
