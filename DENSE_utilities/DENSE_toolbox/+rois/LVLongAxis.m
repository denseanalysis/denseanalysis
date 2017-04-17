classdef LVLongAxis < ROIType

    methods (Static)
        function res = cdata()

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

            res = cat(3, red, green, blue);
        end

        function res = description()
            res = 'Cardiac Region: LV Long Axis';
        end

        function res = tag()
            res = 'hLA';
        end

        function res = isclosed()
            res = false;
        end

        function res = iscurved()
            res = true;
        end

        function res = nlines()
            res = 2;
        end

        function res = type()
            res = 'LA';
        end
    end
end
