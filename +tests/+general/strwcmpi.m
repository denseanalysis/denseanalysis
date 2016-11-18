classdef strwcmpi < tests.DENSEtest
    methods (Test)
        function testString(testCase)
            testCase.assertTrue(strwcmpi('a', 'a'));
            testCase.assertTrue(strwcmpi('a', 'A'));
            testCase.assertTrue(strwcmpi('A', 'a'));
        end

        function testCellArray(testCase)
            testCase.assertEqual(strwcmpi({'a', 'b'}, 'A'), [true, false]);
            testCase.assertEqual(strwcmpi({'a', 'b'}, 'B'), [false, true]);

            testCase.assertEqual(strwcmpi({'A', 'B'}, 'a'), [true, false]);
            testCase.assertEqual(strwcmpi({'A', 'B'}, 'b'), [false, true]);
        end

        function testWildcard(testCase)
            % Wildcards shouldn't care about case
            testCase.assertTrue(strwcmpi('a', '*'));
            testCase.assertTrue(strwcmpi('A', '*'));

            testCase.assertTrue(strwcmpi('AB', '*B'))
            testCase.assertTrue(strwcmpi('aB', '*B'))
        end
    end
end
