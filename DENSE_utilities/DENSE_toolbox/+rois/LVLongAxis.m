classdef LVLongAxis < ROIType
    methods
        function self = LVLongAxis()

            red = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 1 1 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 1 1 1 1 1 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 1 1 1 1 1 0 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 1 1 1 1 0 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN 1 1 1 1 0 NaN NaN NaN NaN NaN 0 NaN NaN NaN
                NaN NaN 1 1 1 0 NaN NaN NaN NaN NaN 0 1 1 NaN NaN
                NaN 1 1 1 1 0 NaN NaN NaN NaN 0 1 1 1 1 NaN
                NaN 1 1 1 0 NaN NaN NaN NaN 0 1 1 1 1 1 NaN
                NaN 1 1 1 0 NaN NaN 0 0 1 1 1 1 1 NaN NaN
                NaN 1 1 1 1 0 0 1 1 1 1 1 1 NaN NaN NaN
                NaN 1 1 1 1 1 1 1 1 1 1 1 NaN NaN NaN NaN
                NaN NaN 1 1 1 1 1 1 1 1 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 1 1 1 1 1 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            green = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 1 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN 0 1 1 1 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 1 1 1 1 1 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 0 1 1 1 1 1 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 0 1 1 1 1 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN 0 1 1 1 1 NaN NaN NaN NaN NaN 1 NaN NaN NaN
                NaN NaN 0 1 1 1 NaN NaN NaN NaN NaN 1 1 1 NaN NaN
                NaN 0 1 1 1 1 NaN NaN NaN NaN 1 1 1 1 1 NaN
                NaN 0 1 1 1 NaN NaN NaN NaN 1 1 1 1 1 0 NaN
                NaN 0 1 1 1 NaN NaN 1 1 1 1 1 1 0 NaN NaN
                NaN 0 1 1 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN 0 1 1 1 1 1 1 1 1 0 0 NaN NaN NaN NaN
                NaN NaN 0 1 1 1 1 1 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 0 0 0 0 0 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            blue = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 0 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN 0 0 0 0 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 0 0 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 0 0 0 0 0 0 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 0 0 0 0 0 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN 0 0 0 0 0 NaN NaN NaN NaN NaN 0 NaN NaN NaN
                NaN NaN 0 0 0 0 NaN NaN NaN NaN NaN 0 0 0 NaN NaN
                NaN 0 0 0 0 0 NaN NaN NaN NaN 0 0 0 0 0 NaN
                NaN 0 0 0 0 NaN NaN NaN NaN 0 0 0 0 0 0 NaN
                NaN 0 0 0 0 NaN NaN 0 0 0 0 0 0 0 NaN NaN
                NaN 0 0 0 0 0 0 0 0 0 0 0 0 NaN NaN NaN
                NaN 0 0 0 0 0 0 0 0 0 0 0 NaN NaN NaN NaN
                NaN NaN 0 0 0 0 0 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN 0 0 0 0 0 NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            cdata = cat(3, red, green, blue);

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
        function tf = maskLA(X, Y, C)
            C = cat(1, C{:});
            tf = inpolygon(X, Y, C(:,1), C(:,2));
        end
    end
end
