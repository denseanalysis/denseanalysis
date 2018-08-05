classdef OpenContour < ROIType
    methods
        function self = OpenContour()

            cdata = [
                5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5
                5 5 5 5 5 3 2 3 5 5 5 5 5 5 5 5
                5 5 5 5 5 2 1 2 5 5 5 5 5 5 5 5
                5 5 5 5 4 3 2 3 5 5 5 5 5 5 5 5
                5 5 5 4 5 5 5 5 5 5 5 5 5 5 5 5
                5 5 4 5 5 5 5 5 5 5 5 5 5 5 5 5
                5 5 4 5 5 5 5 5 5 5 5 5 5 5 5 5
                5 3 2 3 5 5 5 5 5 5 5 5 5 5 5 5
                5 2 1 2 5 5 5 5 5 5 5 5 3 2 3 5
                5 3 2 3 5 5 5 5 5 5 5 5 2 1 2 5
                5 5 4 5 5 5 5 5 5 5 5 5 3 2 3 5
                5 5 4 5 5 5 5 5 5 5 5 5 4 5 5 5
                5 5 5 4 5 5 5 3 2 3 5 4 5 5 5 5
                5 5 5 5 4 4 4 2 1 2 4 5 5 5 5 5
                5 5 5 5 5 5 5 3 2 3 5 5 5 5 5 5
                5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5];

            cmap = [
                0.2510    0.1255         0
                0.5020    0.2510         0
                0.7529    0.6275    0.5059
                1.0000    0.5020         0
                NaN       NaN          NaN];

            cdata = ind2rgb(cdata, cmap);
            color = [1 0.5 0];

            self@ROIType('hopen', 'Open Contour', 1, 'open', cdata, false, true, color)
        end
    end

    methods (Static)
        function tf = mask(X, Y, C)
            tf = maskLine(X, Y, C);
        end
    end
end
