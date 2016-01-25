function J = imtranslate(I,V)

%IMTRANSLATE translate image
%
%INPUTS
%   I.......input image         (MxN)
%   V.......translation vector  (1x2)
%
%OUTPUT
%   J.......output image        (MxN)
%
%USAGE
%
%   J = IMTRANSLATE(I,V) translates the input image I by V(1) rows and V(2)
%   columns, and outputs the result in J.  Note, we use direct assignment
%   as the TRANSLATE/IMDILATE method discussed in the MATLAB help file is
%   much, much slower.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2006.06     Drew Gilliam
%       --creation

% original method discussed in help file, much slower
% se = translate(strel(1), -shft(k,:));
% J  = imdilate(I,se);


% initialize output
Isz = size(I);
J = zeros(Isz,class(I));

% if no shift, quick output
if isempty(I) || all(V == 0)
    J = I;
    return
end

% determine shift indices
if V(1) < 0
    rA = 1-V(1) : Isz(1);
    rB = 1 : Isz(1)+V(1);
else
    rA = 1 : Isz(1)-V(1);
    rB = 1+V(1) : Isz(1);
end

if V(2) < 0
    cA = 1-V(2) : Isz(2);
    cB = 1 : Isz(2)+V(2);
else
    cA = 1 : Isz(2)-V(2);
    cB = 1+V(2) : Isz(2);
end

% shift image
J(rB,cB,:) = I(rA,cA,:);

return



%**************************************************************************
% END OF FILE
%**************************************************************************
