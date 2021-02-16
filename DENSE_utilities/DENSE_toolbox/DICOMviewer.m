% Class definition DICOMviewer

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

classdef DICOMviewer < DataViewer


    properties (Dependent=true)
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

    properties (Hidden)
        hroi
    end

    properties (SetAccess='private',GetAccess='private')

        % current DENSEdata object indices
        seqidx = [];
        roiuid = [];
        frame  = 1;

        % value-to-index mappings
        slicetoseq = [];
        seqtoroi   = [];

        % sequence display
        hsubpanel
        hax
        him

        % DICOM header display
        htable

        % listeners
        hlisten_suspend
        hlisten_restore

        % useful sequence information
        displaydata


        constraintFcn

        % controls
        hslice_text
        hslice_menu
        hseq_text
        hseq_menu
        hroi_text
        hroi_menu
        hroi_button
        hctrl_context

        % other objects
        hslice = [];
        harial = [];

        % list name buffers
        seqbuf
        roibuf


    end


    methods
        function obj = DICOMviewer(varargin)
            options = struct([]);
            obj = obj@DataViewer(options,varargin{:});
            obj = DICOMviewerFcn(obj);
            obj.redrawenable = true;
            redraw(obj);
        end

        function delete(obj)
            deleteFcn(obj);
        end


        function redraw(obj)
            redraw@DataViewer(obj);
            redrawFcn(obj);
        end


        function val = get.SequenceIndex(obj)
            val = obj.seqidx;
        end
        function val = get.ROIIndex(obj)
            val = obj.hroi.ROIIndex;
        end
        function val = get.Frame(obj)
            if isempty(obj.seqidx)
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

        function suspend(obj)
            suspendFcn(obj);
            suspend@DataViewer(obj);
        end

        function restore(obj)
            restoreFcn(obj);
            restore@DataViewer(obj);
        end

        function file = exportImage(obj,varargin)
            obj.exportrect = plotboxpos(obj.hax,true) + [-1 -1 0 0];
            file = exportImage@DataViewer(obj,varargin{:});
        end

        function file = exportVideo(obj,varargin)
            obj.exportrect = plotboxpos(obj.hax,true) + [-1 -1 0 0];
            file = exportVideo@DataViewer(obj,varargin{:});
        end

    end

    methods (Access=protected)
        function playback(obj)
            playbackFcn(obj);
        end

        function reset(obj)
            resetFcn(obj);
        end

        function dataevent(obj,evnt)
            dataeventFcn(obj,evnt);
        end

        function setZoomPanRot(obj)
            setZoomPanRotFcn(obj);
        end

        function contextCallback(obj)
            contextCallbackFcn(obj);
        end

        function resize(obj)
            resize@DataViewer(obj);
            resizeFcn(obj)
        end

    end

end




%% CONSTRUCTOR

function obj = DICOMviewerFcn(obj)

    bgclr = [236 233 216]/255;
    hlclr  = [78 101 148]/255;
    edgeclr = hlclr;
    axesclr = [.5 .5 .5];

    % create object hierarchy
    obj.htable    = uitable('parent',obj.hdisplay);
    obj.hsubpanel = uipanel('parent',obj.hdisplay);
    obj.hax       = axes('parent',obj.hsubpanel);
    obj.him       = imshow(rand(10),'parent',obj.hax,'init','fit');
    obj.hroi      = roitool(obj.hdata,obj.hax);

    hctrl = obj.hcontrol;
    obj.hslice_text = textfig(hctrl);
    obj.hslice_menu = uicontrol('parent',hctrl,'style','popupmenu');
    obj.hseq_text   = textfig(hctrl);
    obj.hseq_menu   = uicontrol('parent',hctrl,'style','popupmenu');
    obj.hroi_text   = textfig(hctrl);
    obj.hroi_menu   = uicontrol('parent',hctrl,'style','popupmenu');
    obj.hroi_button = uicontrol('parent',hctrl,'style','pushbutton');

    % set object properties
    set(obj.htable,...
        'units',            'pixels',....
        'ColumnName',       {'Property','Value'},...
        'Data',             cell(50,2),...
        'ColumnWidth',      {150 300},...
        'RowName',          [],...
        'Enable',           'off',...
        'ForegroundColor',  [222 125 0]/255);

    set(obj.hsubpanel,...
        'units',            'pixels',....
        'BorderType',       'line',...
        'BackgroundColor',  [0 0 0],...
        'HighlightColor',   hlclr);

    set(obj.hax,...
        'color',            axesclr,...
        'units',            'pixels',...
        'clim',             [0 1],...
        'box',              'on',...
        'visible',          'on',...
        'xtick',            [],...
        'ytick',            [],...
        'xcolor',           edgeclr,...
        'ycolor',           edgeclr,...
        'HitTest',          'off',...
        'HandleVisibility', 'off');

    set(obj.him,...
        'Visible',          'off',...
        'HitTest',          'off');

    obj.hplaybar.Parent = obj.hsubpanel;

    h = [obj.hslice_text,obj.hseq_text,obj.hroi_text];
    str = {' Select Slice:',' Select Sequence:',' Select ROI:'};
    set(h(:),...
        {'string'},             str(:),...
        'HorizontalAlignment',  'left',...
        'FontWeight',           'bold',...
        'VerticalAlignment',    'bottom',...
        'Fontsize',             8,...
        'units',                'pixels');

    h = [obj.hslice_menu,obj.hseq_menu,obj.hroi_menu];
    menu = {[],obj.hcontext_control,obj.hcontext_control};
    set(h(:),...
        'string',           'No Data...',...
        'BackgroundColor',  'w',...
        'Fontname',         'fixedwidth',...
        'Enable',           'off',...
        {'UIContextMenu'},  menu(:),...
        {'Callback'},       {@(varargin)hslice_menu_Callback(obj);...
                             @(varargin)hseq_menu_Callback(obj);...
                             @(varargin)hroi_menu_Callback(obj)});

    set(obj.hroi_button,...
        'string',           'New ROI',...
        'Enable',           'off',...
        'BackgroundColor',  'w',...
        'Callback',         @(varargin)hroi_button_Callback(obj));

    % ROI suspend/restore listeners
    obj.hlisten_suspend = addlistener(obj.hroi,...
        'Suspend',@(varargin)suspend(obj));
    obj.hlisten_restore = addlistener(obj.hroi,...
        'Restore',@(varargin)restore(obj));

    % initialize zoom/pan/rot
    setZoomPanRot(obj);

    % ready the object
    if isempty(obj.hdata)
        reset(obj);
    else
        loaddataFcn(obj);
    end

end




function setZoomPanRotFcn(obj)

    % do not complete until axes have been created
    if isempty(obj.hax), return; end

    % zoom behavior callback
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

end


function zoompan(obj,hax)
    if isequal(hax,obj.hax) && ~isempty(obj.seqidx)
        lim = axis(obj.hax);
        obj.displaydata(obj.seqidx).CurrentXYLim = lim;
        if ~isempty(obj.harial)
            obj.harial.Limits = lim;
        end
    end
end

function contrastfcn(obj,hax)
    if isequal(hax,obj.hax) && ~isempty(obj.seqidx)
        clim = get(obj.hax,'clim');
        obj.displaydata(obj.seqidx).CurrentCLim = clim;
    end
end




%% DESTRUCTOR

function deleteFcn(obj)

    % ensure children objects/listeners are deleted
    tags = {'hlisten_suspend','hlisten_restore','hroi'};

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



%% RESET & CLEAR DISPLAY

function resetFcn(obj)

    % empty display indices
    obj.seqidx      = [];
    obj.roiuid      = [];
    obj.frame       = 1;
    obj.displaydata = [];

    % clear/disable controls
    h = [obj.hslice_menu,obj.hseq_menu,obj.hroi_menu];
    set(h,...
        'String',   'No Data...',...
        'Enable',   'off',...
        'UserData', [],...
        'Value',    1);
    set(obj.hroi_button,...
        'Enable',   'off');


    % reset the display
    resetdisp(obj);

end


function resetdisp(obj)

    % stop the playbar
    obj.hlisten_playbar.Enabled = false;
    obj.hplaybar.Max = 0;

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

    % disallow export
    obj.isAllowExportImage = false;
    obj.isAllowExportVideo = false;

    % clear table
    set(obj.htable,...
        'Data',     cell(50,2),...
        'enable',   'off');

    % reset/disable ROI tool
    reset(obj.hroi);
    obj.ROIEdit = 'off';

end




function dataeventFcn(obj,evnt)

    switch lower(evnt.Action)
        case 'load'
            loaddataFcn(obj);
        case {'rename','new','delete'}
            redraw(obj);
    end

end



function loaddataFcn(obj)

    % clear the display
    reset(obj);

    % make sure the DENSEdata is not empty
    if isempty(obj.hdata), return; end


    % initial display parameters
    data = obj.hdata.getDisplayData;

    % gather xy display limits
    N = numel(obj.hdata.img);
    xylim = repmat({NaN(1,4)},[N,1]);
    for k = 1:N
        if ~any(isnan(data(k).ImageSize))
            Isz = data(k).ImageSize;
            xylim{k} = [0 Isz(2) 0 Isz(1)] + 0.5;
        end
    end

    % add fields to display parameters
    [data.CurrentCLim]   = deal([0 1]);
    [data.CurrentXYLim]  = deal(xylim{:});
    [data.CurrentROIUID] = deal([]);

    % save to object
    obj.displaydata = data;


    % populate DICOM slice chooser
    % we only need perform this action once, as the sequences will never
    % change (nor will the slice "names")

    planeid = [obj.hdata.seq.planeid];

    uid = unique(planeid);
    uid = uid(~isnan(uid));
    N = numel(uid);

    strs = cell(N+1,1);
    idx  = cell(N+1,1);
    obj.slicetoseq = false(N+1,numel(obj.hdata.seq));

    strs{1} = 'All slices';
    idx{1}  = 1:numel(obj.hdata.seq);
    obj.slicetoseq(1,:) = true;

    for k = 1:N
        obj.slicetoseq(k+1,:) = (uid(k) == planeid);

        idx{k+1} = find(obj.slicetoseq(k+1,:));
        str = sprintf('%d|',idx{k+1});
        strs{k+1} = sprintf('%2d: [%s]',k,str(1:end-1));
    end
    set(obj.hslice_menu,'String',strs,...
        'UserData',idx,'Value',1,'Enable','on');

    % display the first sequence
    obj.seqidx = 1;
    obj.roiuid = [];
    obj.frame  = 1;
    redraw(obj);

end







function redrawFcn(obj)

    % test for enabled redraw
    if ~obj.redrawenable, return; end

    % resize the child object
    resizeFcn(obj);

    % check for no data
    if isempty(obj.hdata)
       reset(obj);
       return
    end


    % sequence name buffer, containing all sequence display names
    if ~isempty(obj.hdata.seq)
        N = numel(obj.hdata.seq);
        obj.seqbuf = cellfun(...
            @(n,sn,sd)sprintf('%2d: (SN %2d) %s',n,sn,sd),...
                num2cell(1:N)',...
                {obj.hdata.seq.SeriesNumber}',...
                {obj.hdata.seq.DENSEanalysisName}',...
            'uniformoutput',0);
    else
        obj.seqbuf = {};
    end

    % ROI name buffer, containing all ROI display names
    if ~isempty(obj.hdata.roi)
        obj.roibuf = {obj.hdata.roi.Name};
    else
        obj.roibuf = {};
    end


    % gather the available Sequence options & repopulate the sequence menu
    val = get(obj.hslice_menu,'Value');
    idx = find(obj.slicetoseq(val,:));
    set(obj.hseq_menu,'String',obj.seqbuf(idx));

    % if we can locate the current sequence index within the available
    % options, then keep that index and update the sequence menu value.
    % Otherwise, set the sequence index to the first available sequence.
    if isempty(obj.seqidx) || ~any(idx == obj.seqidx)
        val = 1;
        obj.seqidx = idx(1);
        obj.roiuid = obj.displaydata(idx(1)).CurrentROIUID;
        obj.frame  = 1;
    else
        val = find(idx==obj.seqidx,1,'first');
    end

    set(obj.hseq_menu,...
        'String',   obj.seqbuf(idx),...
        'Value',    val,...
        'UserData', idx,...
        'Enable',   'on');


    % if the sequence is not displayable, clear the display,
    % disable ROI options, and return
    if isempty(obj.hdata.img{obj.seqidx})
        resetdisp(obj);
        set([obj.hroi_menu,obj.hroi_button],'enable','off');
        set(obj.hroi_menu,'String','No Data...',...
            'userdata',[],'value',1);
        return;
    end

    % current sequence index
    sidx = obj.seqidx;



    % gather available ROI options (including "none")
    allridx = findROI(obj.hdata,sidx);
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



    % load info to table
    buf = DICOMtablestr(obj.hdata.seq(sidx));
    set(obj.htable,'Data',buf,'enable','on');

    % set up axes/image
    Isz = obj.displaydata(sidx).ImageSize;
    set(obj.him,'visible','on');
    set(obj.hax,...
        'clim',              [0 1],...
        'xlim',              [0.5 Isz(2)+0.5],...
        'ylim',              [0.5 Isz(1)+0.5],...
        'hittest',           'on',...
        'handlevisibility', 'on');

    % reset zoom/clim level to current level
    zoom(obj.hax,'reset');
    fix(obj.hcontrast,obj.hax);


    % display ROI of interest
    if ridx==0
        reset(obj.hroi);
    else
        obj.hroi.SequenceIndex = sidx;
        obj.hroi.ROIIndex = ridx;
        obj.hroi.ROIFrame = obj.frame;
        obj.hroi.Visible = 'on';
        if ~isempty(obj.hroi.ROIIndex)
            obj.hroi.Enable = obj.ROIEdit;
        end
    end

    % update the cLine position constraint function
    fcn = clineConstrainToRectFcn(obj.hroi.cLine,...
        get(obj.hax,'XLim'),get(obj.hax,'YLim'));
    obj.hroi.PositionConstraintFcn = fcn;

    % update limits to last displayed
    xylim = obj.displaydata(sidx).CurrentXYLim;
    clim  = obj.displaydata(sidx).CurrentCLim;
    set(obj.hax,'xlim',xylim(1:2),'ylim',xylim(3:4),'clim',clim);

    % adjust aspect ratio (for non-square pixels)
    px = obj.displaydata(sidx).PixelSpacing;
    dar = [1 px(2)/px(1) 1];
    daspect(obj.hax,dar);

    % update Slice/Arial Viewers
    if ~isempty(obj.hslice)
        obj.hslice.SequenceVisible(:)      = true;
        obj.hslice.SequenceHighlight(:)    = false;
        obj.hslice.SequenceHighlight(sidx) = true;
    end
    if ~isempty(obj.harial)
        obj.harial.SequenceIndex = obj.seqidx;
        obj.harial.Limits = xylim;
    end

    % enable playbar
    obj.hplaybar.Max = obj.displaydata(sidx).NumberOfFrames;
    obj.hplaybar.Value = obj.frame;
    obj.hlisten_playbar.Enabled = true;

    % update the image display
    playback(obj);

    % save the current ROI uid
    obj.displaydata(sidx).CurrentROIUID = obj.roiuid;

    % determine export options
    obj.isAllowExportImage = true;
    if obj.hplaybar.Max > 1
        obj.isAllowExportVideo = true;
    else
        obj.isAllowExportVideo = false;
    end


end









function resizeFcn(obj)

    % test for enabled redraw
    if ~obj.redrawenable, return; end

    % display variables (all in pixels)
    minwh  = [700 300];    % minimum allowable panel size
    margin = 5;            % panel external margins
    axesmargin = 5;        % axes internal margin
%     plsz   = [250 30];

    % determine available display position
    panelpos = getpixelposition(obj.hdisplay);
    sz = max(panelpos(3:4),minwh);

    pos = [1,1+panelpos(4)-sz(2),sz];

    % object width & height
    width  = (pos(3)-3*margin)/2;
    height = pos(4)-2*margin;

    % place the DICOM axes panel
    p = [pos(1)+margin,pos(2)+margin,width,height];
    setpixelposition(obj.hsubpanel,p);

    % place the DICOM header table
    p = [pos(1)+width+2*margin,pos(2)+margin,width,height];
    setpixelposition(obj.htable,p);
    cols = get(obj.htable,'columnwidth');
    if iscell(cols) && all(cellfun(@isnumeric,cols))
        cols{2} = p(3)-cols{1}-2;
        set(obj.htable,'columnwidth',cols);
    end

    % place the axes & playbar within axes panel
    % note we've tweaked the axes display to ensure proper margins
    pos = getpixelposition(obj.hplaybar);
    plsz = pos(3:4);

    p = [(width+1)/2 - (plsz(1)+1)/2, 1+axesmargin, plsz];
    setpixelposition(obj.hplaybar,p);

    p = [1+axesmargin,2*axesmargin+plsz(2)+2,...
       width-2*axesmargin-3.5,height-3*axesmargin-plsz(2)-2];
    setpixelposition(obj.hax,p);


    % control panel position
    panelpos = getpixelposition(obj.hcontrol);

    % control panel display parameters
    yshft  = [15 23 15 23 15 23 23];
    height = [NaN 21 NaN 21 NaN 21 21];

    % determine pushbutton parameters
    buttonwidth = 100;
    wpb = min(buttonwidth,panelpos(3)-2*margin);
    xpb = (panelpos(3)/2) - (wpb/2) + 1;


    h = [obj.hslice_text,   obj.hslice_menu,...
         obj.hseq_text,     obj.hseq_menu,...
         obj.hroi_text,     obj.hroi_menu,...
         obj.hroi_button];
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

    idx = obj.seqidx;
    if isempty(idx) || isempty(obj.hdata.img(idx))
        return;
    end

    frame = obj.hplaybar.Value;

    I  = double(obj.hdata.img{idx}(:,:,frame));
    mx = obj.displaydata(idx).ILim(frame,2);

    I = imtranslate(I,obj.hdata.seq(idx).TranslationRC);
    set(obj.him,'cdata',I/mx);
%     set(obj.hax,'clim',[0 1]);

%     set(obj.him,'cdata',obj.hdata.img{idx}(:,:,frame));
%     set(obj.hax,'clim',obj.displaydata(idx).CurrentILim(frame,:));

    if ~isempty(obj.ROIIndex)
        obj.hroi.ROIFrame = frame;
    end

    obj.frame = frame;

    drawnow update


end




function val = checkROIEdit(obj,val)
    validate_on_off(val, sprintf('%s:invalidROIEdit', mfilename))
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
        obj.hslice.SequenceVisible(:) = true;
        tf = obj.hslice.SequenceHighlight(:);
        tf(:) = false;
        tf(obj.seqidx) = true;
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
        if isempty(obj.hdata)
            obj.harial.SequenceIndex = [];
        else
            obj.harial.SequenceIndex = obj.seqidx;
            obj.harial.Limits = obj.displaydata(obj.seqidx).CurrentXYLim;
        end
    end

end


function suspendFcn(obj)

    % check isSuspended
    if obj.isSuspended, return; end

    % cache current object states
    obj.statecache = struct(...
        'TableEnable',      get(obj.htable,'Enable'),...
        'ROIVisible',       obj.hroi.Visible);

    % deactivate objects
    set(obj.htable,'Enable','off');
%     obj.hroi.Visible = 'off';

end


function restoreFcn(obj)

    % check isSuspended
    if ~obj.isSuspended, return; end

    % restore objects to cached state
    if ~isempty(obj.statecache)
        set(obj.htable,'Enable',obj.statecache.TableEnable);
%         obj.hroi.Visible = obj.statecache.ROIVisible;
    end

end



function hslice_menu_Callback(obj)
    if interrupt(obj.hslice_menu), return; end

    redraw(obj);
%     return
%
%     prop = get(obj.hslice_menu,{'userdata','value'});
%     idx = prop{1}{prop{2}};
%     set(obj.hseq_menu,...
%         'string',   obj.seqbuf(idx),...
%         'userdata', idx,...
%         'Value',    1);
%
%     tf = (idx == obj.SequenceIndex);
%     if any(tf)
%         val = find(tf,1,'first');
%         set(obj.hseq_menu,'Value',val);
%     else
%         obj.SequenceIndex = idx(1);
%     end
%

end

function hseq_menu_Callback(obj)
    if interrupt(obj.hseq_menu), return; end

    prop = get(obj.hseq_menu,{'userdata','value'});
    sidx = prop{1}(prop{2});

    if obj.seqidx ~= sidx
        obj.seqidx = sidx;
        obj.roiuid = obj.displaydata(sidx).CurrentROIUID;
        obj.frame  = 1;
        redraw(obj);
    end
%
%     obj.SequenceIndex = sidx;
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
    redraw(obj);

%     obj.ROIIndex = ridx;

end


function tf = interrupt(h)
    uid = get(h,'Value');
    pause(.01);
    if uid ~= get(h,'Value')
        tf = true;
    else
        tf = false;
    end
end


function hroi_button_Callback(obj)

    ridx = obj.hdata.createROI(obj.seqidx);
%     obj.hroi.SequenceIndex = obj.seqidx;
%     obj.hroi.createROI;
    if ~isempty(ridx)
        obj.roiuid = obj.hdata.roi(ridx).UID;
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
    if isequal(h,obj.hseq_menu) && strcmpi(get(h,'Enable'),'on')

        uimenu('parent',obj.hcontext_control,...
            'Label','Rename Sequence',...
            'Callback',@(varargin)renameseq());

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

    function renameseq()
        prop = get(obj.hseq_menu,{'userdata','value'});
        sidx = prop{1}(prop{2});
        obj.hdata.renameSequence(sidx);
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

