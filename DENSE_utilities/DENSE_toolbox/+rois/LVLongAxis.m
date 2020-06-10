classdef LVLongAxis < ROIType
    methods
        function self = LVLongAxis()

            cdata = [
                4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4
                4 4 4 4 4 4 2 3 4 4 4 4 4 4 4 4
                4 4 4 4 4 2 3 3 3 4 4 4 4 4 4 4
                4 4 4 4 2 3 3 3 3 1 4 4 4 4 4 4
                4 4 4 2 3 3 3 3 1 4 4 4 4 4 4 4
                4 4 4 2 3 3 3 1 4 4 4 4 4 4 4 4
                4 4 2 3 3 3 1 4 4 4 4 4 1 4 4 4
                4 4 2 3 3 1 4 4 4 4 4 1 3 3 4 4
                4 2 3 3 3 1 4 4 4 4 1 3 3 3 3 4
                4 2 3 3 1 4 4 4 4 1 3 3 3 3 2 4
                4 2 3 3 1 4 4 1 1 3 3 3 3 2 4 4
                4 2 3 3 3 1 1 3 3 3 3 3 2 4 4 4
                4 2 3 3 3 3 3 3 3 3 2 2 4 4 4 4
                4 4 2 3 3 3 3 3 2 2 4 4 4 4 4 4
                4 4 4 2 2 2 2 2 4 4 4 4 4 4 4 4
                4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4];

            cmap = [
                0   1   0
                1   0   0
                1   1   0
                NaN NaN NaN];

            cdata = ind2rgb(cdata, cmap);

            self@ROIType('hLA', 'Cardiac Region: LV Long Axis', 2, 'LA', cdata, false, true, [])
        end

        function [pos, iscls, iscrv, iscrn] = drawContour(self, hax, varargin)
            [epi, endo] = getLA(hax, varargin{:});

            pos = {epi, endo};
            iscls = {self.Closed};
            iscrv = {self.Curved};
            iscrn = {false};
        end
    end

    methods (Static)
        function tf = mask(X, Y, C)
            C = cat(1, C{:});
            tf = inpolygon(X, Y, C(:,1), C(:,2));
        end
    end
end
