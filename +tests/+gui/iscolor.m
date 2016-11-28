classdef iscolor < tests.DENSEtest

    properties (Hidden)
        Characters = {'y', 'm', 'c', 'r', 'g', 'b', 'w', 'k'};
        Colors = {'yellow','magenta','cyan','red','green', 'blue', 'white','black'};
        Numbers = [1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0];
    end

    methods (Test)
        function testValidCharacters(testCase)
            for k = 1:numel(testCase.Characters)
                testCase.assertTrue(iscolor(testCase.Characters{k}));
                testCase.assertTrue(iscolor(upper(testCase.Characters{k})));
            end
        end

        function testValidColors(testCase)
            for k = 1:numel(testCase.Colors)
                testCase.assertTrue(iscolor(testCase.Colors{k}));
                testCase.assertTrue(iscolor(upper(testCase.Characters{k})));
            end
        end

        function testNumericColors(testCase)
            for k = 1:numel(testCase.Colors)
                testCase.assertTrue(iscolor(testCase.Numbers(k,:)));
            end
        end

        function testInvalidNumericColors(testCase)
            % Not 3 values
            testCase.assertFalse(iscolor([1 1]));
            testCase.assertFalse(iscolor([1 1 1 1]));

            % Values < 0 or > 1
            testCase.assertFalse(iscolor([2 2 1]));
            testCase.assertFalse(iscolor([2 2 2]));
            testCase.assertFalse(iscolor([-1 0 0]));
        end
    end
end
