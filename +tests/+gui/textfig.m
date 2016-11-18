classdef textfig < tests.DENSEtest
    methods (Test)
        function testFigureInput(testCase)
            fig1 = testCase.figure();
            fig2 = testCase.figure();

            testCase.assertTrue(gcf == fig2);

            % Add text to non-gcf
            tf = textfig(fig1);

            testCase.assertTrue(ishghandle(tf));
            testCase.assertEqual(tf, findall(fig1, 'type', 'text'));
            testCase.assertEmpty(findall(fig2, 'type', 'text'));

            delete(fig1);

            testCase.assertFalse(ishghandle(tf));
        end

        function testPanelInput(testCase)
            fig = testCase.figure();

            p1 = uipanel('Parent', fig);

            tf = textfig(p1);

            testCase.assertTrue(ishghandle(tf));
            testCase.assertTrue(findall(p1, 'type', 'text') == tf);

            delete(p1);

            testCase.assertFalse(ishghandle(tf));
        end
    end
end
