classdef zprPointerBehavior < DENSEtest
    methods (Test)
        function zoomtest(testCase)
            ax = testCase.createAxes();
            zprPointerBehavior(ax, 'zoom');
        end

        function pantest(testCase)
            ax = testCase.createAxes();
            zprPointerBehavior(ax, 'pan');
        end

        function rotate3dtest(testCase)
            ax = testCase.createAxes();
            zprPointerBehavior(ax, 'rotate3d');
        end
    end

    methods
        function ax = createAxes(testCase)
            fig = testCase.figure();
            ax = axes('Parent', fig);
        end
    end
end
