classdef LVShortAxis < ROIType
    methods
        function self = LVShortAxis()

            cdata = [
                4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4
                4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4
                4 4 4 4 4 4 2 2 2 2 4 4 4 4 4 4
                4 4 4 4 2 2 3 3 3 3 2 2 4 4 4 4
                4 4 4 2 3 3 3 3 3 3 3 3 2 4 4 4
                4 4 4 2 3 3 3 1 1 3 3 3 2 4 4 4
                4 4 2 3 3 3 1 4 4 1 3 3 3 2 4 4
                4 4 2 3 3 1 4 4 4 4 1 3 3 2 4 4
                4 4 2 3 3 1 4 4 4 4 1 3 3 2 4 4
                4 4 2 3 3 3 1 4 4 1 3 3 3 2 4 4
                4 4 4 2 3 3 3 1 1 3 3 3 2 4 4 4
                4 4 4 2 3 3 3 3 3 3 3 3 2 4 4 4
                4 4 4 4 2 2 3 3 3 3 2 2 4 4 4 4
                4 4 4 4 4 4 2 2 2 2 4 4 4 4 4 4
                4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4
                4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4];

            cmap = [
                     0    0.7529         0
                1.0000         0         0
                1.0000    1.0000         0
                   NaN       NaN       NaN];

            cdata = ind2rgb(cdata, cmap);

            self@ROIType('hSA', 'Cardiac Region: LV Short Axis', 2, 'SA', cdata, true, true, []);
        end

        function [pos, iscls, iscrv, iscrn] = drawContour(self, hax, varargin)
            [epi, endo] = getSA(hax, varargin{:});

            pos = {epi, endo};
            iscls = {self.Closed};
            iscrv = {self.Curved};
            iscrn = {false};
        end
    end

    methods (Static)
        function tf = mask(X, Y, C)
            [inep, onep] = inpolygon(X, Y, C{1}(:,1), C{1}(:,2));
            [inen, onen] = inpolygon(X, Y, C{2}(:,1), C{2}(:,2));
            tf = (inep & ~inen) | onep | onen;
        end
    end
end
