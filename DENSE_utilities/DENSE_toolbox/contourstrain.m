function strain = contourstrain(varargin)

%PATCHSTRAIN
%
%
%

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
errid = sprintf('%s:invalidInput',mfilename);

    % parse input data
    defapi = struct(...
        'vertices',         [],...
        'faces',            [],...
        'times',            [],...
        'spldx',            [],...
        'spldy',            [],...
        'spldz',            [],...
        'Origin',           [],...
        'Orientation',      []);
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

    % append zero-slice to vertices
    vert(:,3) = 0;

    % check times
    time = api.times;
    if ~isnumeric(time) || ndims(time)~=2
        error(errid,'Invalid times.');
    end

    % additional parameters
    Ntime = numel(time);
    Nface = size(face,1);
    dim   = size(face,2);

    % vertex trajectories
    % note this effectively checks the spline data as well
    try
        vtrj = NaN([size(vert),Ntime]);

        ijt = vert(:,[2 1])';
        for k = 1:Ntime
            ijt(3,:) = time(k);
            dx = fnvalmod(api.spldx,ijt);
            dy = fnvalmod(api.spldy,ijt);
            dz = fnvalmod(api.spldz,ijt);
            vtrj(:,:,k) = vert + [dx(:),dy(:),dz(:)];
        end

    catch ERR
        ME = MException(errid,'Invalid spline data.');
        ME.addCause(ERR);
        throw(ME);
    end





    %% STRAIN CALCULATION

    % initialize output strain structure
    strain = struct(...
        'vertices',vert,...
        'faces',face,...
        'SS',NaN([Nface Ntime]));

    % differences: resting configuration
    x = vert(:,1);
    y = vert(:,2);
    z = vert(:,3);

    dX = sqrt(diff(x(face),1,2).^2 + ...
              diff(y(face),1,2).^2 + ...
              diff(z(face),1,2).^2);

    % strain calculation for each frame
    for fr = 1:Ntime

        % differences: current configuration
        x = vtrj(:,1,fr);
        y = vtrj(:,2,fr);
        z = vtrj(:,3,fr);

        dx = sqrt(diff(x(face),1,2).^2 + ...
                  diff(y(face),1,2).^2 + ...
                  diff(z(face),1,2).^2);

        % strain scalar
        Fave = dx./dX;
        E = 0.5*(Fave.^2 - 1);

        % save to output
        strain.SS(:,fr) = E(:);
    end



end


% function [dx,st,flag_valid] = getdx(dim,face,vert,tdir)
%     flag_valid = true;
%
%     % contour
%     if dim==2
%
%         % vertices
%         a = vert(face(1),:);
%         b = vert(face(2),:);
%
%         % vector between points
%         v = b-a;
%
%         % current configuration
%         dx = sqrt(sum(v.^2));
%
%         % current direction
%         st = v;
%
%     end


%% END OF FILE=============================================================
