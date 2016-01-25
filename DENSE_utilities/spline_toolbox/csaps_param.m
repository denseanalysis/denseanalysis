function p = csaps_param(x,lam,w)
%CSAPS_PARAM Cubic smoothing spline parameter.
%
%This function is derived from the CSAPS function, returning the cubic
%smoothing spline smoothing parameter that would be calculated by that
%function. Here, we only require the "x" input to determine this parameter.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    if nargin<2, lam = []; end
    if nargin<3,   w = []; end

    % gridded data
    if iscell(x)

        m = length(x);
        if isempty(w), w = cell(1,m); end
        if isempty(lam), lam = cell(1,m); end

        p = cell(1,m);
        for i = m:-1:1   % carry out coordinatewise smoothing
          p{i} = csaps1_param(x{i},lam{i},w{i});
        end

    % we have univariate data
    else
        p = csaps1_param(x,lam,w);
    end

end

function p = csaps1_param(x,lam,w)
%CSAPS1_PARAM univariate cubic smoothing spline parameter

    n = length(x);
    if isempty(w), w = ones(1,n); end

    [xi,yi,sizeval,w,origint,p] = chckxywp(x,zeros(size(x)),2,w,[-1 lam]);
    n = size(xi,1);

    % the smoothing spline is the straight line interpolant
    if n==2
       p = 1;

    % set up the linear system for solving for the 2nd derivatives at  xi .
    % this is taken from (XIV.6)ff of the `Practical Guide to Splines'
    % with the diagonal matrix D^2 there equal to diag(1/w) here.
    % Make use of sparsity of the system.
    else

        dx = diff(xi);
        dxol = dx;
        if length(p)>1
            lam  = p(2:end).';
            dxol = dx./lam;
        end

        R = spdiags([dxol(2:n-1), 2*(dxol(2:n-1)+dxol(1:n-2)), ...
                     dxol(1:n-2)], -1:1, n-2,n-2);

        odx = 1./dx;
        Qt = spdiags([odx(1:n-2), -(odx(2:n-1)+odx(1:n-2)), ...
                      odx(2:n-1)], 0:2, n-2,n);

        % solve for the 2nd derivatives
        Qtw = Qt*spdiags(1./sqrt(w(:)),0,n,n);
        QtWQ = Qtw*Qtw.';

        % smoothing parameter
        p = 1/(1+trace(R)/(6*trace(QtWQ)));

    end

end

