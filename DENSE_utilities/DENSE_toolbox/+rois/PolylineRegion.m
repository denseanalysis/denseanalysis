classdef PolylineRegion < ROIType
    methods
        function self = PolylineRegion()
            red = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.5020 0 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 0 0 NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.5020 0 0.5020 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 1 1 1 1 1 0 0 0.5020 0 0.5020 NaN
                NaN NaN NaN NaN 0 1 1 1 1 1 1 1 0 0 0 NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0.5020 0 0.5020 NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN 0.5020 0 0.5020 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN 0 0 0 1 1 1 1 1 1 1 0 NaN NaN NaN NaN
                NaN 0.5020 0 0.5020 0 0 1 1 1 1 1 0 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 0 0 0.5020 0 0.5020 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN 0 0 0 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 0 0.5020 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            green = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.5020 0.2510 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.2510 0 0.2510 NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.5020 0.2510 0.5020 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 1 1 1 1 1 0 0 0.5020 0.2510 0.5020 NaN
                NaN NaN NaN NaN 0 1 1 1 1 1 1 1 0.2510 0 0.2510 NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0.5020 0.2510 0.5020 NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN 0.5020 0.2510 0.5020 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN 0.2510 0 0.2510 1 1 1 1 1 1 1 0 NaN NaN NaN NaN
                NaN 0.5020 0.2510 0.5020 0 0 1 1 1 1 1 0 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 0 0 0.5020 0.2510 0.5020 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.2510 0 0.2510 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 0.2510 0.5020 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            blue = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.7529 0.5020 0.7529 NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.5020 0.5020 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.7529 0.5020 0.7529 1 1 1 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 1 0 0 0 0 0 1 1 0.7529 0.5020 0.7529 NaN
                NaN NaN NaN NaN 1 0 0 0 0 0 0 0 0.5020 0.5020 0.5020 NaN
                NaN NaN NaN 1 0 0 0 0 0 0 0 0 0.7529 0.5020 0.7529 NaN
                NaN NaN NaN 1 0 0 0 0 0 0 0 0 1 NaN NaN NaN
                NaN NaN NaN 1 0 0 0 0 0 0 0 0 1 NaN NaN NaN
                NaN 0.7529 0.5020 0.7529 0 0 0 0 0 0 0 0 1 NaN NaN NaN
                NaN 0.5020 0.5020 0.5020 0 0 0 0 0 0 0 1 NaN NaN NaN NaN
                NaN 0.7529 0.5020 0.7529 1 1 0 0 0 0 0 1 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 1 1 1 0.7529 0.5020 0.7529 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 0.5020 0.5020 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.7529 0.5020 0.7529 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            cdata = cat(3, red, green, blue);

            self@ROIType('hpoly', 'Polyline Region', 1, 'poly', cdata, true, false);
        end
    end
end
