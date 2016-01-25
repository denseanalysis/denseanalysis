function p = tpaps_param(x)
%TPAPS_PARAM Thin-plate smoothing spline parameter calculation.
%
%This function is a truncated copy of the TPAPS matlab thin-plate smoothing
%spline function, calculating only the suggested smoothing parameter
%associated with the "x" input.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    %% SETUP

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


    % ignore all nonfinites
    nonfinites = find(sum(~isfinite(x)));
    if ~isempty(nonfinites)
        x(:,nonfinites) = [];
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

    % For three inputs, simply return the interpolating plane. Note this
    % ignores any smoothing input "p", as the data can be matched exactly.
    if nx==3
        p = 1;

    % thin plate approximating spline parameter
    else
% save('xdata.mat','x');

        [Q,R] = qr([x.' ones(nx,1)]);
        Q(:,1:mp1) = [];
        colmat = stcolmod(x);
%         colmat = zeros(nx,nx);
%         colmat = colmat + (x(1*ones(nx,1),:) - x(1*ones(nx,1),:)').^2;
%         colmat = colmat + (x(2*ones(nx,1),:) - x(2*ones(nx,1),:)').^2;
%         colmat = colmat .* log(colmat);

        p = 1/(1+mean(diag(Q'*colmat*Q)));

    end


end


function K = stcolmod(x)
    FLAG = 1;
    switch FLAG
        case 1
            K = kmatrix2(x.',x.');
        case 2
            nx = size(x,2);
            K = zeros(nx,nx);
            K = K + (x(1*ones(nx,1),:) - x(1*ones(nx,1),:).').^2;
            K = K + (x(2*ones(nx,1),:) - x(2*ones(nx,1),:).').^2;
            K(K<=0) = 1;
            K = K .* log(K);
        otherwise
            K = stcol(x,x,'tr');
    end
end

