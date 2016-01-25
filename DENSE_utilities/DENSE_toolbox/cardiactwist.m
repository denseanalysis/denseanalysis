function [dtheta,ptrj] = cardiactwist(varargin)
% [dtheta,ptrj] = cardiactwist(varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    defapi = struct(...
        'vertices', [],...
        'faces',    [],...
        'times',    [],...
        'spldx',    [],...
        'spldy',    [],...
        'Origin',   [],...
        'Clockwise',[]);

    api = parseinputs(defapi,[],varargin{:});

    % check vertices/faces
    vert = api.vertices;
    face = api.faces;
    if ~isnumeric(vert) || ndims(vert)~=2 || size(vert,2)~=2
        error(errid,'Invalid vertices.');
    elseif ~isnumeric(face) || ndims(face)~=2 || any(mod(face(:),1) ~= 0) || ...
       any(face(:) < 0) || any(size(vert,1) < face(:))
        error(errid,'Invalid faces.');
    end

    % check times
    time = api.times;
    if ~isnumeric(time) || ndims(time)~=2
        error(errid,'Invalid times.');
    end

    % additional parameters
    Ntime = numel(time);
    Nface = size(face,1);

    % face centroids (average of face vertices)
    pos = NaN(Nface,size(vert,2));
    for k = 1:size(vert,2)
        tmp = vert(:,k);
        tmp = tmp(face);
        pos(:,k) = mean(tmp,2);
    end

    % centroid trajectories
    % note this effectively checks the spline data as well
    try
        ptrj = NaN([size(pos),Ntime]);

        pts = pos';
        for k = 1:Ntime
            pts(3,:) = time(k);
            dx = fnvalmod(api.spldx,pts([2 1 3],:));
            dy = fnvalmod(api.spldy,pts([2 1 3],:));
            ptrj(:,:,k) = pos + [dx(:),dy(:)];
        end

    catch ERR
        ME = MException(errid,'Invalid spline data.');
        ME.addCause(ERR);
        throw(ME);
    end


    % parse origin
    origin = api.Origin;
    if isempty(origin), origin = mean(pos,1); end

    if ~isnumeric(origin) || size(origin,2)~=2
        error(errid,'Invalid Origin parameter.');
    end

    % parse clockwise
    clockwise = isequal(api.Clockwise,true);


    %% TWIST CALCULATION

    % bulk correction
    tmp  = mean(pos,1);
    shft = tmp(:,:,ones(Ntime,1)) - mean(ptrj,1);
    ptrj = ptrj + shft(ones(Nface,1),:,:);

    % initial angles
    theta0 = atan2(pos(:,2)-origin(2),pos(:,1)-origin(1));

    % trajectory angles
    theta = atan2(ptrj(:,2,:)-origin(2),ptrj(:,1,:)-origin(1));
    theta = squeeze(theta);

    % correct wrapping errors in trajectory angles
    alltheta = cat(2,theta0,theta);
    tmp = unwrap(alltheta,[],2);
    theta = tmp(:,2:end);

    % angular difference
    dtheta = theta - theta0(:,ones(Ntime,1));

    % correct direction
    if ~clockwise
        dtheta = -dtheta;
    end


end
