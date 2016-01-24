function data = spl2strain(varargin)
% data = spl2strain(varargin)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

    defapi = struct(...
        'Type',                 'unknown',...
        'Mag',                  [],...
        'RestingContour',       [],...
        'spldx',                [],...
        'spldy',                [],...
        'MaskFcn',              [],...
        'xrng',                 [],...
        'yrng',                 [],...
        'Resolution',           1,...
        'PositionA',            [],...
        'PositionB',            [],...
        'Nmodel',               [],...
        'Nseg',                 [],...
        'Clockwise',            [],...
        'CardiacModelPanel',   false);

    api = parseinputs(defapi,[],varargin{:});


    if api.CardiacModelPanel
        opts = cardiacmodel(api);
        if isempty(opts)
            data = [];
            return
        end
        tags = fieldnames(opts);
        for ti = 1:numel(tags)
            api.(tags{ti}) = opts.(tags{ti});
        end
    end


    switch lower(api.Type)
        case 'sa'
            data = spl2patchSA(api);
        case 'la'
            data = spl2patchLA(api);
        otherwise
            data = spl2patchGeneral(api);
    end

    % copy additional fields to the output
    tags = {'xrng','yrng','Resolution','PositionA','PositionB',...
        'Nmodel','Nseg','Clockwise'};
    for ti = 1:numel(tags)
        data.(tags{ti}) = api.(tags{ti});
    end
end




function data = spl2patchGeneral(api)

    type    = api.Type;
    res     = api.Resolution;
    Ccell   = api.RestingContour;

    % number of contours
    Nc   = numel(Ccell);

    % all vertices
    C = cat(1,Ccell{:});

    % number of points per contour
    Npts = cellfun(@(x)size(x,1),Ccell);


    % we don't NEED to, but we still include the ability to correctly
    % mesh cardiac contours just in case...
    switch lower(type)
        case 'la'
            C(end+1,:) = C(1,:);
            edge = [];
            face = [];

        case 'sa'
            edge = cell(2,1);
            offsetedge = [0 cumsum(Npts)];
            for k = 1:2
                tmp = offsetedge(k) + (1:size(Ccell{k},1));
                edge{k} = [tmp(1:end-1); tmp(2:end)]';
            end
            edge = cat(1,edge{:});
            face = {1:size(edge,1)};

        otherwise
            edge = cell(Nc,1);
            face = cell(Nc,1);
            offsetedge = [0 cumsum(Npts)];
            offsetface = 0;
            for k = 1:Nc
                tmp = offsetedge(k) + (1:size(Ccell{k},1));
                edge{k} = [tmp(1:end-1); tmp(2:end)]';

                len = size(edge{k},1);
                face{k} = offsetface + (1:len);
                offsetface = offsetface + len;
            end
            edge = cat(1,edge{:});
    end


    % unstructured mesh via "MESHFACE"
    % (from matlab file exchange)
    optA = struct('hmax',res);
    optB = struct('output',false,'waitbar',false);
    [v,f,id] = meshfaces(C,edge,face,optA,optB);

    % gather output data
    data = struct(...
        'vertices',     v,...
        'faces',        f,...
        'sectorid',     id,...
        'layerid',      id,...
        'orientation',  []);

end



%% SHORT AXIS PATCH
function data = spl2patchSA(api)

    tol = 1e-4;

    maxseg = 132;

    res     = api.Resolution;
    Ccell   = api.RestingContour;
    origin  = api.PositionA;
    posB    = api.PositionB;
    flag_clockwise = api.Clockwise;
    Nseg    = api.Nseg;

    % total number of theta samples per segment
    Nperseg = floor(maxseg/Nseg);
    N = Nperseg*Nseg;

    % full enclosing contour
    C = cellfun(@(c)cat(1,c,NaN(1,2)),Ccell,'uniformoutput',0);
    C = cat(1,C{:});

    % initial angle
    theta0 = atan2(posB(2)-origin(2),posB(1)-origin(1));

    % angular range
    if flag_clockwise
        theta = linspace(0,2*pi,N+1);
    else
        theta = linspace(2*pi,0,N+1);
    end
    theta = theta(1:end-1) + theta0;


    % radial range
    [tmp,r] = cart2pol(C(:,1)-origin(1),C(:,2)-origin(2));
    mxrad = ceil(max(r));
    mnrad = floor(min(r));
    rad = [0 2*mxrad];

    % spokes
    [THETA,RAD] = ndgrid(theta,rad);
    [X,Y] = pol2cart(THETA,RAD);

    xspoke = X'+origin(1);
    xspoke(end+1,:) = NaN;

    yspoke = Y'+origin(2);
    yspoke(end+1,:) = NaN;


    % find intersections
    [x,y,i,j] = intersections(xspoke(:),yspoke(:),...
        Ccell{1}(:,1),Ccell{1}(:,2));

    % sort intersections according to spoke index
    % eliminate any duplicate intersections
    % (enforce one intersection per spoke, closest to the origin)
    [val,idx1] = sort(i,'ascend');
    [val,idx2] = unique(floor(val),'first');

    % record points
    eppts = [x(idx1(idx2)),y(idx1(idx2))];


    % find intersections
    [x,y,i,j] = intersections(xspoke(:),yspoke(:),...
        Ccell{2}(:,1),Ccell{2}(:,2));

    % sort intersections according to spoke index
    % eliminate any duplicate intersections
    % (enforce one intersection per spoke, closest to the origin)
    [val,idx1] = sort(i,'ascend');
    [val,idx2] = unique(floor(val),'first');

    % record points
    enpts = [x(idx1(idx2)),y(idx1(idx2))];


    % number of lines
%     Nline = ceil((mxrad-mnrad)/res);
    Nline = 6;

    % vertices
    X = NaN(N,Nline);
    Y = NaN(N,Nline);

    w = linspace(0,1,Nline);
    for k = 1:Nline
        X(:,k) = w(k)*enpts(:,1) + (1-w(k))*eppts(:,1);
        Y(:,k) = w(k)*enpts(:,2) + (1-w(k))*eppts(:,2);
    end
    v = [X(:),Y(:)];

    % 4-point faces
    f = zeros((Nline-1)*N,4);
    tmp = [1:N; 2:N,1]';
    for k = 1:Nline-1
        rows = (k-1)*N + (1:N);
        f(rows,:) = [tmp,fliplr(tmp)+N] + (k-1)*N;
    end
    Nface = size(f,1);


    % ids
    id = repmat(1:Nseg,[Nperseg,1]);
    id = repmat(id(:),[1,Nline-1]);
    sectorid = id(:);

    id = repmat(1:Nline-1,[N,1]);
    layerid = id(:);



    % face locations (average of vertices)
    pface = NaN(Nface,2);
    for k = 1:2
        vk = v(:,k);
        pface(:,k) = mean(vk(f),2);
    end

    % orientation (pointed towards center)
    [or,rad] = cart2pol(pface(:,1)-origin(1),pface(:,2)-origin(2));
    or = or+pi;


    % gather output data
    data = struct(...
        'vertices',     v,...
        'faces',        f,...
        'sectorid',     sectorid,...
        'layerid',      layerid,...
        'orientation',  or);

end


%% LONG AXIS PATCH
function data = spl2patchLA(api)


    res     = api.Resolution;
    Ccell   = api.RestingContour;
    pos     = [api.PositionA; api.PositionB];
    flag_clockwise = api.Clockwise;

    % standard parameters
    Nline = 6;
    Nseg  = 7;

    % ensure clockwise matches input
    [theta,rad] = cart2pol(Ccell{1}(:,1)-pos(1,1),Ccell{1}(:,2)-pos(1,2));
    maxrad = max(rad);
    theta  = unwrap(theta);
    if (~flag_clockwise && theta(end)>theta(1)) || ...
       ( flag_clockwise && theta(end)<theta(1))
        Ccell = cellfun(@flipud,Ccell,'uniformoutput',0);
    end

    % full enclosing contour
    C = cat(1,Ccell{:});
    Cclose = cat(1,C,C(1,:));

    % normalized posA->posB vector
    vec = diff(pos);
    vec = vec/sqrt(sum(vec.^2));

    % spoke locations
    pos = cat(1,pos(1,:),mean(pos),pos(2,:));

    % spokes
    rad     = 2*maxrad;
    tangent = [-vec(2),vec(1)];
    xspoke  = NaN(3,3);
    yspoke  = NaN(3,3);
    for k = 1:3
        tmpA = pos(k,:) + tangent*rad;
        tmpB = pos(k,:) - tangent*rad;
        xspoke(:,k) = [tmpA(1),tmpB(1),NaN]';
        yspoke(:,k) = [tmpA(2),tmpB(2),NaN]';
    end

    % spoke/contour intersections, sorted by distance along
    % the full combined contour
    [x,y,i] = intersections(...
        Cclose(:,1),Cclose(:,2),xspoke(:),yspoke(:));
    [i,idx] = sort(i);
    x = x(idx); y = y(idx);

    % contour+intersections
    node = [x(:) y(:); C];
    idx  = [i(:)', 1:size(C,1)];

    % note current index into "node" of end of epicardial contour
    epidx = size(Ccell{1},1) + numel(i);

    % full ordered contour with intersections
    [val,order,map] = unique(idx,'first');
    node = node(order,:);

    % define the 7 segments, via their node indices
    tmp = map(1:numel(i));
    tmp = tmp(:)';

    N1 = map(epidx);
    N2 = size(node,1);
    segep = [1, tmp(1:6), N1];
    segen = [N1+1, tmp(7:end), N2];

    seg = [segep(:),flipud(segen(:))];

    % individual borders + intersections
    Cep0 = node(1:N1,:);
    Cen0 = flipud(node(N1+1:end,:));

    idxep = seg(:,1);
    idxen = size(node,1)+1 - seg(:,2);

    % distance between nodes
    dep0 = cumsum([0; sqrt(sum(diff(Cep0).^2,2))]);
    den0 = cumsum([0; sqrt(sum(diff(Cen0).^2,2))]);


    % parameterize contours
    N   = NaN(7,1);
    Cen = cell(7,1);
    sen = cell(7,1);
    Cep = cell(7,1);
    sep = cell(7,1);
    si  = cell(7,1);

    for k = 1:Nseg

        % endocardial segment indices
        idx = idxen(k):idxen(k+1);

        % single index
        if numel(idx) == 1
            sen{k} = [k-1;k];
            Nen = 2;
            Cen{k} = repmat(Cen0(idx,:),[2 1]);

        % multiple indices
        else
            d = den0(idx);
            s = (d-min(d))/(max(d)-min(d));
            sen{k} = (k-1) + s;
            Nen = ceil((d(end)-d(1)) / res);
            Cen{k} = Cen0(idx,:);
        end


        % epicardial indices
        idx = idxep(k):idxep(k+1);

        % single index
        if numel(idx) == 1
            sep{k} = [k-1;k];
            Nep = 2;
            Cep{k} = repmat(Cep0(idx,:),[2 1]);

        % multiple indices
        else
            d = dep0(idx);
            s = (d-min(d))/(max(d)-min(d));
            sep{k} = (k-1) + s;
            Nep = ceil((d(end)-d(1)) / res);
            Cep{k} = Cep0(idx,:);
        end

        % new parameterization
        N(k) = ceil(max([Nen,Nep]));
        si{k} = linspace(k-1,k,N(k))';
    end


    % endocardial points & parameterization
    Cen = cat(1,Cen{:});
    sen = cat(1,sen{:});

    [sen,m,n] = unique(sen);
    Cen = Cen(m,:);

    % epicardial points & parameterization
    Cep = cat(1,Cep{:});
    sep = cat(1,sep{:});

    [sep,m,n] = unique(sep);
    Cep = Cep(m,:);


    % linear interpolation
    spen = spapi(2,sen,Cen');
    spep = spapi(2,sep,Cep');

    si = unique(cat(1,si{:}));
    N  = numel(si);
    enpts = fnval(spen,si)';
    eppts = fnval(spep,si)';


    % vertices
    X = NaN(N,Nline);
    Y = NaN(N,Nline);

    w = linspace(0,1,Nline);
    for k = 1:Nline
        X(:,k) = w(k)*enpts(:,1) + (1-w(k))*eppts(:,1);
        Y(:,k) = w(k)*enpts(:,2) + (1-w(k))*eppts(:,2);
    end

    % quadrilateral identifiers
    id = ceil(si(2:end));
    id = repmat(id(:),[1,Nline-1]);
    sectorid = id;

    id = repmat(1:Nline-1,[N-1,1]);
    layerid = id;

    % triangulate region
    id = cat(3,sectorid,layerid);
    fvc = surf2patch(X,Y,zeros(size(X)),id);%,'triangle');
%     fvc = fvshare(fvc,1e-4);

    v = fvc.vertices(:,[1 2]);
    f = fvc.faces;
    sectorid = fvc.facevertexcdata(:,1);
    layerid  = fvc.facevertexcdata(:,2);




    %
    %
    % if 1, return; end
    %
    %
    % v = [X(:),Y(:)];
    %
    % % 4-point faces
    % f = zeros((Nline-1)*N,4);
    % tmp = [1:N; 2:N,1]';
    % for k = 1:Nline-1
    %     rows = (k-1)*N + (1:N);
    %     f(rows,:) = [tmp,fliplr(tmp)+N] + (k-1)*N;
    % end
    % f(N:N:end,:) = [];
    %
    % % ids
    % id = ceil(si(2:end));
    % id = repmat(id(:),[1,Nline-1]);
    % sectorid = id(:);
    %
    % id = repmat(1:Nline-1,[N-1,1]);
    % layerid = id(:);
    %
    % % triangulate faces
    % f = [f(:,[1 2 3]); f(:,[3 4 1])];
    % sectorid = [sectorid; sectorid];
    % layerid  = [layerid; layerid];
    %
    %
    % tol = 1e-4;
    % fac = 1/tol;
    % vround = round(v*fac)/fac;
    % [uvround,idx,map] = unique(vround,'rows');
    %
    % [idx,m] = sort(idx);
    %
    %
    % if 1, return; end
    %
    % fv = fvshare(struct('faces',f,'vertices',v),1e-4);
    % f = fv.faces;
    % v = fv.vertices;




    % delineate anterior/inferior segments
    if flag_clockwise
        n = [-vec(2),vec(1)];
    else
        n = [vec(2),-vec(1)];
    end

    % face locations (average of vertices)
    Nface = size(f,1);
    pface = NaN(Nface,2);
    for k = 1:2
        tmp = v(:,k);
        tmp = tmp(f);
        pface(:,k) = mean(tmp,2);
    end


    % face orientation
    or = NaN(Nface,1);

    % segment 1|2|3 orientation (towards centerline)
    tf = sectorid==1 | sectorid==2 | sectorid==3;
    theta = atan2(-n(2),-n(1));
    or(tf) = theta;

    % segment 5|6|7 orientation (towards centerline)
    tf = sectorid==5 | sectorid==6 | sectorid==7;
    theta = atan2(n(2),n(1));
    or(tf) = theta;

    % segment 4 orientation (towards pos(1,:))
    tf = sectorid==4;
    theta = atan2(pface(:,2)-pos(1,2),pface(:,1)-pos(1,1));
    or(tf) = theta(tf)+pi;

    % SPECIAL CASE
    if api.Nseg==1
        sectorid(:) = 1;
    end


    % gather output data
    data = struct(...
        'vertices',     v,...
        'faces',        f,...
        'sectorid',     sectorid,...
        'layerid',      layerid,...
        'orientation',  or);


%
%
%     res     = api.Resolution;
%     Ccell   = api.RestingContour;
%     pos     = [api.PositionA; api.PositionB];
%     flag_clockwise = api.Clockwise;
%
%     % ensure clockwise matches input
%     [theta,rad] = cart2pol(Ccell{1}(:,1)-pos(1,1),Ccell{1}(:,2)-pos(1,2));
%     maxrad = max(rad);
%     theta = unwrap(theta);
%     if (~flag_clockwise && theta(end)>theta(1)) || ...
%        ( flag_clockwise && theta(end)<theta(1))
%         Ccell = cellfun(@flipud,Ccell,'uniformoutput',0);
%     end
%
%     % full enclosing contour
%     C = cat(1,Ccell{:});
%     C(end+1,:) = C(1,:);
%
%     % normalized posA->posB vector
%     vec = diff(pos);
%     vec = vec/sqrt(sum(vec.^2));
%
%     % spoke locations
%     pos = cat(1,pos(1,:),mean(pos),pos(2,:));
%
%     % spoke separation distance
%     dist = sqrt(sum(diff(pos).^2,2));
%
%     % spokes
%     rad     = 2*maxrad;
%     tangent = [-vec(2),vec(1)];
%     xspoke  = NaN(3,3);
%     yspoke  = NaN(3,3);
%     for k = 1:3
%         tmpA = pos(k,:) + tangent*rad;
%         tmpB = pos(k,:) - tangent*rad;
%         xspoke(:,k) = [tmpA(1),tmpB(1),NaN]';
%         yspoke(:,k) = [tmpA(2),tmpB(2),NaN]';
%     end
%
%     % spoke/contour intersections, sorted by distance along
%     % the full combined contour
%     [x,y,i] = intersections(...
%         C(:,1),C(:,2),xspoke(:),yspoke(:));
%     [i,idx] = sort(i);
%     x = x(idx); y = y(idx);
%
%     % full contour+intersections
%     node = [x(:) y(:); C];
%     idx  = [i(:)', 1:size(C,1)];
%
%     % note current index into "node" of end of epicardial contour
%     epidx = size(Ccell{1},1) + numel(i);
%
%     % full ordered contour with intersections
%     [val,order,map] = unique(idx,'first');
%     node = node(order,:);
%
%     % define the 7 segments, via their node indices
%     tmp = map(1:numel(i));
%
%     N1 = map(epidx);
%     N2 = map(end);
%     segep = [1, tmp(1:6), N1];
%     segen = [N1+1, tmp(7:end), N2];
%
%     % create edge/face matrices
%     seg = [segep(:),flipud(segen(:))];
%     edge = cell(7,1);
%     face = cell(7,1);
%     offsetface = 0;
%     for k = 1:7
%         tmp = [seg(k,1):seg(k+1,1), seg(k+1,2):seg(k,2)]';
%         edge{k} = [tmp(:),tmp([2:end,1])];
%
%         len = size(edge{k},1);
%         face{k} = offsetface + (1:len);
%         offsetface = offsetface + len;
%     end
%
%     edge = cat(1,edge{:});
%
%     % unstructured mesh via "MESHFACE"
%     % (from matlab file exchange)
%     optA = struct('hmax',res);
%     optB = struct('output',false,'waitbar',false);
%     [v,f,id] = meshfaces(node,edge,face,optA,optB);
%
% %
% %     % sampling grid
% %     Nx = ceil(diff(xrng)/res) + 1;
% %     x  = linspace(xrng(1),xrng(2),Nx);
% %     Ny = ceil(diff(yrng)/res) + 1;
% %     y  = linspace(yrng(1),yrng(2),Ny);
% %
% %     [X,Y] = meshgrid(x,y);
% %
% %     % vertical line segments
% %     xv = [x(:),x(:),NaN(Nx,1)]';
% %     yv = [ones(Nx,1)*y([1 end]),NaN(Nx,1)]';
% %
% %     % horizontal lines segments
% %     xh = [ones(Ny,1)*x([1 end]),NaN(Ny,1)]';
% %     yh = [y(:),y(:),NaN(Ny,1)]';
% %
% %
% %     % various line intersections
% %     [x1,y1,i] = intersections(...
% %         C(:,1),C(:,2),[xv(:);xh(:)],[yv(:);yh(:)]);
% %     Cfull = cat(1,[x1(:),y1(:)],C);
% %     i = [i(:)', 1:size(C,1)];
% %     [val,idx] = sort(i);
% %     Cfull = Cfull(idx,:);
% %
% %
% %     [x2,y2,i2] = intersections(...
% %         xspoke(:),yspoke(:),[xv(:);xh(:)],[yv(:);yh(:)]);
% %
% %     [x3,y3,i3] = intersections(...
% %         xspoke(:),yspoke(:),C(:,1),C(:,2));
% %     [i3,idx] = sort(i3);
% %     x3 = x3(idx); y3 = y3(idx);
% %
% %
% %     x4 = [x2(:);x3(:)]; y4 = [y2(:);y3(:)];
% %     i4 = [i2(:);i3(:)];
% %     [val,idx] = sort(i4);
% %     x4 = x4(idx); y4 = y4(idx);
% %     i4 = i4(idx);
% %
% %
% %     [x5,y5,i5] = intersections(...
% %         C(:,1),C(:,2),xspoke(:),yspoke(:));
% %     [i5,idx] = sort(i5);
% %     x5 = x5(idx); y5 = y5(idx);
% %
% %
% %     % all vertices: grid/contours/intersections
% %     v = cat(1,[X(:),Y(:)],Ccell{:},...
% %         [x1(:),y1(:)],[x2(:),y2(:)],[x3(:),y3(:)]);
% %
% %
% %     % all finite/unique matrices
% %     [tmp,m,n] = unique(v,'rows');
% %     allidx = 1:size(v,1);
% %     tf = ismember(allidx(:),m) & all(isfinite(v),2);
% %     v = v(tf,:);
% %
% %     % triangulate faces
% %     f = delaunay(v(:,1),v(:,2));
% %
% %     % remove all faces not inside resting contours
% %     tf = maskfcn(v(:,1),v(:,2),Ccell);
% %     tf = all(tf(f),2);
% %     f  = f(tf,:);
% %
% %     % remove all unnecessary vertices & remap faces
% %     [idx,m,newf] = unique(f(:));
% %     v = v(idx,:);
% %     f = reshape(newf,size(f));
% %     Nface = size(f,1);
% %
% %
% %
% %     % signed distance to line farthest from apex
% %     r  = [v(:,1)-pos(end,1),v(:,2)-pos(end,2)];
% %     sd = r*vec(:);
% %
% %     % segment IDs
% %     % numbered 1->4, base segments == 1, apical segment == 4
% %     tol = 1e-10;
% %     id  = ones(Nface,1);
% %     for k = 1:3
% %         tf = sd<=tol;
% %         tf = all(tf(f),2);
% %         id(tf) = id(tf)+1;
% %         if k<3, sd = sd+dist(k); end
% %     end
% %
%     % delineate anterior/inferior segments
%     if flag_clockwise
%         n = [-vec(2),vec(1)];
%     else
%         n = [vec(2),-vec(1)];
%     end
% %     sd = r*n(:);
% %     tf = sd<=tol;
% %     tf = all(tf(f),2);
% %     id(tf) = 8-id(tf);
%
%
%     % face locations (average of vertices)
%     Nface = size(f,1);
%     pface = NaN(Nface,2);
%     for k = 1:2
%         tmp = v(:,k);
%         tmp = tmp(f);
%         pface(:,k) = mean(tmp,2);
%     end
%
%
%     % face orientation
%     or = NaN(Nface,1);
%
%     % segment 1|2|3 orientation (towards centerline)
%     tf = id==1 | id==2 | id==3;
%     theta = atan2(-n(2),-n(1));
%     or(tf) = theta;
%
%     % segment 5|6|7 orientation (towards centerline)
%     tf = id==5 | id==6 | id==7;
%     theta = atan2(n(2),n(1));
%     or(tf) = theta;
%
%     % segment 4 orientation (towards pos(1,:))
%     tf = id==4;
%     theta = atan2(pface(:,2)-pos(1,2),pface(:,1)-pos(1,1));
%     or(tf) = theta(tf)+pi;
%
%     % gather output data
%     data = struct(...
%         'vertices',     v,...
%         'faces',        f,...
%         'sectorid',     id,...
%         'layerid',      id,...
%         'orientation',  or);


end




%% OLD CODE
%     % sampling grid
%     Nx = ceil(diff(xrng)/res) + 1;
%     x  = linspace(xrng(1),xrng(2),Nx);
%     Ny = ceil(diff(yrng)/res) + 1;
%     y  = linspace(yrng(1),yrng(2),Ny);
%
%     [X,Y] = meshgrid(x,y);
%
%     % vertical line segments
%     xv = [x(:),x(:),NaN(Nx,1)]';
%     yv = [ones(Nx,1)*y([1 end]),NaN(Nx,1)]';
%
%     % horizontal lines segments
%     xh = [ones(Ny,1)*x([1 end]),NaN(Ny,1)]';
%     yh = [y(:),y(:),NaN(Ny,1)]';
%
%
%     % determine intersections of pixel grid with resting contours
%     [x0,y0] = intersections(...
%         [xv(:);xh(:)],[yv(:);yh(:)],C(:,1),C(:,2));
%
%
%     % triangulate pixel grid/contours/intersections
%     v = cat(1,[X(:),Y(:)],Ccell{:},[x0(:),y0(:)]);
%     v = unique(v,'rows');
%
%     try
%         f = delaunay(v(:,1),v(:,2));
%     catch ERR
%         disp('standard delaunay failed...')
%         f = delaunay(v(:,1),v(:,2),{'Qbb','Qc','QJ'});
%     end
%
%     % remove all faces not inside resting contours
%     tf = maskfcn(v(:,1),v(:,2),Ccell);
%     tf = all(tf(f),2);
%     f  = f(tf,:);
%
%     % remove all unnecessary vertices & remap faces
%     [idx,m,newf] = unique(f(:));
%     v = v(idx,:);
%     f = reshape(newf,size(f));
%



%% END OF FILE=============================================================
