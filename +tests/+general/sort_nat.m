classdef sort_nat < tests.DENSEtest
    methods (Test)
        function numbersOnly(testCase)
            input = {'10', '1', '2', '03'};
            exp_indices = [2; 3; 4; 1];
            [res, indices] = sort_nat(input);
            testCase.assertEqual(res, input(exp_indices));
            testCase.assertEqual(indices, exp_indices);
            testCase.assertClass(res, 'cell')
        end

        function numbersInsideStrings(testCase)
            names = {'file1.txt', 'file10.txt', 'file2.txt'};
            exp_indices = [1; 3; 2];

            [res, indices] = sort_nat(names);
            testCase.assertEqual(res, names(exp_indices));
            testCase.assertEqual(indices, exp_indices);
            testCase.assertClass(res, 'cell')
        end

        function manyNumbersInsideString(testCase)
            names = {'file1.2.txt', 'file1.1.txt', 'file10.2.txt', 'file2.txt'};
            exp_indices = [2; 1; 4; 3];

            [res, indices] = sort_nat(names);
            testCase.assertEqual(res, names(exp_indices));
            testCase.assertEqual(indices, exp_indices);
            testCase.assertClass(res, 'cell')
        end

        function empty(testCase)
            [res, indices] = sort_nat({});

            testCase.assertEmpty(res);
            testCase.assertEmpty(indices);
        end
    end
end
