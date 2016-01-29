function tf = iscellstr_recursive(s)

%ISCELLSTR_RECURSIVE recursively test an array of cells for strings
%
%INPUTS
%   s......cell array
%
%OUTPUTS
%   tf.....true/false value
%
%USAGE
%
%   TF = ISCELLSTR_RECURSIVE(S) tests if the cell array S contains only
%   strings, returning a logical TF value. Unlike ISCELLSTR, this function
%   recursively tests the entire depth of S, ensuring that each element
%   contains only strings. To elaborate, consider the following example:
%       A = {'hello',{'hello','world'}};
%       tf1 = iscellstr(A);
%       tf2 = iscellstr_recursive(A);
%   TF1 would equal FALSE, as A{2} is a cell.
%   TF2 would indicate TRUE, as A{2} is another cellstr.
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

    % non-cells are automatically NOT cellstr
    if ~iscell(s)
        tf = false;

    % recursive check for cells filled with characters
    else
        tf = true;
        for k = 1:numel(s)
            if ischar(s{k})
                continue
            elseif iscell(s{k})
                tf = iscellstr_recursive(s{k});
            else
                tf = false;
                break;
            end
        end
    end

end
