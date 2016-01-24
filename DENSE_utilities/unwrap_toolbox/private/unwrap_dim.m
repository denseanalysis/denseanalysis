function p = unwrap_dim(p,dim)

%UNWRAP_DIM unwrap along a single dimension for up to 3D matrices.
%
% code is derived from the MATLAB "unwrap" function, but does not require
% the time consuming error checking and matrix manipulation.
% Algorithm minimizes the incremental phase variation by constraining
% it to the range [-pi,pi]
%
%INPUTS
%   p.....matrix to unwrap (up to 3D)
%   dim...dimension to unwrap (1,2,3)
%
%OUTPUTS
%   p.....unwrapped matrix
%
%NOTES
%   This code is provided as a helper function to the UNWRAP toolbox.
%   For speed, it does not perform ANY error checking, and assumes all
%   inputs are correct.  USE AS YOUR OWN RISK!!

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
%   2007.09     Drew Gilliam
%     --creation, based on "unwrap" function
%   2008.03     Drew Gilliam
%     --modification for speed


% Incremental phase variations
dp = diff(p,1,dim);

% Equivalent phase variations in [-pi,pi)
% Preserve variation sign for pi vs. -pi
% dps = mod(dp+pi,2*pi) - pi; - MOD IS SLOWER
dps = dp - floor((dp+pi)./(2*pi)).*(2*pi);
dps(dps==-pi & dp>0) = pi;

% Incremental phase corrections
% Ignore correction when incr. variation is < CUTOFF=pi
dp_corr = dps - dp;
dp_corr(abs(dp)<pi) = 0;

% Integrate corrections and add to "p" to produce corrected phase values
m = size(p,dim);
switch dim
    case 1, p(2:m,:,:) = p(2:m,:,:) + cumsum(dp_corr,dim);
    case 2, p(:,2:m,:) = p(:,2:m,:) + cumsum(dp_corr,dim);
    case 3, p(:,:,2:m) = p(:,:,2:m) + cumsum(dp_corr,dim);
end

return



%**************************************************************************
% END OF FILE
%**************************************************************************
