function p = unwrap_2element(p)

%UNWRAP_2ELEMENT unwrap 2 element vecotr helper function
%
% code is derived from the MATLAB "unwrap" function, but does not require
% the time consuming error checking and matrix manipulation.
% Algorithm minimizes the incremental phase variation by constraining
% it to the range [-pi,pi]
%
%INPUTS
%   p.....2-element vector to unwrap
%
%OUTPUTS
%   p.....unwrapped vector
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

% Incremental phase variation
dp  = p(2)-p(1);

% Equivalent phase variations in [-pi,pi)
% Preserve variation sign for pi vs. -pi
% dps = mod(dp+pi,2*pi) - pi; % MOD IS SLOWER
dps = dp - floor((dp+pi)./(2*pi)).*(2*pi);
if dps==-pi && dp>0, dps = pi; end

% Incremental phase corrections
% Ignore correction when incr. variation is < CUTOFF == pi
dp_corr = dps - dp;
if abs(dp)<pi, dp_corr = 0; end

% correct phase
p(2) = p(2) + dp_corr;

return



%**************************************************************************
% END OF FILE
%**************************************************************************
