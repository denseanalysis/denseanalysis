function strain = patchstrain(varargin)

%PATCHSTRAIN
%
%
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    %% PARSE APPLICATION DATA

    errid = sprintf('%s:invalidInput',mfilename);

    % parse input data
    defapi = struct(...
        'vertices',         [],...
        'faces',            [],...
        'times',            [],...
        'spldx',            [],...
        'spldy',            [],...
        'Origin',           [],...
        'Orientation',      []);
    api = parseinputs(defapi,[],varargin{:});

    % check vertices/faces
    vert = api.vertices;
    face = api.faces;
    if ~isnumeric(vert) || ~ismatrix(vert) || size(vert,2)~=2
        error(errid,'Invalid vertices.');
    elseif ~isnumeric(face) || ~ismatrix(face) || any(mod(face(:),1) ~= 0) || ...
       any(face(:) < 0) || any(size(vert,1) < face(:))
        error(errid,'Invalid faces.');
    end

    % check times
    time = api.times;
    if ~isnumeric(time) || ~ismatrix(time)
        error(errid,'Invalid times.');
    end

    % vertex indices that are associated with a face
    idx = unique(face(:));

    % additional parameters
    Ntime = numel(time);
    Nface = size(face,1);
    dim   = size(face,2);


    % vertex trajectories
    % note this effectively checks the spline data as well
    try
        vtrj = NaN([size(vert),Ntime]);

        pts = vert(idx,:)';
        for k = 1:Ntime
            pts(3,:) = time(k);
            dx = fnvalmod(api.spldx,pts([2 1 3],:));
            dy = fnvalmod(api.spldy,pts([2 1 3],:));
            vtrj(idx,:,k) = vert(idx,:) + [dx(:),dy(:)];
        end

    catch ERR
        ME = MException(errid,'Invalid spline data.');
        ME.addCause(ERR);
        throw(ME);
    end


    % face centroids (average of face vertices)
    pos = NaN(Nface,size(vert,2));
    for k = 1:size(vert,2)
        tmp = vert(:,k);
        tmp = tmp(face);
        pos(:,k) = mean(tmp,2);
    end

    % centroid trajectories
    % DO NOT just average the vertex trajectories, instead derive the
    % centroid trajectories directly from the spline data
    ptrj = NaN([size(pos),Ntime]);

    pts = pos';
    for k = 1:Ntime
        pts(3,:) = time(k);
        dx = fnvalmod(api.spldx,pts([2 1 3],:));
        dy = fnvalmod(api.spldy,pts([2 1 3],:));
        ptrj(:,:,k) = pos + [dx(:),dy(:)];
    end


    % parse origin
    origin = api.Origin;
    if isempty(origin), origin = mean(pos,1); end

    if ~isnumeric(origin) || size(origin,2)~=2
        error(errid,'Invalid Origin parameter.');
    end

    % parse orientation
    theta = api.Orientation;
    if isempty(theta)
        theta = cart2pol(pos(:,1)-origin(1),pos(:,2)-origin(2));
    end

    if ~isnumeric(theta) || numel(theta)~= size(pos,1)
        error(errid,'%s','Invalid Orientation.');
    end

    % throw warning
    if ~isempty(api.Orientation) && ~isempty(api.Origin)
        warning(sprintf('%s:ignoringParameter',mfilename),'%s',...
            'It is unneccesary to enter an Origin value ',...
            'when externally defining all FaceOrientations.');
    end

    % cos/sin calculation (saving computational effort)
    ct = cos(theta);
    st = sin(theta);



    %% STRAIN CALCULATION

    % initialize output strain structure
    tmp = NaN([Nface Ntime]);
    strain = struct(...
        'vertices',     vert,...
        'faces',        face,...
        'orientation',  theta,...
        'XX',   tmp,...
        'YY',   tmp,...
        'XY',   tmp,...
        'YX',   tmp,...
        'RR',   tmp,...
        'CC',   tmp,...
        'RC',   tmp,...
        'CR',   tmp,...
        'p1',   tmp,...
        'p2',   tmp,...
        'p1or', tmp);

    % difference matrices: resting configuration
    % Let DIM be the number of vertices per face. The element dX(:,:,k)
    % is a [2xDIM] array, the 1st and 2nd rows containing the x/y distance
    % from the kth face center to each vertex (respectively) at time=0.
    dX = zeros([2 dim Nface]);
    for k = 1:Nface
        tmp = vert(face(k,:),:) - pos(k*ones(dim,1),:);

        %Dan test to start Ecc at zero
        %tmp = vtrj(face(k,:),:,1) - ptrj(k*ones(dim,1),:,1);
        dX(:,:,k) = tmp';
    end

    % strain calculation
    for fr = 1:Ntime

        % loop through each face
        for k = 1:Nface

            % difference matrix: current configuration
            % Let DIM be the number of vertices per face. The matrix "dx"
            % is a [2xDIM] array, the 1st and 2nd rows containing the
            % x/y distance from the kth face center to each
            % vertex (respectively) in the current configuration

            tmp = vtrj(face(k,:),:,fr) - ptrj(k*ones(dim,1),:,fr);
            dx = tmp';

            % average deformation gradient tensor
            Fave = dx/dX(:,:,k);

            % x/y strain tensor
            E = 0.5*(Fave'*Fave - eye(2));

            % coordinate system rotation matrix
            % (Note this is the transpose of the vector rotation matrix)
            Rot = [ct(k) st(k); -st(k) ct(k)];

            % radial/circumferential strain tensor
            Erot = Rot*E*Rot';

            % principal strains
            [v,d] = eig(E,'nobalance');

            % record output
            strain.XX(k,fr) = E(1);
            strain.XY(k,fr) = E(2);
            strain.YX(k,fr) = E(3);
            strain.YY(k,fr) = E(4);

            strain.RR(k,fr) = Erot(1);
            strain.RC(k,fr) = Erot(2);
            strain.CR(k,fr) = Erot(3);
            strain.CC(k,fr) = Erot(4);

            if all(d == 0)
                strain.p1(k,fr) = 0;
                strain.p2(k,fr) = 0;
            else
                strain.p1(k,fr)   = d(end);
                strain.p2(k,fr)   = d(1);
                strain.p1or(k,fr) = atan2(v(2,2),v(1,2));
                strain.p2or(k,fr) = atan2(v(2,1),v(1,1));
            end

        end

    end


end


%% END OF FILE=============================================================
