function varargout = clinesegments(pos,iscls,iscrv,iscrn,res)

%CLINESEGMENTS a helper function for CLINE, GETCLINE, and IMCLINE,
%   defining the default contour segments.
%
%INPUTS
%   pos.....control point positions     [Nx2]
%   iscls..."is closed" flag            logical scalar
%   iscrv..."is curved" flags           logical scalar, [Nx1], [(N-1)x1]
%   iscrn..."is corner" flags           [Nx1]
%   res.....curved segment resolution   scalar
%
%OUTPUTS
%   X.......[Nx1] cell array defining the 2D position of
%           connecting line segments.
%   x/y.....alternative output, defining x/y positions in
%           separate cell arrays.
%
%USAGE
%   XCELL = CLINESEGMENTS(POS,ISCLS,ISCRV,ISCRN) determines the line
%   segments connecting the control points POS according to various flags.
%   ISCLS defines a closed curve; ISCRV defines if each connecting segment
%   is curved or straight; and ISCRN defines if each control point is a
%   corner or smooth point.  The resulting line segments are returned in
%   the cell array XCELL.
%
%   ... = CLINESEGMENTS(...,RES) the user may also specify the curved line
%   segment resolution, defaulted to be 0.5.
%
%   [xcell,ycell] = CLINESEGMENTS(...) users may output the x/y values
%   separately in two cell arrays.
%
%NOTE ON SIZES
%   If ISCLS is true, ISCRV should be a scalar or [Nx1] matrix
%   If ISCLS is false, ISCRV should be a scalar or [(N-1)x1] matrix
%   If the contour is not closed, the last element of the output cell array
%   will be an empty matrix.
%
%NOTE ON INPUTS
%   We avoid the more typical parameter/value input structure, as this
%   function will be called repeatedly during interactive editing requiring
%   fast real time calculations.

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
%   2009.01     Drew Gilliam
%     --creation



    %% SETUP

    % check number of inputs/outputs
    error(nargchk(4,5,nargin));
    error(nargchk(1,2,nargout));

    % default resolution
    if nargin < 5 || isempty(res), res = 0.5; end

    % check position
    if ~isnumeric(pos) || ndims(pos)~= 2 || size(pos,2)~=2
        error(sprintf('%s:invalidInput',mfilename),...
            'Invalid position matrix.');
    end
    N = size(pos,1);

    % check isclosed
    iscls = logical(iscls);
    if numel(iscls) ~= 1
        error(sprintf('%s:invalidInput',mfilename),...
            'Invalid ''isclosed'' vector.');
    end

    % check iscurved
    iscrv = logical(iscrv);
    if numel(iscrv) == 1
        iscrv = iscrv(ones(N,1));
    else
        if iscls && numel(iscrv) < N
            errstr = sprintf('%s',...
                'Invalid ''IsCurved'' input. ',...
                'Closed curve requires scalar or [Nx1] ',...
                '''iscurved'' logical values');
        elseif ~iscls && numel(iscrv) < N-1
            errstr = sprintf('%s',...
                'Invalid ''IsCurved'' input. ',...
                'Open curve requires scalar OR [(N-1)x1] ',...
                '''iscurved'' logical values');
        else
            errstr = [];
        end
        if ~isempty(errstr)
            error(sprintf('%s:invalidInput',mfilename),errstr);
        end
    end

    % check iscorner
    iscrn = logical(iscrn);
    if numel(iscrn) == 1
        iscrn = iscrn(ones(N,1));
    elseif numel(iscrn) ~= N
        error(sprintf('%s:invalidInput',mfilename),...
            'Invalid ''iscorner'' input.');
    end



    %% CALCULATE SEGMENTS
    switch N

        % single point
        case 1
            xcell = {pos(1)};
            ycell = {pos(2)};
            Xcell = {pos};

        % two points (always a straight line)
        case 2
            if iscls
                xcell = {pos(:,1);pos([2 1],1)};
                ycell = {pos(:,2);pos([2 1],2)};
                Xcell = {pos;pos([2 1],:)};
            else
                xcell = {pos(:,1);zeros(0,1)};
                ycell = {pos(:,2);zeros(0,1)};
                Xcell = {pos;zeros(0,2)};
            end

        % more points
        otherwise

            % periodic points
            ppos = pos([1:end 1],:);

            % natural spline (if necessary)
            if any(iscrv)
                if iscls
                    [pp,s] = cscvn2(pos','periodic',iscrn');
                    s(end+1) = pp.breaks(end);
                else
                    [pp,s] = cscvn2(pos','variational',iscrn');
                end

                % evenly sampled chords, including the original control
                % points. Note that each chord will have a slightly
                % different resolution, as close to RES as possible
                Ns = ceil(diff(s)/res);
                si = cell(numel(Ns),1);
                for k = 1:numel(Ns)
                    si{k} = linspace(s(k),s(k+1),Ns(k)+1);
                    si{k} = si{k}(2:end);
                end

                % convert to single vector, noting indices of original
                % control points (a single vector provides a faster FNVAL
                % calculation)
                si = cat(2,0,si{:});
                idx = [1 1+cumsum(Ns)];

                % % evenly spaced samples, by chord length
                % % including the original control points
                % si = 0:res:pp.breaks(end);
                % [si,m,n] = unique([s(:)',si]);
                % idx = n(1:numel(s));

                % resampled spline
                ipos = fnval(pp,si)';

%                 figure(10)
%                 plot(ipos(:,1),ipos(:,2),'-r.')
%                 hold on
%                 plot(ipos(idx,1),ipos(idx,2),'bo')
%                 hold off

            end

            % gather line segments in cell form
            xcell = cell(N,1);
            ycell = xcell;
            Xcell = xcell;

            for k = 1:N
                if (k==N && ~iscls)
                    xcell{k} = zeros(0,1);
                    ycell{k} = zeros(0,1);
                elseif ~iscrv(k)
                    xcell{k} = ppos(k:k+1,1);
                    ycell{k} = ppos(k:k+1,2);
                else
                    xcell{k} = ipos(idx(k):idx(k+1),1);
                    ycell{k} = ipos(idx(k):idx(k+1),2);
                end
                Xcell{k} = [xcell{k},ycell{k}];
            end

    end

    % output
    if nargout <= 1
        varargout{1} = Xcell;
    elseif nargout > 1
        varargout{1} = xcell;
        varargout{2} = ycell;
    end


end
