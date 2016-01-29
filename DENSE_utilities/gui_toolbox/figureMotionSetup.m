function motionapi = figureMotionSetup(hfig,varargin)
%% FIGURE MOTION SETUP
% This function is similar to the IPTPOINTERMANAGER, only simpler.  Use the
% SETAPPDATA function to define an "EnterFcn", "TraverseFcn", and "ExitFcn"
% for any object (This object must be the top-most object that has
% "hittest" set to 'on' for the functions to be executed).
% Additionally, use SETAPPDATA to define a "ToolTip" string for any object.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    % motion api check
    apptag = 'figure_motionapi';
    if isappdata(hfig,apptag) && ~isempty(getappdata(hfig,apptag))
        motionapi = getappdata(hfig,apptag);
%         motionapi.updatestack();
        return
    end

    % default options
    defopt = struct(...
        'ToolTipDelay', 0.5,...
        'ToolTipBackgroundColor',[255 255 225]/255,...
        'ToolTipBorderColor',[0 0 0],...
        'ToolTipFontColor',[0 0 0],...
        'ToolTipFontName','courier',...
        'ToolTipFontSize',8,...
        'CheckExistance',false);
    opt = parseinputs(defopt,[],varargin{:});

    % check existance only
    if isequal(opt.CheckExistance,true)
        motionapi = [];
        return
    end

    % inter-function variables
    active  = true;
    paused  = false;
    context = false;
    hcur    = -1;
    pcur    = NaN(1,2);
    figptr  = struct(...
        'Pointer',              get(hfig,'Pointer'),...
        'PointerShapeCData',    get(hfig,'PointerShapeCData'),...
        'PointerShapeHotSpot',  get(hfig,'PointerShapeHotSpot'));

    % off screen location (tooltip hack)
    scrsz = hgconvertunits(hfig,get(0,'screensize'),...
        get(0,'Units'),'pixels',0);
    offscreen = [2*scrsz(3:4),20,20];

    % tooltip object
    tooltipflag  = false;
    tooltipdelay = opt.ToolTipDelay;
    tooltipfcn   = [];

    hframe = uicontrol(...
        'parent',hfig,...
        'style','frame',...
        'backgroundcolor',opt.ToolTipBackgroundColor,...
        'foregroundcolor',opt.ToolTipBorderColor,...
        'visible','off',...
        'units','pixels',...
        'hittest','off',...
        'handlevisibility','off',...
        'enable','inactive');

    htooltip = NaN(1,2);

    htooltip(1) = uicontrol(...
        'parent',hfig,...
        'style','text',...
        'backgroundcolor',opt.ToolTipBackgroundColor,...
        'foregroundcolor',opt.ToolTipFontColor,...
        'fontname',opt.ToolTipFontName,...
        'fontsize',opt.ToolTipFontSize,...
        'visible','off',...
        'units','pixels',...
        'horizontalalignment','right',...
        'hittest','off',...
        'handlevisibility','off',...
        'enable','inactive');

    htooltip(2) = copyobj(htooltip(1),hfig);
    set(htooltip(2),'horizontalalignment','left');
    set(htooltip(1),'FontAngle','italic');

    % per-tooltip default information
    tooltipdata = struct(...
        'BackgroundColor',opt.ToolTipBackgroundColor,...
        'BorderColor',opt.ToolTipBorderColor,...
        'FontColor',opt.ToolTipFontColor,...
        'FontName',opt.ToolTipFontName,...
        'FontSize',opt.ToolTipFontSize,...
        'String','',...
        'Delay',opt.ToolTipDelay);
    tooltiptags = fieldnames(tooltipdata);


    % tooltip timers
    htimer = timer(...
        'ExecutionMode','fixedDelay',...
        'Period',opt.ToolTipDelay,...
        'StartDelay',0,...
        'BusyMode','queue',...
        'TasksToExecute',2,...
        'TimerFcn',@(h,evnt)timerfcn());



    % motion functions
    motionapi = struct(...
        'figure',   hfig,...
        'stop',     @()stopfcn(),...
        'start',    @()startfcn(),...
        'pause',    @()pausefcn(),...
        'update',   @()updatefcn(true),...
        'isrunning',@()isrunningfcn(),...
        'updatestack',@()updatestack());

    % save motion application data to figure
    setappdata(hfig,apptag,motionapi);

    % figure mode (for zoom,pan,etc.)
    figModeManager = uigetmodemanager(hfig);

    % listen for mode change
    prop = findprop(figModeManager,'CurrentMode');
    hlisten_mode = addlistener_mod(figModeManager,...
        prop,'PostSet',@(varargin)updatefcn(true));

    % listen for figure deletion (to delete tooltip timer)
    hlisten_delete = addlistener(hfig, ...
        'ObjectBeingDestroyed',@(varargin)cleanupfcn());

    % initialize figure motion fcn
    set(hfig,'WindowButtonMotionFcn',@(h,evnt)updatefcn(false));

    % START FUNCTION
    % enable the motion manager
    function startfcn()
        active = true;
        paused = false;
        updatefcn(false);
    end

    % STOP FUNCTION
    % disable the motion manager
    function stopfcn()
        active = false;
        paused = false;
        updatefcn(false);
    end

    % PAUSE FUNCTION
    % temporarily disable the motion manager (this function does not exit
    % the current object)
    function pausefcn()
        paused = true;
    end

    % ISRUNNING
    % return true/false indicating if motion manager is enabled
    function tf = isrunningfcn()
        tf = active & ~paused;
    end


    % UPDATE FUNCTION
    % the new figure motion function.
    function updatefcn(flag_traverse)

        % immediate quit if contextmenu timer is running
        if context, return; end

        % cease tooltip display on any motion
        killTooltip();

        % quit if paused
        if paused || ~isempty(figModeManager.CurrentMode), return; end

        % wait for context menu to close through the timer (for some
        % reason, we are not able to listen to a context menu 'visible'
        % property, so we use this workaround)
        if contextvisible()
            context = true;
            set(htimer,'BusyMode','drop','TasksToExecute',Inf,...
                'Period',0.1,...
                'userdata','context');
            start(htimer);
            return
        end

        % check current object
        if ~ishandle(hcur), hcur = -1; end

        % current point in pixels
        pt = get(hfig,'currentpoint');
        tmp = hgconvertunits(hfig,[pt 0 0],...
            get(hfig,'Units'),'pixels',hfig);
        pt = tmp(1:2);

        % new object in current figure
        if active && isequal(get(0,'currentfigure'),hfig)% && isempty(figModeManager.CurrentMode)
            hnew = hittest(hfig,pt);
            if isempty(hnew) || ~ishandle(hnew), hnew = -1; end
        else
            hnew = -1;
        end

        % quick check - nothing to do
        if (hnew == -1) && (hcur == -1), return; end

        % exit current object (if the valid graphics object under the
        % pointer is no longer the current object)
        % additionally, reset the figure pointer to its original condition
        if hcur>0 && (hnew~=hcur || flag_traverse)
            runfcn(hcur,'ExitFcn');
            set(hfig,figptr);
            tooltipflag = false;
%             if strcmpi(htimer.Running,'on'), stop(htimer); end
%             set([htooltip,hframe],'visible','off','position',offscreen);
            hcur = -1;
        end

        % quit if disabled
        if ~active, return; end

        % enter new object
        if hnew>0 && hnew~=hcur
            hcur = hnew;
            runfcn(hcur,'EnterFcn');
            [tooltipflag,tooltipdelay,tooltipfcn] = parseTooltip(hcur);
%             if isappdata(hcur,'ToolTip')
%                 str = getappdata(hcur,'ToolTip');
%                 if ~isempty(str)
%                     if ~ischar(str) && ~iscellstr(str)
%                         warning('figureMotionFcn:ToolTip',...
%                             ['''ToolTip'' for object %d is not a ',...
%                             'string or cell array of strings.'],hcur);
%                     else
%                         if strcmpi(htimer.Running,'on'), stop(htimer); end
%                         tooltipflag = true;
%                         if ischar(str)
%                             set(htooltip(1),'string','');
%                             set(htooltip(2),'string',str);
%                         else
%                             if size(str,2)==1
%                                 set(htooltip(1),'string','');
%                                 set(htooltip(2),'string',str);
%                             else
%                                 set(htooltip(1),'string',str(:,1));
%                                 set(htooltip(2),'string',str(:,2));
%                             end
%                         end
%                         if tooltipflag
%                             set([htooltip,hframe],'visible','off',...
%                                 'position',offscreen);
% %                             uistack(htooltip,'top');
%                         end
%                     end
%                 end
%             end
        end

        % traverse current object
        if hcur>0 && (flag_traverse || any(pt~=pcur))
            runfcn(hcur,'TraverseFcn');
            if tooltipflag
                if tooltipdelay>0
%                     if strcmpi(htimer.Running,'on'), stop(htimer); end
%                     set([htooltip,hframe],'visible','off','position',offscreen);
                    set(htimer,'BusyMode','queue','TasksToExecute',2,...
                        'userdata',[],'Period',tooltipdelay);
                    start(htimer);
                else
                    displayTooltip();
                end
            end
        end

        % save current point
        pcur = pt;

    end

    % TOOLTIP TIMER
    function timerfcn()
        if htimer.TasksExecuted==1, return; end
        if ~context
            displayTooltip();
        elseif ~contextvisible()
            stop(htimer);
            context = false;
            updatefcn(true);
        end
    end

    % KILL TOOLTIP
    function killTooltip()
        if strcmpi(htimer.Running,'on')
            stop(htimer);
        end
        if any(strcmpi(get([htooltip,hframe],'visible'),'on'))
            set([htooltip,hframe],'visible','off','position',offscreen);
        end
        context = false;
    end

    % TOOLTIP DISPLAY
    % display the tooltip at the current position, assuming there are no
    % context menus currently displayed
    function displayTooltip()
        if tooltipflag && ~contextvisible() && ...
          (get(0,'PointerWindow')==hfig)

            % update tooltip
            if ~isempty(tooltipfcn)
                try
                    str = getToolTipString(tooltipfcn);
                    if isempty(str), return; end
                    for k = 1:2
                        set(htooltip(k),'string',str{k});
                    end
                catch ERR
                    warning('figureMotionFcn:ToolTip',...
                        ['Unknown error executing ''ToolTip'' ',...
                         'string function.'])
                    return
                end
            end

            % pointer offset
            offset = [1 -20];

            % tooltip-to-frame margin
            mg = [5 2];

            % current pixel location & figure size
            pt = get(hfig,'currentpoint');
            pfig = get(hfig,'position');

            % convert units if necessary
            units = get(hfig,'units');
            if ~strcmpi(units,'pixels')
                pt = hgconvertunits(hfig,[pt 0 0],...
                    get(hfig,'Units'),'pixels',hfig);
                pt = pt(1:2);
                pfig = hgconvertunits(hfig,pfig,...
                    get(hfig,'Units'),'pixels',0);
            end

            % number of tooltips
            n = numel(htooltip);

            % tooltip extent requirement
            tf = false(1,n);
            etip = zeros(n,2);
            for k = 1:n
                if ~isempty(get(htooltip(k),'string'))
                    tf(k) = true;
                    ptip = get(htooltip(k),'extent');
                    etip(k,:) = ptip(3:4) + [-2 -5];
                end
            end

            % full tooltip size
            stip = [sum(etip(:,1)) + (sum(tf)+1)*mg(1), ...
                max(etip(:,2))+2*mg(2)];

            % tool tip location
            sfig = pfig(3:4);

            pt = pt - [0 stip(2)] + offset;
            if pt(1)+stip(1) > sfig(1)
                pt(1) = pt(1) + (sfig(1)-pt(1)-stip(1)) + 1;
            end
            if pt(1)<1, pt(1) = 1; end
            if pt(2)<1, pt(2) = 1; end

            % place frame
            set(hframe,'position',[pt,stip],'visible','on');

            % place tooltips
            tmp = [0; cumsum(tf(:).*(etip(:,1)+mg(1)))];
            for k = 1:n
                if tf(k)
                    x = pt(1)+mg(1)+tmp(k);
                    y = pt(2)+mg(2);
                    set(htooltip(k),'position',[x,y,etip(k,:)],...
                        'visible','on');
                end
            end

            return



%             if pt(1) > (sfig(1)-pt(1))
%                 pt(1) = pt(1)-stip(1)+1 - offset(1);
%             else
%                 pt(1) = pt(1) + offset(1);
%             end
%             if pt(2) > (sfig(2)-pt(2))
%                 pt(2) = pt(2)-stip(2)+1 - offset(2);
%             else
%                 pt(2) = pt(2) + offset(2);
%             end

%             if (sfig(1)-pt(1)-stip(1)) < (pt(1)-stip(1))
%                 pt(1) = pt(1)-stip(1);
%             end
%             if (sfig(2)-pt(2)-stip(2)) > (pt(2)-stip(2))
%                 pt(2) = pt(2)+stip(2);
%             end

            % update tooltip position
            set(htooltip,'position',[pt+2,stip-4]);
            set(hframe,'position',[pt,stip]);
            set([htooltip,hframe],'visible','on');%,'position',[pt,stip]);
%             drawnow, pause(0.1)
        end
    end




    % RUN ENTER/TRAVERSE/EXIT FUNCTION
    function runfcn(h,tag)
        if h>0 && isappdata(h,tag)
            fcn = getappdata(h,tag);
            if ~isempty(fcn)
                try
                    fcn(hfig,h,pcur);
                catch ERR
                    warning(sprintf('figureMotionFcn:%s',tag),...
                        'Error in ''%s'' for object %d.',tag,h);
                    ERR.getReport()
                end
            end
        end
    end

    % CHECK FOR VISIBLE CONTEXT MENU
    function [tf,hmenu] = contextvisible()
        hmenu = findall(hfig,'type','uicontextmenu','-and','visible','on');
        tf = ~isempty(hmenu);

%         if isempty(h)
%             tf = false;
%             hmenu = [];
%         else
% %             tfon = strcmpi(get(h,'visible'),'on');
% %             tf = any(tfon);
% %             if tf
%                 hmenu = h(tfon);
%             else
%                 hmenu = [];
%             end
%         end
%         tf = ~isempty(h) && any(strcmpi(get(h,'visible'),'on'));
    end

    % PARSE TOOLTIP INFORMATION
    function [flag,delay,fcn] = parseTooltip(h)
        flag  = false;
        delay = [];
        fcn   = [];

        % retrieve tooltip information
        if ~isappdata(h,'ToolTip'), return; end
        input = getappdata(h,'ToolTip');
        if isempty(input), return; end

        % default data
        data = tooltipdata;

        % structure input: parse additional fields
        if isstruct(input)
            for ti = 1:numel(tooltiptags)
                tag = tooltiptags{ti};
                if isfield(input,tag)
                    data.(tag) = input.(tag);
                end
            end
            input = data.String;

            % check delay
            if isempty(data.Delay) || ...
               ~isnumeric(data.Delay) || data.Delay<0
                data.Delay = tooltipdata.Delay;
            end
        end

        % string for display
        [str,strfcn] = getToolTipString(input);
        if isempty(str), return; end
%
%         % make tooltip invisible & offscreen
%         set([hframe,htooltip],'visible','off','position',offscreen);
%

        % attempt to update tooltips
        try
            for k = 1:2
                set(htooltip(k),...
                    'backgroundcolor',data.BackgroundColor,...
                    'foregroundcolor',data.FontColor,...
                    'fontname',data.FontName,...
                    'fontsize',data.FontSize,...
                    'string',str{k});
            end
            set(hframe,...
                'backgroundcolor',data.BackgroundColor,...
                'foregroundcolor',data.BorderColor);

        catch ERR
            ERR.getReport()
            return
        end

        % valid outputs
        flag  = true;
        delay = data.Delay;
        fcn   = strfcn;

    end


    % GET TOOLTIP STRING
    % gather tooltip string from input, depending on input type (allowing
    % users to dynamically update the tooltip string immediately before
    % display by inputting a function)
    function [str,fcn] = getToolTipString(input)

        % run string function if necessary
        if isa(input,'function_handle')
            fcn = input;
            try
                input = fcn();
            catch ERR
                str = [];
                fcn = [];
                warning('figureMotionFcn:ToolTip',...
                    '''ToolTip'' string function failed.');
                return
            end
        else
            fcn = [];
        end

        % default string
        str = cell(1,2);

        % empty input
        if isempty(input)
            str = [];
            fcn = [];

        % single string
        elseif ischar(input)
            str{2} = input;

        % [Nx1] or [Nx2] cell array of strings
        elseif iscellstr(input)
            if size(input,2)==1
                str{2} = input;
            else
                str{1} = input(:,1);
                str{2} = input(:,2);
            end

        % error
        else
            str = [];
            fcn = [];
            warning('figureMotionFcn:ToolTip',...
                'Unrecognized ''ToolTip''.');
            return
        end

    end


    function updatestack()

        uistack(hframe,'top');
        uistack(htooltip,'top');
%         hch = allchild(hfig);
%
%         hchild = [htooltip(:); hframe];
%         tf = ~ismember(hch,hchild);
%         hchild = [hchild(:); hch(tf)];
%
%         set(hfig,'children',hchild);
    end


    % CLEANUP
    % delete the tooltip timer & figure listener when the
    % figure is destroyed
    function cleanupfcn()
        %fprintf('cleanup...');

        % delete timer & listener
        h = {hlisten_delete,hlisten_mode,htimer};
        for k = 1:numel(h)
            if isobject(h{k}) && isa(h{k},'timer') && isvalid(h{k})
                if strcmpi('on',h{k}.Running), stop(h{k}); end
                delete(h{k});
            elseif ishandle(h{k})
                delete(h{k});
            end
        end
%         if isvalid(htimerstop)
%             if strcmpi('on',htimerstop.Running), stop(htimerstop); end
%             delete(htimerstop);
%         end
%         if ishandle(hlisten)
%             delete(hlisten);
%         end

        %fprintf('complete!\n')
    end

end
