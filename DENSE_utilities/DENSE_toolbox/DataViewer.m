% Class definition DataViewer

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

classdef DataViewer < handle

    properties (Dependent=true)
        DisplayParent
        ControlParent
    end

    properties (SetAccess='protected')
        isSuspended = false
        isAllowExportVideo = false
        isAllowExportImage = false
    end


    properties (Abstract=true,SetAccess='protected',GetAccess='protected')

    end

    % options
    properties (SetAccess='private',GetAccess='protected')
        ControlVisible = 'on';
        PlaybarVisible = 'on';
    end


    properties (SetAccess='protected',GetAccess='protected')

        % parent handles (figures or uipanels)
        hparent_display
        hparent_control

        % figure ancestors
        hfigure_display
        hfigure_control

        % DENSEdata object reference
        hdata

        % invisible container panels
        hdisplay
        hcontrol

        % generic playbar
        hplaybar

        % available context menu
        hcontext_control

        % listeners
        hlisten_delete
        hlisten_redraw
        hlisten_playbar
        hlisten_parent
        hlisten_data

        % zoom/pan/rotate objects for display panel figure
        hzoom
        hpan
        hrot
        hcontrast
        iptinfo = [];

        % default control panel width (pixels)
        ctrlwidth = 200;

        % cached sizes
        ctrlsz_cache = [NaN NaN];
        dispsz_cache = [NaN NaN];

        statecache = [];

        redrawenable = false;

        eximageopts = [];
        exvideoopts = [];
        exportrect  = [];
        exportaxes  = false;


    end


    events
        Suspend
        Restore
    end


    methods
        function obj = DataViewer(varargin)
            obj = DataViewerFcn(obj,varargin{:});
        end

        function delete(obj)
            deleteFcn(obj);
        end

        function redraw(obj)
            resize(obj);
        end

        function val = get.DisplayParent(obj)
            val = obj.hparent_display;
        end

        function val = get.ControlParent(obj)
            if isequal(obj.ControlVisible,'off')
                val = [];
            else
                val = obj.hparent_control;
            end
        end


        function set.DisplayParent(obj,hdisp)
            if isequal(obj.ControlVisible,'off')
                setParentFcn(obj,hdisp,hdisp);
            else
                setParentFcn(obj,hdisp,[]);
            end
            redraw(obj);
        end

        function set.ControlParent(obj,hctrl)
            setParentFcn(obj,[],hctrl);
            redraw(obj);
        end


%         function set.ControlVisible(obj,val)
%            obj.ControlVisible = checkString(val,...
%                {'on','off'},'ControlVisible');
% %            set(obj.hcontrol,'Visible',obj.ControlVisible);
% %            redraw(obj);
%         end
%
%         function set.PlaybarVisible(obj,val)
%             obj.PlaybarVisible = checkString(val,...
%                {'on','off'},'PlaybarVisible');
% %             obj.hplaybar.Visible = obj.PlaybarVisible;
% %             redraw(obj);
%         end

        function suspend(obj)
            suspendFcn(obj);
        end

        function restore(obj)
            restoreFcn(obj);
        end

        function file = exportImage(obj,varargin)
            file = exportFcn(obj,'image',varargin{:});
        end

        function file = exportVideo(obj,varargin)
            file = exportFcn(obj,'video',varargin{:});
        end
    end


    methods (Access=protected)

        function playback(obj)
            % function prototype
        end

        function setZoomPanRot(obj)
            % function prototype
        end

        function dataevent(obj,evnt)
            % function prototype
        end

        function contextCallback(obj)

        end

        function resize(obj)
            resizeFcn(obj);
        end

    end

%
%     methods (Abstract)
%
%         suspend(obj)
%         restore(obj)
%
%     end
%
%     methods (Abstract,Access='protected')
%         playback(obj)
%         zoompan(obj)
%         resize(obj)
%
%     end
%
%     methods (Access='protected')
%
%         function createROItool(obj)
%             createROItoolFcn(obj);
%         end
%
%         function newData(obj)
%             newDataFcn(obj);
%         end
%
%     end


end




%% CONSTRUCTOR

function obj = DataViewerFcn(obj,options,hdata,varargin)

    % parse options
    % note we do NOT error check these options
    if ~isempty(options)

        if ~isstruct(options)
            error(sprintf('%s:invalidOptions',mfilename),...
                'Invalid options structure.');
        end

        tags = {'ControlVisible','PlaybarVisible'};
        for ti = 1:numel(tags)
            if isfield(options,tags{ti})
                obj.(tags{ti}) = options.(tags{ti});
            end
        end
    end


    % test data
    if ~isa(hdata, 'DENSEdata')
        error(sprintf('%s:invalidDENSEdata',mfilename),...
            'First input must be DENSEdata object.');
    end

    % save data reference
    obj.hdata = hdata;

    % test/set parent objects & listeners
    setParentFcn(obj,varargin{:});

    % display panel
    if isprop(obj.hparent_display,'Color')
        clr = get(obj.hparent_display,'Color');
    else
        clr = get(obj.hparent_display,'BackgroundColor');
    end

    obj.hdisplay = uipanel(...
        'parent',           obj.hparent_display,...
        'units',            'normalized',....
        'position',         [0 0 1 1],...
        'BorderType',       'none',...
        'BackgroundColor',  clr);

    % control panel
    % for ease of coding, we always create the panel
    % just sometimes its not visible
    if isequal(obj.ControlVisible,'on')
        vis = 'on';
    else
        vis = 'off';
    end

    if isprop(obj.hparent_control,'Color')
        clr = get(obj.hparent_control,'Color');
    else
        clr = get(obj.hparent_control,'BackgroundColor');
    end

    obj.hcontrol = uipanel(...
        'parent',           obj.hparent_control,...
        'units',            'normalized',....
        'position',         [0 0 1 1],...
        'BorderType',       'none',...
        'Visible',          vis,...
        'BackgroundColor',  clr);

    % playbar & listeners
    if isequal(obj.PlaybarVisible,'on')
        obj.hplaybar = playbar(obj.hdisplay);
        obj.hlisten_playbar = addlistener(obj.hplaybar,...
            'NewValue',@(varargin)playback(obj));
        obj.hlisten_playbar.Enabled = false;
    end

    % control context menu
    obj.hcontext_control = uicontextmenu(...
        'parent',   obj.hfigure_control,...
        'tag',      sprintf('%s context',mfilename),...
        'Callback', @(varargin)contextCallback(obj));


    % DENSEdata listeners - if the DENSEdata object signals an event,
    % we need to respond accordingly.
    obj.hlisten_data = addlistener(obj.hdata,...
        'NewState',    @(src,evnt)dataevent(obj,evnt));
end



%% DESTRUCTOR

function deleteFcn(obj)

    % objects to delete
    tags = {'hlisten_delete','hlisten_redraw','hlisten_playbar',...
        'hlisten_data','hplaybar','hdisplay','hcontrol','hcontext_control'};

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

    % remove exisiting callbacks from the zoom/pan/rot objects
    if ~isempty(obj.iptinfo)
        for k = 1:numel(obj.iptinfo)
            h = obj.iptinfo(k).Object;
            if (isobject(h) && isvalid(h)) || ishandle(h)
                iptremovecallback_mod(...
                    h,obj.iptinfo(k).Callback,obj.iptinfo(k).id);
            end
        end
    end

    % report
%     fprintf('delete %s\n',mfilename);

end




%% SET PARENT
% The user is able to move the object to different figures or uipanels by
% changing the 'DisplayParent' and 'ControlParent' properties.
% We must ensure that the new parents are valid, as well as create a
% several listeners waiting for changes in the parent as well as parent
% deletions.

function setParentFcn(obj,hdisp,hctrl)
% obj........object
% hdisp......candidate parent figure/uipanel for display panel
% hctrl......candidate parent figure/uipanel for control panel

    % default inputs
    if nargin == 1
        hdisp = gcf;
        hctrl = gcf;
    elseif nargin == 2
        hctrl = hdisp;
    end

    % check for empty parents
    if isempty(hdisp), hdisp = obj.hparent_display; end
    if isempty(hctrl), hctrl = obj.hparent_control; end

    % if the control panel is not "visible", it always needs to follow the
    % display panel
    if isequal(obj.ControlVisible,'off') && ...
       ~isequal(hctrl,hdisp)
        error(sprintf('%s:invalidParent',mfilename),'%s',...
            'Cannot change this objects ControlParent.');
    end

    % check for valid parent
    if ~isscalar(hdisp) || ...
       ~(ishghandle(hdisp, 'figure') || ishghandle(hdisp, 'uipanel')) || ...
       ~isscalar(hctrl) || ...
       ~(ishghandle(hctrl, 'figure') || ishghandle(hctrl, 'uipanel'))
        error(sprintf('%s:invalidParent',mfilename),'%s',...
            'Parent objects must be figures or uipanels.');
    end

    % new figure handles
    hfig_disp = ancestor(hdisp,'figure');
    hfig_ctrl = ancestor(hctrl,'figure');

    % reject changes in the figure
    if (~isempty(obj.hfigure_display) && ...
        hfig_disp ~= obj.hfigure_display) || ...
       (~isempty(obj.hfigure_control) && ...
        hfig_ctrl ~= obj.hfigure_control)
        error(sprintf('%s:invalidParent',mfilename),'%s',...
            'Cannot change the figure ancestor!');
    end


    % REMOVE EXISTING OBJECTS----------------------------------------------

    % delete current parent listeners
    if ~isempty(obj.hlisten_delete)
        delete(obj.hlisten_delete);
        obj.hlisten_delete = [];
    end
    if ~isempty(obj.hlisten_redraw)
        delete(obj.hlisten_redraw);
        obj.hlisten_redraw = [];
    end
    if ~isempty(obj.hlisten_parent)
        delete(obj.hlisten_parent);
        obj.hlisten_parent = [];
    end

    % remove exisiting callbacks from zoom/pan/rot objects
    if ~isempty(obj.iptinfo)
        for k = 1:numel(obj.iptinfo)
            iptremovecallback_mod(...
                obj.iptinfo(k).Object,...
                obj.iptinfo(k).Callback,...
                obj.iptinfo(k).id);
        end
        obj.iptinfo = [];
    end


    % OBJECT UPDATE--------------------------------------------------------

    % graphics handles in hierarchy from (hparent_display) to (hfig_disp)
    % and from (hparent_control) to (hfig_ctrl), not including the actual
    % figure obejcts
    hhier = [hierarchy(hdisp,'figure'), hierarchy(hctrl,'figure')];
    hhier = setdiff(hhier,[hfig_disp,hfig_ctrl]);


    % save parents to object
    obj.hparent_display = hdisp;
    obj.hparent_control = hctrl;
    obj.hfigure_display = hfig_disp;
    obj.hfigure_control = hfig_ctrl;

    % move children to new parents (if children exist)
    if ~isempty(obj.hdisplay) && ishandle(obj.hdisplay)
        set(obj.hdisplay,'Parent',hdisp);
    end
    if ~isempty(obj.hcontrol) && ishandle(obj.hcontrol)
        set(obj.hcontrol,'Parent',hctrl);
    end
    if ~isempty(obj.hcontext_control) && ishandle(obj.hcontext_control)
        set(obj.hcontext_control,'Parent',hfig_ctrl);
    end


    % get zoom/pan/rotate objects from new figure
    obj.hzoom = zoom(hfig_disp);
    obj.hpan  = pan(hfig_disp);
    obj.hrot  = rotate3d(hfig_disp);

    % contrast tool access
    obj.hcontrast = contrasttool(hfig_disp);

    % initialize zoom/pan/rotate callbacks
    setZoomPanRot(obj);

    % cache the current parent sizes
    pos = getpixelposition(hctrl);
    obj.ctrlsz_cache = pos(3:4);
    pos = getpixelposition(hdisp);
    obj.dispsz_cache = pos(3:4);



    % LISTENERS------------------------------------------------------------

    % Deletion listener: when either Parent is destroyed,
    % the object is no longer valid and must be destroyed
    cb = @(varargin)obj.delete();
    obj.hlisten_delete = [addlistener(hdisp, 'ObjectBeingDestroyed', cb);
                          addlistener(hctrl, 'ObjectBeingDestroyed', cb)];

    % Resize listener: initialize a listener to ensure the object is
    % redrawn whenever either parent object (or their figure ancestors)
    % are resized.
    cback = @(src,evnt)redrawListenerCallback(obj,src,evnt);
    obj.hlisten_redraw = [...
        position_listener(hdisp, cback);
        position_listener(hctrl, cback);
        position_listener(hfig_disp, cback);
        position_listener(hfig_ctrl, cback);
        addlistener_mod(hdisp, 'BackgroundColor', 'PostSet', cback);
        addlistener_mod(hctrl, 'BackgroundColor', 'PostSet', cback);
        addlistener_mod(hdisp, 'Color', 'PostSet', cback);
        addlistener_mod(hctrl, 'Color', 'PostSet', cback)];

    % Hierachy listener: if the user attempts to change the figure
    % ancestors of the object (like moving the hparent_display panel
    % to a new figure), that could really mess stuff up.
    % Lets reject that action.
    cback = @(src,evnt)parentListenerCallback(obj);
    func = @(x)addlistener_mod(handle(x), 'Parent', 'PostSet', cback);
    listeners = arrayfun(func, hhier, 'UniformOutput', false);
    obj.hlisten_parent = cat(1, listeners{:});
end


function redrawListenerCallback(obj,src,evnt)
    if (isield(src, 'Name') && strcmpi(src.Name, 'Position')) || ...
            isa(evnt, 'matlab.ui.eventdata.SizeChangedData')
        cpos = getpixelposition(obj.hcontrol);
        dpos = getpixelposition(obj.hdisplay);

        if any(cpos(3:4) ~= obj.ctrlsz_cache) || ...
           any(dpos(3:4) ~= obj.dispsz_cache)
            resize(obj)
        end
    elseif any(strcmpi(src.Name,{'BackgroundColor','Color'}))
        resize(obj)
    end
end

function parentListenerCallback(obj)

    % check hierarchy for changes
    hfig_disp = ancestor(obj.hparent_display,'figure');
    hfig_ctrl = ancestor(obj.hparent_control,'figure');

    % delete the object if the figure ancestors have changed
    if hfig_disp ~= obj.hfigure_display || ...
       hfig_ctrl ~= obj.hfigure_control

        delete(obj)
        error(sprintf('%s:changedFigure',mfilename),'%s',...
            'The figure ancestor of DataViewer object has changed, ',...
            'causing the DataViewer object to be deleted.');

    % reset the parent object if the figure ancestors haven't changed
    else
        setParentFcn(obj,[],[]);
    end


%     return
%     % source handle
%     h = findobj(evnt.AffectedObject,'flat');
%
%     % new ancestor figure
%     newfig = ancestor(evnt.NewValue,'figure');
%
%     % test for change in parent figure
%     tfdisp = isancestor(obj.hdisplay,h) && ...
%         newfig ~= obj.hfigure_display;
%     tfctrl = isancestor(obj.hcontrol,h) && ...
%         newfig ~= obj.hfigure_control;
%
%     % delete the object if the parent was changed
%     if tfdisp || tfctrl
%         delete(obj)
%         error(sprintf('%s:changedFigure',mfilename),'%s',...
%             'Cannot change figure ancestor of DataViewer object! ',...
%             'The DataViewer object has been deleted.');
%     else
%
%     end




end



%% REDRAW

function resizeFcn(obj)

    % cache parent sizes to object
    pos = getpixelposition(obj.hcontrol);
    obj.ctrlsz_cache = pos(3:4);
    pos = getpixelposition(obj.hdisplay);
    obj.dispsz_cache = pos(3:4);

    % test for enabled redraw (enabled by subclass)
    if ~obj.redrawenable, return; end

    % place panels
    if strcmpi(get(obj.hcontrol,'Visible'),'off') || ...
       ~isequal(obj.hparent_display,obj.hparent_control)

        set([obj.hdisplay,obj.hcontrol],...
            'units',    'normalized',...
            'Position', [0 0 1 1]);

    else
        ppos = getpixelposition(obj.hparent_display);
        cpos = [1, 1, obj.ctrlwidth, ppos(4)];
        dpos = [1+obj.ctrlwidth, 1, ppos(3)-obj.ctrlwidth, ppos(4)];

        setpixelposition(obj.hcontrol,cpos);
        setpixelposition(obj.hdisplay,dpos);
    end


    % place the playbar at the bottom/center of the display panel
    if ~isempty(obj.hplaybar) && ...
       isequal(obj.hplaybar.Parent,obj.hdisplay)

        pos    = getpixelposition(obj.hplaybar.Parent);
        plsz   = [250 30];
        margin = 5;

        p = [(pos(3)+1)/2 - (plsz(1)+1)/2, 1+margin, plsz];
        setpixelposition(obj.hplaybar,p);
    end

    % update colors
    if isprop(obj.hparent_display,'Color')
        clr = get(obj.hparent_display,'Color');
    else
        clr = get(obj.hparent_display,'BackgroundColor');
    end
    set(obj.hdisplay,'BackgroundColor',clr);

    if isprop(obj.hparent_control,'Color')
        clr = get(obj.hparent_control,'Color');
    else
        clr = get(obj.hparent_control,'BackgroundColor');
    end
    set(obj.hcontrol,'BackgroundColor',clr);

end



%% SUSPEND & RESTORE

function suspendFcn(obj)

    % check isSuspended
    if obj.isSuspended, return; end

    % initialize structure (if necessary)
    if isempty(obj.statecache)
        obj.statecache = struct;
    end

    % cache playbar enable state
    if isequal(obj.PlaybarVisible,'on')
        obj.statecache.PlaybarEnable  = obj.hplaybar.Enable;
        obj.hplaybar.Enable = 'off';
    end

    % cache control children enable state
    if isequal(obj.ControlVisible,'on')

        hchild = findall(obj.hcontrol);
        tf = isprop(hchild,'Enable');
        hchild = hchild(tf);

        obj.statecache.ControlHandles = hchild;
        obj.statecache.ControlEnable  = get(hchild,'enable');

        set(hchild,'enable','off');
    end

    % notify the Suspend Event
    obj.isSuspended = true;
    notify(obj,'Suspend');

end


function restoreFcn(obj)

    % check isSuspended
    if ~obj.isSuspended, return; end

    % restore objects to cached state
    if ~isempty(obj.statecache)

        if isequal(obj.PlaybarVisible,'on')
            obj.hplaybar.Enable = obj.statecache.PlaybarEnable;
        end

        if isequal(obj.ControlVisible,'on')
            set(obj.statecache.ControlHandles,{'Enable'},...
                obj.statecache.ControlEnable);
        end

        obj.statecache = [];
    end

    % notify the Restore Event
    obj.isSuspended = false;
    notify(obj,'Restore');

end




%% HELPER FUNCTION

function val = checkString(val,vals,name)

    if ~ischar(val) || ~any(strcmpi(val,vals))
        str = sprintf('%s|',vals{:});
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            'Invalid ', name,' input; acceptable values are [',...
            str(1:end-1), '].');
    end

end




%% export IMAGE/VIDEO

function filename = exportFcn(obj,type,startpath)

    % video pause factor
    pausefac = 5;

    % stop the playbar
    stop(obj.hplaybar);

    % ensure good rectangle
    rect = obj.exportrect;
    if isempty(obj.exportrect)
        rect = getpixelposition(obj.hdisplay,true);
    end

    % get options
    switch lower(type)
        case 'image'
            if ~obj.isAllowExportImage
                errstr = 'image export is disabled.';
            else
                opts = obj.eximageopts;
            end
        case 'video'
            if ~obj.isAllowExportVideo
                errstr = 'video export is disabled.';
            elseif (obj.hplaybar.Max-obj.hplaybar.Min) > 1
                opts = obj.exvideoopts;
            else
                errstr = sprintf('%s','video export is not allowed ',...
                    'for single-frame sequences');
            end
        otherwise
            errstr = 'unrecognized type';
    end

    % throw error
    if exist('errstr','var')
       error(sprintf('%s:invalidExport',mfilename),errstr);
    end

    % save startpath to export options
    if nargin > 2 && ~isempty(startpath) && exist(startpath,'dir')
        filename = fullfile(startpath,'untitled');
        if isempty(opts)
            opts = struct('Filename',filename);
        else
            opts.Filename = filename;
        end
    end

    % export options
    opts = guiExportOptions(type,opts);
    if isempty(opts)
        filename = [];
        return;
    end

    % delete file if necessary
    filename = opts.Filename;
    if exist(filename,'file'), delete(filename); end

    % open a new figure of the appropriate size
    hfig = figure('position',[100 100 rect(3:4)],...
        'colormap',get(obj.hfigure_display,'colormap'),...
        'visible','off','renderer','zbuffer');
    cleanupFig = onCleanup(@()close(hfig));

    switch lower(type)

        case 'image'

            % save options
            obj.eximageopts = opts;

            % copy display panel
            hpanel = grabPanel(obj,opts,rect,hfig);

            % parse additional options
            tags = {'Format','Resolution','LockAxes','FontMode'};
            hgoptions = struct;
            for ti = 1:numel(tags)
                tag = tags{ti};
                if isfield(opts,tag), hgoptions.(tag) = opts.(tag); end
            end

            % export file
            hgexport(hfig,filename,hgoptions);


        case 'video'

            % save options
            obj.exvideoopts = opts;

            % record frame, suspend the display, create waitbar
            fr = obj.hplaybar.Value;
            suspend(obj);

            % waitbar
            hwait = waitbar(0,'Saving video...',...
                'CreateCancelBtn',@(varargin)closereq);
            set(hwait,'WindowStyle','modal');
            FLAG_quit = false;

            % cleanup function
            cleanupObj = onCleanup(@()cleanupExport(obj,hwait,fr));

            % parse additional options
            tags = {'Resolution','LockAxes','FontMode'};
            hgoptions = struct('Format','tiffn');
            for ti = 1:numel(tags)
                tag = tags{ti};
                if isfield(opts,tag), hgoptions.(tag) = opts.(tag); end
            end

            % test for AVI object
            [p,f,e] = fileparts(filename);
            FLAG_aviobj = strcmpi(e,'.avi');

            % determine delay
            delay = 1/opts.FPS;

            % create AVI object
            if FLAG_aviobj
                aviobj = VideoWriter(filename);
                aviobj.FrameRate = opts.FPS;
                open(aviobj);
                if any(strcmpi(opts.AVIProfile,{'Indexed AVI'}))
                    aviobj.Colormap = colorcube(236);
                    FLAG_index = true;
                else
                    FLAG_index = false;
                end
            end

            try
                rng = obj.hplaybar.Min:obj.hplaybar.Max;
                for k = 1:numel(rng)

                    % set playbar value
                    obj.hplaybar.Value = rng(k);
                    drawnow

                    % grab the panel, set export options
                    hpanel = grabPanel(obj,opts,rect,hfig);
                    state = hgexport(hfig,'temp.tmp',hgoptions,'ApplyStyle',1);
                    drawnow

                    % test for cancel
                    if ~ishandle(hwait)
                        FLAG_quit = true;
                        break;
                    end

                    % get a hardcopy of the figure
                    res = ['-r' num2str(opts.Resolution)];
                    I = hardcopy(hfig, '-dzbuffer', res, '-loose');

                    % delete panel / reset figure
                    delete(hpanel);
                    for n=1:length(state.objs)
                        if ishandle(state.objs{n})
                            set(state.objs{n}, state.prop{n}, state.values{n});
                        end
                    end

                    % AVI frame
                    if FLAG_aviobj
                        if FLAG_index
                            I = rgb2ind(I,map);
                        end
                        writeVideo(aviobj, I);
                        if any(k == [1 numel(rng)])
                            for n = 2:pausefac
                                writeVideo(aviobj, I);
                            end
                        end


                    % ANIMATED GIF frame
                    % try a couple of times to write to the file, as
                    % sometimes the last write is not complete
                    else
                        [I,map] = rgb2ind(I,256);
                        tf = false;

                        for iter = 1:5
                            try
                                if k == 1
                                    imwrite(I,map,filename,...
                                        'LoopCount',Inf,...
                                        'DelayTime',pausefac*delay);
                                elseif k == numel(rng)
                                    imwrite(I,map,filename,...
                                        'DelayTime',pausefac*delay,...
                                        'Writemode','append');
                                else
                                    imwrite(I,map,filename,...
                                        'DelayTime',delay,...
                                        'Writemode','append');
                                end
                                tf = true;
                                break
                            catch gifERR
                                pause(0.1)
                            end
                        end
                        if ~tf, rethrow(gifERR); end
                    end

                    % update waitbar
                    if ~ishandle(hwait)
                        FLAG_quit = true;
                        break;
                    else
                        waitbar(k/numel(rng),hwait);
                    end


                end

            % ERROR: close avi, delete invalid video, rethrow error
            catch ERR
                if FLAG_aviobj
                    close(aviobj);
                    obj.exvideoopts.AVIProfile = 'Motion JPEG AVI';
                end
                if exist(filename,'file'), delete(filename); end
                delete(hwait(ishandle(hwait)));
                rethrow(ERR);
            end

            if FLAG_aviobj
                close(aviobj);
            end
            if FLAG_quit && exist(filename,'file')
                delete(filename)
            end

            if ishandle(hwait), close(hwait); end
    end
end

function cleanupExport(obj,hwait,fr)
    close(hwait(ishandle(hwait)));
    obj.hplaybar.Value = fr;
    restore(obj);
end


function hpanel = grabPanel(obj,opts,rect,hfig)

    % copy all graphics from the display panel to the new figure
    hpanel = copyobj(obj.hdisplay,hfig);
    pos = getpixelposition(obj.hdisplay,true);
    setpixelposition(hpanel,pos,true)

    % recover all children objects
    hchild = findall(hpanel);

    % remove any resize/delete behavior
    tf = isprop(hchild,'DeleteFcn');
    set(hchild(tf),'DeleteFcn',[]);
    tf = isprop(hchild,'ResizeFcn');
    set(hchild(tf),'ResizeFcn',[]);

    % eliminate all interactive behavior
    set(hchild,'hittest','off');

    % remove the playbar panel
    h = findobj(hchild,'flat','tag','Playbar');
    if ~isempty(h)
        delete(h);
        hchild = findall(hpanel);
    end

    % hide all children panels
    h = findobj(hchild,'flat','type','uipanel');
    h = setdiff(h,hpanel);

    % move the display panel to the appropriate location
    pos = getpixelposition(hpanel,true);
    newpos = [pos(1:2)-rect(1:2)+1,pos(3:4)];
    setpixelposition(hpanel,newpos,true);

    % fix the position of all visible axes to their plotbox position
    h = findobj(hchild,'flat','type','axes','visible','on');
    for k = 1:numel(h)
       p = plotboxpos(h(k));
       setpixelposition(h(k),p);
    end

    % make these axes invisible if necessary
    if ~obj.exportaxes
        set(h,'visible','off')
    end

    % all units to normalized
    tf = isprop(hchild,'Units');
    set(hchild(tf),'Units','normalized');

    % manually update lines
    h = findobj(hchild,'flat','type','line','-or','type','patch');
    if ~isnan(opts.LineWidth)
        if opts.LineWidth == 0
            set(h,'linestyle','none');
        else
            set(h,'linewidth',opts.LineWidth);
        end
    end
    if ~isnan(opts.MarkerSize)
        if opts.MarkerSize == 0
            set(h,'marker','none');
        else
            set(h,'markersize',opts.MarkerSize);
        end
    end

    % manually edit background color
    set(hpanel,'BackgroundColor',opts.Background);


end




