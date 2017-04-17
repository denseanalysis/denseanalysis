classdef ClosedContour < ROIType
    methods (Static)
        function res = cdata()
            red = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0.7529 0.5020 0.7529 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 1 1 0.5020 0.2510 0.5020 1 1 1 NaN NaN NaN NaN
                NaN NaN NaN 1 NaN NaN 0.7529 0.5020 0.7529 NaN NaN NaN 1 NaN NaN NaN
                NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN
                NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN
                NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.7529 0.5020 0.7529 NaN
                NaN 0.7529 0.5020 0.7529 NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 0.2510 0.5020 NaN
                NaN 0.5020 0.2510 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN 0.7529 0.5020 0.7529 NaN
                NaN 0.7529 0.5020 0.7529 NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN
                NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN
                NaN NaN 1 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 NaN NaN
                NaN NaN NaN 1 NaN NaN NaN 0.7529 0.5020 0.7529 NaN NaN 1 NaN NaN NaN
                NaN NaN NaN NaN 1 1 1 0.5020 0.2510 0.5020 1 1 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN 0.7529 0.5020 0.7529 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            green = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0.6275 0.2510 0.6275 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0.5020 0.5020 0.2510 0.1255 0.2510 0.5020 0.5020 0.5020 NaN NaN NaN NaN
                NaN NaN NaN 0.5020 NaN NaN 0.6275 0.2510 0.6275 NaN NaN NaN 0.5020 NaN NaN NaN
                NaN NaN 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 NaN NaN
                NaN NaN 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 NaN NaN
                NaN NaN 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.6275 0.2510 0.6275 NaN
                NaN 0.6275 0.2510 0.6275 NaN NaN NaN NaN NaN NaN NaN NaN 0.2510 0.1255 0.2510 NaN
                NaN 0.2510 0.1255 0.2510 NaN NaN NaN NaN NaN NaN NaN NaN 0.6275 0.2510 0.6275 NaN
                NaN 0.6275 0.2510 0.6275 NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 NaN NaN
                NaN NaN 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 NaN NaN
                NaN NaN 0.5020 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5020 NaN NaN
                NaN NaN NaN 0.5020 NaN NaN NaN 0.6275 0.2510 0.6275 NaN NaN 0.5020 NaN NaN NaN
                NaN NaN NaN NaN 0.5020 0.5020 0.5020 0.2510 0.1255 0.2510 0.5020 0.5020 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN 0.6275 0.2510 0.6275 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            blue = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0.5059 0 0.5059 NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 0 0 0 0 0 0 0 NaN NaN NaN NaN
                NaN NaN NaN 0 NaN NaN 0.5059 0 0.5059 NaN NaN NaN 0 NaN NaN NaN
                NaN NaN 0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0 NaN NaN
                NaN NaN 0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0 NaN NaN
                NaN NaN 0 NaN NaN NaN NaN NaN NaN NaN NaN NaN 0.5059 0 0.5059 NaN
                NaN 0.5059 0 0.5059 NaN NaN NaN NaN NaN NaN NaN NaN 0 0 0 NaN
                NaN 0 0 0 NaN NaN NaN NaN NaN NaN NaN NaN 0.5059 0 0.5059 NaN
                NaN 0.5059 0 0.5059 NaN NaN NaN NaN NaN NaN NaN NaN NaN 0 NaN NaN
                NaN NaN 0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0 NaN NaN
                NaN NaN 0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 0 NaN NaN
                NaN NaN NaN 0 NaN NaN NaN 0.5059 0 0.5059 NaN NaN 0 NaN NaN NaN
                NaN NaN NaN NaN 0 0 0 0 0 0 0 0 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN 0.5059 0 0.5059 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            res = cat(3, red, green, blue);
        end

        function res = description()
            res = 'Closed Contour';
        end

        function res = tag()
            res = 'hclosed';
        end

        function res = isclosed()
            res = true;
        end

        function res = iscurved()
            res = true;
        end

        function res = type()
            res = 'closed';
        end

        function res = nlines()
            res = 1;
        end
    end
end
