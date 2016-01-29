function zprPointerBehavior(haxes,behavior)

%ZPRPOINTERBEHAVIOR set the zoom/pan/rotate3d pointer behavior of a given
%   axes (i.e. mouse-over of the axes results in this function only)
%
%INPUTS
%   haxes.....axes of interest
%   behavior..mouse-over action [zoom | pan | rotate3d]
%
%USAGE
%
%   ZPRPOINTERBEHAVIOR(HAX,BEHAVIOR) set the mouse-over pointer behavior of
%   the axes HAX to the BEHAVIOR [zoom|pan|rotate3d].  Thus, whenever the
%   user mouses over the axes, this default behavior is available.
%   Whenever the user leaves the axes, the figure will return to the former
%   zoom/pan/rotate3d state.
%   This function also accepts an axes vector, requiring a corresponding
%   CELLSTR of valid behaviors.
%
%
%NOTES
%
%   This function will not replace exisitng 'ActionPreCallback' and
%   'ActionPostCallback' functions on the zoom/pan/rotate3d objects, using
%   a modified version of the IPTADDCALLBACK function
%   (i.e. IPTADDCALLBACK_MOD).
%
%   However, any exisiting PointerBehavior on the selected axes will be
%   replaced with the new zprPointerBehavior.
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation

    % control flag
    FLAG_iptoverride = false;

    % check for valid axes handles
    if ~all(ishghandle(haxes, 'axes'))
        error(sprintf('%s:invalidAxes', mfilename),...
            'Function requires axes handles as input');
    end

    % check for valid figure ancestors
    hfig = ancestor(haxes,'figure');
    if iscell(hfig), hfig = [hfig{:}]; end
    if ~all(hfig == hfig(1))
        error(sprintf('%s:invalidAxes',mfilename),...
            'All axes must have the same figure ancestor.');
    end

    % number of axes and single figure ancestor
    N = numel(haxes);
    hfig = hfig(1);

    % check for expected number of behaviors & CELLSTR
    if ~iscell(behavior), behavior = {behavior}; end

    if numel(behavior) ~= N || ~iscellstr(behavior)
        error(sprintf('%s:invalidBehavior',mfilename),'%s',...
            '''behavior''  must be a cellstr the same ',...
            'size as the Axes input.');
    end

    % check for allowable strings
    tags = {'zoom','pan','rotate3d'};
    tf = cellfun(@(a)any(strcmpi(a,tags)),behavior);

    if ~all(tf)
        str = sprintf('%s|',tags{:});
        error(sprintf('%s:invalidBehvaior',mfilename),'%s',...
            'Valid ''behavior'' strings are: [',str(1:end-1),'].');
    end


    % zoom/pan/rotate3d objects
    hzoom = zoom(hfig);
    hpan  = pan(hfig);
    hrot  = rotate3d(hfig);

    % check that specified behaviors are allowed
    ztf = isAllowAxesZoom(hzoom,haxes);
    ptf = isAllowAxesPan(hpan,haxes);
    rtf = isAllowAxesRotate(hrot,haxes);

    err = false;
    for k = 1:N
        switch lower(behavior{k})
            case 'zoom',       err = ~ztf(k);
            case 'pan',        err = ~ptf(k);
            case 'rotate3d',   err = ~rtf(k);
        end
        if err
            error(sprintf('%s:invalidBehvaior',mfilename),'%s',...
                'One or more of the specified behaviors are not ',...
                'allowed in the corresponding axes.');
        end
    end


    % stop all functions in all axes
    hzoom.setAllowAxesZoom(haxes,false);
    hpan.setAllowAxesPan(haxes,false);
    hrot.setAllowAxesRotate(haxes,false);

    % set up the axes
    for k = 1:N

        % allow single function
        switch lower(behavior{k})
            case 'zoom',     hzoom.setAllowAxesZoom(haxes(k),true);
            case 'pan',      hpan.setAllowAxesPan(haxes(k),true);
            case 'rotate3d', hrot.setAllowAxesRotate(haxes(k),true);
        end

        % set pointer behavior
        pb = struct(...
            'enterFcn',     @(varargin)enterFcn(behavior{k}),...
            'traverseFcn',  [],...
            'exitFcn',      @(varargin)exitFcn());
        iptSetPointerBehavior(haxes(k),pb);

    end


    % add pre/post callbacks to specified functions
    h = {hzoom,hpan,hrot};
    tf = cellfun(@(tag)any(strcmpi(tag,behavior)),tags);

    idpre  = NaN(1,3);
    idpost = NaN(1,3);

    for k = 1:3
        if tf(k)
            idpre(k) = iptaddcallback_mod(h{k},...
                'ActionPreCallback',  @(varargin)preCallback);
            idpost(k) = iptaddcallback_mod(h{k},...
                'ActionPostCallback', @(varargin)postCallback);
        end
    end

    % initial zoom states
    zoomstate = get(hzoom);
    panstate  = get(hpan);
    rotstate  = get(hrot);


    % MATLAB decided to stop the PointerManager every time the
    % zoom/pan/rotate3d behaviors are activated.  We need to override this
    % behavior, restarting the pointermanager after zoom/pan/rotate3d
    % is enabled. This code is taken from iptPointerManager.
    if FLAG_iptoverride
        figModeManager = uigetmodemanager(hfig);
        hlisten_override = handle.listener(figModeManager, ...
            figModeManager.findprop('CurrentMode'), ...
            'PropertyPostSet', @(varargin)listenerFcn);
    end




    %% LISTENER FUNCTION
    % restart the PointerManager after any zoom/pan/rotate
    function listenerFcn()
        mode = figModeManager.CurrentMode;
        if isempty(mode), return; end

        name = get(mode,'Name');
        if any(strwcmpi(name,{'*zoom*','*pan*','*rotate*'}))
            restartPointerManager();
        end
    end


    %% IPT POINTER MANAGER FUNCTIONS
    function enterFcn(action)

        % update current zoom/pan/rotate3d states
        zoomstate = get(hzoom);
        panstate  = get(hpan);
        rotstate  = get(hrot);

        % start the mouse-action
        switch lower(action)
            case 'zoom',     hzoom.Enable = 'on';
            case 'pan',      hpan.Enable = 'on';
            case 'rotate3d', hrot.Enable = 'on';
        end

        % ensure the pointermanager continues
        restartPointerManager();
    end


    function exitFcn()

        % re-enable last function
        if strcmpi(zoomstate.Enable,'on')
            hzoom.Enable = 'on';
        elseif strcmpi(panstate.Enable,'on')
            hpan.Enable = 'on';
        elseif strcmpi(rotstate.Enable,'on')
            hrot.Enable = 'on';
        else
            hzoom.Enable = 'off';
            hpan.Enable  = 'off';
            hrot.Enable  = 'off';
        end

    end


    %% PRE/POST ACTION CALLBACKS
    % Before the zoom/pan/rotate3d action is initiated, we need to stop the
    % iptPointerManager and allow the function to complete. After the
    % action is complete, we restart the pointer manager (note this will
    % start the pointer manager if none is already started).
    %
    % note we restart the pointermanager after a short delay to avoid a
    % recursion errors (otherwise, we would disable the current
    % zoom/pan/rot action during the zoom/pan/rot action)

    function preCallback()
        iptPointerManager(hfig,'disable');
    end

    function postCallback()
        restartPointerManager()
    end

    function restartPointerManager(delay)
        if nargin < 1, delay = 0.1; end
        htimer = timer(...
            'ExecutionMode',    'singleShot',...
            'StartDelay',       delay,...
            'TimerFcn',         @(varargin)startPM());
        start(htimer)

        function startPM()
            stop(htimer);
            delete(htimer);
            iptPointerManager(hfig,'enable');
        end
    end


end


%% END OF FILE=============================================================
