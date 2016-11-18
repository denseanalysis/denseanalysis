classdef iscellstr_recursive < tests.DENSEtest
    methods (Test)
        function basicSuccess(testCase)

            array = {'a', 'b', 'c', 'd'};

            for k = 1:numel(array)
                testCase.assertTrue(iscellstr_recursive(array(k:end)))
            end
        end

        function nonCell(testCase)
            testCase.assertFalse(iscellstr_recursive([1,2,3,4]));
        end

        function basicFailure(testCase)
            testCase.assertFalse(iscellstr_recursive({'a', 'b', 3}));
            testCase.assertFalse(iscellstr_recursive({'a', 2, 3}));
            testCase.assertFalse(iscellstr_recursive({1, 2, 3}));
        end

        function testNestedSuccess(testCase)
            testCase.assertTrue(iscellstr_recursive({{'a', 'b'}}));
        end

        function testNestedFailure(testCase)
            in = {'a', 'b', {1, 'd'}};
            testCase.assertFalse(iscellstr_recursive(in));
        end

        function testNestedEmpty(testCase)
            in = {'a', 'b', {}, {'c', 'd'}};
            testCase.assertTrue(iscellstr_recursive(in));
        end

        function testEmpty(testCase)
            testCase.assertTrue(iscellstr_recursive({}));
        end
    end
end
