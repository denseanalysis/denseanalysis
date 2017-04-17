classdef PolylineRegion < ROIType
    methods (Static)
        function res = description()
            res = 'Polyline Region';
        end

        function res = tag()
            res = 'hpoly';
        end

        function res = isclosed()
            res = true;
        end

        function res = iscurved()
            res = false;
        end

        function res = nlines()
            res = 1;
        end

        function res = type()
            res = 'line';
        end

        function res = cdata()

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

            res = cat(3, red, green, blue);
        end
    end
end
