function iptremovecallback_mod(h, callback, id)

% This function is a slightly modified version of IPTREMOVECALLBACK,
% corresponding to the modified file IPTADDCALLBACK_MOD

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
error(nargchk(3, 3, nargin, 'struct'));

if ishandle(h)
    cbFun = get(h, callback);
    if isa(cbFun, 'function_handle') && ...
            strcmp(func2str(cbFun), 'iptaddcallback_mod/callbackProcessor')
        cbFun('delete', id);
    end
end

