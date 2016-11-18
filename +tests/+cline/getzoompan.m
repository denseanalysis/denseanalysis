classdef getzoompan < tests.DENSEtest
    methods (Test)
        function invalidHandle(testCase)
            fig = testCase.figure();
            ax = axes('Parent', fig);

            warnid = 'getzoompan:invalidFigure';
            testCase.assertWarning(@()getzoompan(ax), warnid);
        end

        function testEmpty(testCase)
            testCase.assertEmpty(getzoompan([]));
        end

        function default(testCase)
            tools = getzoompan(testCase.figure());
            testCase.assertNumElements(tools, 3);
            testCase.assertTrue(all(ismember(get(tools, 'type'), {'uipushtool', 'uitoggletool'})));
        end
    end
end
