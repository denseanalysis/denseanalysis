function [mask,faceidx] = pixelize(fv,X,Y,pxsz)
% [mask,faceidx] = pixelize(fv,X,Y,pxsz)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    %% SETUP

    % face vertex structure
    if isstruct(fv)

        % confirm single valid FV structure
        if numel(fv)~=1 || ~all(isfield(fv,{'vertices','faces'}))
            error(sprintf('%s:invalidFV',mfilename),...
                ['Bad FV data; must be a structure containing the fields',...
                 '"vertices" and "faces".']);
        end

        % check vertices
        vert = fv.vertices;
        if ~isnumeric(vert) || ndims(vert)~=2 || ...
           size(vert,2)~=2 || ~all(isfinite(vert(:)))
            error(sprintf('%s:invalidFV',mfilename),...
                'Bad FV.VERTICES data; must be an [Nv x 2] numeric matrix.');
        end

        % check faces
        face = fv.faces;
        if ~isnumeric(face) || ndims(face)~=2 || ...
           size(face,2)~=2 || ~all(mod(face(:),1)==0) || ...
           ~all(isfinite(face(:)) & 0<face(:) & face(:)<=size(vert,1))
            error(sprintf('%s:invalidFV',mfilename),...
                ['Bad FV.FACES data; must be an [Nf x 2] integer matrix, '...
                 'with values on the range [1...%d].'],size(vert,1));
        end

    % [Nx2] contour matrix
    else

        % save input as vertices
        vert = fv;

        % check vertices
        if ~isnumeric(vert) || ~all(isfinite(vert(:))) || ...
           ndims(vert)~=2 || ~any(size(vert)==2)
            error(sprintf('%s:invalidContour',mfilename),...
                'Bad contour; must be an [Nx2] numeric matrix.');
        end

        % transpose [2xN] matrix
        if size(vert,2)~=2, vert = vert'; end

        % default faces
        N = size(vert,1);
        face = [1:N-1; 2:N]';

    end


    % check X|Y (finite numeric)
    if ~isnumeric(X) || ~all(isfinite(X(:))) || ...
       ~isnumeric(Y) || ~all(isfinite(Y(:)))
        error(sprintf('%s:invalidXYZ',mfilename),...
            'Bad X|Y data; must be finite numeric matrices.');
    end

    % X|Y as vectors
    if isvector(X,1) && isvector(Y,2)
        x = X(:);
        y = Y(:);
        [X,Y] = meshgrid(x,y);
        sz = [numel(y),numel(x)];

    % X|Y as plaid data (derived from MESHGRID)
    else
        err = false;

        if ndims(X)~=2 || ...
           ndims(X)~=ndims(Y) || ~all(size(X)==size(Y))
            err = true;
        else
            x = X(1,:);
            y = Y(:,1);
            sz = [numel(y),numel(x)];

            if (sz(2)>1 && ~isequal(X,repmat(x, [sz(1) 1]))) || ...
               (sz(1)>1 && ~isequal(Y,repmat(y, [1 sz(2)])))
                err = true;
            end

        end

        if err
            error(sprintf('%s:invalidXY',mfilename),...
                ['Bad X|Y data; X,Y as vectors must be of size ',...
                 '[Nx x 1], [1 x Ny]; ',...
                 'X,Y as matrices must be of identical size.']);
        end
    end

    % check pixel size
    if nargin<4 || isempty(pxsz)
        dx = min(diff(X(1,:)));
        dy = min(diff(Y(:,1)));
        pxsz = [dx,dy];
    elseif ~isnumeric(pxsz) || ~all(isfinite(pxsz)) || ...
       any(pxsz<=0) || ~any(numel(pxsz)==[1 2])
        error(sprintf('%s:invalidPixelSize',mfilename),...
            ['Bad PixelSize; must be a scalar or [1x2] numeric ',...
             'vector of positive values.']);
    end

    if numel(pxsz)==1, pxsz = [pxsz pxsz]; end

    % pixel radius = half pixel size
    h = pxsz(:)'/2;



    %% CALCULATION

    % number of faces
    Nface = size(face,1);

    % AABB  & origins
    ori = [X(:),Y(:)];

    % initialize output mask
    mask = false(sz);
    faceidx = NaN(sz);
    tf = mask;


    for fi = 1:Nface

        % clear variable


        % face index & vertices
        f = face(fi,:);
        v = vert(f,:);

        % for speed, test only those pixels within a box
        % containing the face bounds
        mn = min(v,[],1);
        mx = max(v,[],1);

        xtf = x+h(1)<mn(1) | mx(1)<x-h(1);
        ytf = y+h(2)<mn(2) | mx(2)<y-h(2);

        tf(:) = false;
        tf(~ytf,~xtf) = true;

        % quit if no pixels to test
        if sum(tf(:))==0
            continue
        end

        % locate pixels for detailed testing
        idx = find(tf);
        idx = idx(:)';


        % DETAILED OVERLAP TEST
        % 2D implementation
        % Fast 3D Triangle-Box Overlap Testing
        % Tomas Akenine-Moller
        flag_calc2 = true;

        % detailed testing algorithm
        for k = idx
            if mask(k), continue; end

            % translate face
            vk  = bsxfun(@minus,v,ori(k,:));
            mnk = mn-ori(k,:);
            mxk = mx-ori(k,:);

            % TEST 0----------
            % if any face vertex lies in/on the AABB,
            % return "true" & quit
            tfa = all(bsxfun(@ge,vk,-h),2);
            tfb = all(bsxfun(@le,vk,h),2);
            if any(tfa&tfb)
                faceidx(k) = fi;
                mask(k) = true;
                continue
            end

% %             % TEST 0----------
% %             % if face extents lie entirely within the AABB,
% %             % return "true" & quit
% %             if all(-h<=mnk) && all(mxk<=h)
% %                 faceidx(k) = fi;
% %                 mask(k) = true;
% %                 continue
% %             end


            % TEST 1----------
            % test AABB edge normals as separating axes
            % Specifically, if the AABB does not overlap the face extents,
            % return "false" & quit
            if any(mxk<-h) || any(h<mnk)
                % mask(k) = false
                continue
            end

            % TEST 2----------
            % test normal to face as separating axes
            % Specifically, if the AABB does not intersect the infinite
            % line defined by the face, return "false" & quit

            if flag_calc2

                % face vector(s)
                F = v(2,:) - v(1,:);

                % face normal
                nrm = [F(2),-F(1)];
                tmp = (nrm>0);

                % basic min/max points
                vmin = -h.*tmp + h.*~tmp;
                vmax =  h.*tmp - h.*~tmp;

                % clear calculation flag
                flag_calc2 = false;

            end

            if sum(nrm .* (vmin - vk(1,:))) > 0 || ...
               sum(nrm .* (vmax - vk(1,:))) < 0
                % mask(k) = false;
                continue
            end


            % CLEANUP----------
            % if we pass all tests (i.e. all tests returned false)
            faceidx(k) = fi;
            mask(k) = true;

        end
%         mask(tf) = true;

    end


end


function tf = isvector(val,dim)
    tf = size(val,dim)==1 && sum(size(val)~=1)<=1;
end
