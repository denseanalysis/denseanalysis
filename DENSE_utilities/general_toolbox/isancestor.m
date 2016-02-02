function tf = isancestor(hA, hB)
%ISANCESTOR determines if handle hB is an ancestor of handle hA.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

% WRITTEN BY: Drew Gilliam
% MODIFICATION HISTORY
%   2009.04     Drew Gilliam
%       --creation

    if ~isscalar(hA) || ~ishghandle(hA) || ~isscalar(hB) || ~ishghandle(hB)
        error(sprintf('%s:invalidInputs', mfilename),...
            'Inputs must be valid handles.');
    end

    hhier = hierarchy(hA, 'root');

    tf = ismember(hB, hhier);
end
