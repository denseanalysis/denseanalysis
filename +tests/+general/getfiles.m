classdef getfiles < tests.DENSEtest
    methods (Test)
        function emptyInput(testCase)
            files = getfiles();

            % Make sure that these are all files relative to the current
            % path
            testCase.assertClass(files, 'cell');

            exists = cellfun(@(x)exist(x, 'file'), files);
            testCase.assertTrue(all(exists ~= 0));
        end

        function filter(testCase)
            files = getfiles('', ['*.' mexext]);

            exists = cellfun(@(x)exist(x, 'file'), files);
            testCase.assertTrue(all(exists == 3));

            matches = regexp(files, [mexext, '$'], 'match');
            testCase.assertFalse(any(cellfun(@isempty, matches)));
        end

        function absolutepath(testCase)
            files = getfiles('', '*.*', true);

            exists = cellfun(@(x)exist(x, 'file'), files);
            testCase.assertTrue(all(exists ~= 0));

            % Make sure that the path appears at the beginning of all
            pattern = regexptranslate('escape', pwd);

            % Windows file paths are not case sensitive
            if ispc
                matcher = @regexpi;
            else
                matcher = @regexp;
            end
            
            matches = matcher(files, ['^', pattern], 'match');           
            testCase.assertFalse(any(cellfun(@isempty, matches)));
        end

        function relativepath(testCase)
            files = getfiles('', '*.*', false);

            exists = cellfun(@(x)exist(x, 'file'), files);
            testCase.assertTrue(all(exists ~= 0));

            % Make sure that the path appears at the beginning of all
            pattern = regexptranslate('escape', pwd);

            matches = regexp(files, ['^', pattern], 'match');
            testCase.assertTrue(all(cellfun(@isempty, matches)));
        end
    end
end
