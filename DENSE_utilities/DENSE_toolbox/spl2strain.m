function data = spl2strain(varargin)
% data = spl2strain(varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    defapi = struct(...
        'Type',                 'unknown',...
        'Mag',                  [],...
        'RestingContour',       [],...
        'FramesForAnalysis',    [],...
        'spldx',                [],...
        'spldy',                [],...
        'spldz',                [],...
        'MaskFcn',              [],...
        'xrng',                 [],...
        'yrng',                 [],...
        'Resolution',           1,...
        'PositionA',            [],...
        'PositionB',            [],...
        'Nmodel',               [],...
        'Nseg',                 [],...
        'Clockwise',            [],...
        'PositionIndices',      [],...
        'SegmentModelPanel',    false);

    api = parseinputs(defapi,[],varargin{:});

    if api.SegmentModelPanel
        opts = segmentmodel(api);
        drawnow
        if isempty(opts)
            data = [];
            return
        end
        tags = fieldnames(opts);
        for ti = 1:numel(tags)
            api.(tags{ti}) = opts.(tags{ti});
        end
    end

    % determine face/vertex patch structure
    switch lower(api.Type)
        case 'sa'
            fv = spl2patchSA(api);
        case 'la'
            fv = spl2patchLA(api);
        case {'open','closed'}
            fv = spl2patchContour(api);
        otherwise
            fv = spl2patchGeneral(api);
    end

    % times
    api.times = api.FramesForAnalysis(1):api.FramesForAnalysis(2);

    % output structure
    data = struct;

    % copy application data fields to the output
    tags = {'PositionA','PositionB','Nmodel','Nseg',...
        'Clockwise','PositionIndices','Resolution','xrng','yrng'};
    for ti = 1:numel(tags)
        data.(tags{ti}) = api.(tags{ti});
    end

    % contour strain
    if any(strcmpi(api.Type,{'open','closed'}))

        str = contourstrain(api,fv);
        str = rmfield(str,{'vertices','faces'});

        data.fv     = fv;
        data.strain = str;


    % patch/pixel strain
    else
        str = patchstrain(api,fv);
        str = rmfield(str,{'vertices','faces','orientation'});

        pixapi = spl2pixel(api);
        strpix = pixelstrain(api,pixapi);

        fvpix  = struct('vertices',strpix.vertices,...
            'faces',strpix.faces,'orientation',strpix.orientation,...
            'maskimage',strpix.maskimage);
        strpix = rmfield(strpix,fieldnames(fvpix));

        data.fv     = fv;
        data.strain = str;

        data.fvpix     = fvpix;
        data.strainpix = strpix;
    end


end




function fv = spl2patchGeneral(api)

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
            edge = [];
            face = [];
            %{
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
            %}
    end


    % unstructured mesh via "MESHFACE"
    % (from matlab file exchange)
    optA = struct('hmax',res);
    optB = struct('output',false,'waitbar',false);
    [v,f,id] = meshfaces(C,edge,face,optA,optB);

    % gather output data
    fv = struct(...
        'vertices',     v,...
        'faces',        f,...
        'sectorid',     id,...
        'layerid',      id,...
        'orientation',  []);

end


%% CONTOUR PATCH
function fv = spl2patchContour(api)

    % contours
    Ccell = api.RestingContour;
    Nc = numel(Ccell);

    % contour vertices
    v = cat(1,Ccell{:});

    % contour faces
    N = cellfun(@(c)size(c,1),Ccell);
    f = cell(Nc,1);
    for k = 1:Nc
        f{k} = sum(N(1:k-1)) + [1:N(k)-1; 2:N(k)]';
    end
    f = cat(1,f{:});

    % sector ID
    sectorid = cell(Nc,1);
    nbr = 0;
    for k = 1:Nc
        idx = api.PositionIndices{k};
        npt = numel(idx);
        id = zeros(N(k)-1,1);
        for n = 1:npt-1
            mn = min(idx([n n+1]));
            mx = max(idx([n n+1]));
            id(mn:mx-1) = nbr+n;
        end
        sectorid{k} = id;
        nbr = nbr+(npt-1);
    end
    sectorid = cat(1,sectorid{k});

    % single layer id
    layerid = ones(size(f,1),1);

    % gather output data
    fv = struct(...
        'vertices',     v,...
        'faces',        f,...
        'sectorid',     sectorid,...
        'layerid',      layerid,...
        'orientation',  []);

end


%% SHORT AXIS PATCH
function fv = spl2patchSA(api)

    maxseg = 132;

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
    [or,rad] = cart2pol(origin(1)-pface(:,1),origin(2)-pface(:,2));


    % gather output data
    fv = struct(...
        'vertices',     v,...
        'faces',        f,...
        'sectorid',     sectorid,...
        'layerid',      layerid,...
        'orientation',  or);

end


%% LONG AXIS PATCH
function fv = spl2patchLA(api)

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

    % mesh region
    id = cat(3,sectorid,layerid);
    fvc = surf2patch(X,Y,zeros(size(X)),id);%,'triangle');
%     fvc = fvshare(fvc,1e-4);

    v = fvc.vertices(:,[1 2]);
    f = fvc.faces;
    sectorid = fvc.facevertexcdata(:,1);
    layerid  = fvc.facevertexcdata(:,2);


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


    % orientation
    or = orientLA(pos(1,:),pos(end,:),pface(:,1),pface(:,2));

%     % line segment information
%     x = pos([1 end],1);
%     y = pos([1 end],2);
%     dx = diff(x);
%     dy = diff(y);
%     L2 = dx.^2 + dy.^2;
%
%     % face parameters
%     r = ((pface(:,1)-x(1))*dx + (pface(:,2)-y(1))*dy) / L2;
%     s = ((pface(:,1)-x(1))*dy - (pface(:,2)-y(1))*dx) / L2;
%
%     % normals
%     nx =  dy*ones(Nface,1);
%     ny = -dx*ones(Nface,1);
%
%     tf = s>0;
%     nx(tf) = -nx(tf);
%     ny(tf) = -ny(tf);
%
%     tf = r<0;
%     nx(tf) = x(1)-pface(tf,1);
%     ny(tf) = y(1)-pface(tf,2);
%
%     tf = r>1;
%     nx(tf) = x(2)-pface(tf,1);
%     ny(tf) = y(2)-pface(tf,2);
%
%     nmag = sqrt(nx.^2 + ny.^2);
%     nx = nx./(nmag+eps);
%     ny = ny./(nmag+eps);
%
%     % face orientation
%     or = atan2(ny,nx);

    % SPECIAL CASE
    if api.Nseg==1
        sectorid(:) = 1;
    end


    % gather output data
    fv = struct(...
        'vertices',     v,...
        'faces',        f,...
        'sectorid',     sectorid,...
        'layerid',      layerid,...
        'orientation',  or);

end



%% PIXEL STRAIN
function data = spl2pixel(api)

    type = api.Type;
    x = api.xrng(1):api.xrng(2);
    y = api.yrng(1):api.yrng(2);

    [X,Y] = meshgrid(x,y);
    mask = api.MaskFcn(X,Y,api.RestingContour);

    % determine pixel orientation
    switch lower(type)
        case 'la'
            or = orientLA(api.PositionA,api.PositionB,X,Y);
        case 'sa'
            origin = api.PositionA;
            [or,rad] = cart2pol(origin(1)-X,origin(2)-Y);
        otherwise
            or = [];
    end

    % gather output data
    data = struct(...
        'X',            X,...
        'Y',            Y,...
        'mask',         mask,...
        'Orientation',  or);
end



function or = orientLA(p0,p1,X,Y)

    % line segment information
    dx = p1(1)-p0(1);
    dy = p1(2)-p0(2);
    L2 = dx.^2 + dy.^2;

    % face parameters
    r = ((X-p0(1))*dx + (Y-p0(2))*dy) / L2;
    s = ((X-p0(1))*dy - (Y-p0(2))*dx) / L2;

    % normals
    nx =  dy*ones(size(X));
    ny = -dx*ones(size(X));

    tf = s>0;
    nx(tf) = -nx(tf);
    ny(tf) = -ny(tf);

    tf = r<0;
    nx(tf) = p0(1)-X(tf);
    ny(tf) = p0(2)-Y(tf);

    tf = r>1;
    nx(tf) = p1(1)-X(tf);
    ny(tf) = p1(2)-Y(tf);

    nmag = sqrt(nx.^2 + ny.^2);
    nx = nx./(nmag+eps);
    ny = ny./(nmag+eps);

    % face orientation
    or = atan2(ny,nx);

end



%% END OF FILE=============================================================
