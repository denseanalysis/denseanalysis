classdef DataViewer < tests.DENSEtest
    methods (Test)
        function testSingleParentAssignmentFigure(testCase)
            % Ensure that setting the parent is actually respected
            fig = testCase.figure();

            % Make this other one the current figure to make sure it goes
            % to the correct one
            testCase.figure();

            dv = DataViewer([], DENSEdata, fig);

            testCase.assertNotEmpty(dv);
            testCase.assertEqual(fig, dv.DisplayParent);
            testCase.assertEqual(fig, dv.ControlParent);
        end

        function testDoubleParentAssignmentFigure(testCase)
            % Ensure that setting the parent is actually respected

            % Now set different parents for each
            fig1 = testCase.figure();
            fig2 = testCase.figure();

            dv = DataViewer([], DENSEdata, fig1, fig2);

            testCase.assertNotEmpty(dv);
            testCase.assertEqual(fig1, dv.DisplayParent);
            testCase.assertEqual(fig2, dv.ControlParent);
        end

        function testParentAssignmentPanel(testCase)
            % Assign a parent that is a panel rather than a figure
            panel = uipanel('Parent', testCase.figure());

            dv = DataViewer([], DENSEdata, panel);

            testCase.assertNotEmpty(dv);
            testCase.assertEqual(panel, dv.DisplayParent);
            testCase.assertEqual(panel, dv.ControlParent);
        end

        function testFigureListeners(testCase)
            % Ensure that we listen to when the parent figure is destroyed

            fig = testCase.figure();

            % Specify the parent figure to be explicit
            opts.hparent_display = fig;
            opts.hparent_control = fig;

            dv = DataViewer(opts, DENSEdata);

            % Now make sure that when we delete the figure, the DataViewer
            % instance gets removed as well indicating that the
            % ObjectBeingDestroyed callback was assigned, stored, and
            % triggered properly
            testCase.assertNotEmpty(dv);

            delete(fig);

            testCase.assertFalse(isvalid(dv));
        end
    end
end
