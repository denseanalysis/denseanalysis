% Class definition DENSEviewer

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

classdef DENSEviewer < DataViewer

    properties (Dependent=true,SetAccess='private')
        DENSEIndex
        SequenceIndex
        ROIIndex
        Frame
    end

    properties (Dependent=true)
        SliceViewer
        ArialViewer
    end

    properties
        ROIEdit = 'off';
    end

    properties (SetAccess='private',GetAccess='public')

        % DENSEdata indices
        dnsidx = [];
        roiuid = [];
        frame = 1;

        dnsbuf = [];
        roibuf = [];

        % image display and related objects
        hax
        him
        htitle
        hroi

        % listeners
        hlisten_suspend
        hlisten_restore

        % useful sequence information
        displaydata

        % roi export information
        exportroiapi = [];

        % zoom/pan/rotate objects
        constraintFcn

        hdns_text
        hdns_menu
        hdns_button
        hreg_button
        hflag_panel
        hflag_swap
        hflag_negx
        hflag_negy
        hflag_negz
        hroi_text
        hroi_menu
        hroi_button

        hslice
        harial

        hclimlink
    end

    methods
        function obj = DENSEviewer(varargin)
            options = struct([]);
            obj = obj@DataViewer(options,varargin{:});
            obj = DENSEviewerFcn(obj);
            obj.redrawenable = true;
            redraw(obj);
            obj.exportaxes = true;
        end

        function delete(obj)
            deleteFcn(obj);
        end

        function redraw(obj)
            redraw@DataViewer(obj);
            redrawFcn(obj);
        end

        function val = get.DENSEIndex(obj)
            val = obj.dnsidx;
        end
        function val = get.SequenceIndex(obj)
            if isempty(obj.dnsidx)
                val = [];
            else
                val = [obj.hdata.dns(obj.dnsidx).MagIndex;
                       obj.hdata.dns(obj.dnsidx).PhaIndex;];
                val = val(:);
                val = val(~isnan(val));
            end
        end
        function val = get.ROIIndex(obj)
            val = obj.hroi.ROIIndex;
        end
        function val = get.Frame(obj)
           if isempty(obj.dnsidx)
                val = [];
            else
                val = obj.frame;
            end
        end

        function set.ROIEdit(obj,val)
            val = checkROIEdit(obj,val);
            if ~isempty(obj.ROIIndex), obj.hroi.Enable = val; end
            obj.ROIEdit = val;
        end

        function val = get.SliceViewer(obj)
            val = obj.hslice;
        end
        function set.SliceViewer(obj,val)
            setSliceViewerFcn(obj,val);
        end

        function val = get.ArialViewer(obj)
            val = obj.harial;
        end
        function set.ArialViewer(obj,val)
            setArialViewerFcn(obj,val);
        end

        function newROI(obj)
            obj.hroi.createROI(obj.SequenceIndex(1));
            if ~isempty(obj.ROIIndex)
                obj.hroi.Visible = 'on';
                obj.ROIEdit = 'on';
            end
        end

        function suspend(obj)
            suspendFcn(obj);
            suspend@DataViewer(obj);
        end

        function restore(obj)
            restoreFcn(obj);
            restore@DataViewer(obj);
        end

        function file = exportImage(obj,varargin)
            obj.exportrect = getpixelposition(obj.hdisplay,true)...
                + [0 45 0 -45];
            file = exportImage@DataViewer(obj,varargin{:});
        end

        function file = exportVideo(obj,varargin)
            obj.exportrect = getpixelposition(obj.hdisplay,true)...
                + [0 45 0 -45];
            file = exportVideo@DataViewer(obj,varargin{:});
        end

        function path = exportROI(obj,varargin)
            path = exportROIFcn(obj,varargin{:});
        end
    end

    methods (Access=protected)
        function playback(obj)
            playbackFcn(obj);
        end

        function setZoomPanRot(obj)
            setZoomPanRotFcn(obj);
        end

        function reset(obj)
            resetFcn(obj);
        end

        function dataevent(obj,evnt)
            dataeventFcn(obj,evnt);
        end

        function resize(obj)
            resize@DataViewer(obj);
            resizeFcn(obj)
        end

        function contextCallback(obj)
            contextCallbackFcn(obj);
        end
    end
end

function obj = DENSEviewerFcn(obj)

    hlclr   = [78 101 148]/255;
    axesclr = [.5 .5 .5];

    titles = {'X-MAGNITUDE','X-PHASE',...
              'Y-MAGNITUDE','Y-PHASE',...
              'Z-MAGNITUDE','Z-PHASE'};
    tags = {'xmag','xpha','ymag','ypha','zmag','zpha'};

    % create object hierarchy
    obj.hax    = [];
    obj.him    = [];
    obj.htitle = [];
    for k = 1:6
        obj.hax = cat(1, obj.hax, axes('parent',obj.hdisplay));
        obj.him = cat(1, obj.him, imshow(rand(10),'parent',obj.hax(k)));
        obj.htitle = cat(1, obj.htitle, textfig(obj.hdisplay));
    end

    obj.hroi = roitool(obj.hdata,obj.hax);

    % controls
    hctrl = obj.hcontrol;
    obj.hdns_text   = textfig(hctrl);
    obj.hdns_menu   = uicontrol('parent',hctrl,'style','popupmenu');
    obj.hdns_button = uicontrol('parent',hctrl,'style','pushbutton');
    obj.hreg_button = uicontrol('parent',hctrl,'style','pushbutton');
    obj.hflag_panel = uipanel('parent',hctrl);
    obj.hflag_swap  = uicontrol('parent',obj.hflag_panel,'style','checkbox');
    obj.hflag_negx  = uicontrol('parent',obj.hflag_panel,'style','checkbox');
    obj.hflag_negy  = uicontrol('parent',obj.hflag_panel,'style','checkbox');
    obj.hflag_negz  = uicontrol('parent',obj.hflag_panel,'style','checkbox');
    obj.hroi_text   = textfig(hctrl);
    obj.hroi_menu   = uicontrol('parent',hctrl,'style','popupmenu');
    obj.hroi_button = uicontrol('parent',hctrl,'style','pushbutton');

    % set properties

    set(obj.hax(:),...
        'color',        axesclr,...
        'clim',         [0 1],...
        'box',          'on',...
        'visible',      'on',...
        'xtick',        [],...
        'ytick',        [],...
        'xcolor',       hlclr,...
        'ycolor',       hlclr,...
        {'tag'},        tags(:),...
        'HitTest',              'off',...
        'HandleVisibility',     'off',...
        'XLimMode',             'manual',...
        'YLimMode',             'manual',...
        'DataAspectRatioMode',  'manual');

    set(obj.him,...
        'Visible',      'off',...
        'HitTest',      'off');

    set(obj.htitle(:),...
        {'string'},             titles(:),...
        'horizontalalignment',  'left',...
        'verticalalignment',    'bottom',...
        'color',                hlclr,...
        'fontweight',           'bold',...
        'rotation',             90,...
        'units',                'pixels',...
        'fontsize',             12);
%     set(obj.htitle,'fontunits','normalized');

    h = [obj.hdns_text,obj.hroi_text];
    str = {' Select DENSE data:',' Select ROI'};
    set(h(:),...
        {'string'},             str(:),...
        'HorizontalAlignment',  'left',...
        'FontWeight',           'bold',...
        'VerticalAlignment',    'bottom',...
        'Fontsize',             8,...
        'units',                'pixels');

    set(obj.hflag_panel,...
        'BackgroundColor',  'w',...
        'BorderType',      'line',...
        'HighlightColor',   hlclr);

    h = [obj.hflag_swap,obj.hflag_negx,...
         obj.hflag_negy,obj.hflag_negz];
    pos = {[5 35 75 15]; [80 35 75 15]; [80 20 75 15]; [80 5 75 15]};
    str = {'Swap XY','Negate X','Negate Y','Negate Z'};
    set(h(:),...
        {'string'},             str(:),...
        'Fontsize',             8,...
        'units',                'pixels',...
        'BackgroundColor',      'w',...
        {'Position'},           pos(:));

    h = [obj.hdns_menu,obj.hroi_menu];
    set(h(:),...
        'string',           'No Data...',...
        'BackgroundColor',  'w',...
        'Fontname',         'fixedwidth',...
        'Enable',           'off',...
        'UIContextMenu',    obj.hcontext_control,...
        {'Callback'},       {@(varargin)hdns_menu_Callback(obj);...
                             @(varargin)hroi_menu_Callback(obj)});

    h = [obj.hdns_button,obj.hreg_button,obj.hroi_button];
    str = {'Edit Groups','Register Data','New ROI'};
    set(h(:),...
        {'string'},         str(:),...
        'Enable',           'off',...
        'BackgroundColor',  'w',...
        {'Callback'},       {@(varargin)hdns_button_Callback(obj);
                             @(varargin)hreg_button_Callback(obj);
                             @(varargin)hroi_button_Callback(obj)});

    % link axes limits
    hlink = linkprop(obj.hax,{'XLim','YLim','DataAspectRatio'});
    setappdata(obj.hax(1), 'custom_graphics_linkaxes', hlink);

    % ROI suspend/restore listeners
    obj.hlisten_suspend = addlistener(obj.hroi,...
        'Suspend',@(varargin)suspend(obj));
    obj.hlisten_restore = addlistener(obj.hroi,...
        'Restore',@(varargin)restore(obj));

    % initialize zoom/pan/rot
    setZoomPanRot(obj);

    % ready the object
    loaddnsFcn(obj);
end

function setZoomPanRotFcn(obj)

    % do not complete until axes have been created
    if isempty(obj.hax), return; end

    % add callback to zoom behavior
    id = iptaddcallback_mod(obj.hzoom,...
        'ActionPostCallback', @(h,evnt)zoompan(obj,evnt.Axes));

    obj.iptinfo(1).Object   = obj.hzoom;
    obj.iptinfo(1).Callback = 'ActionPostCallback';
    obj.iptinfo(1).id       = id;

    % pan behavior callback
    id = iptaddcallback_mod(obj.hpan,...
        'ActionPostCallback', @(h,evnt)zoompan(obj,evnt.Axes));

    obj.iptinfo(2).Object   = obj.hpan;
    obj.iptinfo(2).Callback = 'ActionPostCallback';
    obj.iptinfo(2).id       = id;

    % contrast behavior callback
    id = iptaddcallback_mod(obj.hcontrast,...
        'ActionPostCallback', @(h,evnt)contrastfcn(obj,evnt.Axes));

    obj.iptinfo(3).Object   = obj.hcontrast;
    obj.iptinfo(3).Callback = 'ActionPostCallback';
    obj.iptinfo(3).id       = id;

    % disable rotation
    setAllowAxesRotate(obj.hrot,obj.hax,false);

    % disable phase contrast
    obj.hcontrast.setAllowAxes(obj.hax([2 4 6]),false);
end

function zoompan(obj,hax)
    if any(hax==obj.hax) && ~isempty(obj.dnsidx)
        lim = axis(obj.hax(1));
        obj.displaydata(obj.dnsidx).CurrentXYLim = lim;
        if ~isempty(obj.harial)
            obj.harial.Limits = lim;
        end
    end
end

function contrastfcn(obj,hax)
%     idx = [1 3 5];
    if any(hax==obj.hax) && ~isempty(obj.dnsidx)
        for k = 1:6
            clim = get(obj.hax(k),'clim');
            obj.displaydata(obj.dnsidx).CurrentCLim(:,:,k) = clim;
        end
    end
end

function deleteFcn(obj)

    % ensure children objects/listeners are deleted
    tags = {'hlisten_suspend','hlisten_restore',...
        'hroi'};

    % try to delete every listed object
    % report if deletion was unsuccessful
    for ti = 1:numel(tags)
        try
            h = obj.(tags{ti});
            if isempty(h)
                continue;
            elseif isobject(h)
                if isvalid(h), delete(h); end
            elseif ishandle(h)
                delete(h);
            end
        catch ERR
            fprintf('could not delete %s.%s\n',...
                mfilename,tags{ti});
        end
    end
end

function resetFcn(obj)

    % set the display indices to zero
    obj.dnsidx = [];
    obj.roiuid = [];
    obj.frame  = 1;
    obj.displaydata = [];

    % clear/disable controls
    h = [obj.hdns_menu,obj.hroi_menu];
    set(h,...
        'String',   'No Data...',...
        'Enable',   'off',...
        'UserData', [],...
        'Value',    1);

    h = [obj.hflag_swap,obj.hflag_negx,...
         obj.hflag_negy,obj.hflag_negz];
    set(h,...
        'Enable',   'off',...
        'Value',    0);

    h = [obj.hdns_button,obj.hreg_button,obj.hroi_button];
    set(h,...
        'Enable',   'off');

    % reset display
    resetdisp(obj);
end

function resetdisp(obj)

    % stop the playbar
    obj.hlisten_playbar.Enabled = false;
    obj.hplaybar.Max = 0;

    % disable export
    obj.isAllowExportImage = false;
    obj.isAllowExportVideo = false;

    % clear the axes & image
    set(obj.him,...
        'cdata',    ones(10),...
        'visible',  'off');
    set(obj.hax,...
        'xlim',             [0.5 10.5],...
        'ylim',             [0.5 10.5],...
        'clim',             [0 1],...
        'HitTest',          'off',...
        'HandleVisibility', 'off',...
        'DataAspectRatio',  [1 1 1]);

    % delete magnitude clim link
    delete(obj.hclimlink);
    obj.hclimlink = [];

    % reset ROI tool
    reset(obj.hroi);
    obj.ROIEdit = 'off';
end

function dataeventFcn(obj,evnt)
    switch lower(evnt.Action)
        case 'load'
            loaddnsFcn(obj);
        case 'new'
            if strcmpi(evnt.Field,'dns')
                loaddnsFcn(obj);
            else
                redraw(obj);
            end
        case {'delete','rename'}
            redraw(obj);
    end
end

function loaddnsFcn(obj)

    % reset object
    reset(obj);

    % check for empty DENSE field
    if isempty(obj.hdata.dns)
        if ~isempty(obj.hdata)
            set(obj.hdns_button,'enable','on');
        end
        return;
    end

    % sequence display parameters
    seqdata = obj.hdata.getDisplayData;

    % gather DENSE display parameters
    N = numel(obj.hdata.dns);
    data = repmat(struct,[N 1]);

    for k = 1:N

        % current DENSE information
        duid = obj.hdata.dns(k).UID;

        % check for exisiting display information
        % if we already have this information, copy to the new data
        % structure and continue.  Otherwise we need to setup the new
        % display information.
        if ~isempty(obj.displaydata)
            tf = strcmpi(duid,{obj.displaydata.DENSEUID});
            if any(tf)
                idx = find(tf,1,'first');
                tags = fieldnames(obj.displaydata);
                for ti = 1:numel(tags)
                    data(k).(tags{ti}) = obj.displaydata(idx).(tags{ti});
                end
                continue
            end
        end

        % DENSE information
        sidx  = [obj.hdata.dns(k).MagIndex;
                 obj.hdata.dns(k).PhaIndex];
        sidx0 = sidx(find(~isnan(sidx(1,:)),1,'first'));
        Isz   = seqdata(sidx0).ImageSize;
        Nfr   = seqdata(sidx0).NumberOfFrames;

        % new display space
        xylim = [0 Isz(2) 0 Isz(1)] + 0.5;

        % gather intensity limits
        ilim = zeros([Nfr,2,6]);
        for ci = 1:6
            if ~isnan(sidx(ci))
                ilim(:,:,ci) = seqdata(sidx(ci)).ILim;
            end
        end

        % save UID
        data(k).DENSEUID = duid;

        % copy seq0 to dense data structure
        tags = fieldnames(seqdata);
        for ti = 1:numel(tags)
            data(k).(tags{ti}) = seqdata(sidx0).(tags{ti});
        end

        % other fields
        data(k).ILim          = ilim;
        data(k).CurrentCLim   = repmat([0 1],[1 1 6]);
        data(k).CurrentXYLim  = xylim;
        data(k).CurrentROIUID = [];
    end

    % save to object
    obj.displaydata = data;

    % display the first sequence
    obj.dnsidx = 1;
    obj.roiuid = data(1).CurrentROIUID;
    obj.frame  = 1;
    redraw(obj);
end

function redrawFcn(obj)

    % test for enabled redraw
    if ~obj.redrawenable, return; end

    % resize the child object
    resizeFcn(obj);

    % check for no data
    if isempty(obj.hdata.dns)
        reset(obj);
        if ~isempty(obj.hdata)
            set(obj.hdns_button,'enable','on');
        end
        return
    end

    % DENSE name buffer, containing all sequence display names
    if ~isempty(obj.hdata.dns)
        N = numel(obj.hdata.dns);
        obj.dnsbuf = cell(N,1);
        for k = 1:N
            idx = [obj.hdata.dns(k).MagIndex; ...
                   obj.hdata.dns(k).PhaIndex];
            str = sprintf('[%d/%d] ',idx(~isnan(idx)));
            name = obj.hdata.dns(k).Name;
            if isempty(name), name = '[]'; end
            obj.dnsbuf{k} = sprintf('%3s: %s (%s)',...
                obj.hdata.dns(k).Type,name,str);
        end
    else
        obj.dnsbuf = {};
    end

    % ROI name buffer, containing all ROI display names
    if ~isempty(obj.hdata.roi)
        obj.roibuf = {obj.hdata.roi.Name};
    else
        obj.roibuf = {};
    end

    % if the current DENSE UID is as expected, lets display the current
    % sequence.  Otherwise, lets display the first sequence.
    didx = obj.dnsidx;
    if ~isequal(obj.displaydata(didx).DENSEUID,obj.hdata.dns(didx).UID)
        didx = 1;
        obj.dnsidx = didx;
        obj.roiuid = obj.displaydata(didx).CurrentROIUID;
        obj.frame  = 1;
    end

    % update DENSE controls
    set(obj.hdns_menu,'String',obj.dnsbuf,'Value',didx,'Enable','on');
    set(obj.hdns_button,'enable','on');

	% indices into seq
    midx = obj.hdata.dns(didx).MagIndex;
    pidx = obj.hdata.dns(didx).PhaIndex;

    % swap if necessary
    if obj.hdata.dns(didx).SwapFlag
        midx([1 2]) = midx([2 1]);
        pidx([1 2]) = pidx([2 1]);
    end

    % all sequence indices
    sidx = [midx; pidx];

    % update registration controls
    if numel(unique(midx(~isnan(midx)))) > 1
        set(obj.hreg_button,'enable','on');
    else
        set(obj.hreg_button,'enable','off');
    end

    % gather available ROI options (including "none")
    allridx = findROI(obj.hdata,sidx(~isnan(sidx)));
    buf = obj.roibuf(allridx);

    allridx = [0; allridx(:)];
    buf = ['None'; buf(:)];

    % if we can locate the current ROI UID within the available options,
    % then display that ROI.  Otherwise, we do not display any ROI.
    if isempty(obj.roiuid)
        val  = 1;
        ridx = 0;
    else
        ridx = UIDtoIndexROI(obj.hdata,obj.roiuid);
        if isnan(ridx) || ~any(allridx == ridx)
            ridx = 0;
            obj.roiuid = [];
            val = 1;
        else
            val = find(ridx == allridx,1,'first');
        end
    end

    % update ROI controls
    set(obj.hroi_menu,...
        'String',    buf,...
        'Value',     val,...
        'Userdata',  allridx,...
        'Enable',    'on');
    set(obj.hroi_button,'Enable','on');

    % set image visibility
    for k = 1:6
        if isnan(sidx(k))
            set(obj.him(k),'cdata',ones(10),'visible','off');
            set(obj.hax(k),'hittest','off','handlevisibility','off');
        else
            set(obj.him(k),'visible','on')
            set(obj.hax(k),'hittest','on','handlevisibility','on');
        end
    end

    % determine initial zoom
    Isz = obj.displaydata(didx).ImageSize;

    set(obj.hax,...
        'clim',[0 1],...
        'xlim',[.5 Isz(2)+.5],...
        'ylim',[.5 Isz(1)+.5]);

    for k = 1:6
       zoom(obj.hax(k),'reset');
       fix(obj.hcontrast,obj.hax(k));
    end

    % display ROI of interest
    if ridx==0
        reset(obj.hroi);
    else
        tf = isnan(sidx);
        obj.hroi.ignoreAxes(obj.hax(tf(:)));

        tmp = sidx(~isnan(sidx));
        obj.hroi.DENSEIndex    = didx;
        obj.hroi.SequenceIndex = tmp(1);
        obj.hroi.ROIIndex = ridx;
        obj.hroi.ROIFrame = obj.frame;
        obj.hroi.Visible = 'on';
        if ~isempty(obj.hroi.ROIIndex)
            obj.hroi.Enable = obj.ROIEdit;
        end
    end

    % reset the cLine position constraint function
    fcn = clineConstrainToRectFcn(obj.hroi.cLine,...
        get(obj.hax(1),'XLim'),get(obj.hax(1),'YLim'));
    obj.hroi.PositionConstraintFcn = fcn;

    % update limits to last displayed
    lim = obj.displaydata(didx).CurrentXYLim;
    clim = obj.displaydata(didx).CurrentCLim;
    clim = mat2cell(clim,1,2,ones(6,1));
    set(obj.hax(:),'xlim',lim(1:2),'ylim',lim(3:4),{'clim'},clim(:));

    % link clim
    tf = sum(midx([1 1 1],:) == midx([1 1 1],:)') > 1;
    if any(tf)
        magax = obj.hax([1 3 5]);
        obj.hclimlink = linkprop(magax(tf),'clim');
    end

    % adjust aspect ratio (for non-square pixels)
    px = obj.displaydata(didx).PixelSpacing;
    dar = [1 px(2)/px(1) 1];
    daspect(obj.hax(1),dar);

    % update SliceViewer
    if ~isempty(obj.hslice)
        tf = obj.hslice.SequenceHighlight;
        tf(:) = false;
        tf(obj.SequenceIndex) = true;
        obj.hslice.SequenceHighlight = tf;
    end
    if ~isempty(obj.harial)
        obj.harial.SequenceIndex = midx;
        obj.harial.Limits = lim;
    end

    % flag display
    swap = obj.hdata.dns(didx).SwapFlag;
    neg  = obj.hdata.dns(didx).NegFlag;
    set(obj.hflag_swap,'value',swap);
    set([obj.hflag_negx,obj.hflag_negy,obj.hflag_negz]',...
        {'value'},num2cell(neg)');

    % enable playbar
    obj.hplaybar.Max = obj.displaydata(didx).NumberOfFrames;
    obj.hplaybar.Value = obj.frame;
    obj.hlisten_playbar.Enabled = true;

    % display first image!
    playback(obj);

    % save the current ROI uid
    obj.displaydata(didx).CurrentROIUID = obj.roiuid;

    % determine export options
    obj.isAllowExportImage = true;
    if obj.hplaybar.Max > 1
        obj.isAllowExportVideo = true;
    else
        obj.isAllowExportVideo = false;
    end
end

function resizeFcn(obj)

    % display variables (all in pixels)
    minwh = [400 300];  % minimum allowable panel size
    vert  = [10 10 50]; % internal axes vertical spacing (top/mid/bot)
    horz  = [30 30 10]; % internal horizontal spacing    (lft/mid/rgt)
    margin = 5;

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
    ptmp = zeros(6,4);
    for k = 1:6
        setpixelposition(obj.hax(k),pax(k,:));
        p = plotboxpos(obj.hax(k));
        set(obj.htitle(k),'units','pixels','position',p(1:2)+[-1,0]);
        ptmp(k,:) = p;
    end

    % control panel position
    panelpos = getpixelposition(obj.hcontrol);

    % control panel display
    yshft  = [ 15 23 57 25 25 25 23 23];
    height = [NaN 21 55 21 21 NaN 21 21];

    % determine pushbutton parameters
    buttonwidth = 100;
    wpb = min(buttonwidth,panelpos(3)-2*margin);
    xpb = (panelpos(3)/2) - (wpb/2) + 1;

    h = [obj.hdns_text, obj.hdns_menu, ...
         obj.hflag_panel, obj.hdns_button, obj.hreg_button,...
         obj.hroi_text, obj.hroi_menu, obj.hroi_button];

    p = [1+margin,panelpos(4)-margin+1,...
           panelpos(3)-2*margin,0];

    for k = 1:numel(h)
        p(2) = p(2)-yshft(k);
        p(4) = height(k);
        if ishghandle(h(k), 'text')
            set(h(k),'units','pixels','Position',p(1:2));
        elseif ishghandle(h(k), 'uicontrol') && ...
           strcmpi(get(h(k),'style'),'pushbutton')
            ppb = [xpb p(2) wpb p(4)];
            setpixelposition(h(k),ppb);
        else
            setpixelposition(h(k),p);
        end
    end
end

function playbackFcn(obj)

    % current frame
    frame = obj.hplaybar.Value;

    % gather data
    didx  = obj.dnsidx;
    group = obj.hdata.dns(didx);
    sidx  = [group.MagIndex; group.PhaIndex];
    neg   = group.NegFlag;

    % gather frame imagery & image translation
    I = cell(2,3);
    shft = cell(2,3);
    for k = 1:6
        if ~isnan(sidx(k))
            mx = obj.displaydata(obj.dnsidx).ILim(frame,2,k);
            I{k} = double(obj.hdata.img{sidx(k)}(:,:,frame)) / mx;
            shft{k} = obj.hdata.seq(sidx(k)).TranslationRC;
            I{k} = imtranslate(I{k},shft{k});
        end
    end

    % issue warning for strange shifts
    for k = 1:3
        if ~isequaln(shft{1,k},shft{2,k})
            warning(sprintf('%s:translationsWarning',mfilename),...
                'Magnitude/Phase translations do not match...');
            break
        end
    end

    % determine multi-type, indicating we should swap and
    % negate the image display

    % swap imagery
    if group.SwapFlag
        I(:,[1 2]) = I(:,[2 1]);
    end

    % negate imagery
    for k = 1:3
        if neg(k)
            I{2,k} = 1-I{2,k};
        end
    end

    % update image
    for k = 1:6
        set(obj.him(k),'cdata',I{k});
    end

    if ~isempty(obj.ROIIndex)
        obj.hroi.ROIFrame = frame;
    end

    obj.frame = frame;
end

function val = checkROIEdit(obj,val)

    if ~ischar(val) || ~any(strcmpi(val,{'on','off'}))
        errstr = 'Invalid ROIEdit; valid strings are [on|off]';
    end

    if exist('errstr','var')
        error(sprintf('%s:invalidROIEdit',mfilename),errstr);
    end
end

function setSliceViewerFcn(obj,val)

    if ~isempty(val)
        if ~isa(val, 'SliceViewer')
            error(sprintf('%s:invalidSliceViewer',mfilename),...
                'Invalid Slice Viewer Specification.');
        end
    end

    % reset the current slice viewer to its natural state
    if ~isempty(obj.hslice) && ~isempty(obj.hdata)
        obj.hslice.SequenceVisible(:) = true;
        obj.hslice.SequenceHighlight(:) = false;
    end

    % set internal object
    obj.hslice = val;

    % assume control of a new slice viewer
    if ~isempty(obj.hslice) && ~isempty(obj.hdata)
        % gather all DENSE sequences
        tf = cellfun(@(id)~isempty(id) && any(strwcmpi(id,{'mag*','pha*'})),...
            {obj.hdata.seq.DENSEid});

        obj.hslice.SequenceVisible(:) = tf;

        sidx = obj.SequenceIndex;
        tf = obj.hslice.SequenceHighlight;
        tf(:)    = false;
        tf(sidx) = true;
        obj.hslice.SequenceHighlight = tf;
    end
end

function setArialViewerFcn(obj,val)

    if ~isempty(val)
        if ~isa(val, 'ArialViewer')
            error(sprintf('%s:invalidArialViewer',mfilename),...
                'Invalid Arial Viewer Specification.');
        end
    end

    % reset the current slice viewer to its natural state
    if ~isempty(obj.harial)
        obj.harial.SequenceIndex = [];
        obj.harial.Limits = [0 1 0 1];
    end

    % set internal object
    obj.harial = val;

    % assume control of a new slice viewer
    if ~isempty(obj.harial)

        if isempty(obj.hdata) || isempty(obj.dnsidx)
            obj.harial.SequenceIndex = [];
            obj.harial.Limits = [0 1 0 1];
        else
            didx = obj.dnsidx;
            sidx = obj.hdata.dns(didx).MagIndex;
            obj.harial.SequenceIndex = sidx;
            obj.harial.Limits = obj.displaydata(didx).CurrentXYLim;
        end
    end
end

function hdns_menu_Callback(obj)
    if interrupt(obj.hdns_menu), return; end

    didx = get(obj.hdns_menu,'Value');

    if obj.dnsidx ~= didx
        obj.dnsidx = didx;
        obj.roiuid = obj.displaydata(didx).CurrentROIUID;
        obj.frame  = 1;
        redraw(obj);
    end
end

function hroi_menu_Callback(obj)
    if interrupt(obj.hroi_menu), return; end

    prop = get(obj.hroi_menu,{'userdata','value'});
    ridx = prop{1}(prop{2});

    if ridx == 0
        obj.roiuid = [];
    else
        obj.roiuid = obj.hdata.roi(ridx).UID;
    end

    redraw(obj)
end

function tf = interrupt(h)
    uid = get(h,'Value');
    pause(eps);
    if uid ~= get(h,'Value')
        tf = true;
    else
        tf = false;
    end
end

function suspendFcn(obj)

    % check isSuspended
    if obj.isSuspended, return; end

    % cache current object states
    obj.statecache = struct(...
        'ROIVisible',       obj.hroi.Visible);

    % deactivate objects
%     obj.hroi.Visible = 'off';
end

function restoreFcn(obj)

    % check isSuspended
    if ~obj.isSuspended, return; end

    if ~isempty(obj.statecache)
%         obj.hroi.Visible = obj.statecache.ROIVisible;
    end
end

function hdns_button_Callback(obj)
    obj.hdata.editDENSE;
end

function hreg_button_Callback(obj)
    obj.hdata.regDENSE(obj.DENSEIndex);
    redraw(obj);
end

function hroi_button_Callback(obj)

    ridx = obj.hdata.createROI(obj.SequenceIndex(1));
    if ~isempty(ridx)
        uid = obj.hdata.roi(ridx).UID;
        obj.roiuid = uid;
        obj.displaydata(obj.dnsidx).CurrentROIUID = uid;
%         obj.frame
        redraw(obj);
    end
end

function contextCallbackFcn(obj)

    % context menu children
    hchild = allchild(obj.hcontext_control);
    delete(hchild);

    % determine calling object
    h = gco;

    % rename sequence
    if isequal(h,obj.hdns_menu) && strcmpi(get(h,'Enable'),'on')

        uimenu('parent',obj.hcontext_control,...
            'Label','Rename DENSE',...
            'Callback',@(varargin)renamedns());

    % rename ROI
    elseif isequal(h,obj.hroi_menu) && ...
       strcmpi(get(h,'Enable'),'on') && get(h,'Value') ~= 1

        uimenu('parent',obj.hcontext_control,...
            'Label','Rename ROI',...
            'Callback',@(varargin)renameroi());
        uimenu('parent',obj.hcontext_control,...
            'Label','Delete ROI',...
            'Callback',@(varargin)deleteroi());
    end

    drawnow update

    function renamedns()
        didx = get(obj.hdns_menu,'value');
        obj.hdata.renameDENSE(didx);
    end

    function renameroi()
        prop = get(obj.hroi_menu,{'userdata','value'});
        ridx = prop{1}(prop{2});
        obj.hdata.renameROI(ridx);
    end

    function deleteroi()
        prop = get(obj.hroi_menu,{'userdata','value'});
        ridx = prop{1}(prop{2});
        obj.hdata.deleteROI(ridx);
    end
end

function path = exportROIFcn(obj,startpath)

    % check for valid startpath
    if nargin < 2 || ~ischar(startpath) || ~isdir(startpath)
        startpath = pwd;
    end

    % indices
    ridx  = obj.ROIIndex;
    sidx  = obj.SequenceIndex;
    sidx0 = min(sidx);

    % check current study UID against saved application data
    % for a new study, set the initial values
    % otherwise we'll keep the last known values, saving the user from
    % re-entering some information (like series range & family name)
    uid = obj.hdata.seq(sidx0).StudyInstanceUID;
    api = obj.exportroiapi;

    if isempty(api) || ~isequal(uid,api.StudyInstanceUID);
        api = struct('ExportPath',startpath);
    end

    output = obj.hdata.exportROI(ridx,api);
    if isempty(output)
        path = [];
        return;
    end

    obj.exportroiapi = struct;
    tags = {'ExportPath','LastName','SeriesRange'};
    for ti = 1:numel(tags)
        obj.exportroiapi.(tags{ti}) = output.(tags{ti});
    end
    obj.exportroiapi.StudyInstanceUID = uid;
    path = output.ExportPath;
end

