function [st,p] = tpaps_v3(x,y,p)
%TPAPS_V3 Thin-plate smoothing spline.
%
% This function is ALMOST a carbon copy of the MATLAB thin-plate smoothing
% spline TPAPS.  It does not implement the "iterative scheme" solution,
% which can greatly slow execution time.  Additionally, this function
% offers a point-by-point smoothing parameter. Note that when using
% point-by-point smoothing, all smoothing parameters must be non-zero to
% avoid singularities.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    %% SETUP

    % check number of inputs
    narginchk(2, 3);

    % default empty smoothing parameter
    % make this of size [1,0] for later error checks
    if nargin < 3 || isempty(p), p = zeros(1,0); end

    % input sizes
    [m,nx] = size(x);
    mp1 = m+1;

    % check for 2D input
    if m~=2
        if nx==2, addmess = 'Perhaps you meant to supply the transpose of X?';
        else addmess = '';
        end

        error(sprintf('SPLINES:%s:wrongsizeX',mfilename),...
            ['TPAPS(X,...) expects the data sites to form the',...
             ' COLUMNS of X.\nWith that interpretation, you seem',...
             ' to be providing data sites in ', num2str(m),...
             '-dimensional space,\nwhile, at present, TPAPS',...
             ' can only handle data sites in the plane.\n',addmess],...
             0);
    end

    % check for enough data sites
    if nx<mp1
        error(sprintf('SPLINES:%s:notenoughsites',mfilename),...
            ['Thin-plate spline smoothing in ',num2str(m), ...
             ' variables requires at least ',num2str(mp1), ...
             ' data sites.']);
    end

    % convert values to vectors, but remember the actual size of the values
    % in order to set the dimension parameter of the output correctly.
    sizeval = size(y);
    ny = sizeval(end);
    sizeval(end) = [];
    dy = prod(sizeval);
    if length(sizeval)>1
        y = reshape(y,dy,ny);
    end

    if ny~=nx
        if dy==nx, addmess = 'Perhaps you meant to supply the transpose of Y?';
        else  addmess = '';
        end
        error(sprintf('SPLINES:%s:wrongsizeY',mfilename),...
            ['TPAPS(X,Y,...) expects the data values to form the', ...
             ' COLUMNS of Y.\nWith that interpretation, you seem' ...
             ' to be providing ', num2str(ny),...
             ' data value(s),\nyet ', num2str(nx),...
             ' data sites.\n', addmess],...
            0)
    end


    % check smoothing parameter
    if ~ismatrix(p) || size(p,1) ~= 1 || ...
       ~any(size(p,2) == [0 1 nx]) || any(p<0 | 1<p)

        error(sprintf('SPLINES:%s:wrongsizeP',mfilename),...
            ['TPAPS(X,Y,P) expects the smoothing parameter P to be', ...
             ' a scalar or a vector the same size as Y, with all',...
             ' values between [0,1].'])
    end

    np = numel(p);

    if np > 1 && any(p==0) && ~all(p==0)
        error(sprintf('SPLINES:%s:wrongsizeP',mfilename),...
            ['When utilizing point-by-point smoothing, this function',...
            ' expects all smoothing parameters to be non-zero.']);
    end


    % ignore all nonfinites
    nonfinites = find(sum(~isfinite([x;y])));
    if ~isempty(nonfinites)
        x(:,nonfinites) = [];
        y(:,nonfinites) = [];
        if np == nx, p(:,nonfinites) = []; end

        nx = size(x,2);
        warning(sprintf('SPLINES:%s:NaNs',mfilename), ...
            ['All data points with NaNs or Infs'...
             ' in their value will be ignored.'])
    end

    if nx<mp1
       error(sprintf('SPLINES:%s:notenoughsites',mfilename), ...
            ['Thin-plate spline smoothing in ',num2str(m), ...
             ' variables requires at least ',num2str(mp1), ...
             ' data sites.'])
    end

    [Q,R] = qr([ x.' ones(nx,1)]);
    radiags = sort(abs(diag(R)));
    if radiags(1)<1.e-14*radiags(end)
        error(sprintf('SPLINES:%s:collinearsites',mfilename), ...
           ['Some nontrivial linear polynomial'...
            ' vanishes at all data sites.'])
    end

    % For three inputs, simply return the interpolating plane. Note this
    % ignores any smoothing input "p", as the data can be matched exactly.
    if nx==3
        st = stmak(x,[zeros(dy,3), y/(R(1:mp1,1:mp1).')],'tp00');

        if ~isempty(p)
            warning(sprintf('SPLINES:%s:ignoresmoothing',mfilename),...
                ['As there are only 3 data sites, the input smoothing',...
                 ' parameter will be ignored']);
        end
        p = 1;

    % thin plate approximating spline
    else

        Q1 = Q(:,1:mp1);
        Q(:,1:mp1) = [];

        % linear least squares polynomial
        if ~isempty(p) && all(p==0)
            st = stmak(x, [zeros(dy,nx), (y*Q1)/(R(1:mp1,1:mp1).')],'tp00');

        % solve the linear system directly
        else

          colmat = stcol(x,x,'tr');

          % default smoothing parameter
          if isempty(p)
             p = 1/(1+mean(diag(Q'*colmat*Q)));
          end

          colmat(1:nx+1:nx^2) = colmat(1:nx+1:nx^2) + (1-p)./p;
          coefs1 = (y*Q/(Q'*colmat*Q))*Q';
          coefs2 = ((y - coefs1*colmat)*Q1)/(R(1:mp1,1:mp1).');

          st = stmak(x,[coefs1,coefs2],'tp00');
       end
    end
    if length(sizeval)>1, st = fnchg(st,'dz',sizeval); end


end

