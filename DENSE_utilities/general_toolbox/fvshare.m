function fv = fvshare(fv,tol)
%FVSHARE allow shared vertices, eliminating duplicate shared
%   vertices from a face/vertex structure
%
%INPUTS
%   fv.....face/vertices structure with the following fields
%   tol....allowable difference between vertices
%
%OUTPUT
%   fv.....altered structure
%
%USAGE
%   FV = FVSHARE(FV,TOL) eliminates duplicate shared vertices from the
%   face/vertex structure FV.  Duplicate vertices have a euclidean distance
%   in every direction of less than TOL to its matching vertex.

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
%   2008.03     Drew Gilliam
%     --creation

% multiplication factor
fac = 1/tol;

% vertices & faces
v    = fv.vertices;
f    = fv.faces;
fvcd = fv.facevertexcdata;

% unique vertices to round off error
if fac==0
    vround = v;
else
    vround = round(v*fac)/fac;
end
[uvround,idx,map] = unique(vround,'rows');
Nuv = size(uvround,1);

% corresponding unique vertices
uv = v(idx,:);

% new face indices
f(:) = map(f(:));


% eliminate any faces without 3 unique vertices
invalid = f(:,1) == f(:,2) | ...
          f(:,2) == f(:,3) | ...
          f(:,3) == f(:,1);
f = f(~invalid,:);
fvcd = fvcd(~invalid,:);

% save result to original structure
fv.vertices = uv;
fv.faces    = f;
fv.facevertexcdata = fvcd;

return
