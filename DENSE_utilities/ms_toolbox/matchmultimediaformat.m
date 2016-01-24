% match an extension to its format

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

function idx = matchmultimediaformat(ext,formats)
    if isempty(ext) || ~ischar(ext)
        idx = [];
    else
        allext = {formats.Extension};
        tf = cellfun(@(ae)any(strcmpi(ext,ae)),allext);
        if any(tf)
            idx = find(tf,1,'first');
        else
            idx = [];
        end
    end
end
