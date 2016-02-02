function qual = phasequality2(phs, pxsz, mask)
%PHASEQUALITY2 determine phase quality of a 2D phase image, as a
%   weighted sum of the partial derivative local standard deviations.
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
%   pxsz....pixel size (optional)       (1x2 [isz, jsz])
%   mask....mask to measure (optional)  [MxN] logical)
%
%OUTPUT
%   pxsz....[1 1] (isotropic condition)
%   qual....phase quality on [0,1]      [MxN]
%
%USAGE
%   QUAL = PHASEQUALITY2(PHS) measures the phase quality of the 2D phase
%   image  PHS, returning the result in QUAL. We first calculate the
%   standard deviation of the locally unwrapped phase in a 4-connected
%   neighborhood for each spatial direction (i,j). At image edges and
%   corners, we consider the available neighbors within this 4-connected
%   region.  We define the total deviation as the weighted sum of
%   these two directional deviations, with weights determined according
%   to the pixel size. The phase quality at a point (i,j) is defined as:
%       qual(i,j) = exp(-(a*i_stddev(i,j) + b*j_stddev(i,j)))
%   Phase quality ranges between 0 (poor) and 1 (good).
%
%   QUAL = PHASEQUALITY2(PHS,PXSZ,...) defines the weighted sum discussed
%   above. These directional weights are proportional to 1/PXSZ(n), with
%   the sum of weights equal to 1.
%
%   QUAL = PHASEQUALITY2(...,MASK) computes phase quality in the 2D
%   rectangluar region containing all points where mask==1.  This is not
%   truely masking the phase quality calculation, merely reducing
%   execution time using a smaller region of interest.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2007.09     Drew Gilliam
%     --creation of "phasequality" function, derived from
%       "PhaseDerivativeVariance" function by Bruce Spottiswoode
%       (created 2004.10, last modified 2004.12)
%   2008.03     Drew Gilliam
%     --renamed to "phasequality2"
%     --general update
%     --added edge/corner functionality
%   2008.10     Drew Gilliam
%     --error check update



    %% SETUP

    % check number of inputs
    narginchk(1, 3);

    % check input size
    if ~ismatrix(phs) || any(size(phs)<3)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Phase imagery must be a 2D matrix, 3x3 or larger.');
    end

    % voxel size input
    if nargin < 2 || isempty(pxsz), pxsz = [1 1]; end
    if numel(pxsz) ~= 2
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Pixel size must be 1x2 vector.');
    end

    % mask input
    if nargin < 3 || isempty(mask)
        mask = [];
    else
        if ~ismatrix(mask) || any(size(phs) ~= size(mask))
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'Phase & mask must be of same size');
        end
    end


    % crop image to mask extents to save computation time
    if ~isempty(mask)
        sz = size(mask);

        % mask coordinates & limits
        brdr = 2;
        [i,j] = find(mask);
        ilmt = [min(i)-brdr, max(i)+brdr];
        jlmt = [min(j)-brdr, max(j)+brdr];

        % saturate coordinates
        ilmt(ilmt<1)     = 1;
        ilmt(ilmt>sz(1)) = sz(1);
        jlmt(jlmt<1)     = 1;
        jlmt(jlmt>sz(2)) = sz(2);

        % crop image
        phs = phs(ilmt(1):ilmt(2),jlmt(1):jlmt(2));
    end

    % image size
    Isz = size(phs);



    %% directional partial derivatives of the locally unwrapped phase
    di = zeros(Isz);
    dj = di;

    for dim = 1:2
        dimN = Isz(dim);

        idx = [1, 1:dimN-1; ...
               2:dimN, dimN]';
        denom = 3*ones(dimN,1);
        denom([1 end]) = 2;

        for n = 1:dimN
            switch dim
                case 1
                    q = unwrap_dim(phs(idx(n,:),:),dim);
                    di(n,:) = diff(q,1,dim)./denom(n);

    %                 q = phs(idx(n,:),:);
    %                 di(n,:) = (mod(diff(q,1,dim)+pi,2*pi)-pi) ./ denom(n);

                case 2
                    q = unwrap_dim(phs(:,idx(n,:)),dim);
                    dj(:,n) = diff(q,1,dim)./denom(n);

    %                 q = phs(:,idx(n,:));
    %                 dj(:,n) = (mod(diff(q,1,dim)+pi,2*pi)-pi) ./ denom(n);

            end
        end

    end



    %% PHASE QUALITY & RETURN

    % local population variance of partial derivatives
    ivar = localvar(di);
    jvar = localvar(dj);

    % total deviation of partial derivatives
    w = 1./pxsz(:);
    w = w/sum(w(:));
    totalvar = w(1)*sqrt(ivar) + ...
               w(2)*sqrt(jvar);

    % phase quality
    qual = exp(-totalvar);

    % pad image to original size, if necessary
    if ~isempty(mask)
        tmp = zeros(size(mask));
        tmp(ilmt(1):ilmt(2),jlmt(1):jlmt(2)) = qual;
        qual = tmp;
    end


end



%% 2D LOCAL VARIANCE (4-connected region)
function lvar = localvar(I)
% local variance within a 4-connected region (for a total of 5 elements)
% At the edges, we use the valid elements within this neighborhood.
% NOTE this is the population variance and we divide by 5 (Nelements),
% rather than the unbiased sample estimator where we would divide
% by 4 (Nelements-1)

    % input size
    Isz = size(I);

    % number of valid elements within 7 element neighborhood
    N = 5*ones(Isz);
    N([1 end],:) = 4;
    N(:,[1 end]) = 4;
    N([1 end],[1 end]) = 3;

    % pad by one element
    Ipad = zeros(Isz+2);
    Ipad(2:end-1,2:end-1) = I;

    % center pixel indices (in padded array coordinates)
    irng = (1:Isz(1)) + 1;
    jrng = (1:Isz(2)) + 1;

    % local partial derivatives - note edge values are zero, eliminating
    % these locations from the local mean calculation
    dC  = Ipad(irng,   jrng);
    dI0 = Ipad(irng-1, jrng);
    dI1 = Ipad(irng+1, jrng);
    dJ0 = Ipad(irng,   jrng-1);
    dJ1 = Ipad(irng,   jrng+1);

    % local mean
    lmean = (dC+dI0+dI1+dJ0+dJ1)./N;

    % replace edge values with their local mean, eliminating
    % these values from the local variance calculation
    dI0(1,:)   = lmean(1,:);
    dI1(end,:) = lmean(end,:);
    dJ0(:,1)   = lmean(:,1);
    dJ1(:,end) = lmean(:,end);

    % local variance
    lvar =(dC  - lmean).*(dC  - lmean) + ...
          (dI0 - lmean).*(dI0 - lmean) + ...
          (dI1 - lmean).*(dI1 - lmean) + ...
          (dJ0 - lmean).*(dJ0 - lmean) + ...
          (dJ1 - lmean).*(dJ1 - lmean);
    lvar = lvar./N;

end


%**************************************************************************
% END OF FILE
%**************************************************************************
