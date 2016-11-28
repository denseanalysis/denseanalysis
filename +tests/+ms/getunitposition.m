classdef getunitposition < tests.DENSEtest
    methods (Test)
        function testDirectSibling(testCase)
            fig = testCase.figure('Units', 'pixels');
            ax = axes('Parent', fig);

            % Now set the figure position to a known place
            norm_position = [0 0 0.5 0.5];
            set(ax, 'Units', 'norm', 'Position', norm_position);

            % First make sure that if we get the same result
            newpos = getunitposition(ax, 'norm');
            testCase.assertEqual(newpos, norm_position);

            % Now get the position in pixels
            figpos = get(fig, 'Position');
            expected = [1 1 figpos(3:4) .* norm_position(3:4)];

            newpos = getunitposition(ax, 'pixels');
            testCase.assertEqual(newpos, expected);
        end

        function testRecursive(testCase)
            fig = testCase.figure('Units', 'pixels');
            panel = uipanel('Parent',   fig, ...
                            'Units',    'norm', ...
                            'Position', [0.5 0.5 0.5 0.5]);

            rel_norm_pos = [0 0 0.5 0.5];

            ax = axes('Parent',     panel, ...
                      'Units',      'norm', ...
                      'Position',   rel_norm_pos);

            % Not sure if this is correct, I really think that it should be
            % [0.5 0.5 0.25 0.25]
            abs_norm_pos = [0.5 0.5 0.5 0.5];

            testCase.assertEqual(getunitposition(ax, 'norm', false), rel_norm_pos);
            testCase.assertEqual(getunitposition(ax, 'norm', true), abs_norm_pos);

            % Now check for pixels
            figpos = get(fig, 'Position');

            expected = [figpos(3:4), figpos(3:4)] .* [0.5 0.5 0.25 0.25];

            % Account for pixels being 1-based
            expected = expected + [2 2 -2 -2];
            testCase.assertEqual(getunitposition(ax, 'pixel', true), expected);
        end
    end
end
