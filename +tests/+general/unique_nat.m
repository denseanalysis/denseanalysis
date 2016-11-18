classdef unique_nat < tests.DENSEtest
    methods (Test)

        function alreadyUnique(testCase)
            in = {'1'; '10'; '02'; '3'};
            indices = [1; 3; 4; 2];

            [b,m,n] = unique_nat(in);

            testCase.assertEqual(b, in(indices));
            [~, expected] = ismember(b, in);
            testCase.assertEqual(m, expected);
            [~, expected] = ismember(in, b);
            testCase.assertEqual(n, expected);
        end

        function nonUnique(testCase)
            in = {'1'; '10'; '02'; '3'; '1'; '3'};
            indices = [1; 3; 4; 2];

            [b,m,n] = unique_nat(in);

            testCase.assertEqual(b, in(indices));
            [~, expected] = ismember(b, in);
            testCase.assertEqual(m, expected);
            [~, expected] = ismember(in, b);
            testCase.assertEqual(n, expected);
        end

        function nonCell(testCase)
            testCase.assertError(@()unique_nat('1'), 'unique_nat:invalidInput');
        end
    end
end
