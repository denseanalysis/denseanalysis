classdef LVShortAxis < ROIType

    methods (Static)
        function res = cdata()
            red = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 1 1 1 1 1 1 1 1 NaN NaN NaN NaN
                NaN NaN NaN 1 1 1 1 1 1 1 1 1 1 NaN NaN NaN
                NaN NaN NaN 1 1 1 1 0 0 1 1 1 1 NaN NaN NaN
                NaN NaN 1 1 1 1 0 NaN NaN 0 1 1 1 1 NaN NaN
                NaN NaN 1 1 1 0 NaN NaN NaN NaN 0 1 1 1 NaN NaN
                NaN NaN 1 1 1 0 NaN NaN NaN NaN 0 1 1 1 NaN NaN
                NaN NaN 1 1 1 1 0 NaN NaN 0 1 1 1 1 NaN NaN
                NaN NaN NaN 1 1 1 1 0 0 1 1 1 1 NaN NaN NaN
                NaN NaN NaN 1 1 1 1 1 1 1 1 1 1 NaN NaN NaN
                NaN NaN NaN NaN 1 1 1 1 1 1 1 1 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 1 1 1 1 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            green = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 0 1 1 1 1 0 0 NaN NaN NaN NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN NaN NaN 0 1 1 1 0.7529 0.7529 1 1 1 0 NaN NaN NaN
                NaN NaN 0 1 1 1 0.7529 NaN NaN 0.7529 1 1 1 0 NaN NaN
                NaN NaN 0 1 1 0.7529 NaN NaN NaN NaN 0.7529 1 1 0 NaN NaN
                NaN NaN 0 1 1 0.7529 NaN NaN NaN NaN 0.7529 1 1 0 NaN NaN
                NaN NaN 0 1 1 1 0.7529 NaN NaN 0.7529 1 1 1 0 NaN NaN
                NaN NaN NaN 0 1 1 1 0.7529 0.7529 1 1 1 0 NaN NaN NaN
                NaN NaN NaN 0 1 1 1 1 1 1 1 1 0 NaN NaN NaN
                NaN NaN NaN NaN 0 0 1 1 1 1 0 0 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            blue = [
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN 0 0 0 0 0 0 0 0 NaN NaN NaN NaN
                NaN NaN NaN 0 0 0 0 0 0 0 0 0 0 NaN NaN NaN
                NaN NaN NaN 0 0 0 0 0 0 0 0 0 0 NaN NaN NaN
                NaN NaN 0 0 0 0 0 NaN NaN 0 0 0 0 0 NaN NaN
                NaN NaN 0 0 0 0 NaN NaN NaN NaN 0 0 0 0 NaN NaN
                NaN NaN 0 0 0 0 NaN NaN NaN NaN 0 0 0 0 NaN NaN
                NaN NaN 0 0 0 0 0 NaN NaN 0 0 0 0 0 NaN NaN
                NaN NaN NaN 0 0 0 0 0 0 0 0 0 0 NaN NaN NaN
                NaN NaN NaN 0 0 0 0 0 0 0 0 0 0 NaN NaN NaN
                NaN NaN NaN NaN 0 0 0 0 0 0 0 0 NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN 0 0 0 0 NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
                NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN];

            res = cat(3, red, green, blue);
        end

        function res = description()
            res = 'Cardiac Region: LV Short Axis';
        end

        function res = isclosed()
            res = true;
        end

        function res = iscurved()
            res = true;
        end

        function res = tag()
            res = 'hSA';
        end

        function res = nlines()
            res = 2;
        end

        function res = type()
            res = 'SA';
        end
    end
end
