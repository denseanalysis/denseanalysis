classdef clr2num < tests.DENSEtest

    properties (Hidden)
        Characters = {'y', 'm', 'c', 'r', 'g', 'b', 'w', 'k'};
        Colors = {'yellow','magenta','cyan','red','green', 'blue', 'white','black'};
        Numbers = [1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0];
    end

    methods (Test)
        function testSingleLetters(testCase)
            for k = 1:numel(testCase.Characters)
                num = clr2num(testCase.Characters{k});
                testCase.assertEqual(num(:), testCase.Numbers(k,:)');
            end
        end

        function testUpperSingleLetters(testCase)
            for k = 1:numel(testCase.Characters)
                num = clr2num(upper(testCase.Characters{k}));
                testCase.assertEqual(num(:), testCase.Numbers(k,:)');
            end
        end

        function testFullWords(testCase)
            for k = 1:numel(testCase.Colors)
                num = clr2num(testCase.Colors{k});
                testCase.assertEqual(num(:), testCase.Numbers(k,:)');
            end
        end

        function testUpperFullWords(testCase)
            for k = 1:numel(testCase.Colors)
                num = clr2num(upper(testCase.Colors{k}));
                testCase.assertEqual(num(:), testCase.Numbers(k,:)');
            end
        end

        function testNumbers(testCase)
            for k = 1:numel(testCase.Colors)
                num = clr2num(testCase.Numbers(k,:));
                testCase.assertEqual(num(:), testCase.Numbers(k,:)');
            end
        end

        function testInvalidColor(testCase)
                errid = 'clr2num:invalidColor';
                testCase.assertError(@()clr2num('a'), errid);
                testCase.assertError(@()clr2num('color'), errid);
                testCase.assertError(@()clr2num({}), errid);
        end
    end
end
