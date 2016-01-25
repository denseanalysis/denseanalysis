function C = path2cell(str)
% C = path2cell(str)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

if ~isempty(str) && str(end)~=ps
    str = [str ps];
end

cdirs = regexp(str, sprintf('[^\\s%s][^%s]*', ps, ps), 'match')';


end
