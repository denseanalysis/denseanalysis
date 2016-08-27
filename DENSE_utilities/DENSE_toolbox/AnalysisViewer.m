%% ANALYSISVIEWER: DENSEanalysis analysis visualization
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% CLASS DEFINITION
classdef AnalysisViewer < DataViewer

    properties (SetAccess='private')
        isAllowExportMat = false;
        isAllowExportExcel = false;
    end

    properties

        % button group & options
        hbuttongroup
        options
        hmodel

        emptyapi = struct(...
            'initFcn',       [],...
            'resizeFcn',     [],...
            'playbackFcn',   [],...
            'deleteFcn',     []);

        api

        dispclr = [78 101 148]/255;

        straindata
        lastframe = [];

        Enable = 'on';
        enableobject = [];

        strainopts = struct(...
            'Colormap', 'jet',...
            'XXrng',    [-0.5 0.5],...
            'YYrng',    [-0.5 0.5],...
            'XYrng',    [-0.5 0.5],...
            'YXrng',    [-0.5 0.5],...
            'p1rng',    [-0.7 0.7],...
            'p2rng',    [-0.3 0.3],...
            'RRrng',    [-0.7 0.7],...
            'CCrng',    [-0.3 0.3],...
            'SSrng',    [-0.3 0.3],...
            'dXrng',    [-3 3],...
            'dRrng',    [-3 3],...
            'dCrng',    [-1 1],...
            'twistrng', [-10 10],...
            'Pixelate', true,...
            'Marker',   true);
    end

    methods
        function obj = AnalysisViewer(varargin)
            opts = struct([]);
            obj = obj@DataViewer(opts, varargin{:});
            obj = analysisViewerFcn(obj);
            obj.redrawenable = true;
            redraw(obj);
        end

        function redraw(obj)
            redraw@DataViewer(obj);
        end

        function set.Enable(obj,val)
            val = setEnableFcn(obj,val);
            obj.Enable = val;
        end

        function file = exportExcel(obj,startpath)
            file = exportExcelFcn(obj,startpath);
        end

        function file = exportMat(obj,startpath)
            file = exportMatFcn(obj,startpath);
        end

        function strainoptions(obj)
            strainoptsFcn(obj);
        end
    end

    methods (Access=protected)

        function playback(obj)
            if ~isempty(obj.api.playbackFcn)
                obj.api.playbackFcn();
            end
        end

        function reset(obj)
            resetDispFcn(obj);
        end

        function dataevent(obj,evnt)
            dataeventFcn(obj,evnt);
        end

        function resize(obj)
            resize@DataViewer(obj);
            resizeCtrl(obj);
            if ~isempty(obj.api.resizeFcn)
                try
                    obj.api.resizeFcn();
                catch
                    obj.api.resizeFcn = [];
                end
            end
        end

        function loadspl(obj)
            loadsplFcn(obj);
        end
    end
end

%% CONTROL PANEL DISPLAY OPTIONS
function opt = controlOptions()

    idx = 0;
    opt = struct;

    % phase imagery
    idx = idx+1;
    opt(idx).Name  = 'phase';
    opt(idx).Label = 'Phase Imagery';
    opt(idx).Fcn   = @(obj)phaseDisplay(obj);

    % Eulerian 2D wrapped
    idx = idx+1;
    opt(idx).Name  = 'euler2Dwrap';
    opt(idx).Label = 'Eulerian 2D wrapped';
    opt(idx).Fcn   = @(obj)vectorDisplay(obj,'euler','2D','wrap',true);
    opt(idx).Type  = [];

    % Eulerian 2D unwrapped
    idx = idx+1;
    opt(idx).Name  = 'euler2Dunwrap';
    opt(idx).Label = 'Eulerian 2D unwrapped';
    opt(idx).Fcn   = @(obj)vectorDisplay(obj,'euler','2D','unwrap',true);
    opt(idx).Type  = [];

    % Eulerian 3D unwrapped
    idx = idx+1;
    opt(idx).Name  = 'euler3Dunwrap';
    opt(idx).Label = 'Eulerian 3D unwrapped';
    opt(idx).Fcn   = @(obj)vectorDisplay(obj,'euler','3D','unwrap',true);
    opt(idx).Type  = [];

    % Lagrangian 2D
    idx = idx+1;
    opt(idx).Name  = 'lagrange2D';
    opt(idx).Label = 'Lagrangian 2D';
    opt(idx).Fcn   = @(obj)vectorDisplay(obj,'lagrange','2D','unwrap',true);
    opt(idx).Type  = [];

    % Lagrangian 3D
    idx = idx+1;
    opt(idx).Name  = 'lagrange3D';
    opt(idx).Label = 'Lagrangian 3D';
    opt(idx).Fcn   = @(obj)vectorDisplay(obj,'lagrange','3D','unwrap',true);
    opt(idx).Type  = [];

    % Lagrangian 2D w/o bulk motion
    idx = idx+1;
    opt(idx).Name  = 'lagrange2Dnobulk';
    opt(idx).Label = 'Lagrangian 2D (bulk corrected)';
    opt(idx).Fcn   = @(obj)vectorDisplay(obj,'lagrange','2D','unwrap',false);
    opt(idx).Type  = [];

    % xyz displacement
    idx = idx+1;
    opt(idx).Name  = 'cartdisp';
    opt(idx).Label = 'Cartesian Disp.';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'dX','dY','dZ'});
    opt(idx).Type  = [];

    % xyz displacement w/o bulk motion
    idx = idx+1;
    opt(idx).Name  = 'cartdisp';
    opt(idx).Label = 'Cartesian Disp. (bulk corrected)';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'dX','dY','dZ'},true);
    opt(idx).Type  = [];

    % R/C displacement w/o bulk motion
    idx = idx+1;
    opt(idx).Name  = 'cartdisp';
    opt(idx).Label = 'Polar Disp. (bulk corrected)';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'dR','dC'});
    opt(idx).Type  = {'SA'};

    % cardiac twist w/o bulk motion
    idx = idx+1;
    opt(idx).Name  = 'twist';
    opt(idx).Label = 'Cardiac Twist';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'twist'});
    opt(idx).Type  = {'SA'};

    % xy strain
    idx = idx+1;
    opt(idx).Name  = 'cartstrain';
    opt(idx).Label = 'Cartesian Strain';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'XX','YY'});
    opt(idx).Type  = {'curve','line','SA','LA'};

    % shear strain
    idx = idx+1;
    opt(idx).Name  = 'shearstrain';
    opt(idx).Label = 'Shear Strain';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'XY'});
    opt(idx).Type  = {'curve','line','SA','LA'};

    % principal strain
    idx = idx+1;
    opt(idx).Name  = 'prinstrain';
    opt(idx).Label = 'Principal Strain';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'p1','p2'});
    opt(idx).Type  = {'curve','line','SA','LA'};

    % polar strain
    idx = idx+1;
    opt(idx).Name  = 'polstrain';
    opt(idx).Label = 'Polar Strain';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'RR','CC'});
    opt(idx).Type  = {'SA','LA'};

    % contour strain
    idx = idx+1;
    opt(idx).Name  = 'contourstrain';
    opt(idx).Label = 'Contour Strain';
    opt(idx).Fcn   = @(obj)fvDisplay(obj,{'SS'});
    opt(idx).Type  = {'open','closed'};

    % principal strain/time curve
    idx = idx+1;
    opt(idx).Name  = 'prinstraintime';
    opt(idx).Label = 'Principal Strain/Time Curves';
    opt(idx).Fcn   = @(obj)timeDisplay(obj,{'p1','p2'});
    opt(idx).Type  = {'SA','LA'};

    % polar strain/time curve
    idx = idx+1;
    opt(idx).Name  = 'polstraintime';
    opt(idx).Label = 'Polar Strain/Time Curves';
    opt(idx).Fcn   = @(obj)timeDisplay(obj,{'RR','CC'});
    opt(idx).Type  = {'SA','LA'};

    % twist/time curve
    idx = idx+1;
    opt(idx).Name  = 'twisttime';
    opt(idx).Label = 'Twist/Time Curves';
    opt(idx).Fcn   = @(obj)timeDisplay(obj,{'twist'});
    opt(idx).Type  = {'SA'};

    % RURE/CURE curves
    idx = idx+1;
    opt(idx).Name  = 'curerure';
    opt(idx).Label = 'CURE/RURE Indices';
    opt(idx).Fcn   = @(obj)timeDisplay(obj,{'CURE','RURE'});
    opt(idx).Type  = {'SA'};

    % contour strain/time curve
    idx = idx+1;
    opt(idx).Name  = 'contourstraintime';
    opt(idx).Label = 'Contour Strain/Time Curves';
    opt(idx).Fcn   = @(obj)timeDisplay(obj,{'SS'});
    opt(idx).Type  = {'open','closed'};
end

%% CONSTRUCTOR
function obj = analysisViewerFcn(obj)

    % gather control options
    opt = controlOptions;

    % control panel underlying color
    hhier = hierarchy(obj.hcontrol,'figure');
    clr = [1 1 1];
    try
        for k = 1:numel(hhier)
            if ishghandle(hhier(k), 'figure')
                tag = 'Color';
            else
                tag = 'BackgroundColor';
            end
            tmpclr = get(hhier(k),tag);
            if iscolor(tmpclr),
                clr = tmpclr;
                break;
            end
        end
    catch
    end

    % create a button group
    obj.hbuttongroup = uibuttongroup(...
        'parent',               obj.hcontrol,...
        'bordertype',           'none',...
        'units',                'normalized',...
        'position',             [0 0 1 1],...
        'SelectionChangeFcn',   @(src,evnt)switchstate(obj,evnt),...
        'BackgroundColor',      clr);

    % populate button group with options
    fcn = @(tag,str)uicontrol(...
        'parent',           obj.hbuttongroup,...
        'style',            'radiobutton',...
        'tag',              tag,...
        'string',           str,...
        'BackgroundColor',  clr);

    hopt = cellfun(fcn,{opt.Name},{opt.Label}, 'UniformOutput', false);

    % save options to control structure
    [opt.Handle] = deal(hopt{:});

    % save options to object
    obj.options = opt;

    % cardiac model control button
    obj.hmodel = uicontrol(...
        'parent',           obj.hbuttongroup,...
        'style',            'pushbutton',...
        'string',           'Segment Model',...
        'BackgroundColor',  'w',...
        'Callback',         @(varargin)hmodelCallback(obj));

    % initialize empty API
    obj.api = obj.emptyapi;

    % test if SPL is empty
    if isempty(obj.hdata.spl)
        reset(obj);
    else
        loadspl(obj);
    end
end

function dataeventFcn(obj,evnt)

    switch lower(evnt.Action)
        case 'load'
            reset(obj);
        case 'new'
            if isequal(evnt.Field,'spl'), loadspl(obj); end
    end
end

function resetDispFcn(obj,optionsflag)

    if nargin < 2, optionsflag = true; end

    % stop the playbar
    obj.hlisten_playbar.Enabled = false;
    stop(obj.hplaybar);
    obj.hplaybar.Min = 1;
    obj.hplaybar.Max = 0;
    obj.hplaybar.Visible = 'off';

    % reset the current frame
%     obj.lastframe = [];

    % run the delete API
    if ~isempty(obj.api.deleteFcn)
        obj.api.deleteFcn();
    end

    % reset the API
    obj.api = obj.emptyapi;

    % disable all controls within the button group
    if optionsflag
        h = [obj.options.Handle];
        set(h(1),'Value',1);
        set(h,'enable','off');
        set(obj.hmodel,'enable','off');
        obj.lastframe = [];
    end

    % reset export rules
    obj.exportaxes = false;
    obj.exportrect = [];
    obj.isAllowExportImage = false;
    obj.isAllowExportVideo = false;
end

function loadsplFcn(obj)

    % reset the display
    resetDispFcn(obj,true);

    % remove strain data
    obj.straindata = [];
    obj.lastframe  = [];

    % enable controls based on DENSEType/ROIType
    checkfun = @(t)isempty(t) || any(strcmpi(obj.hdata.spl.ROIType,t));
    h  = [obj.options.Handle];
    tf = cellfun(checkfun,{obj.options.Type});

    set(h(~tf),'enable','off');
    set(h( tf),'enable','on');

    if checkfun({'la','sa','open','closed'});
        set(obj.hmodel,'enable','on');
    else
        set(obj.hmodel,'enable','off');
    end

    % locate the 1st enabled option
    tf = strcmpi(get(h,'enable'),'on');
    idx = find(tf,1,'first');
    if isempty(idx), return; end

    % simulate a "switchstate" event
    evnt = struct(...
        'EventName', 'SelectionChanged',...
        'OldValue',  [],...
        'NewValue',  obj.options(idx).Handle);
    set(h(idx),'value',1);

    if strcmpi(obj.Enable,'on')
        switchstate(obj,evnt);
    else
        obj.enableobject = h(idx);
    end
end

function switchstate(obj,evnt)

    % check for change of state
    if isequal(evnt.NewValue,evnt.OldValue)
        return;
    end

    % save current frame
    if ~isempty(obj.api.playbackFcn)
        obj.lastframe = obj.hplaybar.Value;
    end

    % reset (without changing option controls)
    resetDispFcn(obj,false);

    % locate current option
    tf = (evnt.NewValue == [obj.options.Handle]);
    idx = find(tf,1,'first');
    if isempty(idx), return; end

    % attempt to initialize the object
    try
        api = obj.options(idx).Fcn(obj);
        api.initFcn();
    catch ERR
        if exist('api','var') && isstruct(api) && ~isempty(api.deleteFcn)
            api.deleteFcn();
        end
        obj.api = obj.emptyapi;
        if ~isequal(ERR.identifier,'strain:cancel')
            rethrow(ERR);
        end
    end

    % save new display API to object
    obj.api = api;

    % control playbar visibility
    if isempty(api.playbackFcn)
        obj.hplaybar.Visible = 'off';
    else
        obj.hplaybar.Visible = 'on';
        if ~isempty(obj.lastframe)
            obj.hplaybar.Value = obj.lastframe;
        end
    end

    % update the display
    redraw(obj);

    % set export rules
    checkfun = @(t)isempty(t) || any(strcmpi(obj.hdata.spl.ROIType,t));
    obj.isAllowExportMat   = true;
    if checkfun({'sa','la','open','closed'});
        obj.isAllowExportExcel = true;
    else
        obj.isAllowExportExcel = false;
    end
end

function resizeCtrl(obj)

    panelpos = getpixelposition(obj.hbuttongroup);

    height = 20;
    margin = 5;

    p = [1+margin, panelpos(4)-margin, panelpos(3)-2*margin, height];
    for k = 1:numel(obj.options)
        p(2) = p(2)-height;
        setpixelposition([obj.options(k).Handle],p);
    end

    p = p + [15 -25 -30 0];
    setpixelposition(obj.hmodel,p);
end

function val = setEnableFcn(obj,val)

    % test for valid input
    if ~ischar(val) || ~any(strcmpi(val,{'on','off'}))
        error(sprintf('%s:invalidEnable',mfilename),...
            'Invalid Enable.');
    end

    % quit if value has not changed
    if isequal(obj.Enable,val)
        return;
    end

    % reset display, noting current handle
    if strcmpi(val,'off')
        obj.enableobject = get(obj.hbuttongroup,'SelectedObject');
        resetDispFcn(obj);

    % simulate a "switchstate" event
    else

        if isempty(obj.hdata.spl)
            resetDispFcn(obj)

        else
            % enable controls based on DENSEType/ROIType
            checkfun = @(t)isempty(t) || any(strcmpi(obj.hdata.spl.ROIType,t));
            h  = [obj.options.Handle];
            tf = cellfun(checkfun,{obj.options.Type});

            set(h(~tf),'enable','off');
            set(h( tf),'enable','on');

            if checkfun({'la','sa','open','closed'});
                set(obj.hmodel,'enable','on');
            else
                set(obj.hmodel,'enable','off');
            end

            set(obj.hbuttongroup,'SelectedObject',obj.enableobject);

            evnt = struct(...
                'EventName',    'SelectionChanged',...
                'OldValue',     [],...
                'NewValue',     obj.enableobject);
            switchstate(obj,evnt);
        end
        obj.enableobject = [];
    end
end

function hmodelCallback(obj)

    spl2strainFcn(obj);

    % simulate a "switchstate" event
    evnt = struct(...
        'EventName', 'SelectionChanged',...
        'OldValue',  [],...
        'NewValue',  get(obj.hbuttongroup,'SelectedObject'));
    switchstate(obj,evnt);
end

%% WRAPPED/UNWRAPPED DISPLAY

function api = phaseDisplay(obj)

    % persistant objects
    hax    = [];
    him    = [];
    htitle = [];

    % application data
    api.initFcn     = @initFcn;
    api.playbackFcn = @playbackFcn;
    api.deleteFcn   = @deleteFcn;
    api.resizeFcn   = @resizeFcn;

    function initFcn()

        % ensure image/video export includes visible axes
        obj.exportaxes = true;

        % image size
        Isz = size(obj.hdata.spl.Xunwrap(:,:,1));

        % clim
        xmx = max(abs(obj.hdata.spl.Xunwrap(:)));
        ymx = max(abs(obj.hdata.spl.Yunwrap(:)));
        zmx = max(abs(obj.hdata.spl.Zunwrap(:)));
        mx  = ceil(max([xmx,ymx,zmx])/pi) * pi;

        clim = {[-pi pi]; [-mx mx]};
        clim = [clim;clim;clim];

        % create objects
        titles = {'X WRAPPED','X UNWRAPPED',...
                  'Y WRAPPED','Y UNWRAPPED',...
                  'Z WRAPPED','Z UNWRAPPED'};

        % create object hierarchy
        for n = 1:6
            hax = cat(1, hax, axes('parent',obj.hdisplay));
            him = cat(1, him, imshow(rand(Isz),'parent',hax(n)));
            htitle = cat(1, htitle, textfig(obj.hdisplay));
        end

        % set properties
        set(hax(:),...
            'color',        [.5 .5 .5],...
            {'clim'},       clim,...
            'box',          'on',...
            'visible',      'on',...
            'xtick',        [],...
            'ytick',        [],...
            'xcolor',       obj.dispclr(1,:),...
            'ycolor',       obj.dispclr(1,:),...
            'XLimMode',             'manual',...
            'YLimMode',             'manual',...
            'DataAspectRatioMode',  'manual',...
            'TickLength',   [0 0]);

        set(him,...
            'Visible',      'on',...
            'HitTest',      'off');

        set(htitle(:),...
            {'string'},             titles(:),...
            'horizontalalignment',  'left',...
            'verticalalignment',    'bottom',...
            'color',                obj.dispclr(1,:),...
            'fontweight',           'bold',...
            'rotation',             90,...
            'units',                'pixels',...
            'fontsize',             12);

        % link axes
        hlink = linkprop(hax,{'XLim','YLim','DataAspectRatio'});
        setappdata(hax(1),'graphics_linkaxes',hlink);

        % disable rotation/contrast
        hrot = rotate3d(obj.hfigure_display);
        hrot.setAllowAxesRotate(hax,false);
        obj.hcontrast.setAllowAxes(hax,false);

        % disable empty axes
        valid = obj.hdata.spl.XYZValid;
        h = reshape(hax(:),[2 3]);
        set(h(:,~valid),'HitTest','off','HandleVisibility','off')

        % set base zoom level
        arrayfun(@(h)zoom(h,'reset'),hax);

        % zoom to spline range
        xrng = obj.hdata.spl.jrng;
        yrng = obj.hdata.spl.irng;
        rng = [floor(xrng(1)),ceil(xrng(2)),floor(yrng(1)),ceil(yrng(2))];
        axis(hax(1),rng + [-0.5 0.5 -0.5 0.5]);

        % update the playbar
        obj.hplaybar.Min = obj.hdata.spl.frrng(1);
        obj.hplaybar.Max = obj.hdata.spl.frrng(2);
        obj.hplaybar.Enable = 'on';

        % run the playback once
        playbackFcn();
        obj.hlisten_playbar.Enabled = true;

        % reset export rules
        obj.isAllowExportImage = true;
        if (obj.hplaybar.Max-obj.hplaybar.Min) > 1
            obj.isAllowExportVideo = true;
        end
    end

    function resizeFcn()

        % display variables (all in pixels)
        minwh = [400 300];  % minimum allowable panel size
        vert  = [10 10 50]; % internal axes vertical spacing (top/mid/bot)
        horz  = [30 30 10]; % internal horizontal spacing    (lft/mid/rgt)

        % get the current panel margin
        % determine available display position
        pos = getpixelposition(obj.hdisplay);
        pos = [pos(1:2),max(pos(3:4),minwh)];

        % axes width/height
        width  = (pos(3)- 1 - (horz * [1 2 1]')) / 3;
        height = (pos(4) - (vert * [1 1 1]')) / 2;

        % axes a/y position
        x = 1 + horz(1) + [0 1 2]*horz(2) + [0 1 2]*width;
        y = 1 + vert(3) + [1 0]*vert(2) + [1 0]*height;
        [X,Y] = meshgrid(round(x),round(y));
        pax = [X(:),Y(:),ones(6,1)*[width height]];

        % place axes & title within the panel
        for k = 1:6
            setpixelposition(hax(k),pax(k,:));
            p = plotboxpos(hax(k));
            set(htitle(k),'units','pixels','position',p(1:2)+[-1,0]);
        end

        % export rect
        obj.exportrect = getpixelposition(obj.hdisplay,true)...
                + [0 45 0 -45];
    end

    function playbackFcn()
        fr = obj.hplaybar.Value;
        tags = {'Xwrap','Xunwrap','Ywrap','Yunwrap','Zwrap','Zunwrap'};

        for ti = 1:numel(tags)
            I = obj.hdata.spl.(tags{ti})(:,:,fr);
            I(isnan(I)) = 0;
            set(him(ti),'cdata',I);
        end
    end

    function deleteFcn()
        h = [hax(:); htitle(:)];
        delete(h(ishandle(h)));
    end
end

%% 2D EULARIAN VECTOR DISPLAY

function api = vectorDisplay(obj,mode,dim,tag,bulk)

    % check tag/dim
    errid = sprintf('%s:invalidInput',mfilename);
    if ~ischar(mode) || ~any(strcmpi(mode,{'euler','lagrange'}))
        warning(errid,'Unrecognized mode - reset to ''euler''.');
        tag = 'euler';
    elseif ~ischar(dim) || ~any(strcmpi(dim,{'2D','3D'}))
        warning(errid,'Unrecognized dim - reset to ''2D''.');
        dim = '2d';
    elseif ~ischar(tag) || ~any(strcmpi(tag,{'wrap','unwrap'}))
        warning(errid,'Unrecognized tag - reset to ''unwrap''.');
        tag = 'unwrap';
    elseif ~islogical(bulk)
        warning(errid,'Unrecognized bulk - reset to ''true''.');
        bulk = true;
    end

    % we require the "zbuffer" or "opengl" renderer, so temporarily
    % update the display figure
    renderer = get(obj.hfigure_display,'Renderer');
    set(obj.hfigure_display,'Renderer','zbuffer');

    % persistant objects
    hax  = NaN;
    him  = NaN;
    hvec = NaN;
    hpts = NaN;

    X = []; Y = []; Z = [];
    faces = []; changemask = [];
    mask0 = [];

    % gather field names
    xtag = ['X' tag];
    ytag = ['Y' tag];
    ztag = ['Z' tag];

    % application data
    api.initFcn     = @initFcn;
    api.playbackFcn = @playbackFcn;
    api.deleteFcn   = @deleteFcn;
    api.resizeFcn   = @resizeFcn;

    function initFcn()

        axesclr = [0 0 0];
        lineclr = [1 1 0];

        % image size
        Isz = size(obj.hdata.spl.(xtag)(:,:,1));
        Nfr = size(obj.hdata.spl.(xtag),3);

        % image space
        x = 1:Isz(2);
        y = 1:Isz(1);
        [X,Y,Z] = meshgrid(x,y,0);

        % faces & FaceVertexCData values
        N = numel(X);
        faces = reshape(1:2*N,[N,2]);
        fvcd  = ones(N,1)*lineclr;

        % determine any pixel where the value NEVER changes...
        xtmp = all(obj.hdata.spl.(xtag)(:,:,ones(Nfr,1)) == ...
                   obj.hdata.spl.(xtag),3);
        ytmp = all(obj.hdata.spl.(ytag)(:,:,ones(Nfr,1)) == ...
                   obj.hdata.spl.(ytag),3);
        changemask = ~xtmp & ~ytmp;

        % zero-mask for Lagrangian display
        mask0 = obj.hdata.spl.MaskFcn(X,Y,obj.hdata.spl.RestingContour);

        % create objects
        hax  = axes('parent',obj.hdisplay);
        him  = imshow(rand(Isz),[0 1],'init','fit','parent',hax);
        hvec = patch('parent',hax);
        hpts = patch('parent',hax);

        % set properties
        set(hax(:),...
            'color',        axesclr,...
            'box',          'on',...
            'visible',      'on',...
            'xtick',        [],...
            'ytick',        [],...
            'ztick',        [],...
            'xcolor',       obj.dispclr(1,:),...
            'ycolor',       obj.dispclr(1,:),...
            'zcolor',       obj.dispclr(1,:),...
            'XLimMode',             'manual',...
            'YLimMode',             'manual',...
            'ZLimMode',             'manual',...
            'Zdir',                 'reverse',...
            'DataAspectRatioMode',  'manual',...
            'TickLength',   [0 0]);

        set(him,...
            'Visible',      'on',...
            'HitTest',      'off');

        set(hvec,...
            'FaceColor',        'none',...
            'EdgeColor',        'flat',...
            'markeredgecolor',  'flat',...
            'markerfacecolor',  'flat',...
            'FaceVertexCData',  [fvcd; NaN(size(fvcd))],...
            'marker',           'none',...
            'markersize',       3);

        set(hpts,...
            'FaceColor',        'none',...
            'EdgeColor',        'none',...
            'markeredgecolor',  'flat',...
            'markerfacecolor',  'flat',...
            'FaceVertexCData',  fvcd,...
            'marker',           's',...
            'markersize',       3);

        % z-display
        mx = max(abs(obj.hdata.spl.(ztag)(:)));

        % display range
        xrng = obj.hdata.spl.jrng;
        yrng = obj.hdata.spl.irng;
        zrng = [min(-10,floor(-mx-2)),max(10,ceil(mx+2))];
        rng = [floor(xrng(1)),ceil(xrng(2)),...
               floor(yrng(1)),ceil(yrng(2)),...
               zrng];

        % set base zoom level, zoom into area of interest
        zoom(hax,'reset');
        axis(hax,rng + [-0.5 0.5 -0.5 0.5 -0.5 0.5]);

        if strcmpi(dim,'2d')

            % 2D view
            view(hax,2);

            % disable rotation
            hrot = rotate3d(obj.hfigure_display);
            hrot.setAllowAxesRotate(hax,false);

        else
            % reset zoom level
            zoom(hax,'reset')

            % 3D view
            view(hax,3);
            axis(hax,'vis3d');

            % disable zoom/rot
            hzoom = zoom(obj.hfigure_display);
            hpan  = pan(obj.hfigure_display);
            hzoom.setAllowAxesZoom(hax,false);
            hpan.setAllowAxesPan(hax,false);

            % hide image
            set(him,'visible','off')

            % ensure axes are exported
            obj.exportaxes = true;

            % remove lines
            set(hvec,'linestyle','none');
        end

        % disable image for bulk motion removal
        if ~bulk
            set(him,'visible','off');
        end

        % update the playbar
        obj.hplaybar.Min    = obj.hdata.spl.frrng(1);
        obj.hplaybar.Max    = obj.hdata.spl.frrng(2);
        obj.hplaybar.Enable = 'on';

        % run the playback once
        playbackFcn();
        obj.hlisten_playbar.Enabled = true;

        % update export rules
        obj.isAllowExportImage = true;
        if (obj.hplaybar.Max-obj.hplaybar.Min) > 1
            obj.isAllowExportVideo = true;
        end
    end

    function resizeFcn()
        resizeAxes(obj,hax,dim);
    end

    function playbackFcn()
        fr = obj.hplaybar.Value;
        Isz = size(X);

        set(him,'cdata',obj.hdata.spl.Mag(:,:,fr));

        % EULARIAN
        if isequal(mode,'euler')
            xfac = obj.hdata.spl.Multipliers(1);
            yfac = obj.hdata.spl.Multipliers(2);
            zfac = obj.hdata.spl.Multipliers(3);

            X0 = X - obj.hdata.spl.(xtag)(:,:,fr)*xfac;
            Y0 = Y - obj.hdata.spl.(ytag)(:,:,fr)*yfac;
            Z1 = Z + obj.hdata.spl.(ztag)(:,:,fr)*zfac;

            v0 = [X0(:),Y0(:),Z(:)];
            v1 = [X(:),Y(:),Z1(:)];
            mask = ~isnan(X0) & ~isnan(Y0) & changemask;
            newfaces = faces(mask(:),:);

        % LAGRANGIAN
        else
            v0 = [X(:),Y(:),Z(:)];

            dx = zeros(Isz);
            dy = zeros(Isz);
            dz = zeros(Isz);

            pts = [Y(:),X(:),fr*ones(size(X(:)))]';
            dx(mask0) = fnvalmod(obj.hdata.spl.spldx,pts(:,mask0));
            dy(mask0) = fnvalmod(obj.hdata.spl.spldy,pts(:,mask0));
            dz(mask0) = fnvalmod(obj.hdata.spl.spldz,pts(:,mask0));

            % bulk motion removal
            if ~bulk
                dxbulk = mean(dx(mask0));
                dybulk = mean(dy(mask0));
                dzbulk = mean(dz(mask0));
                dx = dx - dxbulk;
                dy = dy - dybulk;
                dz = dz - dzbulk;
            end

            v1 = v0 + [dx(:),dy(:),dz(:)];
            newfaces = faces(mask0,:);
        end

        set(hvec,'vertices',[v0;v1],'faces',newfaces);
        set(hpts,'vertices',v1,'faces',newfaces(:,1));
    end

    function deleteFcn()

        h = hax;
        delete(h(ishandle(h)));

        if ishandle(obj.hfigure_display)
            set(obj.hfigure_display,'renderer',renderer);
        end
    end
end

%% VALUE VERSUS TIME DISPLAY
function api = timeDisplay(obj,names)

    allnames = {'XX','YY','p1','p2','RR','CC','RURE','CURE','twist','SS'};
    alltags  = {'XX','YY','p1','p2','RR','CC','RR','CC','twist','SS'};
    alltitles = {'Horizontal Strain','Vertical Strain',...
        '1st Principal Strain','2nd Principal Strain',...
        'Radial Strain','Circumferential Strain',...
        'RURE Index','CURE Index','Twist Angle (degrees)',...
        'Contour Strain'};

    if strcmpi(obj.hdata.spl.ROIType,'LA')
        alltitles{6} = 'Longitudinal Strain';
    end

    flag_contour = any(strcmpi(obj.hdata.spl.ROIType,{'open','closed'}));

    % title strings
    tags = cell(size(names));
    ttls = cell(size(names));
    for ti = 1:numel(names)
        tf = strcmpi(names{ti},allnames);
        tags{ti} = alltags{tf};
        ttls{ti} = alltitles{tf};
    end

    % persistant variables
    haxseg = preAllocateGraphicsObjects(1);
    hcbseg = preAllocateGraphicsObjects(1);
    hax = preAllocateGraphicsObjects(size(names));

    % we require the "zbuffer" or "opengl" renderer, so temporarily
    % update the display figure
    renderer = get(obj.hfigure_display,'Renderer');
    set(obj.hfigure_display,'Renderer','zbuffer');

    % application data
    api.initFcn     = @initFcn;
    api.playbackFcn = [];
    api.deleteFcn   = @deleteFcn;
    api.resizeFcn   = @resizeFcn;

    function initFcn()

        % ensure image/video export includes visible axes
        obj.exportaxes = true;

        % determine strain object
        if isempty(obj.straindata)
            spl2strainFcn(obj);
            if isempty(obj.straindata)
                error('strain:cancel','cancel message');
            end
        end

        % associated limits
        limits = cell(size(names));
        for k = 1:numel(names)
            if any(strcmpi(names{k},{'RURE','CURE'}))
                limits{k} = [0 1.05];
            else
                clrtag = [tags{k} 'rng'];
                limits{k} = obj.strainopts.(clrtag);
            end
            limits{k} = limits{k} + [-eps eps];
        end

        % create axes objects
        haxseg = axes('parent',obj.hdisplay);
        for k = 1:numel(names)
            hax(k) = axes('parent',obj.hdisplay);
        end

        % common axes initialization
        set([haxseg;hax(:)],...
            'color',        'none',...
            'box',          'on',...
            'visible',      'on',...
            'xcolor',       obj.dispclr(1,:),...
            'ycolor',       obj.dispclr(1,:),...
            'hittest',      'off',...
            'handlevisibility','off');

        % set properties
        Nfr = size(obj.hdata.spl.Mag,3);
        frrng = obj.hdata.spl.frrng;
        set(hax(:),...
            'xlim',         frrng(:) + [-1;1],...
            {'ylim'},       limits(:));

        set(haxseg,...
            'DataAspectRatio', [1 1 1],...
            'xtick',    [],...
            'ytick',    [],...
            'TickLength',   [0 0],...
            'Ydir',         'reverse');

        htmp(1) = title(haxseg,'Segments');
        htmp(2) = xlabel(hax(end),'Frame Number');
        for k = 1:numel(hax)
            htmp = cat(2, htmp, ylabel(hax(k),ttls{k}));
        end

        set(htmp(:),...
            'color',obj.dispclr(1,:),...
            'fontweight','bold',...
            'fontsize',12);
        set(hax(1:end-1),'xticklabel',[]);

        % zoom segment image to spline range
        xrng = obj.hdata.spl.jrng;
        yrng = obj.hdata.spl.irng;
        rng = [floor(xrng(1)),ceil(xrng(2)),floor(yrng(1)),ceil(yrng(2))];
        axis(haxseg,rng + [-0.5 0.5 -0.5 0.5]);

        % vertices & faces
        vert = obj.straindata.fv.vertices;
        face = obj.straindata.fv.faces;

        % separate contour faces for patch display
        if flag_contour
            faceindex = face';
            vert = vert(faceindex,:);
            face = reshape(1:numel(faceindex),size(faceindex))';
            fvcdindex = faceindex([1 1],:);
            fvcdindex = fvcdindex(:);
        else
            fvcdindex = (1:size(face,1))';
        end

        % patch options
        if flag_contour
            patchopts = struct(...
                'edgecolor','flat',...
                'facecolor','none',...
                'linewidth',4);
            Nseg = max(obj.straindata.fv.sectorid);
        else
            patchopts = struct(...
                'edgecolor','none',...
                'facecolor','flat');
            Nseg = obj.straindata.Nseg;
        end

        % segment patch
        id = obj.straindata.fv.sectorid;
        clrs = hsv(Nseg);
        fvcd = clrs(id,:);

        patch('parent',             haxseg,...
              patchopts, ...
              'vertices',           vert,...
              'faces',              face,...
              'facevertexcdata',    fvcd(fvcdindex,:));

        % segment colorbar
        hcbseg = colorbarmod(haxseg,'southoutside',clrs,[0.5 Nseg+0.5]);

        set(hcbseg,'xcolor',obj.dispclr(1,:),'ycolor',obj.dispclr(1,:),...
            'hittest','off','handlevisibility','off');

        set(hax(:),'Colororder',clrs);

        % display value/time per segment
        for k = 1:numel(names)
            data = NaN(Nfr,Nseg);
            for fr = frrng(1):frrng(2)
                strain = obj.straindata.strain.(tags{k})(:,fr);
                for si = 1:Nseg
                   data(fr,si) = mean(strain(id==si,:));
                end
            end

            if any(strcmpi(names{k},{'CURE','RURE'}))
                tmp = data(frrng(1):frrng(2),:);
                data = NaN(Nfr,1);
                data(frrng(1):frrng(2)) = CURE(tmp);
            end

            hold(hax(k),'on')
            plot(hax(k),1:Nfr,data)
            hold(hax(k),'off')
        end

        % update export rules
        obj.exportaxes = true;
        obj.isAllowExportImage = true;
        obj.isAllowExportVideo = false;
    end

    function resizeFcn()

        % display variables (all in pixels)
        minwh  = [400 200];   % minimum allowable panel size
        horz   = [10 80 10];  % internal horizontal spacing (lft/mid/rgt)
        width1 = 150;   % fixed width factor

        % internal vertical spacing    (top/mid/bot)
        vert = [10, 20*ones(numel(names)-1,1), 60];

        % determine available display position
        pos = getpixelposition(obj.hdisplay);
        pos = [pos(1:2),max(pos(3:4),minwh)];

        % cardiac segment axes
        height = pos(4) - sum(vert([1 end]));
        posseg = [horz(1) vert(end) width1 height];
        setpixelposition(haxseg,posseg);

        % remaining display position
        shft = width1 + sum(horz(1:2));
        pos(1) = pos(1) + shft;
        pos(3) = pos(3) - shft;

        % axes position
        width  = pos(3) - horz(end);
        height = (pos(4) - sum(vert)) / numel(names);

        x = pos(1);
        y = 1 + cumsum(vert(end:-1:2)) + (0:numel(names)-1)*height;
        y = y(end:-1:1);
        for k = 1:numel(names)
            setpixelposition(hax(k),[x y(k) width height])
        end

        % export rect
        obj.exportrect = getpixelposition(obj.hdisplay,true);
    end

    function deleteFcn()
        h = [hcbseg;haxseg;hax(:)];
        delete(h(ishandle(h)));

        if ishandle(obj.hfigure_display)
            set(obj.hfigure_display,'renderer',renderer);
        end
    end
end

%% FACE/VERTEX DISPLAY (STRAIN/TWIST)
function api = fvDisplay(obj,tag,flag_nobulk)
    if nargin<3, flag_nobulk = false; end

    tags = {'XX',       'Horizontal Strain';
            'YY',       'Vertical Strain';
            'XY',       'Shear Strain';
            'YX',       'Shear Strain';
            'p1',       '1st Principal Strain';
            'p2',       '2nd Principal Strain';
            'RR',       'Radial Strain';
            'CC',       'Circumferential Strain';
            'dX',       'Horizontal Disp. (pix)';
            'dY',       'Vertical Disp. (pix)';
            'dZ',       'Slice Disp. (pix)';
            'dR',       'Radial Disp. (pix)';
            'dC',       'Circumferential Disp. (pix)';
            'SS',       'Contour Strain';
            'twist',    'Cardiac Twist (degrees)'};

    if strcmpi(obj.hdata.spl.ROIType,'LA')
        tags(:,2) = regexprep(tags(:,2),'Circumferential','Longitudinal');
    end

    % locate names
    name = cell(size(tag));
    for ti = 1:numel(tag)
        name{ti} = tags{strcmpi(tag{ti},tags(:,1)),2};
    end

    % we require the "zbuffer" or "opengl" renderer, so temporarily
    % update the display figure
    renderer = get(obj.hfigure_display,'Renderer');
    set(obj.hfigure_display,'Renderer','zbuffer');

    % persistant variables
    hax = preAllocateGraphicsObjects(size(tag));
    hcb = hax;
    hfv = hax;
    hor = hax;
    htitle = hax;

    % face centroids
    pface = [];

    % display tags
    fvtag = [];
    sttag = [];

    % colormap
    cmap = [];
    crng = cell(size(tag));

    % strain index for fvcd display
    fvcdindex = [];

    % application data
    api.initFcn     = @initFcn;
    api.playbackFcn = @playbackFcn;
    api.deleteFcn   = @deleteFcn;
    api.resizeFcn   = @resizeFcn;

    function initFcn()

        % ensure image/video export includes visible axes
        obj.exportaxes = true;

        % test for contour
        flag_contour = any(strcmpi(...
            obj.hdata.spl.ROIType,{'open','closed'}));

        % determine strain object
        if isempty(obj.straindata)
            spl2strainFcn(obj);
            if isempty(obj.straindata)
                error('strain:cancel','cancel message');
            end
        end

        % pixelate strings
        if obj.strainopts.Pixelate && ~flag_contour
            fvtag = 'fvpix';
            sttag = 'strainpix';
        else
            fvtag = 'fv';
            sttag = 'strain';
        end

        % vertices & faces
        vert = obj.straindata.(fvtag).vertices;
        face = obj.straindata.(fvtag).faces;

        % separate contour faces for patch display
        if flag_contour
            faceindex = face';
            vert = vert(faceindex,:);
            face = reshape(1:numel(faceindex),size(faceindex))';
            fvcdindex = faceindex([1 1],:);
            fvcdindex = fvcdindex(:);
        else
            fvcdindex = (1:size(face,1))';
        end

        % number of faces
        Nface = size(face,1);

        % face centroids (average of face vertices)
        pface = NaN(Nface,2);
        for k = 1:2
            tmp = vert(:,k);
            tmp = tmp(face);
            pface(:,k) = mean(tmp,2);
        end

        % colormap
        cmap = eval([lower(obj.strainopts.Colormap) '(256)']);

        % color ranges
        for k = 1:numel(tag)
            clrtag = [tag{k} 'rng'];
            if isfield(obj.strainopts,clrtag)
                crng{k} = obj.strainopts.(clrtag);
            elseif any(strwcmpi(tag{k},{'dY','dZ'}))
                crng{k} = obj.strainopts.dXrng;
            else
                crng{k} = [-0.5 0.5];
            end
        end

        % patch options
        if flag_contour
            patchopts = struct(...
                'edgecolor','flat',...
                'facecolor','none',...
                'linewidth',4);
        else
            patchopts = struct(...
                'edgecolor','none',...
                'facecolor','flat');
        end

        % create objects
        for k = 1:numel(tag)
            hax(k) = axes('parent',obj.hdisplay);
            hcb(k) = colorbarmod(hax(k),'southoutside',cmap,crng{k});
            hfv(k) = patch('parent',hax(k));
            hor(k) = patch('parent',hax(k));
            htitle(k) = title(hax(k),name{k});
        end

        % set properties
        set(hax(:),...
            'color',        'none',...
            'box',          'on',...
            'visible',      'on',...
            'xtick',        [],...
            'ytick',        [],...
            'xcolor',       obj.dispclr(1,:),...
            'ycolor',       obj.dispclr(1,:),...
            'XLimMode',     'manual',...
            'YLimMode',     'manual',...
            'Ydir',         'reverse',...
            'DataAspectRatioMode',  'manual',...
            'TickLength',   [0 0]);

        set(htitle(:),...
            'FontSize',12,...
            'Color',obj.dispclr(1,:),...
            'FontWeight','bold');

        set(hfv(:),patchopts,...
            'vertices',         vert,...
            'faces',            face,...
            'facevertexcdata',  zeros(numel(fvcdindex),3),...
            'cdatamapping',     'direct');

        set(hcb(:),...
            'xcolor', obj.dispclr(1,:),...
            'ycolor', obj.dispclr(1,:));

        % orientation bars
        v = NaN(2*size(pface,1),2);
        f = reshape(1:2*size(pface,1),[size(pface,1),2]);
        for k = 1:numel(tag)
            if obj.strainopts.Marker && ...
               any(strcmpi(tag{k},{'RR','CC','p1','p2'}))
                set(hor(k),...
                    'vertices', v,...
                    'faces',    f,...
                    'edgecolor',[0 0 0],...
                    'facecolor','none');
            else
                set(hor(k),'visible','off');
            end
        end

        % link axes
        if numel(tag) > 1
            hlink = linkprop(hax,{'XLim','YLim','DataAspectRatio'});
            setappdata(hax(1),'graphics_linkaxes',hlink);
        end

        % disable rotation
        hrot = rotate3d(obj.hfigure_display);
        hrot.setAllowAxesRotate(hax,false);

        % disable contrast
        obj.hcontrast.setAllowAxes(hax(:),false);

        % zoom to spline range
        xrng = obj.hdata.spl.jrng;
        yrng = obj.hdata.spl.irng;
        rng = [floor(xrng(1)),ceil(xrng(2)),floor(yrng(1)),ceil(yrng(2))];
        axis(hax(1),rng + [-0.5 0.5 -0.5 0.5]);

        % set base zoom level
        arrayfun(@(h)zoom(h,'reset'),hax);

        % update the playbar
        obj.hplaybar.Min = obj.hdata.spl.frrng(1);
        obj.hplaybar.Max = obj.hdata.spl.frrng(2);
        obj.hplaybar.Enable = 'on';

        % run the playback once
        playbackFcn();
        obj.hlisten_playbar.Enabled = true;

        % update export rules
        obj.isAllowExportImage = true;
        if (obj.hplaybar.Max-obj.hplaybar.Min) > 1
            obj.isAllowExportVideo = true;
        end
    end

    function resizeFcn()

        % display variables (all in pixels)
        minwh = [400 300];  % minimum allowable panel size
        vert  = [40 120];   % internal axes vertical spacing (top/bot)

        % internal horizontal spacing    (lft/mid/rgt)
        horz = [30, 30*ones(1,numel(tag)-1), 30];

        % determine available display position
        pos = getpixelposition(obj.hdisplay);
        pos = [pos(1:2),max(pos(3:4),minwh)];

        % axes position
        width  = (pos(3) - sum(horz)) / numel(tag);
        height = pos(4) - sum(vert);
        x = 1 + cumsum(horz(1:end-1)) + (0:numel(tag)-1)*width;
        y = 1 + vert(2);
        for k = 1:numel(tag)
            setpixelposition(hax(k),[x(k) y width height])
        end

        % export rect
        obj.exportrect = getpixelposition(obj.hdisplay,true)...
                + [0 45 0 -45];
    end

    function playbackFcn()
        fr = obj.hplaybar.Value;
        r = 0.25;

        for k = 1:numel(tag)

            val = obj.straindata.(sttag).(tag{k})(:,fr);
            if flag_nobulk && any(strcmpi(tag{k},{'dX','dY','dZ'}))
                val = bsxfun(@minus,val,mean(val,1));
            end

            fvcd = straincolorFcn(val,cmap,crng{k});
            set(hfv(k),'facevertexcdata',fvcd(fvcdindex,:));

            switch lower(tag{k})
                case 'rr', or = obj.straindata.(fvtag).orientation;
                case 'cc', or = obj.straindata.(fvtag).orientation + pi/2;
                case 'p1', or = obj.straindata.(sttag).p1or(:,fr);
                case 'p2', or = obj.straindata.(sttag).p1or(:,fr) + pi/2;
                otherwise, continue;
            end
            dX = r*cos(or);
            dY = r*sin(or);
            v  = [pface - 0.5*[dX(:),dY(:)];...
                  pface + 0.5*[dX(:),dY(:)]];
            set(hor(k),'vertices',v,'LineWidth',2);
        end
    end

    function deleteFcn()
        h = [hcb(:); hax(:)];
        delete(h(ishandle(h)));
        if ishandle(obj.hfigure_display)
            set(obj.hfigure_display,'renderer',renderer);
        end
    end
end

%% EXPORT MAT FILE
% MAT file contains images and recovered displacement data, with some
% information on the image source and analysis options
function [file, out] = exportMatFcn(obj,startpath)

    % check for startpath
    if nargin < 2 || isempty(startpath)
        startpath = pwd;
    end

    if ~exist(startpath, 'dir')
        [origstartpath,~,ext] = fileparts(startpath);
        file = startpath;
        startpath = origstartpath;
        if isempty(ext)
            % If there is no extension then MATLAB save will add
            % '.mat'. This will allow us to return the correct
            % filename to the user.
            file = [file '.mat'];
        end
    end

    % DENSE & ROI indices
    duid = obj.hdata.spl.DENSEUID;
    didx = obj.hdata.UIDtoIndexDENSE(duid);

    ruid = obj.hdata.spl.ROIUID;
    ridx = obj.hdata.UIDtoIndexROI(ruid);

    % If the startpath is not a mat file then make one
    if ~exist('file', 'var')
        % file name
        header = sprintf('%s_%s',...
                         obj.hdata.dns(didx).Name,...
                         obj.hdata.roi(ridx).Name);

        expr = '[\\\/\?\%\:\*\"\<\>\|]';
        header = regexprep(header,expr,'_');

        file = fullfile(startpath,[header '.mat']);
        cnt = 0;
        while isfile(file)
            cnt = cnt+1;
            file = fullfile(startpath,sprintf('%s (%d).mat',header,cnt));
        end

        % allow user to change file name
        [uifile,uipath] = uiputfile('*.mat',[],file);
        if isequal(uifile,0)
            file = [];
            return;
        end

        % check extension
        file = fullfile(uipath,uifile);
        [~,~,e] = fileparts(file);
        if ~isequal(e,'.mat')
            file = [file, '.mat'];
        end
    end

    % determine strain object
    if isempty(obj.straindata)
        spl2strainFcn(obj);
        if isempty(obj.straindata)
            file = [];
            return;
        end
    end

    % start waitbartimer
    hwait = waitbartimer;
    cleanupObj = onCleanup(@()delete(hwait(isvalid(hwait))));
    hwait.String = 'Saving MAT file...';
    hwait.WindowStyle = 'modal';
    hwait.AllowClose  = false;
    start(hwait);
    drawnow

    % magnitude/phase indices
    midx = obj.hdata.dns(didx).MagIndex;
    pidx = obj.hdata.dns(didx).PhaIndex;
    sidx = [midx; pidx];

    % image information
    tags = {'DENSEType','Multipliers','Mag'};
    tfsingle = logical([0 0 0]);
    if ~isnan(pidx(1))
        tags = cat(2,tags,{'Xwrap','Xunwrap'});
        tfsingle = [tfsingle, true, true];
    end
    if ~isnan(pidx(2))
        tags = cat(2,tags,{'Ywrap','Yunwrap'});
        tfsingle = [tfsingle, true, true];
    end
    if ~isnan(pidx(3))
        tags = cat(2,tags,{'Zwrap','Zunwrap'});
        tfsingle = [tfsingle, true, true];
    end

    ImageInfo = struct;
    for ti = 1:numel(tags)
        tag = tags{ti};
        if tfsingle(ti)
            ImageInfo.(tag) = single(obj.hdata.spl.(tag));
        else
            ImageInfo.(tag) = obj.hdata.spl.(tag);
        end
    end

    % ROI information
    tags = {'ROIType','RestingContour','Contour'};
    ROIInfo = struct;
    for ti = 1:numel(tags)
        ROIInfo.(tags{ti}) = obj.hdata.spl.(tags{ti});
    end

    % analysis information
    tags = {'ResampleMethod','ResampleDistance','SpatialSmoothing',...
        'TemporalOrder','Xseed','Yseed','Zseed'};
    AnalysisInfo = struct;
    for ti = 1:numel(tags)
        AnalysisInfo.(tags{ti}) = obj.hdata.spl.(tags{ti});
    end

    % frame range analyized
    frrng  = obj.hdata.spl.frrng;
    frames = frrng(1):frrng(2);
    AnalysisInfo.FramesForAnalysis = frrng;

    % segment model & orientation
    if any(strcmpi(obj.hdata.spl.ROIType,{'sa','la'}))
        AnalysisInfo.Nmodel    = obj.straindata.Nmodel;
        AnalysisInfo.PositionA = obj.straindata.PositionA;
        AnalysisInfo.PositionB = obj.straindata.PositionB;
        AnalysisInfo.Clockwise = obj.straindata.Clockwise;
    end

    % DENSE group information
    DENSEInfo = obj.hdata.dns(didx);

    % original sequence header information
    SequenceInfo = repmat(struct,[2 3]);
    for k = 1:6
        if ~isnan(sidx(k))
            tags = fieldnames(obj.hdata.seq(sidx(k)));
            for ti = 1:numel(tags)
                tag = tags{ti};
                SequenceInfo(k).(tag) = ...
                    obj.hdata.seq(sidx(k)).(tag);
            end
        end
    end

    % Displacement Info
    Isz = size(obj.hdata.spl.Xwrap(:,:,1));
    Nfr = size(obj.hdata.spl.Xwrap,3);

    x = 1:Isz(2);
    y = 1:Isz(1);
    [X,Y] = meshgrid(x,y,0);

    mask0 = obj.hdata.spl.MaskFcn(...
        X,Y,obj.hdata.spl.RestingContour);
    Npts = sum(mask0(:));

    DisplacementInfo = struct(...
        'X',    X(mask0),...
        'Y',    Y(mask0),...
        'dX',   NaN([Npts,Nfr]),...
        'dY',   NaN([Npts,Nfr]),...
        'dZ',   NaN([Npts,Nfr]));

    pts = [Y(:),X(:),zeros(size(X(:)))];
    pts = pts(mask0,:)';

    for fr = frames
        pts(3,:) = fr;
        DisplacementInfo.dX(:,fr) = fnvalmod(obj.hdata.spl.spldx,pts);
        DisplacementInfo.dY(:,fr) = fnvalmod(obj.hdata.spl.spldy,pts);
        DisplacementInfo.dZ(:,fr) = fnvalmod(obj.hdata.spl.spldz,pts);
    end

    % short-axis angle
    % for 6-segment model, [0,60)=anterior, [60,120)=anteroseptal, etc.
    % for 4-segment model, [0,90)=anterior, [90 180)=septal, etc.
    if strcmpi(obj.hdata.spl.ROIType,'sa')
        origin  = obj.straindata.PositionA;
        posB    = obj.straindata.PositionB;
        flag_clockwise = obj.straindata.Clockwise;

        theta0 = atan2(posB(2)-origin(2),posB(1)-origin(1));
        theta  = atan2(Y(mask0)-origin(2),X(mask0)-origin(1)) - theta0;
        if ~flag_clockwise, theta = -theta; end

        theta(theta<0) = theta(theta<0) + 2*pi;
        theta(theta>=2*pi) = 0;

        DisplacementInfo.Angle = theta(:);
    end

    % fv & strain tags
    if any(strcmpi(obj.hdata.spl.ROIType,{'open','closed'}))
        fvtag = 'fv';
        sttag = 'strain';
    else
        fvtag = 'fvpix';
        sttag = 'strainpix';
    end

    % Strain data
    StrainInfo = struct(...
        'X',        X,...
        'Y',        Y,...
        'Faces',    obj.straindata.(fvtag).faces,...
        'Vertices', obj.straindata.(fvtag).vertices);

    % strain orientation
    if any(strcmpi(obj.hdata.spl.ROIType,{'sa','la'}))
        StrainInfo.PolarOrientation = obj.straindata.(fvtag).orientation;
    end

    % expand the maskimage
    if ~any(strcmpi(obj.hdata.spl.ROIType,{'open','closed'}))
        irng = obj.hdata.spl.irng;
        jrng = obj.hdata.spl.jrng;

        mask = false(Isz);
        mask(irng(1):irng(2),jrng(1):jrng(2)) = ...
            obj.straindata.(fvtag).maskimage;
        StrainInfo.Mask = mask;
    end

    % strain tag labels
    switch lower(obj.hdata.spl.ROIType)
        case 'sa'
            tagA = {'XX','YY','XY','YX','RR','CC','RC','CR','p1','p2','p1or'};
            tagB = tagA;
        case 'la'
            tagA = {'XX','YY','XY','YX','RR','CC','RC','CR','p1','p2','p1or'};
            tagB = {'XX','YY','XY','YX','RR','LL','RL','LR','p1','p2','p1or'};
        case {'open','closed'}
            tagA = {'SS'};
            tagB = tagA;
        otherwise
            tagA = {'XX','YY','XY','YX','p1','p2','p1or'};
            tagB = tagA;
    end

    % copy relevant strain information
    for ti = 1:numel(tagA)
        StrainInfo.(tagB{ti}) = obj.straindata.(sttag).(tagA{ti});
    end

    % export file
    AnalysisInstanceUID = dicomuid;

    out.ImageInfo = ImageInfo;
    out.ROIInfo = ROIInfo;
    out.DisplacementInfo = DisplacementInfo;
    out.AnalysisInfo = AnalysisInfo;
    out.DENSEInfo = DENSEInfo;
    out.SequenceInfo = SequenceInfo;
    out.StrainInfo = StrainInfo;
    out.TransmuralStrainInfo = computeTransmuralData(obj);
    out.AnalysisInstanceUID = AnalysisInstanceUID;

    save(file, '-struct', 'out')
end

function tdata = computeTransmuralData(obj)
    % Compute transmural strain values
    straintags  = {'RR','CC','p1','p2'};
    strainnames = {'Err','Ecc','E1','E2'};

    switch lower(obj.hdata.spl.ROIType)
        case 'la'
            strainnames{2} = 'Ell';
        case 'sa'
            straintags{end+1} = 'twist';
            strainnames{end+1} = 'Twist';
    end

    % layers to report
    layernames = {'mid','subepi','subendo','ave'};
    layerids = {3, 1, 5, 1:5};

    % Initialize the output structure
    fields = cat(1,layernames, cell(size(layernames)));
    substruct = struct(fields{:});

    fields = cat(1,strainnames,repmat({substruct},size(strainnames)));
    tdata = struct(fields{:});

    [i,j]  = ndgrid(1:numel(strainnames),1:numel(layernames));
    tags  = straintags(i);
    lids  = layerids(j);
    types = strainnames(i);
    trans = layernames(j);

    Nsec   = obj.straindata.Nseg;
    Nfr    = size(obj.straindata.strain.RR,2);
    frrng  = obj.straindata.frrng;
    frames = frrng(1):frrng(2);

    layer  = obj.straindata.fv.layerid;
    sector = obj.straindata.fv.sectorid;

    for k = numel(tags):-1:1
        lid  = lids{k};
        tag  = tags{k};
        data = zeros(Nfr,Nsec);

        ltf = ismember(layer,lid);

        for sid = 1:Nsec
            stf = (sector == sid);
            tf = ltf & stf;

            for fr = frames
                data(fr,sid) = mean(obj.straindata.strain.(tag)(tf,fr));
            end

        end

        tdata.(types{k}).(trans{k}) = data(frames,:);
    end

    % CURE/RURE output
    if isequal(lower(obj.hdata.spl.ROIType),'sa')

        RR = zeros(Nfr,Nsec);
        CC = RR;
        for sid = 1:Nsec
            tf = (sector == sid);
            for fr = frames
                RR(fr,sid) = mean(obj.straindata.strain.RR(tf,fr));
                CC(fr,sid) = mean(obj.straindata.strain.CC(tf,fr));
            end
        end

        valcure = CURE(CC(frames,:));
        valrure = CURE(RR(frames,:));

        tdata.CURE = valcure;
        tdata.RURE = valrure;
    end
end

%% EXPORT EXCEL DOCUMENT

function file = exportExcelFcn(obj,startpath)

    % check for startpath
    if nargin < 2 || isempty(startpath) || ~exist(startpath,'dir')
        startpath = pwd;
    end

    % search for Excel?
    flag_excel = true;
    excelCleanupObj = [];

    % attempt to open Excel automation server
    if flag_excel
        if ~ispc
            flag_excel = false;
        else
            try
                Excel = actxserver('Excel.Application');
                excelCleanupObj = onCleanup(@()excelCleanup(Excel));
            catch
                flag_excel = false;
            end
        end
    end

    % check for template Excel file
    if flag_excel
        basedir = fileparts(mfilename('fullpath'));
        filetemplate = fullfile(basedir, 'template.xls');
        if ~exist(filetemplate,'file')
            warning(sprintf('%s:noTemplateXLS',mfilename),...
                'Cannot locate template XLS file.');
            flag_excel = false;
        end
    end

    % file filter
    filter = {'.xls','*.xls','Microsoft Excel File (*.xls)';
              '.csv','*.csv','Comma Separated Values (*.csv)'};
    if ~flag_excel
        filter = filter(2,:);
    end

    % determine file name
    startfile = fullfile(startpath,['untitled',filter{1,1}]);
    [uifile,uipath,filteridx] = uiputfile(filter(:,2:3),[],startfile);
    if isequal(uifile,0)
        file = [];
        return;
    end

    % save extension
    ext = filter{filteridx,1};

    % ensure proper extension
    file = fullfile(uipath,uifile);
    [~,~,e] = fileparts(file);
    if ~isequal(e,ext), file = [file, ext]; end

    % check for excel
    if ~strcmpi(ext,'.xls')
        delete(excelCleanupObj);
        flag_excel = false;
        drawnow
    end

    % determine strain object
    if isempty(obj.straindata)
        spl2strainFcn(obj);
        if isempty(obj.straindata)
            file = [];
            return;
        end
    end

    % start waitbartimer
    hwait = waitbartimer;
    waitCleanup = onCleanup(@()delete(hwait(isvalid(hwait))));
    hwait.String = 'Saving file...';
    hwait.WindowStyle = 'modal';
    hwait.AllowClose  = false;
    start(hwait);
    drawnow

    % strain tags to report
    switch lower(obj.hdata.spl.ROIType)
        case 'sa'
            straintags = {'RR','CC','p1','p2','twist'};
            strainnames = {'Err','Ecc','E1','E2','Twist'};
        case 'la'
            straintags = {'RR','CC','p1','p2'};
            strainnames = {'Ell','Ecc','E1','E2'};
        case {'open','closed'}
            straintags = {'SS'};
            strainnames = {'Econtour'};
    end

    % layers to report & number of sectors
    switch lower(obj.hdata.spl.ROIType)
        case {'sa','la'}
            layernames = {' mid',' subepi',' subendo',' ave'};
            layerids = {3, 1, 5, 1:5};
            Nsec   = obj.straindata.Nseg;
        otherwise
            layernames = {''};
            layerids = {1};
            Nsec = max(obj.straindata.fv.sectorid);
    end

    [i,j]  = ndgrid(1:numel(strainnames),1:numel(layernames));
    tags  = straintags(i);
    lids  = layerids(j);
    names = strcat(strainnames(i),layernames(j));

    Nfr    = size(obj.straindata.strain.(straintags{1}),2);
    frrng  = obj.straindata.frrng;
    frames = frrng(1):frrng(2);

    layer  = obj.straindata.fv.layerid;
    sector = obj.straindata.fv.sectorid;

    Cdata = cell(Nfr+1,Nsec+1);
    Cdata(2:end,1) = num2cell(1:Nfr);
    Cdata(1,2:end) = num2cell(1:Nsec);

    % excel options
    if flag_excel

        % copy template file
        copyfile(filetemplate,file,'f');

        % Open Excel file
        Workbooks = Excel.Workbooks;
        Workbook = Workbooks.Open(file);

        % Get the list of sheets in the workbook
        Sheets = Workbook.Sheets;

    % CSV options
    else
        fid = fopen(file,'w');
        csvCleanupObj = onCleanup(@()csvCleanup(fid));
    end

    for k = 1:numel(names)%numel(names):-1:1

        name = names{k};
        lid  = lids{k};
        tag  = tags{k};
        data = zeros(Nfr,Nsec);

        ltf = ismember(layer,lid);

        for sid = 1:Nsec
            stf = (sector == sid);
            tf = ltf & stf;

            for fr = frames
                data(fr,sid) = mean(obj.straindata.strain.(tag)(tf,fr));
            end
        end
        Cdata(1+frames,2:end) = num2cell(data(frames,:));

        % excel write
        if flag_excel

            % copy the template sheet (last sheet), placing the
            % new sheet at the front of the workbook
            n = Sheets.Count;
            Sheets.Item(n).Copy(Sheets.Item(k));
            Sheets.Item(k).Name = name;

            xlswrite1(Excel,file,Cdata,name,'B4');
            xlswrite1(Excel,file,{name},name,'A1');

        % CSV write
        else
            fprintf(fid,'%s\n',name);
            fprintf(fid,'Frame,');
            fprintf(fid,'%d,',Cdata{1,2:end});
            fprintf(fid,'\n');

            for row = 2:size(Cdata,1)
                fprintf(fid,'%d,',Cdata{row,1});
                fprintf(fid,'%.8g,',Cdata{row,2:end});
                fprintf(fid,'\n');
            end
            fprintf(fid,'\n');
        end

        drawnow
    end

    % CURE/RURE output
    if isequal(lower(obj.hdata.spl.ROIType),'sa')

        name = 'CURE.RURE';

        Cdata = cell(Nfr+1,3);
        Cdata(2:end,1) = num2cell(1:Nfr);
        Cdata(1,2:3) = {'CURE','RURE'};

        RR = zeros(Nfr,Nsec);
        CC = RR;
        for sid = 1:Nsec
            tf = (sector == sid);
            for fr = frames
                RR(fr,sid) = mean(obj.straindata.strain.RR(tf,fr));
                CC(fr,sid) = mean(obj.straindata.strain.CC(tf,fr));
            end
        end

        valcure = CURE(CC(frames,:));
        valrure = CURE(RR(frames,:));
        Cdata(1+frames,2:3) = num2cell([valcure(:),valrure(:)]);

%         % excel write
        if flag_excel

            % copy the template sheet (last sheet)
            n = Sheets.Count;
            Sheets.Item(n).Copy(Sheets.Item(n));
            Sheets.Item(n).Name = name;

            xlswrite1(Excel,file,Cdata,name,'B4');
            xlswrite1(Excel,file,{name},name,'A1');
            xlswrite1(Excel,file,{''},name,'C3');

        % CSV write
        else
            fprintf(fid,'%s\n',name);
            fprintf(fid,'Frame,');
            fprintf(fid,'%s,',Cdata{1,2:end});
            fprintf(fid,'\n');

            for row = 2:size(Cdata,1)
                fprintf(fid,'%d,',Cdata{row,1});
                fprintf(fid,'%.8g,',Cdata{row,2:end});
                fprintf(fid,'\n');
            end
            fprintf(fid,'\n');

%             fprintf(fid,'%s',name);
%             for row = 1:size(Cdata,1)
%                 fprintf(fid,'%.8g,',Cdata{row,:});
%                 fprintf(fid,'\n');
%             end
        end

        drawnow
    end

    % excel options
    if flag_excel

        n = Sheets.Count;
        Excel.DisplayAlerts = false;
        Sheets.Item(n).Delete;
        Excel.DisplayAlerts = true;
        Sheets.Item(1).Activate;

        % save the new file
        Workbook.Save;

        % direct delete of cleanup object
        delete(excelCleanupObj);

    % CSV options
    else
        delete(csvCleanupObj);
    end
end

function excelCleanup(Excel)
%     disp('Excel Cleanup!');
    Excel.Quit
    Excel.delete
    clear Excel
end

function csvCleanup(fid)
    fclose(fid);
end

%% HELPER FUNCTION: RESIZE SINGLE AXES w/ PLAYBAR
function resizeAxes(obj,hax,dim)
    if ~ishandle(hax), return; end

    minwh = [100 100];  % minimum allowable panel size
    margin = 5;

    % determine available display position
    pos = getpixelposition(obj.hdisplay);
    pos = [pos(1:2),max(pos(3:4),minwh)];

    % subtract playbar
    p = getpixelposition(obj.hplaybar);
    plsz = p(3:4);

    p = [1+margin, 1+plsz(2)+2*margin, ...
        pos(3)-2*margin, pos(4)-plsz(2)-3*margin];
    setpixelposition(hax,p);

    % 3D
    if isequal(lower(dim),'3d')
        obj.exportrect = getpixelposition(hax,true);
        set(hax,'outerposition',get(hax,'position'));
    else
        obj.exportrect = round(plotboxpos(hax,true)) + [-1 -1 0 0];
    end
end

%% MODIFIED COLORBAR AXES
% we use the "colorbar" command as it supplies the necessary resizing
% capabilities, but we must modify the object to display a specific
% colormap.
function hcb = colorbarmod(hax,loc,map,rng)

    Nmap = size(map,1);
    x = [0 1];
    y = linspace(rng(1),rng(2),Nmap+1);
    [X,Y] = meshgrid(x,y);

    % create colorbar
    hcb = colorbar('peer',hax,'location',loc);

    % make the colorbar image invisible
    hchild = findall(hcb,'type','image');

    if isempty(hchild)
        set(hcb, 'Colormap', map);
        set(hax, 'CLim', rng);
        return
    end

    set(hchild,'visible','off');

    % change the colorbar limits & add new patch object
    if isequal(get(hcb,'ylim'),[0 1])
        set(hcb,'xlim',rng);
        [f,v] = surf2patch(Y',X',zeros(size(X')));
    else
        set(hcb,'ylim',rng);
        [f,v] = surf2patch(X,Y,zeros(size(X)));
    end

    v = v(:,[1 2]);
    patch('parent',hcb,'facecolor','flat',...
        'edgecolor','none','facevertexcdata',map,...
        'vertices',v,'faces',f);
end

%% STRAIN HELPER FUNCTIONS
function strainoptsFcn(obj)

    % current enable state
    val = obj.Enable;

    obj.Enable = 'off';

    % setup options
    opts = obj.strainopts;
    opts.SHrng = obj.strainopts.XYrng;
    opts = rmfield(opts,{'XYrng','YXrng'});

    % get new options
    try
        opts = analysisoptions(opts);
    catch ERR
        obj.Enable = val;
        rethrow(ERR);
    end

    if isempty(opts)
        obj.Enable = val;
        return;
    end

    % parse new options
    opts.XYrng = opts.SHrng;
    opts.YXrng = opts.SHrng;
    opts = rmfield(opts,{'SHrng'});

    obj.strainopts = opts;
    obj.Enable = val;
end

function spl2strainFcn(obj)

    % waitbar
    hwait = waitbartimer;
    cleanupObj = onCleanup(@()delete(hwait(isvalid(hwait))));
    hwait.String = 'Calculating strain & displacement patterns';
    hwait.WindowStyle = 'modal';
    hwait.AllowClose = false;
    hwait.start;

    % ROI type
    type = obj.hdata.spl.ROIType;

    % frames for analysis
    Nfr    = size(obj.hdata.spl.Mag,3);
    frrng  = obj.hdata.spl.frrng;
    frames = frrng(1):frrng(2);

    api = struct(...
        'Type',             type,...
        'xrng',             obj.hdata.spl.jrng,...
        'yrng',             obj.hdata.spl.irng,...
        'RestingContour',   {obj.hdata.spl.RestingContour},...
        'FramesForAnalysis',frrng,...
        'res',              1,...
        'MaskFcn',          obj.hdata.spl.MaskFcn,...
        'spldx',            obj.hdata.spl.spldx,...
        'spldy',            obj.hdata.spl.spldy,...
        'spldz',            obj.hdata.spl.spldx);

    if any(strcmpi(type,{'SA','LA'}))
        api.Mag  = obj.hdata.spl.Mag;
        api.SegmentModelPanel = true;
        if ~isempty(obj.straindata)
            api.PositionA = obj.straindata.PositionA;
            api.PositionB = obj.straindata.PositionB;
            api.Nmodel    = obj.straindata.Nmodel;
            api.Nseg      = obj.straindata.Nseg;
            api.Clockwise = obj.straindata.Clockwise;
        end
    elseif any(strcmpi(type,{'open','closed'}))
        api.Mag  = obj.hdata.spl.Mag;
        api.SegmentModelPanel = true;
        if ~isempty(obj.straindata)
            api.PositionIndices = obj.straindata.PositionIndices;
        end
    end

    % strain data
    data = spl2strain(api);
    if isempty(data), return; end

    % append frame range to strain data
    data.frrng = frrng;

    % gather additional data
    strtypes = {'','pix'};
    dsptypes = {'X','Y','Z'};

    for si = 1:numel(strtypes)

        % face/vertex & strain tags
        fvtag = ['fv' strtypes{si}];
        sttag = ['strain' strtypes{si}];

        if ~isfield(data,fvtag), continue; end

        % face centroids (trajectory origins)
        xv = data.(fvtag).vertices(:,1);
        yv = data.(fvtag).vertices(:,2);
        f  = data.(fvtag).faces;

        ori = [mean(xv(f),2),mean(yv(f),2)];
        Nx  = size(ori,1);

        % trajectories
        pos = ori(:,[2 1])';
        for di = 1:numel(dsptypes)
            tagA = ['d' upper(dsptypes{di})];
            tagB = ['spld' lower(dsptypes{di})];

            tmp = zeros(Nx,numel(frames));
            for fridx = 1:numel(frames)
                pos(3,:) = frames(fridx);
                tmp(:,fridx) = fnvalmod(obj.hdata.spl.(tagB),pos);
            end
            data.(sttag).(tagA) = tmp;
        end

        % polar displacement & twist
        if any(strcmpi(type,{'SA'}))

            % polar origins (bulk corrected)
            X0 = ori(:,1) - mean(ori(:,1));
            Y0 = ori(:,2) - mean(ori(:,2));
            [t0,r0] = cart2pol(X0,Y0);

            % polar trajectories (bulk corrected)
            X = bsxfun(@plus,ori(:,1),data.(sttag).dX);
            X = bsxfun(@minus,X,mean(X,1));
            Y = bsxfun(@plus,ori(:,2),data.(sttag).dY);
            Y = bsxfun(@minus,Y,mean(Y,1));
            [t,r] = cart2pol(X,Y);

            % unwrap trajectory angle
            tall = [t0,t];
            tall = unwrap(tall,[],2);
            t = tall(:,2:end);

            % change in radius/angle
            dR = bsxfun(@minus,r,r0);
            dT = bsxfun(@minus,t,t0);

            % change angle direction if necessary
            if ~data.Clockwise
                dT = -dT;
            end

            % arc length (circumferential displacement)
            dC = bsxfun(@times,dT,r0);

            % save polar information
            data.(sttag).dR = dR;
            data.(sttag).dC = dC;
            data.(sttag).twist = dT*180/pi;
        end

        % extend all strain data to size [Nx x Nfr]
        tags = fieldnames(data.(sttag));
        for ti = 1:numel(tags)
            tmp = zeros([Nx,Nfr]);
            tmp(:,frames) = data.(sttag).(tags{ti});
            data.(sttag).(tags{ti}) = tmp;
        end
    end

    % save to object
    obj.straindata = data;
end

function fvcd = straincolorFcn(vals,map,rng)

    fvcd = (vals - rng(1)) / diff(rng);
    fvcd = round(fvcd*(size(map,1)-1)) + 1;
    fvcd = squeeze(ind2rgb(fvcd,map));
end

%% TEMPLATE DISPLAY FUNCTION
% function templateDisplay(obj)
%
%     % application data
%     api.initFcn     = @initFcn;
%     api.playbackFcn = @playbackFcn;
%     api.deleteFcn   = @deleteFcn;
%     api.resizeFcn   = @resizeFcn;
%
%
%     function initFcn()
%
%     end
%
%     function resizeFcn()
%
%     end
%
%     function playbackFcn()
%
%     end
%
%     function deleteFcn()
%
%     end
%
% end
