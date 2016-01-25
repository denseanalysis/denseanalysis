function tf = isequalstruct(a,b,tags)

%ISEQUALSTRUCT check if some fields of two structures are equal
%
%INPUTS
%   a/b....structures for comparision
%   tags...cellstr fieldnames for comparison (optional)
%
%OUTPUTS
%   tf.....logical scalar indicating equality
%
%USAGE
%
%   TF = ISEQUALSTRCUT(A,B,TAGS) checks the equality of the structures
%   A and B based on certain fields specified by TAGS. In order for the
%   function to return true:
%     • ISFIELD(A,TAGS) must equal ISFIELD(B,TAGS)
%     • For those fields that do exist in both structures,
%       A and B must contain the same values within those fields.
%
%   TF = ISEQUALSTRUCT(A,B) is equivalent to ISEQUAL(A,B)
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation


    % check for valid input structures
    if ~isstruct(a) || ~isstruct(b) || numel(a)~=1 || numel(b)~=1
        error(sprintf('%s:invalidInput',mfilename),...
            'Inputs ''a'' and ''b'' must be structures with numel==1.');
    end

    % no 'tags' input -> standard ISEQUAL
    if nargin < 3 || isempty(tags)
        tf = isequal(a,b);
        return

    % check cell input
    else
        if ischar(tags), tags = {tags}; end
        if ~iscellstr(tags)
            error(sprintf('%s:invalidInput',mfilename),...
                '''tags'' must be a valid cell array of strings.');
        end
    end

    % default output
    tf = false;

    % check that tag existance matches
    tfa = isfield(a,tags);
    tfb = isfield(b,tags);
    if ~all(tfa == tfb)
        return
    end

    % check valid tags
    tags = tags(tfa);
    for ti = 1:numel(tags)
        if ~isequal(a.(tags{ti}),b.(tags{ti}))
            return
        end
    end

    % return match
    tf = true;

end
