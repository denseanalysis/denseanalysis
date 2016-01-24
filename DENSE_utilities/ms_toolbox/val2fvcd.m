function rgb = val2fvcd(val,cval,cmap,nanclr)
% rgb = val2fvcd(val,cval,cmap,nanclr)
  
%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
    if nargin<4, nanclr = [0 0 0]; end

    val = double(val);
    vsz = size(val);

    tf = ~isnan(val);
    idx = interp1(cval,1:numel(cval),val(tf),'nearest','extrap');

    R = nanclr(1)*ones(vsz);
    G = nanclr(2)*ones(vsz);
    B = nanclr(3)*ones(vsz);

    R(tf) = cmap(idx,1);
    G(tf) = cmap(idx,2);
    B(tf) = cmap(idx,3);
    rgb = cat(2,R(:),G(:),B(:));


end
