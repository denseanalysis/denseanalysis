classdef hierarchy < tests.DENSEtest
    methods (Test)
        function plainFigure(testCase)
            fig = testCase.figure();
            testCase.assertEqual(hierarchy(fig, 'figure'), fig);
        end

        function testEmptyType(testCase)
            % Type is allowed to be empty but it will never return anything
            testCase.assertEmpty(hierarchy(testCase.figure(), ''));
        end

        function testNonHG(testCase)
            % Pass an empty array
            testCase.assertEmpty(hierarchy([], 'figure'));
            testCase.assertEmpty(hierarchy([], ''));

            % Pass a UDD object which is an object but not an HG object
            mm = uigetmodemanager(testCase.figure());
            testCase.assertEmpty(hierarchy(mm, 'figure'));
        end

        function figureWithChildren(testCase)
            fig = testCase.figure();
            ax1 = axes('Parent', fig);
            ax2 = axes('Parent', fig);
            p1 = plot(1,2, 'Parent', ax1);
            p2 = plot(1,2, 'Parent', ax2);

            h = hierarchy(fig, 'figure');
            testCase.assertEqual(h, fig);

            % Axes level
            testCase.assertEqual(hierarchy(ax1, 'figure'), [ax1, fig]);
            testCase.assertEqual(hierarchy(ax2, 'figure'), [ax2, fig]);

            % Plot level
            testCase.assertEqual(hierarchy(p1, 'figure'), [p1, ax1, fig]);
            testCase.assertEqual(hierarchy(p2, 'figure'), [p2, ax2, fig]);

            % Plot->Axes
            testCase.assertEqual(hierarchy(p1, 'axes'), [p1, ax1]);
            testCase.assertEqual(hierarchy(p2, 'axes'), [p2, ax2]);
        end

        function handleVisibilityCheck(testCase)
            fig = testCase.figure();
            ax1 = axes('Parent', fig);
            p1 = plot(1, 2, 'Parent', ax1);

            set(ax1, 'HandleVisibility', 'off')

            testCase.assertEqual(hierarchy(p1, 'figure'), [p1, ax1, fig]);
        end
    end
end
