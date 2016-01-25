%% ROTATE TOOL
% This class defines a new tool for 3D axis rotation.
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
%   OBJ = ROTATETOOL(HFIG) creates a new object OBJ for the
%   figure HFIG.
%
%   OBJ = ROTATETOOL is the same as ROTATETOOL(GCF)
%
%   DELETE(OBJ) delete the object
%
%   ADDTOGGLE(OBJ,HTB) add a uitoggletool for interactive enable/disable of
%   the tool OBJ to the uitoolbar HTB.
%
%   TF = ISALLOWAXES(OBJ,HAX) returns true/false indicating if tool
%   options are currently enabled/disabled for the axes HAX.
%
%   SETALLOWAXES(OBJ,HAX) enable/disable tool options for the axes HAX.
%
%
%USAGE
%
%
%
%EXAMPLE:
%
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2011.06     Drew Gilliam
%       --creation


%% CLASS DEFINITION
classdef rotatetool < handle

    % set/get properties
    properties
        ActionPreCallback  = [];
        ActionPostCallback = [];
        RotateMethod       = 'upvector';
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
        modename = mfilename;

        % figure cache tag
        cachetag = [mfilename,'_cache'];

        % default rotation allowed
        isallowdef = false;

        %
        currentax = [];
        lastpt = [];
        hcontext
        htoggle
        hlisten_delete
        hlisten_mode
        hmode

        viewangle = -Inf;
    end


    methods

        % constructor
        function obj = rotatetool(hfig)

            % check figure
            if ~isnumeric(hfig) || ~isscalar(hfig) || ...
               ~ishandle(hfig) || ~strcmpi(get(hfig,'type'),'figure')
                error(sprintf('%s:invalidFigure',mfilename),...
                    'Invalid figure handle.');
            end

            % check for previously cached object
            if isappdata(hfig,obj.cachetag)
                obj = getappdata(hfig,obj.cachetag);
            else
                obj = mainFcn(obj,hfig);
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

        function addViews(obj,hax,views)
            addViewsFcn(obj,hax,views);
        end

        function set.RotateMethod(obj,method)
            methods = {'orbit','upvector'};
            if ~ischar(method), rotateError(); end
            idx = find(strcmpi(method,methods),1,'first');
            if isempty(idx), rotateError(); end
            obj.RotateMethod = methods{idx};

            function rotateError()
                str = sprintf('%s|',methods{:});
                error(sprintf('%s:invalidRotateMethod',mfilename),...
                    'Valid RotateMethod values are: [%s]',str(1:end-1));
            end
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



%% CONSTRUCTOR
% note we already have checked the input figure
function obj = mainFcn(obj,hfig)

    % create pointer object
    tmp = setptr('rotate');
    tmp = reshape(tmp,[2 numel(tmp)/2]);
    obj.pointerdata = cell2struct(tmp(2,:),tmp(1,:),2);

    % create icon (for user-defined toolbar)
    try
        filename = fullfile(toolboxdir('matlab'),'icons','tool_rotate_3d.png');
        [im, ~, alpha] = imread(filename);
        im = double(im) / (2^16);
        for k = 1:3
            tmp = im(:,:,k);
            tmp(alpha == 0) = NaN;
            im(:,:,k) = tmp;
        end
        obj.icon = im;
    catch ERR
        obj.icon = zeros([16 16 3]);
    end


    % save the figure handle
    obj.FigureHandle = hfig;

    % setup axes inventory
    inventory = struct(...
        'AxesHandle',   NaN,...
        'isAllow',      false,...
        'ViewNames',    {{}},...
        'ViewOptions',  {{}},...
        'ViewCallback', {{}});
    obj.inventory = repmat(inventory,[0 1]);

    % cache object reference to figure
    setappdata(hfig,obj.cachetag,obj);

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
        'Tag',              mfilename);

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
        emptyview(obj,idx,hax(k),tf(k));
    end

end



%% START/STOP THE TOOL

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
        tf = (allaxes(k)==objaxes);
        if ~any(tf)
            idx = numel(obj.inventory)+1;
            emptyview(obj,idx,allaxes(k),obj.isallowdef);
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
        computeView(obj);
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
            emptyview(obj,idx,hax,obj.isallowdef);
        end

        % call the pre-action callback
        if obj.inventory(idx).isAllow
            callPreCallback(obj,hax);
        end

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


function computeView(obj)

    % axes
    hax = obj.currentax;

    % figure points & offset
    newpt  = get(obj.FigureHandle,'CurrentPoint');
    offset = newpt - obj.lastpt;
    obj.lastpt = newpt;

    % speed (180° across the axes)
    pos   = getunitposition(hax,get(obj.FigureHandle,'units'));
    speed = 180./pos(3:4);

    % rotate camera
    rot    = -speed.*offset;
    dtheta = rot(1);
    dphi   = rot(2);

    % check right-handedness
    dirs = get(hax, {'xdir' 'ydir' 'zdir'});
    num  = length(find(lower(cat(2,dirs{:}))=='n'));
    val  = mod(num,2);
    if ~val, dtheta = -dtheta; end

    % object parameters
    pos  = get(hax, 'cameraposition' );
    targ = get(hax, 'cameratarget'   );
    dar  = get(hax, 'dataaspectratio');
    up   = get(hax, 'cameraupvector' );

    % rotate camera
    [newPos newUp] = camrotate(pos,targ,dar,up,rot(1),rot(2),'data',up);

    % correct up vector
    if strcmpi(obj.RotateMethod,'upvector')
        if dot(up,newUp)<0
            newUp = -up;
        else
            newUp =  up;
        end
    end

    % update axes
    set(hax,'cameraposition',newPos,'cameraupvector',newUp);

%     % check cameraviewangle
%     set(hax,'cameraviewanglemode','auto');
%     angle = get(hax,'cameraviewangle');
%     if angle > obj.viewangle
%         obj.viewangle = angle;
%     end
%     set(hax,'cameraviewangle',obj.viewangle);
%
%     obj.viewangle

end


%% CONTEXT VIEW FUNCTIONS
function addViewsFcn(obj,hax,views)

    % check for valid axes
    testaxes(obj,hax);

    % check views
    reqtags = {'Name'};
    valtags = {'View','CameraUpVector','CameraTarget','CameraPosition'};
    cbktags = {'Callback'};

    tags = fieldnames(views);
    if ~isstruct(views) || ~all(ismember(reqtags,tags)) || ...
       ~all(ismember(tags,[reqtags,valtags,cbktags]))
        error(sprintf('%s:invalidViews',mfilename),...
            'Unrecognized Views.');
    end

    % view names
    names = {views.Name};
    Nview = numel(views);

    % view options & callbacks
    opts = cell(Nview,1);
    cbks = cell(Nview,1);
    for k = 1:Nview
        opts{k} = cell(1,0);
        for ti = 1:numel(valtags)
            tag = valtags{ti};
            if isfield(views,tag) && ~isempty(views(k).(tag))
                opts{k} = [opts{k},tag,views(k).(tag)];
            end
        end

        if isfield(views,'Callback') && ~isempty(views(k).Callback)
            cbks{k} = views(k).Callback;
        else
            cbks{k} = [];
        end
    end



    % add axes to the inventory if necessary
    objaxes = [obj.inventory.AxesHandle];
    idx = find(hax == objaxes,1,'first');
    if isempty(idx)
        idx = numel(obj.inventory)+1;
        emptyview(obj,idx,hax,obj.isallowdef);
    end

    % set the views
    obj.inventory(idx).ViewNames   = ...
        [obj.inventory(idx).ViewNames; names(:)];
    obj.inventory(idx).ViewOptions = ...
        [obj.inventory(idx).ViewOptions; opts(:)];
    obj.inventory(idx).ViewCallback = ...
        [obj.inventory(idx).ViewCallback; cbks(:)];

end



function contextCallback(obj)

    % delete all children from context menu
    hchild = allchild(obj.hcontext);
    delete(hchild);

    % locate the current axes
    hax = findAxes(obj);
    if isempty(hax), return; end

    % locate axes within inventory
    objaxes = [obj.inventory.AxesHandle];
    idx = find(hax == objaxes,1,'first');

    % quit if axes is not found, rotation is not allowed,
    % or no "Views" are available
    if isempty(idx) || ~obj.inventory(idx).isAllow || ...
       isempty(obj.inventory(idx).ViewNames)
        return
    end

    % create new children
    names = obj.inventory(idx).ViewNames;
    for k = 1:numel(names)
        uimenu('parent',obj.hcontext,...
            'Label',    names{k},...
            'Callback', @(varargin)viewCallback(k));
    end

    % adjust view callback
    function viewCallback(viewidx)
        callPreCallback(obj,hax);

        opts = obj.inventory(idx).ViewOptions{viewidx};
        fcn  = obj.inventory(idx).ViewCallback{viewidx};

        try
            if ~isempty(opts), set(hax,opts{:}); end
            if ~isempty(fcn), fcn(hax); end

        catch ERR
            warning(sprintf('%s:invalidView',mfilename),'%s',...
                'There was a problem applying the view ',...
                obj.inventory(idx).ViewNames{viewidx},...
                '.  This view will be eliminated from the ',...
                'available options.');

            obj.inventory(idx).ViewNames(viewidx)    = [];
            obj.inventory(idx).ViewOptions(viewidx)  = [];
            obj.inventory(idx).ViewCallback(viewidx) = [];
        end

%         % update cameraviewangle
%         set(hax,'cameraviewanglemode','auto');
%         obj.viewangle = get(hax,'cameraviewangle');
%         set(hax,'cameraviewangle',obj.viewangle);

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
% This function creates a new uimode for the tool, making
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
            'tag',      [mfilename 'menu'],...
            'Callback', @(varargin)contextCallback(obj));
%         uimenu('parent',obj.hcontext,...
%             'Label',    'Reset Contrast',...
%             'tag',      'resetcontrast',...
%             'Callback', @(varargin)resetFcn(obj));
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
        idx = find(hitaxes(k) == objaxes,1,'first');
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



%% CREATE NEW VIEW
function emptyview(obj,idx,hax,isallow)
    obj.inventory(idx).AxesHandle   = hax;
    obj.inventory(idx).isAllow      = isallow;
    obj.inventory(idx).ViewNames    = {};
    obj.inventory(idx).ViewOptions  = {};
    obj.inventory(idx).ViewCallback = {};
end



%% END OF FILE=============================================================
