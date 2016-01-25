function ind = quickfind(tf,idx)
%QUICKFIND search logical matrix in specified order for first "true" value
%   This function is given as an alternative to QUICKFIND_MEX, which is
%   significantly faster.
%
%INPUTS
%   tf..........logical matrix to search
%   idx.........search index order (in MATLAB base-1)
%
%OUTPUT
%   ind.........first "true" index found (in MATLAB base-1)
%
%USAGE
%   ind = quickfind(logical(tf),uint32(idx))
%   search the logical TF in the index order specified by IDX
%   (in MATLAB base-1) for the first "true" value. We return the result
%   as a double in IND. Note the benefits of this function are really
%   evident at large sizes of TF.
%
%NOTES
%   If TF contains all "false" values, IND returns -1.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
%  WRITTEN BY:  Drew Gilliam
%
%  MODIFICATION HISTORY:
%     2008.10   Drew Gilliam
%         --creation

    % check inputs
    if ~islogical(tf) || ~isinteger(idx)
        error(sprintf('%s:inputerror',mfilename),...
            'First input expects logical, second input expects integer.');
    end

    % default output
    ind = -1;

    % search for first "true"
    for k = 1:numel(idx)
        if tf(idx(k))
            ind = double(idx(k));
            return;
        end
    end


end

