classdef imcline < tests.DENSEtest
    methods (Test)
        function testConstructor(testCase)
            testCase.figure();
            c = cline();

            im = imcline(c);

            testCase.assertEqual(im.cLine, c);
            testCase.assertSameHandle(im.cLine, c);
        end

        function specifyParentAxes(testCase)
            fig = testCase.figure();
            ax1 = axes('Parent', fig);
            ax2 = axes('Parent', fig);

            testCase.assertEqual(get(fig, 'CurrentAxes'), ax2);

            im = imcline(cline(), ax1);

            testCase.assertEqual(im.Parent, ax1);
        end

        function deleteGraphics(testCase)
        end

        function deleteCline(testCase)
        end
    end
end
