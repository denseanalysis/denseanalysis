function [pp,sparam] = cscvn2(points,endconds,iscorner)

%CSCVN2 `Natural' or periodic interpolating cubic spline curve.
%   This function is similar to bultin MATLAB function CSCVN,
%   but tailored for the GETCLINE function.
%
%INPUTS
%   points......input points (Npoints x Ndim)
%   endconds....end condition ('periodic' or 'variational')
%   iscorner....logical idicating point as corner (Npoints x 1)
%
%OUTPUTS
%   pp..........spline function
%   sparam......parameter values of each POINTS
%
%USAGE
%
%   PP = CSCVN2(POINTS) returns a variational `natural' cubic spline
%   that interpolates to the given points POINTS(:,i) at parameter values
%   s(i), i=1,2,..., with  s(i) chosen by Eugene Lee's centripetal scheme,
%   i.e., as accumulated square root of chord-length.
%
%   PP = CSCVN2(POINTS,ENDCONDS) allows the user to select either a
%   'periodic' spline or a 'variational' (default) spline.
%
%   PP = CSCVN2(POINTS,ENDCONDS,ISCORNER) allows the user to select certain
%   points as corners, creating variational splines between each specified
%   corner.
%
%   [...,SPARAM] = CSCVN2(POINTS,...) additionally returns the paramter
%   value associated with each POINTS
%
%NOTES
%   This function makes use of the CSAPE spline function, i.e. we use
%   cubic splines with end conditions.  Duplicate conrol points are ignored.
%
%   When a user indicates that certain control points are corners via
%   the ISCORNER vector, we contruct variational cubic splines between
%   each corner control point.  If the user also chooses to specifiy the
%   'periodic' ENDCONDS contdition with corner points, care is taken to
%   ensure that the splines smoothly pass through the first point if
%   appropriate (unlike the MATLAB function CSCVN)
%
%EXAMPLE
%
%     points   = [1 0 -1 0; 0 1 0 -1];
%     iscorner = [0 0 1 0];
%     endconds = 'periodic';
%
%     [pp,sparam] = cscvn2(points,endconds,iscorner);
%     s = unique([linspace(0,pp.breaks(end),100),sparam]);
%     vals = fnval(pp,s);
%
%     strs = cellfun(@(x)sprintf('  %d',x),num2cell(1:size(points,2)),...
%         'uniformoutput',0);
%
%     figure, axis equal, box on, axis([-2 2 -2 2]);
%     hold on
%     hline = plot(vals(1,:),vals(2,:),'-r');
%     plot(points(1,:),points(2,:),'ob');
%     text(points(1,:),points(2,:),strs,'color','b',...
%         'horizontalalignment','left');
%     hold off
%

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
%% WRITTEN BY:  Drew Gilliam
% Derived from MATLAB builtin CSCVN
%
%MODIFICATION HISTORY:
%   2009.01     Drew Gilliam
%     --creation



    %% SETUP

    % check points input
    if ~isnumeric(points) || ndims(points)~=2
        error(sprintf('%s:invalidInput',mfilename),...
            'Invalid ''points'' Input.');
    end

    % iscorner
    if nargin < 3 || isempty(iscorner)
        iscorner = false(size(points(1,:)));
    end
    iscorner = logical(iscorner);

    if numel(iscorner) ~= size(points,2)
        error(sprintf('%s:invalidInput',mfilename),...
            'Invalid ''iscorner'' Input.');
    end

    % end condition
    if nargin < 2 || isempty(endconds), endconds = 'variational'; end

    tf = strcmpi(endconds,{'periodic','variational'});
    if ~any(tf)
        error(sprintf('%s:invalidInput',mfilename),...
            '''endconds'' input expects ''periodic'' or ''variational''.');
    end

    FLAG_periodic = isequal(endconds,'periodic');
    if FLAG_periodic
        points   = points(:,[1:end 1]);
        iscorner = iscorner(:,[1:end 1]);
    end


    %% REMOVE DUPLICATE POINTS

    % parameter s
    if size(points,2)==1
        ds = [];
    else
        ds = sum((diff(points.').^2).').^(1/4);
    end
    s = cumsum([0,ds]);
    srng = [min(s) max(s)];

    % output parameter
    if FLAG_periodic
        sparam = s(1:end-1);
    else
        sparam = s;
    end

    % remove all duplicate points
    % note this is more complex than it seems - if the "iscorner" flag is
    % raised on any duplicate point, we consider the "iscorner" flag raised
    % on ALL duplicate points.
    tol = 1e-10;
    if any(ds<=tol)
        tf = [false,(ds<tol)];

        % update iscorner structure
        if any(iscorner)
            n = 1;
            for k = 1:numel(tf)
                if tf(k)
                   iscorner(n) = iscorner(n) | iscorner(k);
                else
                   n = k;
                end
            end
        end

        % remove duplicate points
        iscorner = iscorner(~tf);
        points   = points(:,~tf);
        s = s(~tf);
    end

    % number of unique points
    N = size(points,2);


    %% SPLINE

    % single unique point
    if N == 1
        pp = csape([0 1],points(:,[1 1]),endconds);
        sparam(:) = 0;


    % multiple unique points
    else

        % no corners
        if ~any(iscorner)
            pp = csape(s,points,endconds);

        % corners exist
        else

            % corner indices
            idx = find(iscorner);

            % periodic extension of spline around initial point
            % this ensures that coefficent calculations around
            % the first point are correct
            if FLAG_periodic
                s = [s(idx(end):end-1)-s(end), s, s(2:idx(1))+s(end)];
                points = points(:,[idx(end):end-1,1:end,2:idx(1)]);
                idx = idx + N-idx(end);
            end

            % valid segments (2xNseg)
            seg = [1,idx; idx,numel(s)];
            seg = seg(:,seg(1,:) ~= seg(2,:));

            % variational segment spline coeffecients
            coefs = [];
            for k = 1:size(seg,2)
                sk = s(seg(1,k):seg(2,k));
                pk = points(:,seg(1,k):seg(2,k));
                coefs = [coefs;...
                    ppbrk(csape(sk,pk,'variational'),'c')];
            end

            % Remove the extra periodic extension coefficents
            if FLAG_periodic
                sind = find(srng(1)<=s & s<=srng(2));
                tmp = 2*(sind(1:end-1)-1);
                cind = [tmp+1; tmp+2];

                s = s(sind);
                coefs = coefs(cind,:);
            end

            % create spline
            pp = ppmak(s,coefs,size(points,1));

        end

    end


end

