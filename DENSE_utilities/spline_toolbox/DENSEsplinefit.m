function spl = DENSEsplinefit(i,j,k,vals)
% spl = DENSEsplinefit(i,j,k,vals)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

% sizes
sz = [numel(i),numel(j),numel(k)];

% splie each frame
data = repmat(struct,[numel(k),1]);
for ki = 1:numel(k)
    tmp = csape({i,j},vals(:,:,ki));
    tags = fieldnames(tmp);
    for ti = 1:numel(tags)
        data(ki).(tags{ti}) = tmp.(tags{ti});
    end
end

spl = struct(...
    'form',     'splinefit2',...
    'breaks',   {{i,j,k}},...
    'data',     data);


end
