function options = segmentmodel(varargin)
% options = segmentmodel(varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    errid = sprintf('%s:invalidInput',mfilename);

    % parse input arguements
    defargs = struct(...
        'Type',                 'sa',...
        'Mag',                  [],...
        'FramesForAnalysis',    [],...
        'RestingContour',       [],...
        'spldx',                [],...
        'spldy',                [],...
        'PositionA',            [],...
        'PositionB',            [],...
        'Clockwise',            false,...
        'Nmodel',               [],...
        'Nseg',                 [],...
        'MaxSegments',          132,...
        'PositionIndices',      []);

    api = parseinputs(defargs,[],varargin{:});

    % check type
    types = {'SA','LA','open','closed'};
    if ~ischar(api.Type) || ~any(strcmpi(api.Type,types))
        error(errid,'Invalid Type.');
    end



    % check MAG
    if ~isnumeric(api.Mag) || ~any(ndims(api.Mag)==[2 3])
       error(errid,'Invalid Mag.');
    end
    api.Isz = size(api.Mag(:,:,1));
    api.Nfr = size(api.Mag,3);


    % check frames of interest
    checkfcn = @(x)isnumeric(x) && numel(x)==2 && ...
        all(mod(x,1)==0) && all(1<=x & x<=api.Nfr) && x(2)>=x(1);

    if isempty(api.FramesForAnalysis)
        api.FramesForAnalysis = [1 api.Nfr];
        tfframes = true(1,api.Nfr);
    else
        if ~checkfcn(api.FramesForAnalysis)
            error(errid,'Invalid FramesForAnalysis.');
        end
        frrng = api.FramesForAnalysis;
        tfframes = false(1,api.Nfr);
        tfframes(frrng(1):frrng(2)) = true;
    end


    % check resting contour
    C0 = api.RestingContour;
    checkfcn = @(c)ismatrix(c) && size(c,1) > 3 && size(c,2) == 2;
    if ~iscell(C0) || ~all(cellfun(checkfcn,C0))
        error(errid,'Invalid RestingContour.');
    elseif any(strcmpi(api.Type,{'SA','LA'})) && numel(C0)~=2
        error(errid,'Invalid RestingContour.');
    end

% %     if any(strcmpi(api.Type,{'open','closed'}))
% %         if numel(C0)>1
% %             error(errid,'Invalid RestingContour; too many contours.');
% %         end
% %     end


    % contour trajectories
    % --note this effectively checks the spline data
    % --note also we don't use the DENSEdata "Contours" property, as we
    %   instead require the position of "RestingContour" on each frame.
    try
        C = cell(api.Nfr,numel(C0));
        for k = 1:numel(C0)
            pts = C0{k}';
            for fr = 1:api.Nfr
                if ~tfframes(fr), continue; end
                pts(3,:) = fr;
                dx = fnvalmod(api.spldx,pts([2 1 3],:));
                dy = fnvalmod(api.spldy,pts([2 1 3],:));
                C{fr,k} = C0{k} + [dx(:),dy(:)];
            end
        end
        api.Contour = C;
    catch ERR
        ERR.getReport()
        ME = MException(errid,'Invalid spline data.');
        ME.addCause(ERR);
        throw(ME);
    end


    % display range
    brdr = 5;
    Call = cat(1,C0{:},C{:});
    mn = max(1, floor(min(Call))-brdr);
    mx = min(api.Isz, ceil(max(Call))+brdr);
    api.drng = [mn(1),mx(1),mn(2),mx(2)] + [-.5 .5 -.5 .5];


    % SA/LA checks
    if any(strcmpi(api.Type,{'SA','LA'}))

        % application data fields to remove
        tagremove = {'PositionIndices'};

        % auto origin
        api.autoorigin = mean(C0{1});

        % check input positions
        checkfcn1 = @(x)isnumeric(x) && all(isfinite(x)) && numel(x)==2;
        checkfcn2 = @(x)inpolygon(x(1),x(2),C0{2}(:,1),C0{2}(:,2));

        if ~isempty(api.PositionA)
            if ~checkfcn1(api.PositionA) || ~checkfcn2(api.PositionA)
                error(errid,'Invalid PositionA; must be within endocardium.');
            end
        end

        if ~isempty(api.PositionB)
            if ~checkfcn1(api.PositionB)
                error(errid,'Invalid PositionB.');
            elseif strcmpi(api.Type,'LA') && ~checkfcn2(api.PositionB)
                error(errid,'Invalid PositionB; must be within endocardium.');
            end
        end


        % check clockwise
        api.Clockwise = isequal(api.Clockwise,true);


        % check Nmodel/Nseg
        checkmodel = @(x,vals)isnumeric(x) && isscalar(x) && ...
            isfinite(x) && any(x==vals);
        checkseg   = @(x)isnumeric(x) && isscalar(x) && ...
            isfinite(x) && 0<x && (x==1 || rem(x,api.Nmodel)==0);

        switch lower(api.Type)
            case 'sa'
                if isempty(api.Nmodel)
                    api.Nmodel = 6;
                elseif ~checkmodel(api.Nmodel,[4 6])
                    error(errid,'Invalid Nmodel.');
                end
                if isempty(api.Nseg)
                    api.Nseg = api.Nmodel;
                elseif ~checkseg(api.Nseg)
                    error(errid,'Invalid Nseg.');
                end

            case 'la'
                if isempty(api.Nmodel)
                    api.Nmodel = 7;
                elseif ~checkmodel(api.Nmodel,7)
                    error(errid,'Invalid Nmodel.');
                end
                if isempty(api.Nseg)
                    api.Nseg = api.Nmodel;
                elseif ~checkseg(api.Nseg)
                    error(errid,'Invalid Nseg.');
                end

        end

    % CONTOUR checks
    else

        % application data fields to remove
        tagremove = {'PositionA','PositionB','Clockwise','Nmodel','Nseg'};

        % check position indices
        nbr = cellfun(@(c)size(c,1),C0);

        if isempty(api.PositionIndices)
            idx = cell(size(C0));
            for k = 1:numel(C0)
                idx{k} = unique(round(linspace(1,nbr(k),5)));
            end
        else
            idx = api.PositionIndices;

            checkfcn = @(i,n)isnumeric(i) && ismatrix(i) && ...
                any(size(i)==1) && all(isfinite(i)) && ...
                all(mod(i,1)==0) && all(1<=i & i<=n);
            if ~iscell(idx) || numel(idx)~=numel(C0) || ...
               ~all(cellfun(checkfcn,idx,num2cell(nbr)))
                error(errid,'Invalid PositionIndices.');
            end
        end

        % ensure 1st & last contour points are represented
        for k = 1:numel(C0)
            if ~(idx{k}(1)==1 && idx{k}(end)==nbr(k)) && ...
               ~(idx{k}(1)==nbr(k) && idx{k}(end)==1)
                error(errid,'Invalid PositionIndices.');
            end
        end

        % save position indices
        api.PositionIndices = idx;

    end


    % alter maximum segments
    if strcmpi(api.Type,'LA')
        api.MaxSegments = 7;
    elseif any(strcmpi(api.Type,{'open','closed'}))
        nbr = cellfun(@(c)size(c,1),C0);
        api.MaxSegments = sum(nbr);
    end

    % check MagSegments
    checkfcn = @(x)isnumeric(x) && isscalar(x) && isfinite(x);
    if ~checkfcn(api.MaxSegments)
        error(errid,'Invalid MaxSegments.');
    elseif any(strcmpi(api.Type,{'SA','LA'})) && api.Nseg>api.MaxSegments
        error(errid,'Invalid MaxSegments.');
    end


    % remove unnecessary fields
    api = rmfield(api,tagremove);



    %% LOAD GUI & PASS TO MAIN FUNCTION

    % load gui
    hfig = hgload([mfilename '.fig']);
    cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
    api.hfig = hfig;
    set(api.hfig,'renderer','zbuffer','colormap',gray(256));

    % gather controls
    hchild = findobj(hfig);
    tags = get(hchild,'tag');
    for ti = 1:numel(hchild)
        if ~isempty(tags{ti}) && strcmpi(tags{ti}(1),'h')
            api.(tags{ti}) = hchild(ti);
        end
    end

    % pass to the subfunction
    options = mainFcn(api);


end



%% MAIN FUNCTION
function options = mainFcn(api)

    % colors
    api.clrA = [1 0.5 0];
    api.clrB = [0.5 0.5 1.0];
    api.clrP = [0.75 0.25 1];
    api.clrH = [1 1 0];


    % COMMON INITIALIZATION------------------------------------------------


    % display magnitude image
    api.him = image('parent',api.hmag,...
        'cdata',zeros(api.Isz),...
        'cdatamapping','scaled');
    set(api.hmag,'clim',[0 1]);
    set(api.hfig,'colormap',gray(256),'renderer','zbuffer');

    % link axes / set display limits
    linkaxes([api.hrest,api.hmag]);
    axis(api.hmag,api.drng);

    % axes titles
    htitle(1) = title(api.hrest,'Resting Contours');
    htitle(2) = title(api.hmag,'Magnitude Viewer');
    set(htitle,'fontweight','bold','fontsize',12);


    % display contours
    if any(strcmpi(api.Type,{'SA','LA'}))
        clrs = [1 0 0; 0 1 0];
    else
        clrs = api.clrB;
    end

    Ncontour = numel(api.RestingContour);
    api.hcontour = preAllocateGraphicsObjects(Ncontour,1);
    api.hcontourmag = preAllocateGraphicsObjects(Ncontour,1);
    for k = 1:numel(api.RestingContour)
        api.hcontour(k) = line(...
            'parent',api.hrest,...
            'xdata',api.RestingContour{k}(:,1),...
            'ydata',api.RestingContour{k}(:,2),...
            'color',clrs(min(k,size(clrs,1)),:),...
            'hittest','off');
        api.hcontourmag(k) = copyobj(api.hcontour(k),api.hmag);
    end
%     heprest = line('parent',api.hrest,...
%         'xdata',api.RestingContour{1}(:,1),...
%         'ydata',api.RestingContour{1}(:,2),...
%         'color','r','hittest','off');
%     henrest = line('parent',api.hrest,...
%         'xdata',api.RestingContour{2}(:,1),...
%         'ydata',api.RestingContour{2}(:,2),...
%         'color','g','hittest','off');
%
%     % display frame contours
%     api.hep = copyobj(heprest,api.hmag);
%     api.hen = copyobj(henrest,api.hmag);


    % interactive points
    if any(strcmpi(api.Type,{'SA','LA'}))
        Npt = 2;
    else
        nbr = cellfun(@(i)numel(i),api.PositionIndices);
        Npt = sum(nbr) - 2*Ncontour;
    end

    api.hpoint = preAllocateGraphicsObjects(Npt,1);
    api.constrainFcn = cell(Npt,1);

    api.hpoint = pointCreate(api.hrest,api.clrP,Npt);
    api.constrainFcn = cell(Npt,1);
%     for k = 1:Npt
%         api.hpoint(k) = line(...
%             'parent',       api.hrest,...
%             'color',        api.clrP,...
%             'marker',       'o',...
%             'markersize',   15,...
%             'linewidth',    3);
%
%         pb = struct(...
%             'enterFcn',     @(varargin)pointEnter(api.hpoint(k),api.hfig),...
%             'traverseFcn',  [],...
%             'exitFcn',      @(varargin)pointExit(api.hpoint(k),api.hfig));
%         iptSetPointerBehavior(api.hpoint(k),pb);
%
%         set(api.hpoint(k),'ButtonDownFcn',...
%             @(varargin)pointDrag(api.hpoint(k),api.hfig));
%     end


    % COMMON CARDIAC INITIALIZATION----------------------------------------
    if any(strcmpi(api.Type,{'SA','LA'}))

        % minor spokes
        api.hspokeminor = patch(...
            'parent',           api.hrest,...
            'vertices',         NaN(1,2),...
            'faces',            1,...
            'edgecolor',        'flat',...
            'facecolor',        'none',...
            'facevertexcdata',  NaN(1,3),...
            'linestyle',        '--',...
            'hittest',          'off');

        % major spokes
        api.hspokemajor = copyobj(api.hspokeminor,api.hrest);
        set(api.hspokemajor,'linestyle','-');

        % primary spoke
        api.hspoke1 = copyobj(api.hspokeminor,api.hrest);
        set(api.hspoke1,'linestyle','-','linewidth',2,'edgecolor',api.clrA);


        % major intersections
        api.hcross = patch(...
            'parent',           api.hrest,...
            'vertices',         NaN(1,2),...
            'faces',            1,...
            'edgecolor',        'none',...
            'facecolor',        'none',...
            'markerfacecolor',  'flat',...
            'markeredgecolor',  'flat',...
            'marker',           'o',...
            'markersize',       6,...
            'facevertexcdata',  NaN(1,3),...
            'hittest',          'off');

        % primary intersection
        api.hcross1 = copyobj(api.hcross,api.hrest);
        set(api.hcross1,'marker','s');

        % copy intersection object to magnitude display
        api.hcrossmag  = copyobj(api.hcross, api.hmag);
        api.hcross1mag = copyobj(api.hcross1,api.hmag);

    %     tags = {'Faces','facevertexcdata'};
    %     hlink = linkprop([api.hcross,api.hcrossmag],tags);
    %     setappdata(hcrossmag,'face_link',hlink);
    %     hlink = linkprop([api.hcross1,api.hcrossmag1],tags);
    %     setappdata(hcrossmag1,'face_link',hlink);

    end



    % SHORT AXIS INITIALIZATION--------------------------------------------
    if strcmpi(api.Type,'SA')

        % redraw function
        api.redrawFcn = @redrawSA;

        % constraint functions
        api.constrainFcn{1} = @(varargin)constrainInContour(...
            varargin{:},api.RestingContour{2});
        api.constrainFcn{2} = @(varargin)constrainOnContour(...
            varargin{:},api.RestingContour{1});

        % auotmated point locations
        pos = api.autoorigin;
        set(api.hpoint(1),'xdata',pos(1),'ydata',pos(2),'hittest','off');
        pos = api.RestingContour{1}(1,:);
        set(api.hpoint(2),'xdata',pos(1),'ydata',pos(2));

        % inputted point locations
        if ~isempty(api.PositionA)
            pos = api.constrainFcn{1}(api.hpoint(1),api.PositionA,api);
            set(api.hpoint(1),'xdata',pos(1),'ydata',pos(2),'hittest','on');
            set(api.huser,'value',1);
        end

        if ~isempty(api.PositionB)
            pos = api.constrainFcn{2}(api.hpoint(2),api.PositionB,api);
            set(api.hpoint(2),'xdata',pos(1),'ydata',pos(2));
        end

        % Nmodel popup
        str = {'6 segments','4 segments'};
        val = find(api.Nmodel==[6,4]);
        set(api.hmodel,'String',str,'Value',val);

        % Nseg popup
        seg = [1,api.Nmodel:api.Nmodel:api.MaxSegments];
        val = find(api.Nseg==seg);
        set(api.hnseg,'String',num2cell(seg),'Value',val);

        % note to user
        note = sprintf('%s','Adjust the purple positions. ',...
            'The orange lines define the anterior segment. ',...
            'Segments are numbered from from the thick orange ',...
            'line in the direction specified.');


    % LONG AXIS INITIALIZATION---------------------------------------------
    elseif strcmpi(api.Type,'LA')

        % connector line
        pos = [api.RestingContour{1}(1,:); api.RestingContour{2}(end,:);
               NaN,NaN;
               api.RestingContour{2}(1,:); api.RestingContour{1}(end,:)];
        hconnect = line('parent',api.hrest,...
            'xdata',pos(:,1),'ydata',pos(:,2),...
            'color','b','hittest','off');
        api.hconnect = copyobj(hconnect,api.hmag);

        % redraw function
        api.redrawFcn = @redrawLA;

        % constraint functions
        api.constrainFcn{1} = @(varargin)...
            constrainInContour(varargin{:},api.RestingContour{2});
        api.constrainFcn{2} = @(varargin)...
            constrainInContour(varargin{:},api.RestingContour{2});

        % primary location
        C  = api.RestingContour{2};
        d1 = (C(1,1)-C(:,1)).^2 + (C(1,2)-C(:,2)).^2;
        d2 = (C(end,1)-C(:,1)).^2 + (C(end,2)-C(:,2)).^2;
        [val,idx] = max(d1+d2);
        posA = C(idx,:);

        % secondary location
        posB = mean(api.RestingContour{2}([1 end],:));

        % automated point locations
        fac = [0.01 0.75];
        pos = NaN(2,2);
        for k = 1:2
            pos(k,:) = fac(k)*(posB-posA) + posA;
        end
        set(api.hpoint,{'xdata'},num2cell(pos(:,1)),...
            {'ydata'},num2cell(pos(:,2)));

        % inputted point locations
        if ~isempty(api.PositionA)
            pos = api.constrainFcn{1}(api.hpoint(1),api.PositionA,api);
            set(api.hpoint(1),'xdata',pos(1),'ydata',pos(2));
        end

        if ~isempty(api.PositionB)
            pos = api.constrainFcn{2}(api.hpoint(2),api.PositionB,api);
            set(api.hpoint(2),'xdata',pos(1),'ydata',pos(2));
        end

        % Nmodel popup
        set(api.hmodel,'String',{'7 segments'},...
            'Value',1,'enable','off');

        % Nseg popup
        seg = [1,api.Nmodel:api.Nmodel:api.MaxSegments];
        val = find(api.Nseg==seg);
        set(api.hnseg,'String',num2cell(seg),'Value',val,'enable','on');

        % additional control setup
        set(api.huser,'value',1);
        set(api.hauto,'enable','off');

        % note to user
        note = sprintf('%s','Adjust the purple positions. ',...
            'The orange lines define the first segment. ',...
            'Segments are numbered from [1:7] ',...
            'in the direction specified.');


    % CONTOUR INITIALIZATION-----------------------------------------------
    else

        % redraw function
        api.redrawFcn = @redrawContour;

        % update active points
        vert = cell(Ncontour,1);
        cidx = cell(Ncontour,1);
        for k = 1:Ncontour
            C0 = api.RestingContour{k};
            idx = api.PositionIndices{k};
            vert{k} = C0(idx(2:end-1),:);
            n = size(vert{k},1);
            cidx{k} = k*ones(n,1);
        end
        vert = cat(1,vert{:});
        cidx = cat(1,cidx{:});

        api.crvIDX = cidx(:);
        api.constrainFcn{1} = cell(Ncontour,1);

        for k = 1:Npt
            api.constrainFcn{k} = @(varargin)constrainToPoints(...
                varargin{:},api.RestingContour{cidx(k)});
            set(api.hpoint(k),'xdata',vert(k,1),'ydata',vert(k,2));
        end


        % 1st segment
        api.hsegment = patch(...
            'parent',           api.hrest,...
            'vertices',         NaN(1,2),...
            'faces',            1,...
            'edgecolor',        [0 1 0],...
            'facecolor',        'none',...
            'hittest',          'off');

        % inactive points
        api.hinactive = patch(...
            'parent',           api.hrest,...
            'vertices',         NaN(1,2),...
            'faces',            1,...
            'edgecolor',        'none',...
            'facecolor',        'none',...
            'markerfacecolor',  'flat',...
            'markeredgecolor',  'flat',...
            'marker',           'o',...
            'markersize',       6,...
            'facevertexcdata',  NaN(1,3),...
            'hittest',          'off');


        % copy objects to magnitude display
        api.hsegmentmag  = copyobj(api.hsegment, api.hmag);
        api.hinactivemag  = copyobj(api.hinactive, api.hmag);


        % context menu
        api.hcontextmenu = uicontextmenu(...
            'parent',api.hfig,...
            'callback',@(h,e)contextFcn(api.hfig));

        set([api.hcontour(:);api.hpoint(:)],...
            'uicontextmenu',api.hcontextmenu);
        set(api.hcontour,'hittest','on');


        % note to user
        note = ['Adjust the purple positions. ',...
            'The green segment defines the first segment of the ',...
            'contour. Segment numbers increase from the first segment.'];
    end


    % ADDITIONAL SETUP-----------------------------------------------------

    % display note
    [note,pos] = textwrap(api.hnote,{note});
    set(api.hnote,'string',note);


    % cardiac callbacks
    if any(strcmpi(api.Type,{'SA','LA'}))
        set(api.hcardiacpanel,'visible','on');

        % Clockwise setup
        if api.Clockwise
            set(api.hclock,'value',1);
        else
            set(api.hcounterclock,'value',1);
        end

        % other callbacks
        set(api.hmodel,'Callback',...
            @(varargin)modelCallback(api.hfig));
        set(api.hnseg,'Callback',...
            @(varargin)nsegCallback(api.hfig));
        set(api.hclockpanel,'SelectionChangeFcn',...
            @(src,evnt)clockCallback(api.hfig,evnt));
        set(api.horiginpanel,'SelectionChangeFcn',...
            @(src,evnt)originCallback(api.hfig,evnt));

    end

    % OK position
    if strcmpi(get(api.hcardiacpanel,'visible'),'off');
        pA = getpixelposition(api.hcardiacpanel);
        pB = getpixelposition(api.hokpanel);

        setpixelposition(api.hokpanel,[pB(1),pA(2)+pA(4)-pB(4),pB(3:4)]);
    end


    % ok/cancel callbacks
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));

    % initialize pointer manager
    iptPointerManager(api.hfig,'enable');

    % initialize playbar
    api.hplaybar = playbar(api.hppanel);
    api.hplaybar.Min = api.FramesForAnalysis(1);
    api.hplaybar.Max = api.FramesForAnalysis(2);
    hlisten_playbar = addlistener(api.hplaybar,...
        'NewValue',@(varargin)playbackFcn(api.hfig));

    % position playbar
    pos    = getpixelposition(api.hplaybar.Parent);
    plsz   = [200 30];
    margin = 5;
    p = [(pos(3)+1)/2 - (plsz(1)+1)/2, 1+margin, plsz];
    setpixelposition(api.hplaybar,p);

    % update figure
    api.cross = [];
    guidata(api.hfig,api);
    api.redrawFcn(api.hfig);


    % WAIT & CLEANUP-------------------------------------------------------

    % wait for figure to finish
    waitfor(api.hfig,'userdata')

    % cleanup
    delete(hlisten_playbar);

    % output
    if ~ishandle(api.hfig) || ~isequal(get(api.hfig,'userdata'),'complete')
        options = [];
    else
        api = guidata(api.hfig);

        if any(strcmpi(api.Type,{'SA','LA'}))
            propA = get(api.hpoint(1),{'xdata','ydata'});
            propB = get(api.hpoint(2),{'xdata','ydata'});
            options = struct(...
                'Nmodel',       api.Nmodel,...
                'Nseg',         api.Nseg,...
                'Clockwise',    api.Clockwise,...
                'PositionA',    cat(2,propA{:}),...
                'PositionB',    cat(2,propB{:}));
        else
            options = struct(...
                'PositionIndices',{api.PositionIndices});
        end
    end


end



%% BUTTON CALLBACKS (OK/CANCEL/FIGURECLOSE)

function okCallback(hfig)
    set(hfig,'userdata','complete');
end

function cancelCallback(hfig)
    set(hfig,'userdata','cancel');
end

function figCloseRequestFcn(hfig)
    set(hfig,'userdata','cancel');
end



%% UICONTROL CALLBACKS

function modelCallback(hfig)
% MODEL NUMBER CALLBACK

    % gather data
    api = guidata(hfig);

    % current selection
    contents = get(api.hmodel,'String');
    str = contents{get(api.hmodel,'Value')};
    val = str2double(str(1));

    % check for change & update
    if ~isempty(val) && api.Nmodel ~= val
        api.Nmodel = val;

        segs = [1 val:val:api.MaxSegments];
        set(api.hnseg,'string',num2cell(segs),'value',2);
        api.Nseg = api.Nmodel;

        guidata(api.hfig,api);
        api.redrawFcn(api.hfig);
    end

end


function nsegCallback(hfig)
% NUMBER OF SEGMENTS CALLBACK

    % gather data
    api = guidata(hfig);

    % current selection
    contents = get(api.hnseg,'String');
    str = contents{get(api.hnseg,'Value')};
    val = str2double(str);

    % check for change & update
    if ~isempty(val) && api.Nseg ~= val
        api.Nseg = val;
        guidata(api.hfig,api);
        api.redrawFcn(api.hfig);
    end

end



%% UIBUTTON SELECTION FUNCTION CALLBACKS

function originCallback(hfig,evnt)
% AUTO/USER ORIGIN DEFINITION (used by SA only)

    % application data
    api = guidata(hfig);

    % check for change
    if (evnt.NewValue == api.hauto)
        pos = api.autoorigin;
        set(api.hpoint(1),'xdata',pos(1),'ydata',pos(2),'hittest','off');
    else
        set(api.hpoint(1),'hittest','on');
    end

    % update figure
    guidata(api.hfig,api);
    api.redrawFcn(api.hfig);

end


function clockCallback(hfig,evnt)
% CLOCKWISE/COUNTERCLOCKWISE DEFINITION

    % application data
    api = guidata(hfig);

    % check or change
    if (evnt.NewValue == api.hclock)
        api.Clockwise = true;
    else
        api.Clockwise = false;
    end

    % update figure
    guidata(api.hfig,api);
    api.redrawFcn(api.hfig);

end



%% POINT UPDATE FUNCTIONS
% Ther functions define the interactive behavior of the user-draggable
% points, including "enter" and "exit" functions for the Pointer Manager,
% and a "drag" function for the ButtonDownFcn.

function hpt = pointCreate(haxs,clr,N)
    hfig = ancestor(haxs,'figure');

    hpt = preAllocateGraphicsObjects(N,1);
    for k = 1:N
        hpt(k) = line(...
            'parent',       haxs,...
            'color',        clr,...
            'marker',       'o',...
            'markersize',   15,...
            'linewidth',    3);

        pb = struct(...
            'enterFcn',     @(varargin)pointEnter(hpt(k),hfig),...
            'traverseFcn',  [],...
            'exitFcn',      @(varargin)pointExit(hpt(k),hfig));
        iptSetPointerBehavior(hpt(k),pb);

        set(hpt(k),'ButtonDownFcn',...
            @(varargin)pointDrag(hpt(k),hfig));
    end

end


function pointEnter(hpt,hfig)
% enter point - update color & figure pointer
    api = guidata(hfig);
    set(hpt,'color',api.clrH);
    set(api.hfig,'Pointer','fleur');
end

function pointExit(hpt,hfig)
% exit point - reset color
    if ishandle(hpt)
        api = guidata(hfig);
        set(hpt,'color',api.clrP);
    end
end


function pointDrag(hpt,hfig)
% drag point - initialize an "onCleanup" object for graceful cleanup and
% pass to the main drag function.
    cobj = onCleanup(@()pointDragCleanup(hfig));
    pointDragMain(hpt,hfig);
end

function pointDragMain(hpt,hfig)
% drag point MAIN - allow the user to drag the given point to locations
% contrained by the various "constrainFcn"

    % current application data
    api = guidata(hfig);

    % current point index
    idx = find(hpt == api.hpoint,1,'first');

    % stop PointerManager
    iptPointerManager(api.hfig, 'disable')

    % initialize buttonmotion/buttonup functions
    set(api.hfig,'WindowButtonMotionFcn',   @(varargin)buttonMotion(),...
                 'WindowButtonUpFcn',       @(varargin)buttonUp());

    % wait for userdata
    set(hpt,'userdata',[]);
    waitfor(hpt,'userdata');

    % MOTION FUNCTION
    function buttonMotion()
        try
            % current constrained point
            pos = get(api.hrest,'currentpoint');
            pos = pos([1 3]);
            if ~isempty(api.constrainFcn{idx})
                pos = api.constrainFcn{idx}(hpt,pos,api);
            end

            % update point
            set(hpt,'xdata',pos(1),'ydata',pos(2));

            % redraw
            api.redrawFcn(api.hfig);

        catch ERR
            set(hpt,'userdata','error');
            rethrow(ERR)
        end
    end

    % BUTTON UP FUNCTION
    function buttonUp()
        set(hpt,'userdata','complete')
    end

end


function pointDragCleanup(hfig)
% drag cleanup - return the figure to its initial pre-drag state and force
% the software to recalculate the automated SpatialSmoothing parameter.

    if ~ishandle(hfig) || strcmpi(get(hfig,'BeingDeleted'),'on')
        return;
    end
    set(hfig,...
        'WindowButtonMotionFcn',[],...
        'WindowButtonUpFcn',    []);
    iptPointerManager(hfig, 'enable')

end



%% REDRAW SHORT AXIS CONTOURS
function redrawSA(hfig)

    % gather guidata
    api = guidata(hfig);

    % drawing parameters
    N      = api.Nmodel;
    Ntotal = api.Nseg;
    if Ntotal<N, Ntotal=N; end

    flag_clockwise = api.Clockwise;
    fac = Ntotal/N;
    C0 = api.RestingContour;

    % current origin
    prop = get(api.hpoint(1),{'xdata','ydata'});
    origin = cat(2,prop{:});

    % current spoke location
    prop = get(api.hpoint(2),{'xdata','ydata'});
    pos = cat(2,prop{:});


    % primary spoke angle
    theta0 = atan2(pos(2)-origin(2),pos(1)-origin(1));

    % minor spoke angles
    if flag_clockwise
        theta = linspace(0,2*pi,Ntotal+1);
    else
        theta = linspace(2*pi,0,Ntotal+1);
    end
    theta = theta(1:end-1) + theta0;

    % spoke vertices/faces/colors
    lim = api.drng;
    rad = 2*max([lim(2)-lim(1),lim(4)-lim(3)]);
    [x,y] = pol2cart(theta,rad);
    x = x(:)+origin(1);
    y = y(:)+origin(2);

    vertices = [origin; x,y];
    faces    = [ones(1,Ntotal); 2:Ntotal+1]';

    fvcd = [NaN(1,3); ones(Ntotal,1)*api.clrB];
    fvcd([2 2+fac],:) = ones(2,1)*api.clrA;

    % update spoke appearance
    idxmajor = 1:fac:Ntotal;
    idxminor = setdiff(1:Ntotal,idxmajor);
    faces = {faces(1,:); faces(idxmajor,:); faces(idxminor,:)};

    set([api.hspoke1,api.hspokemajor,api.hspokeminor],...
        'vertices',vertices,{'faces'},faces(:),'facevertexcdata',fvcd);

    % remove too many-spokes
    if Ntotal > 36
        set(api.hspokeminor,'visible','off');
    else
        set(api.hspokeminor,'visible','on');
    end

    % determine intersections of major spokes with contours
    vertices = repmat({NaN(N,2)},[2 1]);
    pts = [origin; x(idxmajor),y(idxmajor)];
    for ck = 1:2
        for sk = 1:N
            idx = [1 sk+1];
            [xi,yi] = intersections(pts(idx,1),pts(idx,2),...
                C0{ck}(:,1),C0{ck}(:,2));
            if ~isempty(xi)
                vertices{ck}(sk,:) = [xi(1),yi(1)];
            end
        end
    end

    % check if origin is on the endocardial border
    [tfin,tfon] = inpolygon(origin(1),origin(2),C0{2}(:,1),C0{2}(:,2));
    if tfon
        vertices{2}(:) = NaN;
    end

    % intersection vertices/faces/colors
    vertices = cat(1,vertices{:});
    faces = (1:2*N)';

    fvcd = [ones(2,1)*api.clrA; ones(N-2,1)*api.clrB];
    fvcd = [fvcd; fvcd];

    % update intersections
    idx1 = [1 N+1];
    idx  = setdiff(1:2*N,idx1);
    set([api.hcross1,api.hcross],...
        'vertices',vertices,...
        {'faces'},{faces(idx1,:); faces(idx,:)},...
        'facevertexcdata',fvcd);

    % save intersections to api
    api.cross = vertices;
    api.faces = faces;
    api.fvcd  = fvcd;

    % update & playback
    guidata(api.hfig,api);
    playbackFcn(api.hfig);

    % update OK button

    if isempty(api.cross(:)) || any(isnan(api.cross(:)))
        set(api.hok,'enable','off');
    else
        set(api.hok,'enable','on');
    end

end



%% REDRAW LONG AXIS CONTOURS
function redrawLA(hfig)

    % gather guidata
    api = guidata(hfig);

    % drawing parameters
    N = api.Nmodel;
    flag_clockwise = api.Clockwise;
    C0 = api.RestingContour;

    % current origin
    prop = get(api.hpoint(1),{'xdata','ydata'});
    origin = cat(2,prop{:});

    % secondary spoke location
    prop = get(api.hpoint(2),{'xdata','ydata'});
    pos = cat(2,prop{:});

    % primary vector
    v = pos-origin;
    d = sqrt(sum(v.^2));
    v = v/d;

    % check for invalid definition
    if all(v==0)
        api.cross = [];
        set([api.hspoke1,api.hspokemajor],...
            'vertices',         NaN(1,2),...
            'faces',            [],...
            'facevertexcdata',  NaN(1,3));
        return
    end

    % 3-element varying position
    fac = [0 0.5 1];
    pos = [1;1;1]*origin + fac(:)*d*v;

    % normal to primary vector
    n = [-v(2),v(1)];
    if ~flag_clockwise, n = -n; end

    % large radius
    lim = api.drng;
    rad = 2*max([lim(2)-lim(1),lim(4)-lim(3)]);

    % major spokes vertices/faces/colors
    tmp1 = rad*n([1 1 1],:);
    tmp2 = pos(3,:)+rad*v;
    vertices = [pos;tmp2;pos+tmp1;pos-tmp1];

    faces = [1 2 3 1 2 3  4;
             5 6 7 8 9 10 1]';

    fvcd = ones(size(vertices,1),1)*api.clrB;
    fvcd(1:3,:) = NaN;

    % update major spokes
    set(api.hspokemajor,...
        'vertices',         vertices,...
        'faces',            faces,...
        'facevertexcdata',  fvcd);

    % primary spoke
    vertices = [pos(3,:); pos(3,:)+tmp1(3,:); tmp2];
    faces = [1 2; 1 3];

    set(api.hspoke1,...
        'vertices', vertices,...
        'faces',    faces);

    % determine intersections of major spokes with contours
    Nv = N-1;
    vertices = repmat({NaN(Nv,2)},[2 1]);
    ptsA = [flipud(pos); pos];
    ptsB = ptsA + [flipud(tmp1); -tmp1];
    for ck = 1:2
        for sk = 1:Nv
            pts = [ptsA(sk,:);ptsB(sk,:)];
            [xi,yi] = intersections(pts(:,1),pts(:,2),...
                C0{ck}(:,1),C0{ck}(:,2));
            if ~isempty(xi)
                vertices{ck}(sk,:) = [xi(1),yi(1)];
            end
        end
    end

    % check if origin is on the endocardial border
    [tfin,tfon] = inpolygon(pos(:,1),pos(:,2),C0{2}(:,1),C0{2}(:,2));
    if any(tfon)
        vertices{2}(:) = NaN;
    end

    % intersection vertices/faces/colors
    vertices = cat(1,vertices{:});

    faces = (1:2*Nv)';

    idx1 = [1 Nv+1];
    idx  = setdiff(1:2*Nv,idx1);

    fvcd = [api.clrA; ones(Nv-1,1)*api.clrB];
    fvcd = [fvcd; fvcd];

    set([api.hcross1,api.hcross],...
        'vertices',vertices,...
        {'faces'},{faces(idx1,:); faces(idx,:)},...
        'facevertexcdata',fvcd);

    % save intersections to api
    api.cross = vertices;
    api.faces = faces;
    api.fvcd  = fvcd;

    % update data & playback
    guidata(api.hfig,api);
    playbackFcn(api.hfig);

    % test OK button
    % (OK is only enabled when all intersections are valid)
    if isempty(api.cross(:)) || any(isnan(api.cross(:)))
        set(api.hok,'enable','off');
    else
        set(api.hok,'enable','on');
    end

end


%% REDRAW CONTOUR
function redrawContour(hfig)

    % gather guidata
    api = guidata(hfig);

    % number of contours
    Ncontour = numel(api.RestingContour);

    % position indices
    posind = api.PositionIndices;
    for k = 1:Ncontour
        C0 = api.RestingContour{k};
        nbr = size(C0,1);

        if posind{k}(1)==1
            order = 'ascend';
        else
            order = 'descend';
        end

        ptind = find(api.crvIDX==k);
        idx = NaN(1,numel(ptind));

        compare = 2:nbr-1;

        for n = 1:numel(ptind)
            h = api.hpoint(ptind(n));
            p = [get(h,'xdata'),get(h,'ydata')];
            dsq = (C0(compare,1)-p(1)).^2 + (C0(compare,2)-p(2)).^2;
            [~,ind] = min(dsq(:));

            idx(n) = compare(ind);
        end

        posind{k} = [1,idx,nbr];
        posind{k} = sort(posind{k},order);
    end

    api.PositionIndices = posind;


    % all points
    clr1 = get(api.hsegment,'edgecolor');


    inavert = cell(Ncontour,1);
    inafvcd = cell(Ncontour,1);
    segvert = cell(Ncontour,1);
    segface = cell(Ncontour,1);
    nbr = 0;
    for k = 1:Ncontour
        C0 = api.RestingContour{k};
        idx = api.PositionIndices{k};
        inavert{k} = C0(idx,:);
        inafvcd{k} = [clr1; ones(size(inavert{k},1)-1,1)*api.clrB];

        mx = max(idx(1:2));
        mn = min(idx(1:2));
        segvert{k} = C0(mn:mx,:);
        n = size(segvert{k},1);
        segface{k} = nbr + [1:n-1; 2:n]';
        nbr = nbr+n;
    end

    vert = cat(1,inavert{:});
    set(api.hinactive,...
        'vertices',vert,...
        'faces',(1:size(vert,1))',...
        'facevertexcdata',cat(1,inafvcd{:}));

    set(api.hsegment,...
        'vertices',cat(1,segvert{:}),...
        'faces',cat(1,segface{:}));

    % update & playback
    guidata(api.hfig,api);
    playbackFcn(api.hfig);

    % update OK button
    set(api.hok,'enable','on');

end



%% PLAYBAR PLAYBACK FUNCTION
function playbackFcn(hfig)

    % gather gui data
    api = guidata(hfig);

    % current frame
    fr = api.hplaybar.Value;

    % update image & contours
    set(api.him,'cdata',api.Mag(:,:,fr));

    for k = 1:numel(api.RestingContour)
        set(api.hcontourmag(k),...
            'xdata',api.Contour{fr,k}(:,1),...
            'ydata',api.Contour{fr,k}(:,2));
    end
%     set(api.hep,'xdata',api.Contour{fr,1}(:,1),...
%         'ydata',api.Contour{fr,1}(:,2));
%     set(api.hen,'xdata',api.Contour{fr,2}(:,1),...
%         'ydata',api.Contour{fr,2}(:,2));


    % cardiac update
    if any(strcmpi(api.Type,{'SA','LA'}))

        % update spoke intersections
        if ~isempty(api.cross)

            N = size(api.cross,1)/2;
            tf = ~any(isnan(api.cross),2);
            if ~any(tf)
                vertices = NaN(2*N,2);
            else
                dx = NaN(1,2*N);
                dy = NaN(1,2*N);

                pts = api.cross(tf,:)';
                pts(3,:) = fr;
                dx(tf) = fnvalmod(api.spldx,pts([2 1 3],:));
                dy(tf) = fnvalmod(api.spldy,pts([2 1 3],:));

                vertices = api.cross + [dx(:),dy(:)];
            end

            idx1 = [1 N+1];
            idx  = setdiff(api.faces,idx1);
            set([api.hcross1mag,api.hcrossmag],...
                'vertices',         vertices,...
                {'faces'},          {api.faces(idx1,:);
                                     api.faces(idx,:)},...
                'facevertexcdata',  api.fvcd);

        end

        % update connector line
        if strcmpi(api.Type,'LA')
            pos = [api.Contour{fr,1}(1,:); api.Contour{fr,2}(end,:); NaN,NaN;
                   api.Contour{fr,2}(1,:); api.Contour{fr,1}(end,:)];
            set(api.hconnect,'xdata',pos(:,1),'ydata',pos(:,2));
        end


    % contour update
    else

        % update point locations
        tags = {'hinactive','hsegment'};
        for ti = 1:numel(tags)
            h = api.(tags{ti});
            h2 = api.([tags{ti} 'mag']);

            pts = get(h,'vertices');
            pts(:,3) = fr;

            tf = all(isfinite(pts),2);
            if any(tf)
                dx = fnvalmod(api.spldx,pts(tf,[2 1 3])');
                dy = fnvalmod(api.spldy,pts(tf,[2 1 3])');
                pts(tf,1:2) = pts(tf,1:2) + [dx(:),dy(:)];
            end

            set(h2,...
                'vertices',pts(:,1:2),...
                'faces',get(h,'faces'),...
                'facevertexcdata',get(h,'facevertexcdata'));
        end

    end

end


%% CONTEXT MENU
function contextFcn(hfig)
    api = guidata(hfig);

    % clear context menu
    delete(allchild(api.hcontextmenu));

    % clicked location
    pt = get(api.hrest,'CurrentPoint');
    pt = pt([1 3]);

    % context menu items
    h = get(hfig,'currentobject');
    if any(h==api.hcontour)
        crvidx = find(api.hcontour==h);
        uimenu(...
            'parent',api.hcontextmenu,...
            'Label','Add Point',...
            'Callback',@(varargin)addLocal());
        uimenu(...
            'parent',api.hcontextmenu,...
            'Label','Reverse Segments',...
            'Callback',@(varargin)reverseLocal());
    elseif any(h==api.hpoint)
        ptidx = find(api.hpoint==h);
        uimenu(...
            'parent',api.hcontextmenu,...
            'Label','Delete Point',...
            'Callback',@(varargin)deleteLocal());
    else
        return
    end


    function deleteLocal()
        nbr = cumsum(api.crvIDX(ptidx)==api.crvIDX);
        api.PositionIndices{api.crvIDX(ptidx)}(nbr(ptidx)+1) = [];
        api.crvIDX(ptidx) = [];
        api.hpoint(ptidx) = [];

        delete(h);
        guidata(api.hfig,api);
        api.redrawFcn(api.hfig);

    end

    function addLocal()

        % closest un-allocated point on the current curve
        C = api.RestingContour{crvidx};
        idx = setdiff(1:size(C,1),api.PositionIndices{crvidx});
        if isempty(idx)
            warning(sprintf('%s:contourFilled',mfilename),...
                'cannot add another point');
        end
        dsq = (C(idx,1)-pt(1)).^2 + (C(idx,2)-pt(2)).^2;
        [~,ind] = min(dsq);

        % create a new point
        hpt = pointCreate(api.hrest,api.clrP,1);
        set(hpt,'xdata',C(ind,1),'ydata',C(ind,2),...
            'uicontextmenu',api.hcontextmenu);

        % save constraint function
        api.constrainFcn{end+1} = @(varargin)constrainToPoints(...
            varargin{:},api.RestingContour{crvidx});

        %
        api.hpoint(end+1) = hpt;
        api.crvIDX(end+1) = crvidx;

        %
        guidata(api.hfig,api);
        api.redrawFcn(api.hfig);

    end

    function reverseLocal()
        api.PositionIndices{crvidx} = api.PositionIndices{crvidx}(end:-1:1);
        guidata(api.hfig,api);
        api.redrawFcn(api.hfig);
    end
end



%% HELPER FUNCTIONS: POINT CONSTRAINT FUNCTIONS
% this area defines various constraint functions used by
% the draggable points

function newpos = constrainInContour(hpt,pos,api,C)
% contrain INSIDE a contour

    % inside contour - we're golden
    if inpolygon(pos(1),pos(2),C(:,1),C(:,2))
        newpos = pos;

    % outside contour - determine best point inside contour
    else
        pts = [pos;api.autoorigin];
        [xi,yi] = intersections(pts(:,1),pts(:,2),...
            C([1:end,1],1),C([1:end,1],2));

        % give up and don't move the point
        if isempty(xi)
            prop = get(hpt,{'xdata','ydata'});
            newpos = cat(2,prop{:});

        % update the point
        else
            newpos = [xi(1),yi(1)];
        end
    end
end


function newpos = constrainOnContour(hpt,pos,api,C)
% constrain ON a contour

    % large radial distance
    lim = api.drng;
    rad = max([lim(2)-lim(1), lim(4)-lim(3)]);

    % vector from middle of epicardium in "pos" direction
    v = pos - api.autoorigin;
    pts = [api.autoorigin; pos + 2*rad*v];

    % vector/contour intersection
    [xi,yi] = intersections(pts(:,1),pts(:,2),C(:,1),C(:,2));

    % give up & don't move the point
    if isempty(xi)
        prop = get(hpt,{'xdata','ydata'});
        newpos = cat(2,prop{:});

    % update point
    else
        newpos = [xi(1),yi(1)];
    end

end


function newpos = constrainToPoints(hpt,pos,api,C)
% constrain to the exact points on a contour

    % allowable points for motion
    idx = 2:size(C,1)-1;

    % distance from position to all points on current contour
    dsq = (C(idx,1)-pos(1)).^2 + (C(idx,2)-pos(2)).^2;

    % minimal distance
    [~,ind] = min(dsq(:));
    idx = idx(ind);

    % new position
    newpos = C(idx,:);


end



%% END OF FILE=============================================================
