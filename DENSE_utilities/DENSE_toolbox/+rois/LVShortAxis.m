classdef LVShortAxis < ROIType
    methods
        function self = LVShortAxis()

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

            cdata = cat(3, red, green, blue);

            self@ROIType('hSA', 'Cardiac Region: LV Short Axis', 2, 'SA', cdata, true, true);
        end
    end
end
