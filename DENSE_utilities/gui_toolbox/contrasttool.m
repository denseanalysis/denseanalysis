%% CONTRAST TOOL
% This class defines a new tool for contrast editing of an image, similar
% to the IMCONTRAST tool provided by MATLAB. However, this tool can be
% simply added to the toolbar, works for any number of subplots, and does
% not require the additional figure overhead of IMCONTRAST.
%
%
%PROPERTIES
%
%   FigureHandle........parent figure
%       Get enabled, set upon initialization
%
%   ToggleHandle........handle of toggle button, created via the ADDTOGGLE
%       method. Get enabled only.
%
%   ActionPreCallback...function handle called just after left click,
%       before contrast is adjusted. Set/Get enabled.
%
%   ActionPostCallback..function handle called after the left button is
%       released. Set/Get enabled.
%
%   Enable..............is the contrast tool active
%       Set/Get enabled, [on|{off}]
%
%
%METHODS
%
%   OBJ = CONTRASTTOOL(HFIG) creates a new contrasttool object OBJ for the
%   figure HFIG.
%
%   OBJ = CONTRASTTOOL is the same as CONTRASTTOOL(GCF)
%
%   DELETE(OBJ) delete the contrastool object
%
%   ADDTOGGLE(OBJ,HTB) add a uitoggletool for interactive enable/disable of
%   the contrastool OBJ to the uitoolbar HTB.
%
%   TF = ISALLOWAXES(OBJ,HAX) returns true/false indicating if contrast
%   adjustment is currently enabled/disabled for the axes HAX.
%
%   SETALLOWAXES(OBJ,HAX) enable/disable contrast adjustment for the axes
%   HAX.
%
%   FIX(OBJ,HAX) fix the base CLIM value of the axes HAX to the current
%   CLIM value.  If the user selects the "reset" option from the contrast
%   adjustment context menu, the axes clim will return to this fixed value.
%
%
%USAGE
%
%   This class creates a contrast editor associated with a given figure,
%   similar to the IMCONTRAST matlab tool.  Once activated (either via a
%   toggle tool or manually via the "Enable" property), users can adjust
%   the "clim" property of the axes under the pointer by pressing and
%   holding the left mouse button and moving the cursor in the four
%   cardinal directions. Moving the pointer up/down will adjust the
%   brightness, while moving the pointer left/right will adjust the
%   contrast.
%
%
%EXAMPLE:
%
%   This example opens a figure and displays an image, then adds the
%   CONTRAST TOOL to the figure toolbar and activates to allow contrast
%   changes of the image.
%
%     % open figure & display image
%     images = load('imdemos');
%     hfig = figure;
%     imshow(images.coins2,[],'init','fit');
%
%     % add constrast tool
%     htb = findall(hfig,'type','uitoolbar');
%     htool = contrasttool(hfig);
%     htool.addToggle(htb);
%     htool.Enable = 'on';
%

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2009.04     Drew Gilliam
%       --creation


%% CLASS DEFINITION
classdef contrasttool < handle

    % set/get properties
    properties
        ActionPreCallback  = [];
        ActionPostCallback = [];
    end
    properties (Dependent)
        Enable
    end

    % get-only properties
    properties (Dependent,SetAccess='private')
        ToggleHandle
    end
    properties (SetAccess='private')
        FigureHandle = [];
    end

    % private properties
    properties (SetAccess='private',GetAccess='public')

        % pointer/toggle icons
        pointerdata
        icon

        % axes inventory
        inventory

        % uimode name
        modename = 'ContrastTool';

        %
        currentax = [];
        lastpt = [];
        hcontext
        htoggle
        hlisten_delete
        hlisten_mode
        hmode
    end


    methods

        % constructor
        function obj = contrasttool(hfig)

            % check figure
            if ~isnumeric(hfig) || ~isscalar(hfig) || ...
               ~ishandle(hfig) || ~strcmpi(get(hfig,'type'),'figure')
                error(sprintf('%s:invalidFigure',mfilename),...
                    'Invalid figure handle.');
            end

            % check for previously cached object
            if isappdata(hfig,'contrasttool_cache')
                obj = getappdata(hfig,'contrasttool_cache');
            else
                obj = contrasttoolFcn(obj,hfig);
            end
        end

        % destructor
        function delete(obj)
            deleteFcn(obj);
        end

        % get functions
        function val = get.Enable(obj)
            if isactiveuimode(obj.FigureHandle,obj.modename)
                val = 'on';
            else
                val = 'off';
            end
        end

        function val = get.ToggleHandle(obj)
            if ishandle(obj.htoggle)
                val = obj.htoggle;
            else
                val = [];
            end
        end


        % set functions
        function set.ActionPreCallback(obj,val)
            if isempty(val) || isa(val,'function_handle')
                obj.ActionPreCallback = val;
            end
        end

        function set.ActionPostCallback(obj,val)
            if isempty(val) || isa(val,'function_handle')
                obj.ActionPostCallback = val;
            end
        end

        function set.Enable(obj,val)
            if strcmpi(val,'on')
                createMode(obj);
                activateuimode(obj.FigureHandle,obj.modename);
            else
                activateuimode(obj.FigureHandle,'');
            end
        end


        % action functions
        function addToggle(obj,htoolbar)
            addToggleFcn(obj,htoolbar);
        end

        function val = isAllowAxes(obj,hax)
            val = isAllowAxesFcn(obj,hax);
        end

        function setAllowAxes(obj,hax,tf)
            setAllowAxesFcn(obj,hax,tf);
        end

        function fix(obj,hax)
            fixFcn(obj,hax)
        end

    end


    % hidden methods
    methods (Hidden)
        function val = ishandle(obj)
            val = isvalid(obj);
        end

        function val = get(obj,tag)
            val = obj.(tag);
        end

        function set(obj,tag,val)
            obj.(tag) = val;
        end
    end

end

function icon = mousePointerIcon()
    icon = [0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0;
            0 0 0 0 0 2 1 2 0 0 0 0 0 0 0 0;
            0 0 0 0 2 1 1 1 2 0 0 0 0 0 0 0;
            0 0 0 0 0 2 1 2 0 0 0 0 0 0 0 0;
            0 0 2 0 0 2 0 2 0 0 2 0 0 0 0 0;
            0 2 1 2 2 2 1 2 2 2 1 2 0 0 0 0;
            2 1 1 1 0 1 1 1 0 1 1 1 2 0 0 0;
            0 2 1 2 2 2 1 2 2 2 1 2 0 0 0 0;
            0 0 2 0 0 2 0 2 0 2 2 2 2 2 0 0;
            0 0 0 0 0 2 1 2 2 2 1 1 1 1 2 0;
            0 0 0 0 2 1 1 1 2 1 1 1 2 1 1 2;
            0 0 0 0 0 2 1 2 2 1 1 1 2 2 1 2;
            0 0 0 0 0 0 2 0 2 1 1 1 2 2 1 2;
            0 0 0 0 0 0 0 0 2 1 1 1 2 1 1 2;
            0 0 0 0 0 0 0 0 0 2 1 1 1 1 2 0;
            0 0 0 0 0 0 0 0 0 0 2 2 2 2 0 0];

    % Set zeros to be transparent
    icon(icon == 0) = NaN;
end

function icon = contrastToolbarIcon()
    icon = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
            1 1 1 1 1 1 2 2 2 2 2 1 1 1 1 1
            1 1 1 1 2 2 4 4 4 5 5 2 2 1 1 1
            1 1 1 2 4 4 3 3 3 6 6 5 4 2 1 1
            1 1 1 2 4 3 3 3 3 6 6 6 5 2 1 1
            1 1 2 4 3 3 3 3 3 6 6 6 6 5 2 1
            1 1 2 4 3 3 3 3 3 6 6 6 6 5 2 1
            1 1 2 4 3 3 3 3 3 6 6 6 6 5 2 1
            1 1 2 4 3 3 3 3 3 6 6 6 6 5 2 1
            1 1 2 4 3 3 3 3 3 6 6 6 6 5 2 1
            1 1 1 2 4 3 3 3 3 6 6 6 5 2 1 1
            1 1 1 2 4 4 3 3 3 6 6 5 5 2 1 1
            1 1 1 1 2 2 4 4 4 5 5 2 2 1 1 1
            1 1 1 1 1 1 2 2 2 2 2 1 1 1 1 1
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];

    cmap = repmat([NaN; 0; 0.0824; 0.2; 0.8; 1.0], [1, 3]);
    icon = ind2rgb(icon, cmap);
 end

%% CONSTRUCTOR
% note we already have checked the input figure
function obj = contrasttoolFcn(obj,hfig)

    obj.pointerdata = struct(...
        'Pointer',              'custom',...
        'PointerShapeCData',    mousePointerIcon(),...
        'PointerShapeHotSpot',  [1 1]);

    obj.icon = contrastToolbarIcon();

    % save the figure handle
    obj.FigureHandle = hfig;

    % setup axes inventory
    inventory = struct(...
        'AxesHandle',   NaN,...
        'isAllow',      false,...
        'BaseCLim',     []);
    obj.inventory = repmat(inventory,[0 1]);

    % cache object reference to figure
    setappdata(hfig,'contrasttool_cache',obj);

    % deletion listener: is the parent figure is deleted, we need to
    % delete the contrast object
    obj.hlisten_delete = handle.listener(...
        hfig,'ObjectBeingDestroyed',@(varargin)delete(obj));

    % mode listener: if the mode manager changes the figure mode, we
    % need start/stop the contrast tool appropriately
    hmanager = uigetmodemanager(hfig);
    prop = findprop(hmanager,'CurrentMode');
    obj.hlisten_mode = handle.listener(hmanager,...
        prop,'PropertyPostSet',@(varargin)modeFcn(obj));

    % create a UI mode object
    createMode(obj);
%     obj.hmode = getuimode(hfig,obj.modename);
%     if isempty(obj.hmode)
%         obj.hmode = uimode(hfig,obj.modename);
%         set(obj.hmode,'WindowButtonDownFcn',@(varargin)buttonDownFcn(obj));
%         set(obj.hmode,'WindowButtonUpFcn',@(varargin)buttonUpFcn(obj));
%         set(obj.hmode,'WindowButtonMotionFcn',@(src,evnt)motionFcn(obj,evnt));
%         set(obj.hmode,'UIContextMenu',[]);
%         set(obj.hmode,'UseContextMenu','on');
%     end


end





%% DESTRUCTOR
function deleteFcn(obj)

    hfig = obj.FigureHandle;
    if ishandle(hfig) && strcmpi(get(hfig,'BeingDeleted'),'off')
        stopTool(obj);
    end

    tags = {'hlisten_mode','hlisten_delete','htoggle','hcontext'};

    for ti = 1:numel(tags)
        h = obj.(tags{ti});
        try
            if isempty(h)
                continue;
            elseif isobject(h) && isvalid(h)
                delete(h);
            elseif ishandle(h)
                delete(h);
            end
        catch ERR
        end
    end

end


%% TOGGLE TOOL FUNCTIONS

function addToggleFcn(obj,htoolbar)

    % check toolbar
    if ~isnumeric(htoolbar) || ~isscalar(htoolbar) || ...
       ~ishandle(htoolbar) || ~strcmpi(get(htoolbar,'type'),'uitoolbar')
        error(sprintf('%s:invalidToolbar',mfilename),...
            'Invalid toolbar handle.');
    end

    % intialize toggle tool
    obj.htoggle = uitoggletool(...
        'parent',           htoolbar,...
        'cdata',            obj.icon,...
        'ClickedCallback',  @(varargin)toggleCallback(obj),...
        'Tag',              'ContrastTool');

end


function toggleCallback(obj)
    if strcmpi(get(obj.htoggle,'state'),'on')
        createMode(obj);
        activateuimode(obj.FigureHandle,obj.modename);
    else
        activateuimode(obj.FigureHandle,'');
    end
end



%% CHECK/SET ALLOWABLE AXES

function val = isAllowAxesFcn(obj,hax)

    % check for valid axes
    testaxes(obj,hax);

    % default output
    val = false(size(hax));

    % search axes inventory
    objaxes = [obj.inventory.AxesHandle];
    for k = 1:numel(hax)
        idx = find(hax == objaxes,1,'first');
        if ~isempty(idx)
            val(k) = obj.inventory(idx).isAllow;
        end
    end

end


function setAllowAxesFcn(obj,hax,tf)

    % check for valid axes
    testaxes(obj,hax);

    % check tf
    tf = logical(tf);
    if numel(tf) == 1
        tf = tf(ones(numel(hax),1));
    elseif numel(tf)~=numel(hax)
        error(sprintf('%s:invalidAllow',mfilename),'%s',...
            'Function expects single logical input or a logical array',...
            'of size [',num2str(numel(hax)),'x1].');
    end

    % update axes inventory
    objaxes = [obj.inventory.AxesHandle];
    for k = 1:numel(hax)
        idx = find(hax(k) == objaxes,1,'first');
        if isempty(idx), idx = numel(obj.inventory)+1; end
        obj.inventory(idx).AxesHandle = hax(k);
        obj.inventory(idx).isAllow    = tf(k);
        obj.inventory(idx).BaseCLim   = [];
    end

end



%% FIX THE CURRENT CONTRAST AS THE BASE CONTRAST
function fixFcn(obj,hax)

    % check for valid axes
    testaxes(obj,hax);

    % update axes inventory
    objaxes = [obj.inventory.AxesHandle];
    for k = 1:numel(hax)
        idx = find(hax(k) == objaxes,1,'first');
        if isempty(idx)
            idx = numel(obj.inventory)+1;
            obj.inventory(idx).AxesHandle = hax(k);
            obj.inventory(idx).isAllow    = true;
        end
        obj.inventory(idx).BaseCLim = get(hax(k),'clim');
    end

end



%% START/STOP THE CONTRAST TOOL

function modeFcn(obj)
    if isactiveuimode(obj.FigureHandle,obj.modename)
        startTool(obj);
    else
        stopTool(obj);
    end
end

function startTool(obj)

    % current figure
    hfig = obj.FigureHandle;

    % locate all axes within figure (with visible handles)
    allaxes = findobj(hfig,'type','axes');

    % inventory all axes within figure
    objaxes = [obj.inventory.AxesHandle];
    for k = 1:numel(allaxes)
        idx = find(allaxes(k)==objaxes);
        if isempty(idx)
            idx = numel(obj.inventory)+1;
            obj.inventory(idx).AxesHandle = allaxes(k);
            obj.inventory(idx).isAllow    = true;
            obj.inventory(idx).BaseCLim   = get(allaxes(k),'CLim');
        elseif isempty(obj.inventory(idx).BaseCLim)
            obj.inventory(idx).BaseCLim   = get(allaxes(k),'CLim');
        end

    end

    % turn on the toggle tool
    set(obj.htoggle,'state','on');

end

function stopTool(obj)
    set(obj.htoggle,'state','off');
end



%% BUTTON MOTION/UP/DOWN CALLBACKS & COMPUTE NEW CLIM
function motionFcn(obj,evnt)

    % figure handle
    hfig = obj.FigureHandle;

    % manually update the current figure point
    curr_units = hgconvertunits(hfig,[0 0 evnt.CurrentPoint],...
        'pixels',get(hfig,'Units'),hfig);
    pt = curr_units(3:4);
    set(hfig,'CurrentPoint',pt);

    % DRAG EVENT
    if ~isempty(obj.currentax)
        computeCLim(obj);
        return
    end

    % OTHER EVENTS
    hax = findAxes(obj);
    if ~isempty(hax)
        set(obj.hmode,'UIContextMenu',obj.hcontext);
        set(hfig,obj.pointerdata);
    else
        set(obj.hmode,'UIContextMenu',[]);
        setptr(hfig,'arrow');
    end

end


function buttonDownFcn(obj)

    sel = get(obj.FigureHandle,'SelectionType');
    if ~strcmpi(sel,'normal'), return; end


    hax = findAxes(obj);
    if ~isempty(hax)
        obj.currentax = hax;
        obj.lastpt = get(obj.FigureHandle,'CurrentPoint');

        % add this axes to the inventory if necessary
        objaxes = [obj.inventory.AxesHandle];
        idx = find(hax == objaxes,1,'first');
        if isempty(idx)
            idx = numel(obj.inventory)+1;
            obj.inventory(idx).AxesHandle = hax;
            obj.inventory(idx).isAllow    = true;
            obj.inventory(idx).BaseCLim   = get(hax,'CLim');
        elseif isempty(obj.inventory(idx).BaseCLim)
            obj.inventory(idx).BaseCLim = get(hax,'CLim');
        end

        % call the pre-action callback
        callPreCallback(obj,hax);

    else
        obj.currentax = [];
    end
end


function buttonUpFcn(obj)

    % reset pointer
    if ~isempty(obj.currentax)
        hax = findAxes(obj);
        if ~isempty(hax)
            set(obj.FigureHandle,obj.pointerdata);
        else
            setptr(obj.FigureHandle,'arrow');
        end

        % call the post-action callback
        callPostCallback(obj,obj.currentax);

    end

    % reset object properties
    obj.currentax = [];

end


function computeCLim(obj)

    tol = 1e-10;

    newpt  = get(obj.FigureHandle,'CurrentPoint');
    offset = newpt - obj.lastpt;
    obj.lastpt = newpt;

    % axes index
    objaxes = [obj.inventory.AxesHandle];
    idx = find(obj.currentax == objaxes,1,'first');

    % base clim
    baseclim = obj.inventory(idx).BaseCLim;
    speed = diff(baseclim)/500;

    % current clim
    clim = get(obj.currentax,'CLim');

    % adjust window width/center
    width  = clim(2) - clim(1);
    center = clim(1) + width/2;

    % adjust width/center
    width  =  width + speed*offset(1);  % contrast
    center = center + speed*offset(2);  % brightness

    % ensure positive width
    width = max(width,eps);

    % recover clim
    clim = center + [-width/2,width/2];

    if clim(1) < baseclim(1)
        clim(1) = baseclim(1);
    end
    if clim(2) > baseclim(2)
        clim(2) = baseclim(2);
    end
    if (clim(2)-clim(1)) < tol
        clim(2) = clim(1) + tol;
    end

    % save clim
    set(obj.currentax,'clim',clim);



end



%% RESET AXES CLIM TO BASE LEVEL
function resetFcn(obj)

    % locate the current axes
    hax = findAxes(obj);
    if isempty(hax), return; end

    % locate axes within inventory
    objaxes = [obj.inventory.AxesHandle];
    idx = find(hax == objaxes,1,'first');

    % reset the axes clim to the base level
    if ~isempty(idx) && ~isempty(obj.inventory(idx).BaseCLim)
        callPreCallback(obj,hax);
        set(hax,'clim',obj.inventory(idx).BaseCLim);
        callPostCallback(obj,hax);
    end

end



%% CALL THE PRE/POST CALLBACK ACTIONS
% note we wrap these function calls within a try/catch loop, ensuring
% valid operation if upon user error.

function callPreCallback(obj,hax)
    if ~isempty(obj.ActionPreCallback)
        try
            data = struct('Axes',hax);
            obj.ActionPreCallback(obj.FigureHandle,data);
        catch ERR
            warning(sprintf('%s:failedActionPreCallback',mfilename),...
                '%s','ActionPreCallback failure.  Callback ',...
                'is being removed.');
            obj.ActionPreCallback = [];
        end
    end
end


function callPostCallback(obj,hax)
    if ~isempty(obj.ActionPostCallback)
        try
            data = struct('Axes',hax);
            obj.ActionPostCallback(obj.FigureHandle,data);
        catch ERR
            warning(sprintf('%s:failedActionPostCallback',mfilename),...
                '%s','ActionPostCallback failure.  Callback ',...
                'is being removed.');
            obj.ActionPostCallback = [];
        end
    end
end



%% CREATE UIMODE
% This function creates a new uimode for the contrast tool object, making
% use of the undocumented UIMODE operations. Additionally, this function
% will initialize a new context menu for the tool if one does not exist.
function createMode(obj)
    hfig = obj.FigureHandle;

    % create the UI mode
    obj.hmode = getuimode(hfig,obj.modename);
    if isempty(obj.hmode)
        obj.hmode = uimode(hfig,obj.modename);
        set(obj.hmode,...
            'WindowButtonDownFcn',  @(varargin)buttonDownFcn(obj),...
            'WindowButtonUpFcn',    @(varargin)buttonUpFcn(obj),...
            'WindowButtonMotionFcn',@(src,evnt)motionFcn(obj,evnt),...
            'UIContextMenu',        [],...
            'UseContextMenu',       'on');
    end

    % create a context menu
    if isempty(obj.hcontext) || ~ishandle(obj.hcontext)
        obj.hcontext = uicontextmenu(...
            'parent',   hfig,...
            'tag',      'ContrastMenu');
        uimenu('parent',obj.hcontext,...
            'Label',    'Reset Contrast',...
            'tag',      'resetcontrast',...
            'Callback', @(varargin)resetFcn(obj));
    end


end



%% CURRENT AXES HELPER FUNCTION
function hax = findAxes(obj)

    % locate axes
    hitaxes = hittest(obj.FigureHandle,'axes');
    hitaxes = findobj(hitaxes,'flat','Type','Axes','HandleVisibility','on');

    % inventory
    objaxes = [obj.inventory.AxesHandle];

    % find an axes within the inventory
    hax = [];
    for k = 1:length(hitaxes)
        idx = find(hitaxes(k) == objaxes);
        if isempty(idx) || obj.inventory(idx).isAllow
            hax = hitaxes(k);
            break;
        end
    end
    if isempty(hax), return; end

    % test for click within axes boundary
    tol = 3e-16;
    fcn = @(pt,idx,lim)...
       ((pt(1,idx) - min(lim)) < -tol || (pt(1,idx) - max(lim)) > tol) && ...
       ((pt(2,idx) - min(lim)) < -tol || (pt(2,idx) - max(lim)) > tol);
    cp = get(hax,'CurrentPoint');
    if fcn(cp,1,get(hax,'XLim')) || ...
       fcn(cp,2,get(hax,'YLim')) || ...
       fcn(cp,3,get(hax,'ZLim'))
        hax = [];
    end

end



%% AXES VALIDATION HELPER FUNCTION
function testaxes(obj,hax)

    errid = sprintf('%s:invalidAxes',mfilename);

    % check for valid axes handles
    if ~isnumeric(hax) || ~all(ishandle(hax)) || ...
       ~all(strcmpi(get(hax,'type'),'axes'))
        error(errid,'Input must be axes handles.');
    end

    % ensure axes are within object
    hfig = ancestor(hax,'figure');
    if iscell(hfig), hfig = [hfig{:}]; end

    if any(hfig ~= obj.FigureHandle)
        error(errid,'Axes must be resident in the object figure.');
    end

end



%% END OF FILE=============================================================
