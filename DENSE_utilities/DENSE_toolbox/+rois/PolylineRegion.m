classdef PolylineRegion < ROIType
    methods
        function self = PolylineRegion()

            cdata = [
                6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6
                6 6 6 6 4 3 4 6 6 6 6 6 6 6 6 6
                6 6 6 6 3 1 3 6 6 6 6 6 6 6 6 6
                6 6 6 6 4 3 4 2 2 2 6 6 6 6 6 6
                6 6 6 6 2 5 5 5 5 5 2 2 4 3 4 6
                6 6 6 6 2 5 5 5 5 5 5 5 3 1 3 6
                6 6 6 2 5 5 5 5 5 5 5 5 4 3 4 6
                6 6 6 2 5 5 5 5 5 5 5 5 2 6 6 6
                6 6 6 2 5 5 5 5 5 5 5 5 2 6 6 6
                6 4 3 4 5 5 5 5 5 5 5 5 2 6 6 6
                6 3 1 3 5 5 5 5 5 5 5 2 6 6 6 6
                6 4 3 4 2 2 5 5 5 5 5 2 6 6 6 6
                6 6 6 6 6 6 2 2 2 4 3 4 6 6 6 6
                6 6 6 6 6 6 6 6 6 3 1 3 6 6 6 6
                6 6 6 6 6 6 6 6 6 4 3 4 6 6 6 6
                6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6];

            cmap = [
                     0         0    0.5020
                     0         0    1.0000
                     0    0.2510    0.5020
                0.5020    0.5020    0.7529
                1.0000    1.0000         0
                   NaN       NaN       NaN];

            cdata = ind2rgb(cdata, cmap);

            self@ROIType('hpoly', 'Polyline Region', 1, 'poly', cdata, true, false);
        end
    end
end
