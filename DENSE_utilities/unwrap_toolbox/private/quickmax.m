function [val,ind] = quickmax(matrix,mask)
%QUICKMAX find the value/index of maximum value in a given matrix
%   within the specified mask.  This function is given as an alternative
%   to QUICKMAX_MEX, which is significantly faster.
%
%INPUTS
%   matrix......double matrix to search
%   mask........logical mask of valid search space
%
%OUTPUT
%   val.........1st maximum value
%   ind.........1st maximum index
%
%USAGE
%   [VAL,IND] = QUICKMAX(MATRIX,MASK)
%   search MATRIX at all "true" locations in MASK for the maximum value.
%   The max-value is returned as a double in VAL, and the max-index
%   (in MATLAB base-1) is returned as a double in IND.
%
%   If no maximum is found (i.e. all MASK values are "false"
%
%NOTES
%   If no maximum is found (i.e. MASK contains no "true" values, or
%   MATRIX consists entirely of -Inf values), IND returns -1.

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
%  WRITTEN BY:  Drew Gilliam
%
%  MODIFICATION HISTORY:
%     2008.10   Drew Gilliam
%         --creation

    % check inputs
    if ~islogical(mask)
        error(sprintf('%s:inputerror',mfilename),...
            'Second input must be logical');
    end

    if numel(matrix) ~= numel(mask)
        error(sprintf('%s:inputerror',mfilename),...
            'MATRIX and MASK must be of the same size.');
    end

    % default outputs
    val = -Inf;
    ind = -1;

    % search matrix for maximum value within mask
    for k = 1:numel(matrix)
        if mask(k) && matrix(k) > val
            val = matrix(k);
            ind = k;
        end
    end


end
