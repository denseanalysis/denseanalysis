classdef popuptabs < tests.DENSEtest
    methods (Test)
        function pt = constructor(testCase)
            fig = testCase.figure();
            pt = popuptabs(fig);

            testCase.assertClass(pt, 'popuptabs');
            testCase.assertTrue(isvalid(pt));

            % Check to make sure that the graphics were created under fig
        end

        function addTabDefault(testCase)
            pt = testCase.constructor();
            pt.addTab('Tab1');
        end

        function addTabWithPanel(testCase)
            pt = testCase.constructor();
            panel = uipanel('Parent', ancestor(pt.Parent, 'figure'));
            pt.addTab('Tab1', panel);
        end

        function deleteHandle(testCase)
            pt = testCase.constructor();

            testCase.assertWarningFree(@()delete(pt));
            testCase.assertFalse(isvalid(pt));
        end

        function deleteFigure(testCase)
            pt = testCase.constructor();
            fig = ancestor(pt.Parent, 'figure');

            testCase.assertWarningFree(@()delete(fig));
            testCase.assertFalse(isvalid(pt));
        end
    end
end
