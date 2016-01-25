function varargout = DENSEms(varargin)
% varargout = DENSEms(varargin)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

    % figure colormap
    figcmap = gray(256);

    % utility directories
    basepath = fileparts(mfilename('fullpath'));
    utildir = fullfile(basepath, 'DENSE_utilities');
    addutilities(utildir);

    % check for Excel availability
    FLAG_excel = false;
    if ispc
        try
            Excel = actxserver('Excel.Application');
            Excel.Quit;
            Excel.delete;
            FLAG_excel = true;
        catch %#ok
        end
    end

    % parse additional input
    defapi = struct(...
        'WaitForOutput',    false,...
        'ResetOptions',     false,...
        'ResetPaths',       false);
    api = parseinputs(defapi,[],varargin{:});

    % flags
    api.WaitForOutput  = isequal(true,api.WaitForOutput);
    api.ResetOptions   = isequal(true,api.ResetOptions);
    api.ResetPaths     = isequal(true,api.ResetPaths);
    api.ExcelAvailable = FLAG_excel;

    % load program info from file
    api = loadInfo(api);


    % initialize empty structure with expected fields
    idtags = {'Name','File'};
    seqtags = {'StudyInstanceUID';'SeriesInstanceUID';
        'NumberInSequence';
        'Height'; 'Width'; 'PixelSpacing'; ...
        'ImagePositionPatient'; 'ImageOrientationPatient'};
    datatags = {'AnalysisInstanceUID',...
        'ImageInfo','ROIInfo','AnalysisInfo','DENSEInfo',...
        'SequenceInfo','DisplacementInfo','StrainInfo'};

    tags = [idtags(:);datatags(:);seqtags(:);];
    data = cell2struct(cell(size(tags)),tags);
    api.data = repmat(data,[0 1]);
    api.seqtags = seqtags;
    api.datatags = datatags;

    % all multimedia formats
    api.formats = multimediaformats();



    % LOAD FIGURE----------------------------------------------------------
    try

        % load figure
        hfig = hgload([mfilename '.fig']);
        setappdata(hfig,'WaitForOutput',api.WaitForOutput);
        api.hfig = hfig;

        % force close after output (on function cleanup)
        if api.WaitForOutput
            cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
        end

        % place figure in screen center
        posscr = get(0,'ScreenSize');
        posfig = getpixelposition(hfig);
        posfig(1:2) = (posscr(3:4)-posfig(3:4))/2;
        setpixelposition(hfig,posfig);

        % gather controls
        hchild = findobj(hfig);
        if ~isempty(hchild)
            tags = get(hchild,'tag');
            if ~iscell(tags), tags = {tags}; end
            for ti = 1:numel(hchild)
                if ~isempty(tags{ti}) && strwcmpi(tags{ti},'h*')
                    api.(tags{ti}) = hchild(ti);
                end
            end
        end

        % pass to the subfunction
        set(hfig,'visible','off','colormap',figcmap);
        guidata(hfig,api);
        setappdata(hfig,'figureSetupComplete',false);
        output = mainFcn(api);

        if nargout > 0
            varargout{1} = output;
        end

    catch ERR
        close(hfig(ishandle(hfig)),'force');
        drawnow
        rethrow(ERR);
    end

    if api.WaitForOutput
        close(hfig(ishandle(hfig)),'force');
        drawnow
    end

end



%% MAIN FUNCTION
function output = mainFcn(api)


    % DISPLAY OPTIONS------------------------------------------------------

    % colors
    set(api.hbgcolor,'cdata',colorblock(api.backgroundcolor));
    set(api.haxcolor,'cdata',colorblock(api.edgecolor));
    set(api.htxcolor,'cdata',colorblock(api.textcolor));

    set(api.hmain,'backgroundcolor',api.backgroundcolor);
    set([api.hpanel3d,api.hpaneltime,api.hpanelbullseye],...
        'backgroundcolor','none');

    % ranges
    set(api.htwistmin,'string',api.twistrng(1));
    set(api.htwistmax,'string',api.twistrng(end));

    set(api.htorsionmin,'string',api.torsionrng(1));
    set(api.htorsionmax,'string',api.torsionrng(end));

    % colormaps
    set(api.hlistcmap,'string',{api.colormaps.Name},...
        'Value',api.colormapidx);


    % AXES SETUP-----------------------------------------------------------

    % gather all axes
    api.hcb = [api.haxcb3d,api.haxcbbullseye];
    api.hax = [api.hax3d,api.haxA,api.haxB,api.haxbullseye];

    % titles & labels
    api.httlbullseye = title(api.haxbullseye,'Regional Twist');

    api.httlA  = title(api.haxA,'Average Twist vs. Time');
    api.hxlblA = xlabel(api.haxA,'Frame');
    api.hylblA = ylabel(api.haxA,{'Twist';'\fontsize{8}(degrees)'});

    api.httlB  = title(api.haxB,'Torsion vs. Time');
    api.hxlblB = xlabel(api.haxB,'Frame');
    api.hylblB = ylabel(api.haxB,...
        {'Torsion';'\fontsize{8}(deg. per mm length)'});

    api.httl = [api.httlbullseye,api.httlA,api.httlB];
    api.hlbl = [api.hxlblA,api.hxlblB,api.hylblA,api.hylblB];

    % fontsize
    set(api.hax,    'fontsize',8);
    set(api.hcb,    'fontsize',8);
    set(api.httl,   'fontsize',14);
    set(api.hlbl,   'fontsize',11,'interpreter','tex');

    % colors
    set([api.hax,api.hcb],'color','none','xcolor',api.edgecolor,...
        'ycolor',api.edgecolor,'zcolor',api.edgecolor);
    set(api.hax3d,'color',api.backgroundcolor);
    set([api.httl,api.hlbl],'color',api.edgecolor);

    % axes limits
    set([api.hcb,api.haxA],'ylim',api.twistrng);
    set(api.haxB,'ylim',api.torsionrng);


    % colormap patchs
    Ncb = numel(api.hcb);
    api.hcmap = NaN(1,Ncb);
    for k = 1:Ncb
        api.hcmap(k) = patch('parent',api.hcb(k),...
            'facecolor','flat','edgecolor','none');
    end
    updateColormap(api,false);

    % 3D colorbar invisible
    set([api.hcb(1),api.hcmap(1)],'visible','off');


    % ROTATION TOOL--------------------------------------------------------

    % available 3D views
    views = struct; idx = 0;

    idx = idx+1;
    views(idx).Name = 'Default View (Base Up)';
    views(idx).View = [-37.5,15];
    views(idx).CameraUpVector = [0 0 1];

    idx = idx+1;
    views(idx).Name = 'Apical View';
    views(idx).View = [75,-37.5];
    views(idx).CameraUpVector = [0 -1 0];

    idx = idx+1;
    views(idx).Name = 'Basal View';
    views(idx).View = [75,37.5];
    views(idx).CameraUpVector = [0 -1 0];

    idx = idx+1;
    views(idx).Name = 'Apical 2D View';
    views(idx).View = [0,-90];
    views(idx).CameraUpVector = [0 -1 0];

    idx = idx+1;
    views(idx).Name = 'Basal 2D View';
    views(idx).View = [0,90];
    views(idx).CameraUpVector = [0 -1 0];

    % create rotation tool
    api.hrotate = rotatetool(api.hfig);

    api.hrotate.setAllowAxes(api.hax3d,true);
    api.hrotate.addViews(api.hax3d,views);

    % initial view
    set(api.hax3d,...
        'view',                 views(1).View,...
        'cameraupvector',       views(1).CameraUpVector,...
        'cameraviewanglemode',  'auto');


    % ORIENTATION AXES-----------------------------------------------------

    % orientation labels
    str = {'APEX','BASE'};
    clr = {[0 1 0],[1 0 0]};
    pt  = [0 0 -.5;0 0 .5];
    api.htxori = text(pt(:,1),pt(:,2),pt(:,3),str,...
        'Parent',               api.haxori,...
        'Horizontalalignment',  'center',...
        'BackgroundColor',      get(api.haxori,'color'),...
        'FontSize',             8,...
        {'color'},              clr(:),...
        {'edgecolor'},          clr(:));


    % link orientation axes to main axes
    linkfcn = @(hsub,hmain)set(hsub,...
        'view',             get(hmain,'view'),...
        'CameraUpVector',   get(hmain,'CameraUpVector'));

    proptags = {'CameraPosition','CameraTarget','CameraUpVector'};
    h = handle(api.hax3d);
    props = cellfun(@(t)findprop(h,t),proptags,'uniformoutput',0);
    api.hcameralistener = handle.listener(h,cell2mat(props),...
        'PropertyPostSet',@(src,evnt)linkfcn(api.haxori,api.hax3d));

    linkfcn(api.haxori,api.hax3d);

    % update/fix cameraviewangle
    set(api.haxori,'cameraviewanglemode','auto');
    set(api.haxori,'cameraviewangle',get(api.haxori,'cameraviewangle'));


    % CARDIAC SEGMENT DISPLAY----------------------------------------------

    idx = 1;
    data(idx).SegmentModel = 4;
    data(idx).NumberOfSegments = 4;
    data(idx).NumberOfLayers   = 1;
    data(idx).Text = {'Anterior','Septal','Inferior','Lateral'};
    data(idx).SegmentEdgeColor = 'none';

    idx = idx+1;
    data(idx).SegmentModel = 6;
    data(idx).NumberOfSegments = 6;
    data(idx).NumberOfLayers   = 1;
    data(idx).Color = hsv(data(idx).NumberOfSegments);

    idx = idx+1;
    data(idx).SegmentModel = 4;
    data(idx).NumberOfSegments = 4;
    data(idx).NumberOfLayers   = 1;
    data(idx).Color = hsv(data(idx).NumberOfSegments);

    api.hseg = dense_bullseye(api.haxseg,data);


    % ADDITIONAL SETUP-----------------------------------------------------

    % popup tab initialization
    pos = getpixelposition(api.hplotpanel);
    api.hpopup = popuptabsmod(api.hfig,'TabWidth',pos(3));
    api.hpopup.addTab('Plot Selection',api.hplotpanel);
    api.hpopup.addTab('Display Options',api.hoptpanel);


    % slice selection list
    set(api.hslice,...
        'string',       {'<html><i>Select slice...</i></html>'},...
        'callback',     @(h,evnt)selectSlice(h,api.hfig),...
        'uicontextmenu',api.hmenu_slice);

    % slice selection context menu
    set(api.hmenu_slice,'Callback',@(h,evnt)sliceContext(h,api.hslice));
    set(api.hslicecolor,'Callback',@(varargin)sliceColor(api.hfig));
    set(api.hslicename,'Callback',@(varargin)sliceName(api.hfig));

    % plot selection
    set(api.hplotpanel,'SelectionChangeFcn',...
        @(h,evnt)displayChange(api.hfig,evnt));

    % colormap context menu
    set(api.hlistcmap,'uicontextmenu',api.hmenu_cmap);
    set(api.hnewcmap,'Callback',@(varargin)addColormap(api.hfig));
    set(api.hdeletecmap,'Callback',@(varargin)deleteColormap(api.hfig));

    % bullseye context menu
    set(api.hmenu_bullseye,'Callback',@(h,evnt)bullseyeContext(h,api.hfig));

    % options panel
    hopt = [api.hbgcolor,api.haxcolor,api.htxcolor,...
        api.hcheckreversez,...
        api.htwistmin,api.htwistmax,...
        api.htorsionmin,api.htorsionmax,...
        api.hlistslicecolor,api.hlistcmap];
    set(hopt,'Callback',@(h,evnt)displayOptions(h,api.hfig));

    % playbar & listener
    api.hplaybar = playbar(api.hmain);
    api.hplaybarlistener = addlistener(...
        api.hplaybar,'NewValue',@(h,evnt)playbarCallback(api.hfig));


    % file menu options
    set(api.hload,          'Callback',@(varargin)loadFile(api.hfig));
    set(api.hclear,         'Callback',@(varargin)clearFile(api.hfig));
    set(api.hexportmedia,'Callback',@(varargin)exportMultimedia(api.hfig));
    set(api.hexportexcel,'Callback',@(varargin)exportExcel(api.hfig));

    % misc menu options
    set(api.htest,'Callback',@(varargin)testCode(api.hfig));

    % create empty objects
    api.hpts            = [];
    api.hcentroid       = [];
    api.htwist          = [];
    api.htwistlegend    = [];
    api.htorsion        = [];
    api.hbullseye       = [];

    % figure options
    set(api.hfig,...
        'ResizeFcn',@(h,evnt)figResize(h),...
        'CloseRequestFcn',@(h,evnt)figCloseRequest(h),...
        'DeleteFcn',@(h,evnt)figDelete(h));

    % finalize figure
    iptPointerManager(api.hfig,'enable');
    guidata(api.hfig,api);
    setappdata(api.hfig,'figureSetupComplete',true);

    displayChange(api.hfig);
    set(api.hfig,'visible','on');
    drawnow

    % exit function immediately
    if ~api.WaitForOutput
        output = 'loaded';

    % wait for close request
    else
        set(api.hfig,'userdata','waiting');
        waitfor(api.hfig,'userdata')
        output = 'closed';
    end

end




%% FIGURE RESIZE FUNCTION
function figResize(hfig)

    % check for completed setup
    if ~isappdata(hfig,'figureSetupComplete') || ...
       ~isequal(true,getappdata(hfig,'figureSetupComplete'))
        return
    end

    % application data
    api = guidata(hfig);

    % parameters
    mnsz = [500 350];   % minimum allowable figure size
    axmg = 10;          % axes margin
    plmx = 400;         % maximum playbar width
    wcb  = [25,50];     % colorbar inner/outer width
    orsz = [150 150];   % orientation axes size

    % figure size
    pfig = getpixelposition(api.hfig);
    sfig = max(mnsz,pfig(3:4));

    % popup position
    ppop = getpixelposition(api.hpopup);

    % main panel position
    w = ppop(1)+ppop(3)-1;
    ppnl = [1+w,1+pfig(4)-sfig(2),sfig(1)-w,sfig(2)];
    setpixelposition(api.hmain,ppnl);
    setpixelposition(api.hpanel3d,[1 1 ppnl(3:4)]);
    setpixelposition(api.hpaneltime,[1 1 ppnl(3:4)]);
    setpixelposition(api.hpanelbullseye,[1 1 ppnl(3:4)]);


    % playbar position
    pply = getpixelposition(api.hplaybar);
    pply(3) = min(ppnl(3) - 2*axmg,plmx);
    pply(1:2) = 1 + [(ppnl(3)-pply(3))/2, axmg];
    setpixelposition(api.hplaybar,pply);


    % A/B axes position
    h = (ppnl(4)-4*axmg)/2;
    w = (ppnl(3)-2*axmg);
    paxs = [1+axmg,1+3*axmg+h,w,h;
            1+axmg,1+axmg,w,h];
    set(api.haxA,'outerposition',paxs(1,:));
    set(api.haxB,'outerposition',paxs(2,:));

    % Bullseye axes position
    w = ppnl(3)-4*axmg-2*wcb(2);
    h = ppnl(4)-3*axmg-pply(4)-30;
    d = min(w,h);

    y = 1+axmg+pply(4) + (ppnl(4)-d-30-axmg-pply(4))/2;
    x = 1+(ppnl(3)-d)/2;

    fac = 0.8;
    hcb = fac*d;
    paxs = [x,y,d,d;
            x+d+axmg,y+d*(1-fac)/2,wcb(1),hcb];
    set(api.haxbullseye,'position',paxs(1,:));
    set(api.haxcbbullseye,'position',paxs(2,:));


    % 3D axes position
    if strcmpi(get(api.haxcb3d,'visible'),'on')
        xmg = (2*axmg+wcb(2))*[1 1];
        ymg = [pply(2)+pply(4),0] + axmg;
        pax = [1+xmg(1),1+ymg(1),ppnl(3)-sum(xmg),ppnl(4)-sum(ymg)];
        set(api.hax3d,'position',pax);

        pcb = [pax(1)+pax(3)+axmg,pax(2)+(pax(4)-hcb)/2,wcb(1),hcb];
        set(api.haxcb3d,'position',pcb);

    else
        xmg = axmg*[1 1];
        ymg = [pply(2)+pply(4),0] + axmg;
        pax = [1+xmg(1),1+ymg(1),ppnl(3)-sum(xmg),ppnl(4)-sum(ymg)];
        set(api.hax3d,'position',pax);
    end


end



%% FIGURE CLOSE REQUEST & DELETE

% figure close request
function figCloseRequest(hfig)

    % application data
    api = guidata(hfig);

    % confirm close (only when files are loaded)
    if ~isempty(api.data)
        str = 'Are you sure you want to quit?';
        answer = questdlg(str,'Quit?',...
            'Quit','Cancel','Cancel');
        if ~isequal(answer,'Quit')
            return
        end
    end

    % kill figure
    if isappdata(hfig,'WaitForOutput') && getappdata(hfig,'WaitForOutput')
        set(hfig,'userdata','close');
    else
        close(hfig,'force');
    end

end

% figure delete
function figDelete(hfig)

    % application data
    api = guidata(hfig);

    % save program information
    saveInfo(api);

    % eliminate objects
    tags = {'hcameralistener','hplaybarlistener','hplaybar'};

    for ti = 1:numel(tags)
        if isfield(api,tags{ti})
            try
                delete(api.(tags{ti}))
            catch ERR
                fprintf('Could not delete "%s"\n',tags{ti});
                ERR.getReport()
            end
        else
            fprintf('"%s" was not found\n',tags{ti})
        end
    end

end



%% LOAD/SAVE PROGRAM INFORMATION

% load program information
function api = loadInfo(api)

    % info file
    filename = fullfile(userdir(), ['.', mfilename]);

    % default software options
    definfo = struct(...
        'matpath',              pwd,...
        'exportpath',           pwd,...
        'excelpath',            pwd,...
        'backgroundcolor',      [0 0 0],...
        'edgecolor',            [1 1 1],...
        'textcolor',            [1 1 1],...
        'twistrng',             [-10 10],...
        'torsionrng',           [-0.5 0.5],...
        'colormaps',            defaultcolormaps,...
        'colormapidx',          1);
    tags = fieldnames(definfo);

    % reset options
    if api.ResetOptions && api.ResetPaths
        info = definfo;

    % parse options
    else

        % try to load file
        try
            s = load(filename,'-mat');
        catch ERR %#ok<*NASGU>
            s = struct;
        end

        % parse file options
        info = parseinputs(definfo,[],s);

        % check paths
        for ti = 1:numel(tags)
            tag = tags{ti};
            val = info.(tag);

            if strwcmpi(tag,'*path')
                if api.ResetPaths
                    val = definfo.(tag);
                else
                    if iscell(val), val = val{1}; end
                    if ischar(val)
                        val = regexprep(val,'[\/\\]',filesep);
                    end
                    if ~ischar(val) || ~isdir(val)
                        val = definfo.(tag);
                    end
                end

            elseif strwcmpi(tag,'*color')
                if api.ResetOptions || ~iscolor(val)
                    val = definfo.(tag);
                end
                val = clr2num(val);

            elseif strwcmpi(tag,'*rng')
                if api.ResetOptions || ...
                   ~isnumeric(val) || numel(val)~=2 || ...
                   ~all(isfinite(val)) || val(2)<=val(1)
                    val = definfo.(tag);
                end

            else
                continue
            end

            info.(tag) = val;
        end


        % check colormaps
        if api.ResetOptions
            info.colormaps   = definfo.colormaps;
            info.colormapidx = definfo.colormapidx;
        end

        N = numel(info.colormaps);
        valid = false(N,1);
        for k = 1:N
            try
                cmap = info.colormaps(k).Value;
                if ischar(cmap), cmap = eval(cmap); end
            catch ERR
                continue;
            end
            if isnumeric(cmap) && ndims(cmap)==2 && ...
              size(cmap,1)<=128 && size(cmap,2)==3 ...
              && ~(min(cmap(:))<0 || max(cmap(:))>1)
                valid(k) = true;
            end
        end
        info.colormaps = info.colormaps(valid);
        if any(~valid)
            info.colormapidx = 1;
        end

    end

    % copy to application data
    api.infofile = filename;
    api.infotags = tags;
    for ti = 1:numel(tags)
        api.(tags{ti}) = info.(tags{ti});
    end

end


% save program information
function saveInfo(api)

    % gather program information
    svdata = struct;
    tags   = api.infotags;
    for ti = 1:numel(tags)
        if isfield(api,tags{ti})
            svdata.(tags{ti}) = api.(tags{ti});
        end
    end

    % save
    if ~isempty(fieldnames(svdata))
        save(api.infofile,'-struct','svdata');
    end

end


function cmapstruct = defaultcolormaps()

    % typical 128 length colormaps
    allnames = {'Jet','Hot','Cool','Spring',...
        'Autumn','Winter','Gray','Bone','Copper','Pink'};
    allcmaps = cellfun(@(n)[lower(n) '(128)'],allnames,'uniformoutput',0);

    % high-mid-low colormaps
    names = {'High/Low (Color)'; 'High/Low (Gray)'};
    cmaps = {[0 0 1; 0 1 0; 1 0 0]; bsxfun(@times,[.2;.5;.8],ones(3))};

    allnames = [allnames(:);names(:)];
    allcmaps = [allcmaps(:);cmaps(:)];

    % cmaps
    cmapstruct = cell2struct([allnames(:),allcmaps(:)],{'Name','Value'},2);

end



%% LOAD ANALYSES

function loadFile(hfig)
    api = guidata(hfig);

    % analysis file extension
    ext = '*.mat';

    % various invalid files
    unrecognized   = {};
    wrongstudy     = {};
    duplicate      = {};
    uniqueparallel = {};


    % get file(s)
    startpath = api.matpath;
    [uifile,uipath] = uigetfile(...
        {ext,['Analysis File (' ext ')']; ...
         '*.*',  'All Files (*.*)'},...
        'Select Analysis File(s)',...
        startpath,'MultiSelect','on');
    if isequal(uipath,0), return; end

    % save new path
    api.matpath = uipath;
    guidata(api.hfig,api);


    % files to load
    if ~iscell(uifile), uifile = {uifile}; end
    files = cellfun(@(f)fullfile(uipath,f),uifile(:),'uniformoutput',0);
    if numel(files)>1, files = sort_nat(files); end
    Nfile = numel(files);

    % initialize space for file data
    Ndata = numel(api.data);
    idx = Ndata + (1:Nfile);
    api.data(idx(end)).Name = '';

    % record file validity
    valid = false(Nfile,1);


    % load files
    for fi = 1:Nfile
        try

            % record file & default name
            [~,f,e] = fileparts(files{fi});
            api.data(idx(fi)).File = files{fi};
            api.data(idx(fi)).Name = f;

            % load file
            data = load(files{fi},'-mat');

            % check for expected fields
            if ~all(isfield(data,api.datatags))
                continue;
            end

            % confirm some expected information
            if ~ischar(data.ROIInfo.ROIType) || ...
               ~strcmpi(data.ROIInfo.ROIType,'SA')
                continue;
            end

            tags = {'X','Y','dX','dY','dZ','Angle'};
            if ~all(isfield(data.DisplacementInfo,tags))
                continue;
            end

            % identifying sequence index
            midx = [data.DENSEInfo.MagIndex];
            tf = isfinite(midx);
            sidx = find(tf,1,'first');

            % copy to data structure
            tags = fieldnames(data);
            for ti = 1:numel(api.datatags)
                tag = api.datatags{ti};
                api.data(idx(fi)).(tag) = data.(tag);
            end

            % copy specific identifying information
            for ti = 1:numel(api.seqtags)
                tag = api.seqtags{ti};
                api.data(idx(fi)).(tag) = data.SequenceInfo(sidx).(tag);
            end

            % analysis information
            n = api.data(idx(fi)).AnalysisInfo.Nmodel;
            api.data(idx(fi)).Nmodel   = n;
            api.data(idx(fi)).Nsegment = n;

            % cleanup
            clear data
            valid(fi) = true;

        catch ERR %#ok<*NASGU>
%             ERR.getReport()
        end

    end


    % record & remove unrecognized files
    unrecognized = files(~valid);
    if any(~valid), removeData(); end


    % check for duplicates
    if numel(files)>0
        uid = {api.data.AnalysisInstanceUID};

        % duplicates
        valid = true(size(files));
        for k = 1:numel(files)
            uidk = uid{idx(k)};
            ind = find(strcmpi(uidk,uid));
            valid(k) = ind(1)==idx(k);
        end

        if any(~valid)
            duplicate = files(~valid);
            removeData();
        end
    end


    % confirm consistent study
    if numel(files)>0
        uid = {api.data.StudyInstanceUID};
        valid = strcmpi(uid(idx),uid{1});
        if any(~valid)
            if Ndata==0
                wrongstudy = files;
                valid(:) = false;
            else
                wrongstudy = files(~valid);
            end
            removeData();
        end
    end


    % check for unique parallel slices
    if numel(files)>0
        slicedata = DICOMslice(api.data);
        par = [slicedata.parallelid];
        pla = [slicedata.planeid];

        valid = true(size(files));
        for k = 1:numel(files)
            ind = find(pla(idx(k))==pla);
            valid(k) = (par(idx(k))==par(1)) && (ind(1)==idx(k));
        end

        if any(~valid)
            if Ndata==0
                uniqueparallel = files;
                valid(:) = false;
            else
                uniqueparallel = files(~valid);
            end
            removeData();
        end
    end




    % report to user
    str = {'----------------------------------------';
           sprintf('FILE REPORT FOR %d FILE(S)',Nfile);
           '----------------------------------------';' '};
    filefcn = @(F)cellfun(@(f)['    ',f],F,'uniformoutput',0);

    n = numel(files);
    if n>0
        filestr = files;
    else
        filestr = {'--'};
    end
    str = [str;sprintf('LOADING (%d)',n);...
        filefcn(filestr(:));' '];

    n = numel(uniqueparallel);
    if isempty(uniqueparallel), uniqueparallel = {'--'}; end
    str = [str;sprintf('NOT UNIQUE & PARALLEL SLICE PLANES (%d)',n);
        filefcn(uniqueparallel(:));' '];

    n = numel(wrongstudy);
    if isempty(wrongstudy), wrongstudy = {'--'}; end
    str = [str;sprintf('INCONSISTENT STUDY (%d)',n);
        filefcn(wrongstudy(:));' '];

    n = numel(duplicate);
    if isempty(duplicate), duplicate = {'--'}; end
    str = [str;sprintf('DUPLICATE or ALREADY LOADED (%d)',n);
        filefcn(duplicate(:));' '];

    n = numel(unrecognized);
    if isempty(unrecognized), unrecognized = {'--'}; end
    str = [str;sprintf('UNRECOGNIZED (%d)',n);
        filefcn(unrecognized(:));' '];

    h = msgbox(str,'File Report','modal');

    % quit if no valid files
    if numel(files)==0, return; end

    % save application data
    api = redrawDisplay(api);
    guidata(hfig,api);


    % enable clear menu option
    if numel(api.data)>0
        ena = 'on';
    else
        ena = 'off';
    end
    set([api.hclear,api.hexportmedia,api.hexportexcel],'enable',ena);



    function removeData()
        api.data(idx(~valid)) = [];
        files(~valid) = [];
        valid(~valid) = [];
        idx = Ndata + (1:numel(valid));
    end


end



function clearFile(hfig)
    api = guidata(hfig);

    % check for loaded files
    if isempty(api.data)
        set(api.hclear,'enable','off');
        return
    end

    % list files
    s = '&nbsp';
    fmt = ['<html>%s' s s s s '<font color=#888888><i>%s</i></font></html>'];
    liststr = cellfun(@(n,f)sprintf(fmt,n,f),...
        {api.data.Name},{api.data.File},'uniformoutput',0);

    [sel,ok] = listdlg(...
        'ListString',liststr(:),...
        'listsize',[300 200],...
        'promptstring','Select files to remove');
    if ~isequal(ok,1), return; end

    api.data(sel) = [];
    api = redrawDisplay(api);
    guidata(hfig,api);

end



%% REDRAW ALL DISPLAYS DISPLAY

function api = redrawDisplay(api)

    % delete current display objects
    delete([api.hpts;api.hcentroid;...
        api.htwist;api.htwistlegend;...
        api.htorsion;api.hbullseye]);
    api.hpts            = [];
    api.hcentroid       = [];
    api.htwist          = [];
    api.htorsion        = [];
    api.hbullseye       = [];
    api.htwistlegend    = [];

    % number of data elements
    Ndata = numel(api.data);


    % reset software if no loaded data
    if Ndata==0
        strs = get(api.hslice,'string');
        set(api.hslice,'string',strs(1),'value',1,'enable','off');
        set([api.hax3d,api.haxbullseye],...
            'xlim',[0 1],'ylim',[0 1],'zlim',[0 1]);
        set([api.haxA,api.haxB],'xlim',[0 10]);
        api.hplaybar.Min = 1;
        api.hplaybar.Max = 0;
        set([api.hclear,api.hexportmedia,api.hexportexcel],'enable','off');
        return
    end


    % order data along ImageOrientationPatient
    ipp = [api.data.ImagePositionPatient]';
    iop = [api.data.ImageOrientationPatient]';
    [~,pos,order] = isparallel(ipp,iop);

    h = api.hcheckreversez;
    tfz = isequal(get(h,'value'),get(h,'max'));
    if tfz
        pos(:,3) = -pos(:,3);
        order = Ndata+1 - order;
    end

    tmp = num2cell(pos,2);
    [api.data.SlicePosition] = deal(tmp{:});

    api.data = api.data(order);
    api.data = api.data(end:-1:1);


    % assign default slice colors
    clrs = sixcolors(Ndata);
    for k = 1:Ndata
        if ~isfield(api.data,'Color') || isempty(api.data(k).Color)
            api.data(k).Color = clrs(k,:);
        end
    end



    % all available frames (assuming 1-to-1 correspondance between slices)
    frmax = max([api.data.NumberInSequence]);
    allframes = 0:frmax;
    Nfr = numel(allframes);

    api.Frames = allframes;


    % parse displacement information
    ptmin = zeros(Ndata,3);
    ptmax = zeros(Ndata,3);

    api.AnalyzedFrames = false([Ndata,Nfr]);

    for k = 1:Ndata

        % dataset information
        pxsp = api.data(k).PixelSpacing(:)';
        imsz = double([api.data(k).Height,api.data(k).Width]);
        offset = api.data(k).SlicePosition;
        Npts = numel(api.data(k).DisplacementInfo.X);

        % valid frame indices into "dX"
        rng = api.data(k).AnalysisInfo.FramesForAnalysis;
        idx = rng(1):rng(2);


        % material point origins
        X0 = pxsp(2)*(api.data(k).DisplacementInfo.X-1) + offset(1);
        Y0 = pxsp(1)*(api.data(k).DisplacementInfo.Y-1) + offset(2);
        Z0 = zeros(size(X0)) + offset(3);

        % displacement from origins for frame [idx]
        dX = pxsp(2)*api.data(k).DisplacementInfo.dX(:,idx);
        dY = pxsp(1)*api.data(k).DisplacementInfo.dY(:,idx);
        dZ = pxsp(1)*api.data(k).DisplacementInfo.dZ(:,idx);

        % material point locations for frame [0,idx]
        X = [X0,bsxfun(@plus,X0,dX)];
        Y = [Y0,bsxfun(@plus,Y0,dY)];
        Z = [Z0,bsxfun(@plus,Z0,dZ)];


        % epicardial centroid for frame [0,idx]
        crv = cat(1,api.data(k).ROIInfo.RestingContour,...
            api.data(k).ROIInfo.Contour(idx,:));

        centroid = zeros(1,3,size(crv,1));
        for fr = 1:size(crv,1)
            BW = poly2mask(crv{fr,1}(:,1),crv{fr,1}(:,2),imsz(1),imsz(2));
            prop = regionprops(BW,'Centroid');
            centroid(:,:,fr) = [pxsp([2 1]).*(prop.Centroid-1),0] + offset;
        end


        % twist around current centroid
        xori = squeeze(centroid(:,1,:))';
        yori = squeeze(centroid(:,2,:))';
        theta = atan2(bsxfun(@minus,X,xori),bsxfun(@minus,Y,yori));
        theta = unwrap(theta,[],2);

        dtheta = bsxfun(@minus,theta,theta(:,1));

%         if api.data(k).AnalysisInfo.Clockwise
%             dtheta = -dtheta;
%         end






        % index into "pts" for 3D display for "allframes" members
        frames = [0,idx];
        dspidx = NaN(1,Nfr);
        for j = 1:Nfr
            d = allframes(j) - frames;
            dspidx(j) = find(d>=0,1,'last');
        end


        % record 3D plot information
        api.data(k).pts = zeros([Npts,3,Nfr]);
        api.data(k).pts(:,1,:) = X(:,dspidx);
        api.data(k).pts(:,2,:) = Y(:,dspidx);
        api.data(k).pts(:,3,:) = Z(:,dspidx);

        api.data(k).centroid = centroid(:,:,dspidx);


        % data extents
        ptmin(k,:) = min(min(api.data(k).pts,[],1),[],3);
        ptmax(k,:) = max(max(api.data(k).pts,[],1),[],3);

        % record angle identifier & twist
        th = api.data(k).DisplacementInfo.Angle;
        th(th<0 | th>=2*pi) = 0;
        api.data(k).Angle = th;
        api.data(k).Twist = dtheta(:,dspidx)*180/pi;

        % record members of "allframes" that this dataset considered
        api.AnalyzedFrames(k,:) = ismember(allframes,frames);

    end


    % average twist per cross section
    api.Twist = NaN([Ndata,Nfr]);
    for k = 1:Ndata
        tf = api.AnalyzedFrames(k,:);
        twi = mean(api.data(k).Twist,1);
        api.Twist(k,tf) = twi(tf);
    end

    % torsion (note we require at least two slices to have a valid
    % measurement on a given frame to calculate torsion)
    api.Torsion = NaN(1,Nfr);
    if Ndata>1
        pos = cat(1,api.data.SlicePosition);
        for fr = 1:numel(api.Frames)
            vals = api.Twist(:,fr);
            tf   = api.AnalyzedFrames(:,fr);
            if sum(tf)>=2
                api.Torsion(fr) = ...
                    -mean(diff(vals(tf))./diff(pos(tf,3)));
            end
        end
    end


    % update playbar limits & value
    val = api.hplaybar.Value;
    rng = [api.hplaybar.Min,api.hplaybar.Max];
    if isempty(val) || ~all(rng == allframes([1 end]))
        api.hplaybar.Min   = allframes(1);
        api.hplaybar.Max   = allframes(end);
        api.hplaybar.Value = allframes(1);
    end

    % current frame index
    val = api.hplaybar.Value;
    fridx = find(val==allframes,1,'first');

    % 3D display range
    dsprng = [min(ptmin,[],1); max(ptmax,[],1)];
    brdr = max(5,0.1*min(diff(dsprng)));
    dsprng = bsxfun(@plus,dsprng,[-brdr;brdr]);

    % 3D display
    set(api.hax3d,'xlim',dsprng(:,1),...
        'ylim',dsprng(:,2),'zlim',dsprng(:,3));
    api = init3d(api,fridx);

    % bullseye
    api = initBullseye(api,fridx);


    % twist & torsion display
    set([api.haxA;api.haxB],'xlim',allframes([1 end]));

    api.htwist = NaN(Ndata,1);
    for k = Ndata:-1:1
        tf = isfinite(api.Twist(k,:));
        api.htwist(k) = line(...
            'parent',api.haxA,...
            'xdata',api.Frames(tf),...
            'ydata',api.Twist(k,tf),...
            'color',api.data(k).Color,...
            'marker','.',...
            'DisplayName',api.data(k).Name);
    end

    api.htwistlegend = legend(api.haxA,'location','northeast');
    api.htwistlegendtext = findall(api.htwistlegend,'type','text');
    set(api.htwistlegend,...
        'color',api.backgroundcolor,...
        'xcolor',api.edgecolor,'ycolor',api.edgecolor,...
        'interpreter','none');
    set(api.htwistlegendtext,'fontsize',8,'color',api.edgecolor);

    tf = isfinite(api.Torsion);
    api.htorsion = line(...
        'parent',api.haxB,...
        'xdata',api.Frames(tf),...
        'ydata',api.Torsion(tf),...
        'color',api.edgecolor,...
        'marker','.');


    % list slices
    strs = get(api.hslice,'string');
    strs = {strs{1},api.data.Name};
    set(api.hslice,'string',strs,'value',1,'enable','on');

%     % save application data
%     guidata(hfig,api);

end


%% PLAYBAR CALLBACK
function playbarCallback(api)

    % figure input
    if ishandle(api), api = guidata(api); end

    % is update necessary
    val = api.hplaybar.Value;
    vis = api.hplaybar.Visible;
    if isempty(val) || strcmpi(vis,'off'), return; end

    % index into "Frames"
    fridx = find(val==api.Frames,1,'first');

    % display
    switch api.mode
        case api.hradio3d
            update3d(api,fridx);
        case api.hradiobullseye
            updateBullseye(api,fridx);

    end
    drawnow

end




%%
function displayChange(hfig,evnt)
    api = guidata(hfig);

    % selected object handle
    if nargin<2 || isempty(evnt)
        h = findobj(get(api.hplotpanel,'SelectedObject'));
    else
        h = evnt.NewValue;
    end

    % adjust axes visibility
    switch h
        case api.hradio3d
            hobj = api.hpanel3d;
            playbarvis = 'on';
            rotateena  = 'on';
        case api.hradiotime
            hobj = api.hpaneltime;
            playbarvis = 'off';
            rotateena  = 'off';
        case api.hradiobullseye
            hobj = api.hpanelbullseye;
            playbarvis = 'on';
            rotateena  = 'off';
    end

    hall = [api.hpanel3d,api.hpaneltime,api.hpanelbullseye];
    set(setdiff(hall,hobj),'visible','off');

    set(hobj,'visible','on');
    api.hplaybar.Visible = playbarvis;
    api.hrotate.Enable = rotateena;

    api.mode = h;
    guidata(hfig,api);

    playbarCallback(api);

%     figResize(hfig);

end


%% DISPLAY OPTIONS
function selectSlice(h,hfig)
    api = guidata(hfig);
    val = get(h,'value');
    idx = val-1;

    set([api.hpts;api.hcentroid;api.htwist],'linewidth',0.5);
    set(api.hbedge,'linewidth',0.5);

    if idx > 0
        set([api.hpts(idx);api.hcentroid(idx);api.htwist(idx)],'linewidth',4);
        set(api.hbedge(idx,1:2),'linewidth',4);
    end

end


function displayOptions(h,hfig)
    api = guidata(hfig);

    switch h
        case api.hbgcolor
            clr = uisetcolor(api.backgroundcolor,'Background');
            api.backgroundcolor = clr;

            set(h,'cdata',colorblock(clr));
            set(api.hmain,'backgroundcolor',clr);
            set(api.hax3d,'color',clr);

            if ~isempty(api.htwistlegend)
                set(api.htwistlegend,'color',clr);
            end

        case api.haxcolor
            clr = uisetcolor(api.edgecolor,'Axes');
            api.edgecolor = clr;

            set(h,'cdata',colorblock(clr));
            set([api.hax,api.hcb],'xcolor',clr,'ycolor',clr,'zcolor',clr);
            set(api.httl,'color',clr);
            set(api.htorsion,'color',clr);

            if ~isempty(api.hbullseye)
                set(api.hbedge,'edgecolor',clr);
            end

            if ~isempty(api.htwistlegend)
                set(api.htwistlegend,'xcolor',clr,'ycolor',clr);
                set(api.htwistlegendtext,'color',clr);
            end

        case api.htxcolor
            clr = uisetcolor(api.textcolor,'Text');
            api.textcolor = clr;

            set(h,'cdata',colorblock(clr));

            if ~isempty(api.hbullseye)
                set(cat(1,api.hbtext{:}),'color',clr);
            end

        case api.htwistmin
            tag = 'twistrng';
            setrng(h,tag,false);
            set([api.haxA,api.hcb],'ylim',api.(tag));
            updateColormap(api);

        case api.htwistmax
            tag = 'twistrng';
            setrng(h,tag,true);
            set([api.haxA,api.hcb],'ylim',api.(tag));
            updateColormap(api);

        case api.htorsionmin
            tag = 'torsionrng';
            setrng(h,tag,false);
            set(api.haxB,'ylim',api.(tag));

        case api.htorsionmax
            tag = 'torsionrng';
            setrng(h,tag,true);
            set(api.haxB,'ylim',api.(tag));

        case api.hlistcmap
            api.colormapidx = get(api.hlistcmap,'Value');
            updateColormap(api);

        case api.hcheckreversez
            api = redrawDisplay(api);

        case api.hlistslicecolor
            slicemode = get(api.hlistslicecolor,'value');
            if slicemode == 3
                vis = 'on';
            else
                vis = 'off';
            end
            set([api.hcb(1),api.hcmap(1)],'visible',vis);

            for k = 1:numel(api.data)
                set(api.hpts(k),'facevertexcdata',...
                    slicefvcd(api,k,slicemode));
            end

    end

    % save new data
    guidata(hfig,api);

    % update axes locations
    figResize(hfig);


    % change range
    function setrng(h,tag,flagmax)
        nbr = str2double(get(h,'string'));
        if flagmax
            if ~isfinite(nbr) || nbr <= api.(tag)(1)
                nbr = api.(tag)(end);
            end
            api.(tag)(end) = nbr;
        else
            if ~isfinite(nbr) || nbr >= api.(tag)(end)
                nbr = api.(tag)(1);
            end
            api.(tag)(1) = nbr;
        end
        set(h,'string',nbr);
    end

end



function im = colorblock(clr)
    sz = [15 15];
    clr = clr2num(clr);
    im = cat(3,clr(1)*ones(sz),clr(2)*ones(sz),clr(3)*ones(sz));
end



function fvcd = slicefvcd(api,idx,mode)
    if nargin<3 || isempty(mode)
        mode = get(api.hlistslicecolor,'value');
    end

    npts = size(api.data(idx).pts,1);
    switch mode

        % slice color
        case 1
            fvcd = ones(npts,1)*api.data(idx).Color;

        % segment color
        case 2
            n    = api.data(idx).Nmodel;
            cval = linspace(0,2*pi,n+1);
            cval = (cval(1:end-1)+cval(2:end))/2;
            cmap = hsv(n);
            fvcd = val2fvcd(api.data(idx).Angle,cval,cmap,[0 0 0]);

        % twist color
        case 3
            val   = api.hplaybar.Value;
            fridx = find(val==api.Frames,1,'first');
            cdata = get(api.hcmap(1),'userdata');

            fvcd = val2fvcd(api.data(idx).Twist(:,fridx),cdata.colorval,...
                cdata.colormap,api.backgroundcolor);

    end

end




%% SLICE NAME & COLOR
function sliceContext(hmenu,hlist)
    val = get(hlist,'value');
    if val==1
        vis = 'off';
    else
        vis = 'on';
    end
    set(allchild(hmenu),'visible',vis);
end


function sliceName(hfig)
    api = guidata(hfig);

    val = get(api.hslice,'value');
    if val==1, return; end
    idx = val-1;

    answer = inputdlg('Enter New Name','Modify Name',1,{api.data(idx).Name});
    if isempty(answer), return; end
    name = answer{1};

    api.data(idx).Name = name;
    guidata(hfig,api);

    strs = get(api.hslice,'String');
    strs{val} = name;
    set(api.hslice,'String',strs);

    set(api.htwist(idx),'DisplayName',name);
    drawnow

    set(api.htwistlegendtext,'color',api.edgecolor);
end


function sliceColor(hfig)
    api = guidata(hfig);

    val = get(api.hslice,'value');
    if val==1, return; end
    idx = val-1;

    clr = uisetcolor(api.data(idx).Color,api.data(idx).Name);

    api.data(idx).Color = clr;
    guidata(hfig,api);

    set(api.hpts(idx),'facevertexcdata',slicefvcd(api,idx));
    set(api.hcentroid(idx),'markerfacecolor',clr,'markeredgecolor',clr);
    set(api.htwist(idx),'color',clr);

end



%% COLORMAP FUNCTIONS

function updateColormap(api,flag_runplaybar)

    % default flag
    if nargin<2, flag_runplaybar = true; end
    flag_runplaybar = isequal(true,flag_runplaybar);

    % twist range
    rng = api.twistrng;

    % colormap
    cmap = api.colormaps(api.colormapidx).Value;
    if ischar(cmap), cmap = eval(cmap); end

    % color values
    N = size(cmap,1);
    y = linspace(rng(1),rng(2),N+1);
    cval = (y(1:end-1)+y(2:end))/2;

    % face/vertex struture
    [X,Y] = meshgrid([0 1],y);
    fv = surf2patch(X,Y,zeros(size(X)));
    fv.vertices = fv.vertices(:,1:2);
    fv.facevertexcdata = cmap;

    % update colormap patches
    svdata = struct('colormap',cmap,'colorval',cval);
    set(api.hcmap,fv,'userdata',svdata);

    % update additional display objects
    if flag_runplaybar, playbarCallback(api); end

end


function addColormap(hfig)
    answer = inputdlg({'Colormap Name','Colormap command'},...
        'New Colormap',1,{'Custom',''});
    if isempty(answer), return; end

    try
        name = answer{1};
        cmap = eval(answer{2});

        if ~isnumeric(cmap) || ndims(cmap)~=2 || ...
            size(cmap,1)>128 || size(cmap,2)~=3
            error('temp:temp','invalid');
        end

        api = guidata(hfig);
        newidx = numel(api.colormaps)+1;
        api.colormaps(newidx).Name  = name;
        api.colormaps(newidx).Value = cmap;
        api.colormapidx = newidx;
    catch ERR
        error(sprintf('%s:invalidColormap',mfilename),'%s',...
            'Unrecognized colormap.  Colormap command must ',...
            'evaluate to an [Nx3] matrix, where N<=128.');
    end

    % update display
    set(api.hlistcmap,'string',{api.colormaps.Name},'value',newidx);
    updateColormap(api);

    % save application data
    guidata(hfig,api);

end


function deleteColormap(hfig)
    api = guidata(hfig);

    if numel(api.colormaps)==1
        errordlg('Cannot delete all colormaps','Delete Colormap','modal');
        return
    else
        str = sprintf(['Are you sure you would like ',...
            'to delete the "%s" colormap?'],...
            api.colormaps(api.colormapidx).Name);
        answer = questdlg(str,'Delete Colormap','Yes','Cancel','Cancel');
        if ~isequal(answer,'Yes'), return; end
    end

    % delete colormap
    api.colormaps(api.colormapidx) = [];
    api.colormapidx = 1;

    % update display
    set(api.hlistcmap,'string',{api.colormaps.Name},'value',api.colormapidx);
    updateColormap(api);

    % save application data
    guidata(hfig,api);

end


%% 3D FUNCTIONS

function api = init3d(api,fridx)

    % eliminate current plot
    delete([api.hpts,api.hcentroid]);
    api.pts       = [];
    api.hcentroid = [];

    % number of data elements
    Ndata = numel(api.data);
    if Ndata==0, return; end

    % current frame index
    if nargin<2 || isempty(fridx)
        val = api.hplaybar.Value;
        fridx = find(val==api.Frames,1,'first');
    end


    % create graphics
    api.hpts = NaN(Ndata,1);
    api.hcentroid = NaN(Ndata,1);
    for k = 1:Ndata
        vert = api.data(k).pts(:,:,1);
        npts = size(vert,1);
        face = (1:npts)';

        api.hpts(k) = patch(...
            'parent',api.hax3d,...
            'vertices',vert,...
            'faces',face,...
            'facecolor','none',...
            'edgecolor','none',...
            'marker','o',...
            'markeredgecolor','flat',...
            'markerfacecolor','flat',...
            'markersize',4,...
            'facevertexcdata',zeros(npts,3),...
            'linewidth',0.5);

        api.hcentroid(k) = patch(...
            'parent',api.hax3d,...
            'vertices',api.data(k).centroid(:,:,1),...
            'faces',1,...
            'facecolor','none',...
            'edgecolor','none',...
            'marker','s',...
            'markerfacecolor',api.data(k).Color,...
            'markeredgecolor',api.data(k).Color,...
            'markersize',6,...
            'linewidth',0.5);
    end

    % update material point colors
    update3d(api,fridx);

end


function update3d(api,fridx,opt)

    if nargin<3 || isempty(opt)
        opt = get(api.hlistslicecolor,'value');
    end

    for k = 1:numel(api.data)

        % coloring
        npts = size(api.data(k).pts,1);
        switch opt

            % slice color
            case 1
                fvcd = ones(npts,1)*api.data(k).Color;

            % segment color
            case 2
                n    = api.data(k).Nmodel;
                cval = linspace(0,2*pi,n+1);
                cval = (cval(1:end-1)+cval(2:end))/2;
                cmap = hsv(n);
                fvcd = val2fvcd(api.data(k).Angle,cval,cmap,[0 0 0]);

            % twist color
            case 3
                cdata = get(api.hcmap(1),'userdata');
                fvcd = val2fvcd(api.data(k).Twist(:,fridx),cdata.colorval,...
                    cdata.colormap,api.backgroundcolor);

        end

        % update display
        set(api.hpts(k),'vertices',api.data(k).pts(:,:,fridx),...
            'facevertexcdata',fvcd);
        set(api.hcentroid(k),'vertices',api.data(k).centroid(:,:,fridx));
    end


end





%% BULLSEYE FUNCTIONS

function api = initBullseye(api,fridx)

    % eliminate current bullseye plot
    delete(api.hbullseye);
    api.hbullseye = [];

    % number of data elements
    Ndata = numel(api.data);
    if Ndata==0, return; end

    % current frame index
    if nargin<2 || isempty(fridx)
        val = api.hplaybar.Value;
        fridx = find(val==api.Frames,1,'first');
    end


    % calculate regional twist
    % based on current user-selected number of segments
    for k = 1:Ndata

        th = api.data(k).Angle;
        n = api.data(k).Nsegment;
        id = floor(n*th/(2*pi))+1;

        tffr = api.AnalyzedFrames(k,:);
        api.data(k).RegionalTwistValue = NaN(n,numel(api.Frames));
        clrs = hsv(n);
        for ri = 1:n
            tf = (id==ri);
            if any(tf)
                api.data(k).RegionalTwistValue(ri,tffr) = ...
                    mean(api.data(k).Twist(tf,tffr),1);
            end
        end
    end


    % colormap information
    cdata = get(api.hcmap(1),'userdata');

    % create bullseye
    bdata = repmat(struct,[Ndata,1]);
    for k = 1:Ndata
        bdata(k).SegmentModel     = api.data(k).Nmodel;
        bdata(k).NumberOfSegments = api.data(k).Nsegment;
        bdata(k).NumberOfLayers   = 1;
        bdata(k).Text = api.data(k).RegionalTwistValue(:,fridx);
    end
    [api.hbullseye,api.hbface,api.hbedge,api.hbtext] = ...
        dense_bullseye(api.haxbullseye,bdata,...
        'SegmentEdgeColor',api.edgecolor,'FontColor',api.textcolor);

    % add context menu
    set(api.hbface,'uicontextmenu',api.hmenu_bullseye);

    % text visibility
    set(cat(1,api.hbtext{:}),'visible',get(api.hdisplaytext,'checked'));

    % update text & colors
    updateBullseye(api,fridx);

end


function updateBullseye(api,fridx)
    cdata = get(api.hcmap(1),'userdata');

    for k = 1:numel(api.data)
        vals = api.data(k).RegionalTwistValue(:,fridx);
        strs = cellfun(@(nbr)sprintf('%.1f',nbr),num2cell(vals),...
                'uniformoutput',0);
        fvcd = val2fvcd(vals,cdata.colorval,...
                cdata.colormap,api.backgroundcolor);

        set(api.hbtext{k}(:),{'String'},strs(:));
        set(api.hbface(k),'facecolor','flat',...
            'FaceVertexCData',fvcd);
    end
end


function bullseyeContext(hmenu,hfig)
    api = guidata(hfig);

    % current selection
    idx = find(gco==api.hbface,1,'first');
    if isempty(idx)
        set(allchild(hmenu),'visible','off');
        return;
    end

    % eliminate previous options
    hchild = allchild(hmenu);
    hchild = setdiff(hchild,api.hdisplaytext);
    delete(hchild);

    % text display option
    set(api.hdisplaytext,'callback',@(varargin)displayText());

    % create menu items
    nbr = unique([api.data(idx).Nmodel * (1:4),...
        api.data(idx).Nsegment]);

    chkidx = find(nbr==api.data(idx).Nsegment,1,'first');
    chk  = repmat({'off'},numel(nbr));
    chk{chkidx} = 'on';

    sep = 'on';
    for k = 1:numel(nbr)
        uimenu('parent',hmenu,'Label',sprintf('%d segments',nbr(k)),...
            'Callback',@(varargin)changeSegments(idx,nbr(k)),...
            'Separator',sep,'Checked',chk{k});
        sep = 'off';
    end

    set(allchild(hmenu),'visible','on');

    function displayText()
        if isequal(get(api.hdisplaytext,'Checked'),'on')
            val = 'off';
        else
            val = 'on';
        end
        set(api.hdisplaytext,'checked',val);
        set(cat(1,api.hbtext{:}),'visible',val);
    end

    function changeSegments(idx,n)
        api.data(idx).Nsegment = n;
        api = initBullseye(api);
        guidata(api.hfig,api);
    end

end



%% EXPORT OPTIONS

function exportMultimedia(hfig)
    api = guidata(hfig);

    % check for valid data
    if isempty(api.data)
        return;
    end

    % allowable export formats & colormaps
    switch api.mode
        case api.hradiotime
            export = {'Image'};
            hpanel = api.hpaneltime;
            cmapmode = cat(1,api.data.Color);
        case api.hradio3d
            export = {'Video','Image'};
            hpanel = api.hpanel3d;

            Ndata = numel(api.data);
            cmapmode = cell(Ndata,1);
            for k = 1:numel(api.data)
                cmapmode{k} = unique([api.data(k).Color;...
                    hsv(api.data(k).Nmodel)],'rows');
            end
            cmapmode = cat(1,cmapmode{:});

            if strcmpi(get(api.hcmap(1),'visible'),'on')
                cmapmode = [cmapmode; get(api.hcmap(1),'facevertexcdata')];
            end

        case api.hradiobullseye
            export = {'Video','Image'};
            hpanel = api.hpanelbullseye;
            cmapmode = get(api.hcmap(2),'facevertexcdata');
    end

    % check cmapmode
    if isempty(cmapmode)
        cmapmode = zeros(0,3);
    end

    % full colormap
    cmap = [api.backgroundcolor;api.edgecolor;api.textcolor;cmapmode];
    cmap = unique(cmap,'rows');
    tf   = ~ismember(cmap,api.backgroundcolor,'rows');
    cmap = [api.backgroundcolor;cmap(tf,:)];

    formats = api.formats;
    tf = cellfun(@(f)any(strcmpi(export,f)),{formats.Type});
    formats = formats(tf);

    % last export options
    if ~isfield(api,'exportopts') || isempty(api.exportopts)
        opts = struct('File','');
    else
        opts = api.exportopts;
    end


    % export path
    p = api.exportpath;
    if ~isdir(p), p = pwd; end

    % export file
    [~,f,e] = fileparts(opts.File);
    if isempty(f), f = 'untitled'; end
    idx = regexp(f,'\(\d+\)');
    if ~isempty(idx), f = f(1:idx(1)-1); end
    f = strtrim(f);


    % export extension
    idx = matchmultimediaformat(e,formats);
    if isempty(idx)
        e = api.formats(1).Extension{1};
    end

    % check for default export file existance
    file = fullfile(p,[f,e]);
    cnt  = 0;
    while isfile(file)
        cnt = cnt+1;
        file = fullfile(p,sprintf('%s (%d)%s',f,cnt,e));
    end
    opts.File = file;

    % export file selection & options
    opts = exportgui(opts,'AllFormats',formats,'ParseOptions',false);
    if isempty(opts), return; end

    % remove format info from options
    format = opts.Format;
    opts   = rmfield(opts,'Format');

    % file & path
    exportfile = opts.File;
    [p,~,e] = fileparts(exportfile);
    exportpath = p;

    % write new application data
    api.exportopts = opts;
    api.exportpath = exportpath;
    guidata(hfig,api);



    % EXPORT FIGURE SETUP--------------------------------------------------

    % rectangle from current figure for export
    rect = getunitposition(hpanel,'inches',true);
    if isequal(api.hplaybar.Visible,'on')
        pply = getunitposition(api.hplaybar,'inches',true);
        offset = pply(2)+pply(4);
        rect(2) = rect(2) + offset;
        rect(4) = rect(4) - offset;
    end

    % allowable screen size
    units = get(0,'Units');
    set(0,'Units','inches');
    pos = get(0,'ScreenSize');
    set(0,'Units',units);
    scrsz = ceil(pos(3:4)-1);

    % export size & resolution
    if opts.UseScreenResolution
        res = get(0,'ScreenPixelsPerInch');
    else
        res = opts.Resolution;
    end

    if opts.UseScreenSize
        figsz = rect(3:4);
    else
        figsz = [opts.Width,opts.Height];
        if any(figsz>scrsz)
            fac   = max(figsz./scrsz);
            figsz = figsz / fac;
            res   = res*fac;
        end
    end


    % invisible figure for export
    vis = 'off';
    hexfig = figure('units','inches','position',[0 0 rect(3:4)],...
        'color',api.backgroundcolor,...
        'renderer','zbuffer','visible',vis,...
        'menubar','none','toolbar','none','resize','off',...
        'paperunits','inches','papersize',figsz);
    if strcmpi(vis,'off')
        cleanupFig = onCleanup(@()close(hexfig(ishandle(hexfig)),'force'));
    end

    % frame text
    fontsz = 14;
    hframe = textfig(hexfig,'units','pixels','units','normalized',...
        'position',[1 0],'horizontalalignment','right',...
        'verticalalignment','bottom','string','0 ',...
        'FontSize',fontsz,'Color',api.edgecolor,...
        'fontweight','bold','fontname','calibri',...
        'visible',api.hplaybar.Visible);


    % empty export axes
    hax = [];

    % figure export options on figure
    hgoptions = struct(...
        'Background',   api.backgroundcolor,...
        'Format',       format.HGExportFormat,...
        'LockAxes',     'on',...
        'LineMode',     'none',...
        'FontMode',     'none',...
        'Resolution',   res);

    % waitbar
    [hwait,cleanupWait] = waitbarnotex(0,{'Exporting',exportfile});
    drawnow



    % IMAGE EXPORT---------------------------------------------------------
    if isequal(format.Type,'Image')
        copyfigure();
        hgexport(hexfig,exportfile,hgoptions);


    % VIDEO EXPORT---------------------------------------------------------
    else

        % current frame
        curframe = api.hplaybar.Value;

        % video options
        fps    = opts.FramesPerSecond;
        delay  = (1/fps);
        codec  = opts.AVICodec;
        resstr = sprintf('-r%d',res);
        frames = api.Frames;
        fac    = 5; % 1st/Last frame delay factor

        % apply hgexport options to figure
        state = hgexport(hexfig,'temp.tmp',hgoptions,'ApplyStyle',1);


        % *****AVI EXPORT*****
        if isequal(format.Name,'AVI')

            % append frames
            frames = frames([1*ones(1,fac),2:end-1,end*ones(1,fac)]);

            % compression options
            if any(strcmpi(codec,{'MSVC','RLE'}))
%                 cmap = colorcube(256);
                args = {'colormap',cmap};
                FLAG_index = true;
            elseif any(strcmpi(codec,{'Indeo3'}))
%                 cmap = colorcube(236);
                args = {'colormap',cmap};
                FLAG_index = true;
            else
                args = {};
                FLAG_index = false;
            end


            % create video
            aviobj = [];
            try

                % initialize AVI file
                aviobj = avifile(exportfile,args{:},...
                    'compression',codec,'fps',fps);

                for k = 1:numel(frames)

                    % update figure
                    api.hplaybar.Value = frames(k);
                    drawnow

                    % figure snapshot
                    copyfigure();
                    drawnow
                    im = hardcopy(hexfig,'temp.tmp','-dzbuffer',resstr);
                    if FLAG_index, im = rgb2ind(im,cmap); end

                    % save image
                    aviobj = addframe(aviobj,im);

                    % update waitbar
                    waitbar(k/numel(frames),hwait);
                    drawnow
                end
                aviobj = close(aviobj);

            % video creation problem
            % (often due to an invalid compression codec)
            catch ERR
                if ~isempty(aviobj), aviobj = close(aviobj); end
                if isfile(exportfile), delete(exportfile); end

                api.exportopts.AVICodec = 'None';
                guidata(hfig,api);

                api.hplaybar.Value = curframe;
                rethrow(ERR);
            end


        % *****GIF EXPORT*****
        else

            % adjust delay
            delay = delay .* [fac,1];

            % default colormap for GIF
%             cmap = colorcube(256);

            % create video
            try
                for k = 1:numel(frames)

                    % update figure
                    api.hplaybar.Value = frames(k);
                    drawnow

                    % figure snapshot
                    copyfigure();
                    drawnow
                    im = hardcopy(hexfig,'temp.tmp','-dzbuffer',resstr);
                    im = rgb2ind(im,cmap);

                    % gif export options
                    if k==1
                        gifopts = {'Writemode','overwrite',...
                                   'LoopCount',Inf,...
                                   'BackgroundColor',0,...
                                   'DelayTime',delay(1),...
                                   'DisposalMethod','doNotSpecify'};
                    elseif k==numel(frames)
                        gifopts = {'Writemode','append',...
                                   'DelayTime',delay(1),...
                                   'DisposalMethod','doNotSpecify'};
                    else
                        gifopts = {'Writemode','append',...
                                   'DelayTime',delay(2),...
                                   'DisposalMethod','doNotSpecify'};
                    end


                    % ANIMATED GIF frame
                    % try several times times to write to file, as the
                    % initial write operation may not complete
                    gifERR = [];
                    for gifiter = 1:5
                        try
                            imwrite(im,cmap,exportfile,gifopts{:});
                            gifERR = [];
                            break
                        catch gifERR
                            pause(0.1)
                        end
                    end
                    if isa(gifERR,'MException'), rethrow(gifERR); end

                    % update waitbar
                    waitbar(k/numel(frames),hwait);
                    drawnow

                end

            % video creation problem
            catch ERR
                if isfile(exportfile), delete(exportfile); end
                api.hplaybar.Value = curframe;
                rethrow(ERR);
            end

        end

        % reset playbar
        api.hplaybar.Value = curframe;
        drawnow

    end


    % CLEANUP--------------------------------------------------------------

    % waitbar completion
    if ishandle(hwait)
        waitbar(1,hwait,{'Export Complete',exportfile});
        pause(1.0);
    end


    function copyfigure()

        % remove current axes
        delete(hax);

        % reset external figure size
        set(hexfig,'position',[0 0 rect(3:4)]);

        % copy visible axes from selected panel to external figure
        haxorig = findall(hpanel,'type','axes','-and','visible','on');
        hax = copyobj(haxorig,hexfig);

        % reposition axes
        set(hax,'units','inches');
        for ai = 1:numel(hax)
            pos = getunitposition(haxorig(ai),'inches',true);
            pos(1:2) = pos(1:2) - rect(1:2);
            set(hax(ai),'position',pos);
        end

        % allow axes stretch
        set(hax,'units','normalized');

        % adjust figure to export size
        set(hexfig,'position',[0 0 figsz]);

        % update frame number
        if strcmpi(get(hframe,'visible'),'on')
            uistack(hframe,'top');
            set(hframe,'String',sprintf('%d ',api.hplaybar.Value));
        end

    end



end


%% EXPORT MEASUREMENTS (EXCEL/CSV)

function exportExcel(hfig)
    api = guidata(hfig);
    if numel(api.data)==0, return; end

    % sizes
    Nfr   = numel(api.Frames);
    Nsl   = numel(api.data);
    Nseg  = sum([api.data.Nsegment]);


    % save file filters
    filter = {'.xls','*.xls','Microsoft Excel (*.xls)';
              '.csv','*.csv','Comma Delimited Text (*.csv)'};
    if ~api.ExcelAvailable, filter(1,:) = []; end


    % last export options
    if ~isfield(api,'excelfile') || isempty(api.excelfile)
        file = '';
    else
        file = api.excelfile;
    end

    % export path
    p = api.excelpath;
    if ~isdir(p), p = pwd; end

    % export file
    [~,f,e] = fileparts(file);
    if isempty(f), f = 'untitled'; end
    idx = regexp(f,'\(\d+\)');
    if ~isempty(idx), f = f(1:idx(1)-1); end
    f = strtrim(f);

    % export extension
    if isempty(e) || ~ischar(e) || ~any(strcmpi(e,filter(:,1)))
        e = filter{1,1};
    end

    % check for default export file existance
    file = fullfile(p,[f,e]);
    cnt  = 0;
    while isfile(file)
        cnt = cnt+1;
        file = fullfile(p,sprintf('%s (%d)%s',f,cnt,e));
    end


    % reorder filter
    idx = find(strcmpi(e,filter(:,1)),1,'first');
    if ~isempty(idx)
        idx = [idx,setdiff(1:size(filter,1),idx)];
        filter = filter(idx,:);
    end

    % user-selected file
    [uifile,uipath,filteridx] = uiputfile(filter(:,2:end),...
        'Save Measurements',file);
    if isequal(uifile,0), return; end
    uiext = filter{filteridx,1};

    % check file extension
    [~,~,e] = fileparts(uifile);
    if ~strcmpi(e,uiext), uifile = [uifile,uiext]; end
    file = fullfile(uipath,uifile);


    api.excelpath = uipath;
    api.excelfile = file;
    guidata(hfig,api);



    % AVERAGE TWIST-----------
    Ctwist = cell(Nsl+2,Nfr+1);

    % title
    Ctwist{1,1} = 'Average Twist (degrees)';

    % frames
    Ctwist{2,1}     = 'Frame';
    Ctwist(2,2:end) = num2cell(api.Frames);

    % avg twist values
    Ctwist(3:end,1) = {api.data.Name};

    nbr = num2cell(api.Twist);
    tf  = cellfun(@(n)isnan(n),nbr);
    nbr(tf) = {[]};
    Ctwist(3:end,2:end) = nbr;


    % TORSION-----------------
    Ctorsion = cell(3,Nfr+1);

    % title
    Ctorsion{1,1} = 'Torsion (degrees/mm)';

    % frames
    Ctorsion{2,1}     = 'Frame';
    Ctorsion(2,2:end) = num2cell(api.Frames);

    % torsion values
    Ctorsion{3,1}     = 'Torsion';

    nbr = num2cell(api.Torsion);
    tf  = cellfun(@(n)isnan(n),nbr);
    nbr(tf) = {[]};
    Ctorsion(3,2:end) = nbr;



    % REGIONAL TWIST----------

    % 4/6 element labels
    label4 = {'anterior','septal','inferior','lateral'};
    label6 = {'anterior','anteroseptal','inferoseptal',...
        'inferior','inferolateral','anterolateral'};


    % initialize
    Cregion = cell(Nseg+2+Nsl,Nfr+1);
    Cregion{1,1} = 'Regional Twist (degrees)';

    Cregion{2,1} = 'Frame';
    Cregion(2,2:end) = num2cell(api.Frames);

    row = 3;
    for k = 1:Nsl
        Cregion{row,1} = api.data(k).Name;

        nmod = api.data(k).Nmodel;
        nseg = api.data(k).Nsegment;

        lbl = arrayfun(@(n)sprintf('    %d',n),1:nseg,'uniformoutput',0);

        skip = nseg/nmod;
        if nmod == 4
            lbl(1:skip:end) = strcat(lbl(1:skip:end),' (',label4,')');
        else
            lbl(1:skip:end) = strcat(lbl(1:skip:end),' (',label6,')');
        end

        r = row+(1:nseg);
        Cregion(row+(1:nseg),1) = lbl;

        nbr = num2cell(api.data(k).RegionalTwistValue);
        tf  = cellfun(@(n)isnan(n),nbr);
        nbr(tf) = {[]};
        Cregion(row+(1:nseg),2:end) = nbr;

        row = row+nseg+1;
    end


    % OUTPUT FILE---------

    % delete exiting file
    if isfile(file), delete(file); end

    % waitbar
    [hwait,cleanupWait] = waitbarnotex(0,{'Exporting',file});
    drawnow

    % gather cells
    C = [Ctwist;
         cell(2,Nfr+1);
         Ctorsion;
         cell(2,Nfr+1);
         Cregion];

    % excel output
    if strcmpi(uiext,'.xls')
        xlswrite(file,C);


    % comma-delimited output
    else

        % pad title column
        n   = max(cellfun(@numel,C(:,1)));
        fmt = sprintf('%%-%ds',n)  ;
        C(:,1) = cellfun(@(c)sprintf(fmt,c),C(:,1),'uniformoutput',0);

        % convert numbers to strings of equal length
        C(:,2:end) = cellfun(@(c)makestr(c),C(:,2:end),'uniformoutput',0);

        % string printing
        fmt = repmat('%s,',[1 size(C,2)]);
        fmt = [fmt,'\r\n'];

        % open file
        fid = fopen(file,'w');

        ERR = [];
        try
            for row = 1:size(C,1)
                fprintf(fid,fmt,C{row,:});
            end
        catch ERR
            fclose(fid);
            if isfile(file), delete(file); end
            rethrow(ERR);
        end
        fclose(fid);

    end

    % update waitbar
    if ishandle(hwait)
        waitbar(1,hwait,{'Export Complete',file});
        pause(1);
    end



    % HELPER FUNCTION - NUMBER TO STRING
    function c = makestr(c)
        defc = '          ';
        if isempty(c)
            c = defc;
        elseif isnumeric(c)
            if mod(c,1)==0
                c = sprintf('%10d',c);
            else
                c = sprintf('%10.4f',c);
            end
        elseif ~ischar(c)
            c = defc;
        end
    end


end


function [hwait,cleanupWait] = waitbarnotex(val,str)

    % disable tex warning
    warnid = 'MATLAB:tex';
    state = warning('query',warnid);
    warning('off',warnid);

    % start waitbar
    hwait = [];
    try
        hwait = waitbar(val,str,...
            'WindowStyle','modal','CloseRequestFcn',[]);
        cleanupWait = onCleanup(@()close(hwait(ishandle(hwait)),'force'));
        htmp = findall(hwait,'type','text');
        set(htmp,'Interpreter','none');
    catch ERR
        warning(state,warnid);
        if ishandle(hwait), close(hwait,'force'); end
        rethrow(ERR);
    end

    % reset warning
    warning(state.state,warnid);

end



%% TEST CODE
function testCode(hfig)
    api = guidata(hfig);

    get(api.hax3d)
    api.hrotate.RotateMethod = 'upvector';
    api.hrotate
%     set(api.hax3d,'CameraUpVector',[0 0 1],...
%         'CameraViewAngleMode','auto',...
%         'View',[30 45]);
%     get(api.hax3d)
%     set(api.hax3d,'cameraviewangle',get(api.hax3d,'cameraviewangle'));


end






