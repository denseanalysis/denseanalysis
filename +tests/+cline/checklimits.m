classdef checklimits < tests.DENSEtest
     methods (Test)
          function invalidHandle(testCase)
               % Not an axes
               fig = testCase.figure();

               testCase.assertFalse(checklimits(fig, [1, 1]));
          end

          function invalidPoint(testCase)
               fig = testCase.figure();
               ax = axes('Parent', fig);

               testCase.assertFalse(checklimits(ax, []));
          end

          function validHandleInvalidPoint(testCase)
               fig = testCase.figure();
               ax = axes('Parent', fig, 'xlim', [0 1], 'ylim', [0 1]);

               testCase.assertFalse(checklimits(ax, [0.5, -1.5]));
               testCase.assertFalse(checklimits(ax, [0.5,  1.5]));
               testCase.assertFalse(checklimits(ax, [-1.5, 0.5]));
               testCase.assertFalse(checklimits(ax, [1.5,  0.5]));
          end

          function validHandleValidPoint(testCase)
               fig = testCase.figure();
               ax = axes('Parent', fig, 'xlim', [0 1], 'ylim', [0 1]);

               testCase.assertTrue(checklimits(ax, [0.5, 0.5]));

               % Edge cases
               testCase.assertTrue(checklimits(ax, [0 0]));
               testCase.assertTrue(checklimits(ax, [1 1]));
               testCase.assertTrue(checklimits(ax, [0 1]));
               testCase.assertTrue(checklimits(ax, [1 0]));
          end
     end
end
