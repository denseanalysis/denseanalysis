function base = basepath(files, base)
    % basepath - Compute the shared base path of the input files
    %
    % USAGE:
    %   base = basepath(files)
    %
    % INPUTS:
    %   files:  [M x 1] Cell Array, Array of absolute or relative
    %           filepaths. If relative filepaths are provided, it is
    %           assumed that all paths are relative to the SAME directory.
    %
    % OUTPUTS:
    %   base:   String, Path that is shared by all files. If no shared path
    %           is found, an empty string is returned.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    if ~exist('base', 'var')
        base = fileparts(files{1});
    elseif isempty(base)
        return
    end

    % Now check the base guess
    pattern = ['^', regexptranslate('escape', base)];
    if any(cellfun(@isempty, regexp(files, pattern)));
        base = basepath(files, fileparts(base));
    end
end
