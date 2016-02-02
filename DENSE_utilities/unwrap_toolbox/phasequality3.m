function qual = phasequality3(phs, vxsz, mask)

%PHASEQUALITY3 determine phase quality of a 3D phase volume, as a
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
%   phs.....phase matrix                [Ni x Nj x Nk]
%   vxsz....voxel size (optional)       1x3 [isz, jsz, ksz]
%   mask....mask to measure (optional)  [Ni x Nj x Nk] logical
%
%OUTPUT
%   vxsz....[1 1 1] (isotropic condition)
%   qual....phase quality on [0,1]      [Ni x Nj x Nk]
%
%USAGE
%   QUAL = PHASEQUALITY3(PHS) measures the phase quality of the 3D phase
%   volume PHS, returning the result in QUAL. We first calculate the
%   standard deviation of the locally unwrapped phase in a 6-connected
%   neighborhood for each spatial direction (i,j,k). At volume edges and
%   corners, we consider the available neighbors within this 6-connected
%   region.  We define the total deviation as the weighted sum of
%   these three directional deviations, with weights determined according
%   to the voxel size. The phase quality is defined as:
%       qual(i,j,k) = exp(-(...
%           a*i_stddev(i,j,k) + b*j_stddev(i,j,k) + c*k_stddev(i,j,k)))
%   Phase quality ranges between 0 (poor) and 1 (good).
%
%   QUAL = PHASEQUALITY3(PHS,VXSZ,...) defines the weighted sum discussed
%   above. These directional weights are proportional to 1/VXSZ(n), with
%   the sum of weights equal to 1.
%
%   QUAL = PHASEQUALITY3(...,MASK) computes phase quality only where the 3D
%   MASK is equal to 1.  This is not truely masking the phase quality
%   calculation, merely reducing execution time using a smaller
%   region of interest.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2008.03     Drew Gilliam
%     --creation, based on "phasequality2"
%   2008.11     Drew Gilliam
%     --error check update



    %% SETUP

    % check number of inputs
    narginchk(1, 3);

    % check input size
    if ndims(phs) ~= 3 || any(size(phs)<3)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Phase input must be a 3D matrix, 3x3x3 or larger.');
    end

    % voxel size input
    if nargin < 2 || isempty(vxsz), vxsz = [1 1 1]; end
    if numel(vxsz) ~= 3
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Voxel size must be 1x3 vector.');
    end

    % mask input
    if nargin < 3 || isempty(mask)
        mask = [];
    else
        if ndims(mask) ~= 3 || any(size(phs) ~= size(mask))
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'Phase volume & mask must be of same size');
        end
    end


    % crop image to mask extents to save computation time
    if ~isempty(mask)
        sz = size(mask);

        % mask coordinates & limits
        ind = find(mask);
        [i,j,k] = ind2sub(sz,ind);
        ilmt = [min(i)-1, max(i)+1];
        jlmt = [min(j)-1, max(j)+1];
        klmt = [min(k)-1, max(k)+1];

        % saturate coordinates
        ilmt(ilmt<1)     = 1;
        ilmt(ilmt>sz(1)) = sz(1);
        jlmt(jlmt<1)     = 1;
        jlmt(jlmt>sz(2)) = sz(2);
        klmt(klmt<1)     = 1;
        klmt(klmt>sz(3)) = sz(3);

        % crop image
        phs = phs(ilmt(1):ilmt(2),jlmt(1):jlmt(2),klmt(1):klmt(2));
    end

    % image size
    Vsz = size(phs);



    %% directional partial derivatives of the locally unwrapped phase
    di = zeros(Vsz);
    dj = di;
    dk = di;

    for dim = 1:3
        dimN = Vsz(dim);

        idx = [1, 1:dimN-1; 2:dimN, dimN]';
        denom = 3*ones(dimN,1);
        denom([1 end]) = 2;

        for n = 1:dimN
            switch dim
                case 1
                    q = unwrap_dim(phs(idx(n,:),:,:),dim);
                    di(n,:,:) = diff(q,1,dim)/denom(n);
                case 2
                    q = unwrap_dim(phs(:,idx(n,:),:),dim);
                    dj(:,n,:) = diff(q,1,dim)/denom(n);
                case 3
                    q = unwrap_dim(phs(:,:,idx(n,:)),dim);
                    dk(:,:,n) = diff(q,1,dim)/denom(n);
            end
        end

    end



    %% PHASE QUALITY & RETURN

    % local population variance of partial derivatives
    ivar = localvar3(di);
    jvar = localvar3(dj);
    kvar = localvar3(dk);

    % total deviation of partial derivatives
    w = 1./vxsz(:);
    w = w/sum(w(:));
    totalvar = w(1)*sqrt(ivar) + ...
               w(2)*sqrt(jvar) + ...
               w(3)*sqrt(kvar);

    % phase quality
    qual = exp(-totalvar);

    % pad image to original size, if necessary
    if ~isempty(mask)
        tmp = zeros(size(mask));
        tmp(ilmt(1):ilmt(2),jlmt(1):jlmt(2),klmt(1):klmt(2)) = qual;
        qual = tmp;
    end

end



%% 3D LOCAL VARIANCE (6-connected region)
function lvar = localvar3(V)
% local variance within a 6-connected region (for a total of 7 elements)
% At the edges, we use the valid elements within this neighborhood.
% NOTE this is the population variance and we divide by 7 (Nelements),
% rather than the unbiased sample estimator where we would divide
% by 6 (Nelements-1)

    % input size
    Vsz = size(V);

    % number of valid elements within 7 element neighborhood
    N = 7*ones(Vsz);
    N([1 end],:,:) = 6;
    N(:,[1 end],:) = 6;
    N(:,:,[1 end]) = 6;
    N([1 end],[1 end],:) = 5;
    N([1 end],:,[1 end]) = 5;
    N(:,[1 end],[1 end]) = 5;
    N([1 end],[1 end],[1 end]) = 4;

    % pad input by one element (avoid edge problems)
    Vpad = zeros(Vsz+2);
    Vpad(2:end-1,2:end-1,2:end-1) = V;

    % center pixel indices (into padded array)
    irng = (1:Vsz(1)) + 1;
    jrng = (1:Vsz(2)) + 1;
    krng = (1:Vsz(3)) + 1;

    % local partial derivatives - note edge values are zero, eliminating
    % these locations from the local mean calculation
    dC  = Vpad(irng,   jrng,   krng);
    dI0 = Vpad(irng-1, jrng,   krng);
    dI1 = Vpad(irng+1, jrng,   krng);
    dJ0 = Vpad(irng,   jrng-1, krng);
    dJ1 = Vpad(irng,   jrng+1, krng);
    dK0 = Vpad(irng,   jrng,   krng-1);
    dK1 = Vpad(irng,   jrng,   krng+1);


    % local mean
    lmean = (dC+dI0+dI1+dJ0+dJ1+dK0+dK1)./N;

    % replace edge values with their local mean, eliminating
    % these values from the local variance calculation
    dI0(1,:,:)   = lmean(1,:,:);
    dI1(end,:,:) = lmean(end,:,:);
    dJ0(:,1,:)   = lmean(:,1,:);
    dJ1(:,end,:) = lmean(:,end,:);
    dK0(:,:,1)   = lmean(:,:,1);
    dK1(:,:,end) = lmean(:,:,end);

    % local variance
    lvar =(dC  - lmean).*(dC  - lmean) + ...
          (dI0 - lmean).*(dI0 - lmean) + ...
          (dI1 - lmean).*(dI1 - lmean) + ...
          (dJ0 - lmean).*(dJ0 - lmean) + ...
          (dJ1 - lmean).*(dJ1 - lmean) + ...
          (dK0 - lmean).*(dK0 - lmean) + ...
          (dK1 - lmean).*(dK1 - lmean);
    lvar = lvar./N;

end



%**************************************************************************
% END OF FILE
%**************************************************************************
