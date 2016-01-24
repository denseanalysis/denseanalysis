function tf = checknomex()
%CHECKNOMEX return status of UNWRAPTOOLBOX_NOMEX global flag.
%   unwrapping toolbox helper function.
%
%Returns "true" if UNWRAPTOOLBOX_NOXMEX exists and is equal to "true".
%Returns "false" otherwise.

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2008.12     Drew Gilliam
%     --creation

    global UNWRAPTOOLBOX_NOMEX
    tf = ~isempty(UNWRAPTOOLBOX_NOMEX) && ...
        isequal(UNWRAPTOOLBOX_NOMEX,true);
    clear UNWRAPTOOLBOX_NOMEX

end
