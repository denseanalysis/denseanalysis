function [b,m,n] = unique_nat(a,varargin)

%UNIQUE_NAT naturally sorted unique strings from cell array of strings
%   This function has the same inputs and outputs as UNIQUE, however
%   the output B is naturally ordered.

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

    % check for valid cell vector of strings
    if ~iscellstr(a) || ~isvector(a)
        error(sprintf('%s:invalidInput',mfilename),...
            'UNIQUE_MAT accepts only an [Nx1] cell vector of strings');
    end

    % unique values
    [b,m,n] = unique(a(:),varargin{:});

    % natural sort
    [b,order] = sort_nat(b);

    % update m/n
    [tmp,idx] = sort(order);
    m(:) = m(order);
    n(:) = idx(n);
end
