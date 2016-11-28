classdef strwcmp < tests.DENSEtest
    methods (Test)
        function testString(testCase)
            testCase.assertTrue(strwcmp('a', 'a'));
            testCase.assertFalse(strwcmp('a', 'b'));
        end

        function testCellArray(testCase)
            testCase.assertEqual(strwcmp({'a', 'b'}, 'a'), [true, false]);
            testCase.assertEqual(strwcmp({'b', 'a'}, 'a'), [false, true]);

            testCase.assertEqual(strwcmp('a', {'a', 'b'}), [true, false]);
            testCase.assertEqual(strwcmp('a', {'b', 'a'}), [false, true]);
        end

        function testWildcard(testCase)
            testCase.assertTrue(strwcmp('a', '*'));
            testCase.assertTrue(strwcmp('ab', '*'));

            testCase.assertTrue(strwcmp('abc', 'a*'));
            testCase.assertTrue(strwcmp('abc', '*c'));
            testCase.assertTrue(strwcmp('abc', '*b*'));

            % Wildcard should match 0-N occurances
            testCase.assertTrue(strwcmp('abcd', '*b*'));
            testCase.assertTrue(strwcmp('abc', '*abc'));
        end

        function testCaseSensitivity(testCase)
            testCase.assertFalse(strwcmp('a', 'A'));
            testCase.assertFalse(strwcmp('A', 'a'));

            testCase.assertEqual(strwcmp({'a', 'b'}, 'A'), [false, false]);
            testCase.assertEqual(strwcmp({'a', 'b'}, 'B'), [false, false]);

            testCase.assertEqual(strwcmp({'A', 'B'}, 'a'), [false, false]);
            testCase.assertEqual(strwcmp({'A', 'B'}, 'b'), [false, false]);

            % Wildcards shouldn't care about case
            testCase.assertTrue(strwcmp('a', '*'));
            testCase.assertTrue(strwcmp('A', '*'));

            testCase.assertTrue(strwcmp('AB', '*B'))
            testCase.assertTrue(strwcmp('aB', '*B'))
        end
    end
end
