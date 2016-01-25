function tf = isemptystruct(s,tags)

%ISEQUALSTRUCT check if some fields of a single structure are empty
%
%INPUTS
%   s......input structure
%   tags...cellstr fieldnames
%
%OUTPUTS
%   tf.....logical scalar indicating empty
%
%USAGE
%
%   TF = ISEMPTYSTRUCT(S,TAGS) checks the if the TAGS fields of the
%   structure S are empty. Note that if any field does not exist, the field
%   is considered empty and (TF==true).
%
%   TF = ISEMPTYSTRUCT(S) is the same as ISEMPTYSTRUCT(S,FIELDNAMES(S))
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


    % default inputs
    if isempty(s), s = struct([]); end
    if nargin < 2 || isempty(tags), tags = fieldnames(s); end

    % make string input into CELLSTR
    if ischar(tags), tags = {tags}; end

    % test for valid inputs
    if ~isstruct(s) || numel(s)>1
        error(sprintf('%s:invalidInput',mfilename),...
            'Input must be single structure.');
    elseif ~iscellstr(tags)
        error(sprintf('%s:invalidInput',mfilename),...
                'Fieldnames must be single string or CELLSTR.');
    end

    % test for empty input
    if isempty(s)
        tf = true;
        return
    end

    % test for field existance
    % (a field that does not exist would be "empty")
    tf = any(~isfield(s,tags));
    if tf, return; end

    % test for actual empty field
    for ti = 1:numel(tags)
        tf = isempty(s.(tags{ti}));
        if ~tf, break; end
    end

end
