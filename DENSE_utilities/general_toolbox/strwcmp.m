function tf = strwcmp(str,wild)
    %STRWCMP compare string with wildcard ('*') string
    %
    %INPUTS str.......string (or cell array of strings) wild......wildcard
    %       string (or cell array of strings)
    %
    %OUTPUT tf.........logical TRUE if string match, logical FALSE
    %       otherwise
    %
    %USAGE TF = STRWCMP(S,W) searches the string S for the wildcard string
    %W, returning TRUE if they are identical and FALSE otherwise.
    %
    %   TF = STRCMP(S,WC), compares string S to each element of cell array
    %   WC, containing wildcard strings. The function returns TF, a logical
    %   array the same size as WC, containing TRUE for elements of WC that
    %   are a match, and FALSE for elements that are not a match.
    %
    %   TF = STRCMP(SC,W), compares the cell array of strings SC to the
    %   wildcard string W. The function retures TF, a logical array the
    %   same size as SC, containing TRUE for elements of SC that are a
    %   match, and FALSE for elements that are not a match.
    %
    %   TF = STRCMP(SC,WC) compares each element of SC to WC, where SC and
    %   WC are equal-sized cell array of strings.  The function returns TF,
    %   a logical array the same size as SC or WC, containing TRUE for
    %   elements of SC and WC that are a match, and FALSE for elements that
    %   are not a match.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    % correct number of arguments
    error(nargchk(2,2,nargin));

    % check for empties
    if iscell(str)
        for k = 1:numel(str)
            if isempty(str{k}), str{k} = ''; end
        end
    else
        if isempty(str), str = ''; end
    end

    if iscell(wild)
        for k = 1:numel(wild)
            if isempty(wild{k}), wild{k} = ''; end
        end
    else
        if isempty(wild), wild = ''; end
    end

    % input check
    if ~((ischar(str) && ischar(wild)) || ...
        (iscell(str) && ischar(wild)) || ...
        (ischar(str) && iscell(wild)) || ...
        (iscell(str) && iscell(wild) && numel(str)==numel(wild)))
        error(sprintf('%s:InputSizeMismatch',mfilename),...
            'Inputs must be the same size or either one can be a scalar.');
    end

    % ensure cell
    if ~iscell(str)
        str = {str};
    end

    % translate wildcard string to regular expression
    wild = regexptranslate('wildcard',wild);

    % append regular expressions for exact match
    if iscell(wild)
        wild = cellfun(@(x)['^' x '$'],wild,'uniformoutput',0);
    else
        wild = ['^' wild '$'];
    end

    % test wildcards
    idx = regexp(str,wild);

    % true/false
    tf = false(size(idx));
    for k = 1:numel(idx)
        tf(k) = ~isempty(idx{k});
    end
end
