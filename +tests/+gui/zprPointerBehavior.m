classdef zprPointerBehavior < tests.DENSEtest
    methods (Test)
        function zoomtest(testCase)
            ax = testCase.createAxes();
            zprPointerBehavior(ax, 'zoom');
        end

        function combotest(testCase)
            [ax, fig] = testCase.createAxes();
            ax = [ax, axes('Parent', fig), axes('Parent', fig)];
            zprPointerBehavior(ax, {'zoom', 'pan', 'rotate3d'});
        end

        function zoomTestNotAllowed(testCase)
            [ax,fig] = testCase.createAxes();
            hzoom = zoom(fig);

            hzoom.setAllowAxesZoom(ax, false);

            errid = 'zprPointerBehavior:invalidBehavior';

            testCase.assertError(@()zprPointerBehavior(ax, 'zoom'), errid);
        end

        function panTestNotAllowed(testCase)
            [ax,fig] = testCase.createAxes();
            hpan = pan(fig);

            hpan.setAllowAxesPan(ax, false);

            errid = 'zprPointerBehavior:invalidBehavior';

            testCase.assertError(@()zprPointerBehavior(ax, 'pan'), errid);
        end

        function rotateTestNotAllowed(testCase)
            [ax,fig] = testCase.createAxes();
            hrot = rotate3d(fig);

            hrot.setAllowAxesRotate(ax, false);

            errid = 'zprPointerBehavior:invalidBehavior';

            testCase.assertError(@()zprPointerBehavior(ax, 'rotate3d'), errid);
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
        function [ax, fig] = createAxes(testCase)
            fig = testCase.figure();
            ax = axes('Parent', fig);
        end
    end
end
