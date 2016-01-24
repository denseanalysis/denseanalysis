function [hgroup,hface,hedge,htext] = bullseye(h,data,varargin)
% [hgroup,hface,hedge,htext] = bullseye(h,data,varargin)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

    % get parent figure and axes handles
    if isempty(h), h = gcf; end

    if ~ishandle(h)
        error(sprintf('%s:expectedHandle',mfilename), ...
            'Parent input is not a valid handle');
    end

    switch get(h, 'Type')
        case 'figure'
            hfig  = h;
            hax = get(hfig, 'CurrentAxes');
            if (isempty(hax))
                hax = axes('Parent',hfig);
            end

        case 'axes'
            hax  = h;
            hfig = ancestor(hax, 'figure');

        otherwise
            error(sprintf('%s:expectedFigureOrAxesHandle',mfilename), ...
                'Parent input should be a figure or axes handle');
    end


    % check for expected data elements
    tags = {'SegmentModel','NumberOfSegments','NumberOfLayers'};
    if ~isstruct(data) || ~all(isfield(data,tags))
        error(sprintf('%s:invalidData',mfilename), ...
            'Unrecognized data input.');
    end
    Ndata = numel(data);



    % parse additional inputs
    defapi = struct(...
        'InnerRadius',      3,...
        'Thickness',        6,...
        'Margin',           0,...
        'SegmentEdgeColor', 'k',...
        'LayerEdgeColor',   .5*[1 1 1],...
        'FontName',         get(0,'DefaultTextFontName'),...
        'FontSize',         10,...
        'FontWeight',       'normal',...
        'FontColor',        [0 0 0],...
        'RotateText',       true);
    api = parseinputs(defapi,[],varargin{:});


    % gather defaults for each dataset
    tags = {'Text','Color','SegmentEdgeColor','LayerEdgeColor'};
    def  = {[],[],api.SegmentEdgeColor,api.LayerEdgeColor};
    for k = 1:Ndata
        for ti = 1:numel(tags)
            tag = tags{ti};
            if ~isfield(data,tag) || isempty(data(k).(tag))
                data(k).(tag) = def{ti};
            end
        end
    end


    % process data elements (note we process the elements in reverse,
    % from the inner to the outer radius)
    Nmin = 120;
    radinner = api.InnerRadius;

    for k = Ndata:-1:1

        % check segment model
        val = data(k).SegmentModel;
        if ~isequal(val,4) && ~isequal(val,6)
            error(sprintf('%s:invalidSegmentModel',mfilename,tag),'%s',...
                'Valid "SegmentModel" values in data structure are 4 and 6.');
        end

        if val==4
            theta0 = pi/4;
        else
            theta0 = pi/3;
        end

        % check segments
        nseg = data(k).NumberOfSegments;
        if isempty(nseg) || ~isnumeric(nseg) || ~isfinite(nseg) || ...
           nseg<=0 || mod(nseg,data(k).SegmentModel)~=0
            error(sprintf('%s:invalidNumberOfSegments',mfilename,tag),'%s',...
                 'A valid "NumberOfSegments" value in the data structure ',...
                 'is a positive multiple of the corresponding ',...
                 '"SegmentModel" value.');
        end


        % check layers
        nlay = data(k).NumberOfLayers;
        if isempty(nlay) || ~isnumeric(nlay) || ~isfinite(nlay) || ...
           nlay<=0 || mod(nlay,1)~=0
            error(sprintf('%s:invalidNumberOfLayers',mfilename),'%s',...
                'A valid "NumberOfLayers" value in the data structure ',...
                'is a positive integer.');
        end

        % number of faces
        nface = nseg*nlay;

        % check/expand text
        val = data(k).Text;
        if isempty(val), val = repmat({''},[nface,1]); end

        if numel(val)~=nface
            error(sprintf('%s:invalidText',mfilename),'%s',...
                'Text size in data structure must be ',...
                '[NumberOfSegments x NumberOfLayers]');
        end

        if isnumeric(val)
            val = arrayfun(@(v)num2str(v),val,'uniformoutput',0);
        elseif ~iscellstr(val)
            error(sprintf('%s:invalidText',mfilename),'%s',...
                'Text in data structure must be empty, a matrix of ',...
                'numeric values, or a cell matrix of strings.');
        end

        data(k).Text = val(:);


        % check/expand face colors
        val = data(k).Color;
        if isempty(val) || isequal(val,'none')
            data(k).FaceColor = 'none';
            data(k).FaceVertexCData = [];

        elseif iscolor(val)
            data(k).FaceColor = clr2num(val);
            data(k).FaceVerxtexCData = [];

        elseif iscell(val) && numel(val)==nface && ...
           all(cellfun(@iscolor,val))
            tmp = cellfun(@clr2num,val,'uniformoutput',0);
            tmp = cat(1,tmp{:});
            data(k).FaceColor = 'flat';
            data(k).FaceVertexCData = tmp;

        elseif isnumeric(val) && ndims(val)==2 && all(size(val)==[nface,3])
            data(k).FaceColor = 'flat';
            data(k).FaceVertexCData = val;

        else
            error(sprintf('%s:invalidColor',mfilename),'%s',...
                'Unrecognized "Color" in data structure.');
        end


        % determine vertices & faces
        rad = linspace(radinner+api.Thickness,radinner,nlay+1);

        nperseg = ceil(Nmin/nseg);
        n = nseg*nperseg;

        theta = linspace(0,2*pi,n+1) + theta0;
        theta = theta(1:end-1);

        [T,R] = ndgrid(theta,rad);
        [X,Y] = pol2cart(T,R);

        IND = reshape(1:(n*(nlay+1)),size(X));

        INDA = reshape(IND(:,1:end-1),[nperseg,nseg*nlay])';
        INDB = reshape(IND(:,2:end),[nperseg,nseg*nlay])';

        endrow = reshape(1:size(INDA,1),[nseg,nlay]);
        endrow = endrow([2:end,1],:);
        endrow = endrow(:);

        INDA(:,end+1) = INDA(endrow,1);
        INDB(:,end+1) = INDB(endrow,1);

        data(k).Vertices = [X(:),Y(:)];
        data(k).Faces = [INDA,INDB(:,end:-1:1)];


        % all layer faces
        n = size(X,1);
        tmp = bsxfun(@plus,[1:n,1],((0:nlay)*n)');

        data(k).SegmentFaces = tmp([1 end],:);
        data(k).LayerFaces = tmp(2:end-1,:);

        % spoke faces
        data(k).SpokeFaces = data(k).Faces(:,[1 end]);


        % face centers
        th = T(data(k).Faces);
        th = unwrap(th,[],2);
        th = mean(th,2);
        th = mod(th+pi,2*pi)-pi;

        rd = mean(R(data(k).Faces),2);

        [x,y] = pol2cart(th,rd);

        data(k).Centroid = [x(:),y(:)];

        % text rotation
        if api.RotateText
            rot = th - (pi/2);
            rot = mod(rot+pi,2*pi)-pi;

            tf = abs(rot)>pi/2;
            rot(tf) = rot(tf)+pi;
            rot = mod(rot+pi,2*pi)-pi;

            rot = rot*180/pi;
            data(k).TextRotation = num2cell(rot);
        else
            data(k).TextRotation = zeros(size(th));
        end

        % update inner radius;
        radinner = radinner + api.Thickness + api.Margin;

    end

    hgroup = [];


    % display limits
    dsprng = 1.05*radinner * [-1 1 -1 1];

    % ready axes for display
    set(hax,'xlim',dsprng(1:2),'ylim',dsprng(3:4),'zlim',[-1 1],...
        'dataaspectratio',[1 1 1],'xdir','normal','ydir','normal','layer','top');

    % create data group
    hgroup = hggroup('parent',hax);

    % display
    hface  = NaN(Ndata,1);
    houteredge = NaN(Ndata,1);
    hinneredge = NaN(Ndata,1);
    hspoke = NaN(Ndata,1);
    htext = cell(Ndata,1);
    for k = 1:Ndata
        str = sprintf('bullseye%d-',k);
        hface(k) = patch('parent',hgroup,'vertices',data(k).Vertices,...
            'Faces',data(k).Faces,'facecolor',data(k).FaceColor,...
            'facevertexcdata',data(k).FaceVertexCData,...
            'EdgeColor','none',...
            'tag',[str,'face']);

        houteredge(k) = patch('parent',hgroup,'vertices',data(k).Vertices,...
            'Faces',data(k).SegmentFaces,'facecolor','none',...
            'EdgeColor',data(k).SegmentEdgeColor,'LineStyle','-',...
            'tag',[str,'segmentedge']);
%
        hinneredge(k) = patch('parent',hgroup,'vertices',data(k).Vertices,...
            'Faces',data(k).LayerFaces,'facecolor','none',...
            'EdgeColor',data(k).LayerEdgeColor,'LineStyle','--',...
            'tag',[str,'layeredge']);
%
        hspoke(k) = patch('parent',hgroup,'vertices',data(k).Vertices,...
            'Faces',data(k).SpokeFaces,'facecolor','none',...
            'EdgeColor',data(k).SegmentEdgeColor,'LineStyle','-',...
            'tag',[str,'spokeedge']);

        pos = data(k).Centroid;
        pos(:,3) = 0.1;
        htext{k} = text(pos(:,1),pos(:,2),pos(:,3),data(k).Text,...
            'parent',hgroup,...
            'horizontalalignment','center','verticalalignment','middle',...
            'Fontsize',api.FontSize,'fontname',api.FontName,...
            'color',api.FontColor,...
            'tag',[str,'text']);
        set(htext{k},{'Rotation'},data(k).TextRotation(:));

    %     for i = 1:numel(htext{k})
    %         set(htext{k}(i),'Rotation',60);%data(k).TextRotation{i});
    %     end

    end

    hedge = [houteredge(:),hspoke(:),hinneredge(:),];


    set([hgroup;hedge(:);cat(1,htext{:})],'hittest','off');



end
