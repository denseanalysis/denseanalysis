function [V,F] = rectmesh(X,Y)

%RECTMESH determine rectangular mesh vertices/faces from X/Y pairs
%
%INPUTS
%   X/Y.....2D x/y coordinate matrices (as you would supply to MESH)
%
%OUTPUTS
%   V/F.....vertices/faces suitable for PATCH command
%
%USAGE
%
%   [V,F] = RECTMESH(X,Y) determines the vertiex/face data V and F
%   (respectively) for the input matrices X/Y without creating any
%   graphics. V/F are suitable for input to the PATCH command.
%

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
%   2008        Drew Gilliam
%     --creation
%   2009.02     Drew Gilliam
%     --modification, returning vertices/faces
%     --additional error checking & comments

    % input sizes
    Xsz = size(X);
    Ysz = size(Y);
    if ~isnumeric(X) || ~isnumeric(Y) || ...
       ndims(X)~=2 || ndims(Y)~=2 || any(Xsz ~= Ysz) || ...
       any(Xsz==1)

        error(sprintf('%s:invalidInputs',mfilename),...
            'X & Y must be 2D matrices of the same size');
    end

    % vertices
    V = [X(:) Y(:)];

    % face indices
    IND = reshape(1:prod(Xsz),Xsz);
    IND = IND(1:end-1,1:end-1);
    IND = IND(:);

    % face definition
    F = [IND, IND+1, IND+Xsz(1)+1, IND+Xsz(1)];

end
