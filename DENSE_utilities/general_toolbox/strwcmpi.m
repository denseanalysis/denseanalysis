function tf = strwcmpi(str,wild)
%STRCMPI compare string with wildcard ('*') string, ignoring case.
%   See STRCMP for more information.

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
%   2008.10     Drew Gilliam
%       --creation

% call regular string wildcard compare with lowered arguments
tf = strwcmp(lower(str),lower(wild));

end
