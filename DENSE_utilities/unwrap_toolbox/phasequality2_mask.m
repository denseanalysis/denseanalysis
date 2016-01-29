function qual = phasequality2_mask(phs, pxsz, mask, conn)
%PHASEQUALITY2_MASK determine phase quality of a 2D phase image, as a
%   weighted sum of the partial derivative local standard deviations.
%
%COMPARISON TO PHASEQUALITY2
%   This function is derived from PHASEQUALITY2.  Differences include:
%   --true phase quality masking, only including those pixels within the
%     mask in the phase quality calculation
%   --different pixel connectivity conditions, considering 4-connected or
%     8-connected neighbors in the phase quality calcluation
%
%REFERENCE
%   Quality-guided path following phase unwrapping:
%   D. C. Ghiglia and M. D. Pritt, Two-Dimensional Phase Unwrapping:
%   Theory, Algorithms and Software. New York: Wiley-Interscience, 1998.
%
%   Repeated in:
%   B. S. Spottiswoode, X. Zhong, A. T. Hess, C. M. Kramer,
%   E. M. Meintjes, B. M. Mayosi, and F. H. Epstein,
%   "Tracking Myocardial Motion From Cine DENSE Images Using
%   Spatiotemporal Phase Unwrapping and Temporal Fitting,"
%   Medical Imaging, IEEE Transactions on, vol. 26, pp. 15, 2007.
%
%INPUTS
%   phs.....phase image                 [MxN]
%   pxsz....pixel size (optional)       1x2 [isz, jsz]
%   mask....mask to measure (optional)  [MxN] logical
%   conn....connectivity (optional)     scalar, [4|8]
%
%DEFAULT INPUTS
%   mask....true(image_size)
%   pxsz....[1 1]
%   conn....4
%
%OUTPUT
%   qual....phase quality on [0,1]      [MxN]
%
%USAGE
%   QUAL = PHASEQUALITY2_MASK(PHS) measures the phase quality of the 2D
%   phase PHS, returning the result in QUAL.  We first calculate the
%   locally unwrapped phase difference between each pixel and its
%   4-connected neighbors.  We then calculate the weighted variance
%   of these locally unwrapped phase differences, favoring closer neighbors
%   with higher weights.  Phase quality is defined as:
%      qual(i,j) = exp(-weighted_phase_variance(i,j));
%   Phase quality ranges between 0 (poor) and 1 (good).
%
%   QUAL = PHASEQUALITY2_MASK(PHS,PXSZ,...) defines the distance between
%   adjacent pixels, affecting the weighting of the phase differences.
%
%   QUAL = PHASEQUALITY2_MASK(...,MASK,...) computes phase quality using
%   only those pixels where mask==true.
%
%   QUAL = PHASEQUALITY2_MASK(...,CONN) considers either a 4-connected or
%   8-connected neighborhood during the phase quality calculation.
%   In the 8-connected condition, immediately adjacent neighbors are
%   favored over diagonally adjacent neighbors in the weighting scheme.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2013.03     Drew Gilliam
%     --created (derived from PHASEQUALITY2)



    %% SETUP

    % check number of inputs
    narginchk(1, 4);

    % check input size
    if ndims(phs) ~= 2 || any(size(phs)<3)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Phase imagery must be a 2D matrix, 3x3 or larger.');
    end

    % pixel size input
    if nargin < 2 || isempty(pxsz), pxsz = [1 1]; end
    if numel(pxsz) ~= 2
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Pixel size must be 1x2 vector.');
    end

    % mask input
    if nargin < 3 || isempty(mask)
        mask = [];
    else
        if ndims(mask) ~= 2 || any(size(phs) ~= size(mask))
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'Phase & mask must be of same size');
        end
    end

    % connectivity size input
    if nargin < 4 || isempty(conn), conn = 4; end
    if ~isnumeric(conn) || ~isscalar(conn) || ~any(conn==[4 8])
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Connectivity accepts [4|8].');
    end


    %% ANALYSIS

    % volume size
    sz = size(phs);

    % search kernel (based on connectivity request)
    if conn==4
        h = [0 1 0; 1 0 1; 0 1 0];
    else
        h = [1 1 1; 1 0 1; 1 1 1];
    end

    % neighborhood index offsets
    [i,j] = find(h==1);
    nhood = [i(:),j(:)] - 2;

    % distance multiplier: favor closer neighbors
    weight = bsxfun(@times,nhood,pxsz([2 1]));
    weight = 1./sqrt(sum(weight.^2,2));

    % voxel indices in mask
    if isempty(mask)
        ind = 1:prod(sz);
    else
        ind = find(mask);
    end
    ind = ind(:);

    % voxel coordinates
    [I,J] = ind2sub(sz,ind);

    % number of analysis points & neighbors
    Npts = numel(ind);
    Nngh = size(nhood,1);

    % gradients & distance weights
    G = zeros(Npts,Nngh);
    W = zeros(Npts,Nngh);

    for n = 1:Nngh
        In = I - nhood(n,1);
        Jn = J - nhood(n,2);
        indn = In + sz(1)*(Jn-1);

        tf = 1<=In & In<=sz(1) ...
           & 1<=Jn & Jn<=sz(2);
        tf(tf) = mask(indn(tf));

        G(tf,n) = phs(indn(tf)) - phs(ind(tf));
        W(tf,n) = weight(n);
    end

    % locally unwrapped gradient
    G = mod(G+pi,2*pi) - pi;

    % normalized weights
    W = bsxfun(@rdivide,W,sum(W,2));

    % weighted average of gradients
    Gmean = sum(W.*G,2);

    % weighted variance of gradients
    G = bsxfun(@minus,G,Gmean);
    Gvar = sum(W.*(G.*G),2);

    % phase quality
    qual = NaN(sz);
    qual(mask) = exp(-sqrt(Gvar));


end



%**************************************************************************
% END OF FILE
%**************************************************************************
