%% IMcLINE HANDLE CLASS DEFINITION
%Interactive placement of a cLINE object.
%
%Users are offered a number of different interactive cLINE tools via the
%IMcLINE object (see INTERACTIVE TOOLS below), including:
%   � Editing of control point position through click & drag
%   � Editing of the entire contour position through click & drag
%   � Context menu options to add/delete control points
%   � Context menu options to define line segments as straight or curved,
%     control points as corners or smooth, and cLINE as open or closed
%
%IMPORTANT: To start editing, the Pointer Manager must be enabled!
%   ex.  iptPointerManager(handle_figure,'enable')
%
%
%PROPERTIES
%
%   Parent.......parent axes
%       Get enabled, defaults to GCA
%
%   cLine........reference cLINE object
%       Get enabled, set on creation
%
%   Appearance...unselected IMcLINE appearance
%       Set/Get enabled, see note on APPEARANCE below
%
%   Highlight....selected IMcLINE appearance
%       Set/Get enabled, see note on HIGHLIGHT below
%
%   Resolution...curved line segment display resolution
%       Set/Get enabled, defaults to 1/1000th of the shorter axis (x/y)
%
%   Visible......imcline visibility
%       Set/Get enabled, [{on}|off]
%
%   Enable.......enable/disable interactivity
%       Set/Get enabled, [{on}|off]
%
%   ContextOpenClosed.........allow open/closed contour
%   ContextSmoothCorner.......allow smooth/corner positions
%   ContextStraightCurved.....allow straight/curved line segments
%   ContextAdd................allow point addition
%   ContextDelete.............allow point deletion
%       These properties enable/disable various context menu options.
%       Set/Get enabled, [{on}|off]
%
%   IndependentDrag....enable/disable cline children independent drag
%       Set/Get enabled, see note on INDEPENDENT DRAG below
%
%
%METHODS
%
%   OBJ = IMCLINE(HCLINE)
%       creates a default IMCLINE object to edit the HCLINE object in the
%       current axes.  Note the object is initially not running (i.e.
%       'isRunning' == false).
%
%   OBJ = IMCLINE(HCLINE,HAXES)
%       creates the IMCLINE object within HAXES.
%
%   OBJ.REDRAW
%       manually redraw the IMCLINE object
%
%
%NOTE ON APPEARANCE
%
%   The general appearance of the IMCLINE object can be modified
%   through the APPEARANCE property, a structure containing the
%   following fields:
%       Color, LineStyle, LineWidth, Marker,
%       MarkerEdgeColor, MarkerFaceColor, and MarkerSize.
%
%   The default appearance is a 2pt blue solid line with 6pt blue
%   circle control point markers.
%
%   The user can modify the appearance of each child line within the
%   reference HCLINE object separately, inputting an array of structures
%   to the APPEARANCE property. This property is circularly assigned to the
%   HCLINE children (e.g. if the user defines 4 HCLINE children, but the
%   APPEARANCE structure is only of length 2, the HCLINE children will be
%   assigned the [1st, 2nd, 1st, 2nd] APPEARANCE respectively).
%
%
%NOTE ON HIGHLIGHT
%
%   When a user hovers the mouse pointer over an IMCLINE point or line
%   segment, and subsequently selects and modifies the object, the IMCLINE
%   will change to the "highlighted" appearance defined by HIGHLIGHT.
%
%   Similar to the APPEARANCE property, HIGHLIGHT is a structure containing
%   the following fields:
%       Color, LineStyle, LineWidth, Marker,
%       MarkerEdgeColor, MarkerFaceColor, and MarkerSize.
%
%   The default appearance is a 2pt yellow solid line with 10pt yelloe
%   'x' control point markers.
%
%   The user may only define a [1x1] HIGHLIGHT property, applying to all
%   HCLINE children.
%
%
%NOTE ON INDEPENDENT DRAG
%
%   By default, if the user selects and drags a line segment, the entire
%   cLINE object will be tranlated together (i.e. all CLINE children
%   will be tranlated in the same manner). The user may choose to instead
%   modify only a single CLINE child via the INDEPENDENTDRAG property.
%   Setting the element of this cell array of strings corresponding to the
%   CLINE child to 'on' will allow this feature. Note, this proeprty is not
%   tied to the CLINE 'NumberOfLines' property.  If the NumberOfLines is
%   greater than the length of the INDEPENDENTDRAG cellstr, the remaining
%   CLINE children INDEPENDENTDRAG option defaults to 'off'.
%
%
%INTERACTIVE TOOL INSTRUCTIONS
%
%   � Control point drag and drop
%     --Single left click mouse while control point is highlighted
%     --Drag control point to new position
%     --Release mouse button
%
%   � cLINE drag and drop
%     --Single left click mouse while line segment is highlighted
%     --drag cLINE to new position
%     --Release mouse button
%
%   � Add Point
%     --Right click mouse on line segment of interest
%     --Select "Add Point" from context menu
%
%   � Delete Point
%     --Right click mouse on control point of interest
%     --Select "Delete Point" from context menu
%
%   � Corner or Smooth Control Point
%     --Right click mouse on control point of interest
%     --Select "Corner Point" or "Smooth Point" from context menu
%
%   � Curved or Straight Line Segment
%     --Right click mouse on line segment of interest
%     --Select "Curved Segment" or "Straight Segment" from context menu
%
%   � Open or Closed cLINE
%     --Right click mouse on any line segment
%     --Select "Open" or "Closed" from context menu
%
%
%NOTES
%
%   � The life-cycle of every IMcLINE object is tied to a cLINE object.
%     If the cLINE is deleted, all IMcLINEs referencing that object
%     become invalid and are deleted. Note the opposite is not true, i.e.
%     deletion of an IMcLINE object does not delete the referenced cLINE.
%
%   � Care has been taken to ensure the IMcLINE display is always
%     representative of the current cLINE object, updating whenever the
%     cLINE object triggers its 'NewProperty' event.
%
%   � The IMcLINE class is written specifically to allow for multiple
%     IMcLINE objects to edit a single cLINE object.
%
%   � The IMcLINE constructor does not initiate the Pointer Manager, to
%     allow the user to completely setup the figure and axes prior to
%     interactive behavior initialization.
%
%
%EXAMPLE
%   This example initiates a single cLINE object (containing two contours)
%   and two side-by-side IMcLINE interactive tools.
%
%     % position & cLINE object
%     pos = [1 0; 0 -1; -1 0; 0 1];
%     hcline = cline({pos,0.5*pos});
%
%     % constrained cLINE position
%     hcline.PositionConstraintFcn = ...
%         clineConstrainToRect(hcline,[-2 2],[-2 2]);
%
%     % initialize figure & axes
%     hfig = figure;
%     hax(1) = subplot(1,2,1);
%     axis equal, axis([-2 2 -2 2]), box on
%     hax(2) = subplot(1,2,2);
%     axis equal, axis([-2 2 -2 2]), box on
%     linkaxes(hax);
%
%     % create interactive tools
%     h(1) = imcline(hcline,hax(1));
%     h(2) = imcline(hcline,hax(2));
%
%     [h(1).Appearance(1:2).Color] = deal('r','g');
%     [h(1).Appearance(1:2).MarkerFaceColor] = deal('r','g');
%     h(1).IndependentDrag{2} = 'on';
%
%     [h(2).Appearance(1:2).Color] = deal('r','g');
%     [h(2).Appearance(1:2).MarkerFaceColor] = deal('r','g');
%     h(2).IndependentDrag{2} = 'on';
%
%     % start interactive edit
%     iptPointerManager(hfig,'enable');
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.01     Drew Gilliam
%     --creation
%   2009.03     Drew Gilliam
%     --modification to mutli-contour methods

%% CLASS DEFINITION
classdef imcline < handle

    properties (Dependent=true,SetAccess='private')
        Parent
        cLine
    end

    properties
        Appearance
        Highlight
        Resolution
        Visible = 'off';
        Enable  = 'on';
        ContextOpenClosed     = 'on';
        ContextSmoothCorner   = 'on';
        ContextStraightCurved = 'on';
        ContextAdd            = 'on';
        ContextDelete         = 'on';
        IndependentDrag       = {};
    end

    % private properties
    properties (SetAccess = 'protected',GetAccess = 'protected')

        % cline object & refresh listener
        hcline
        hlisten_cline
        hlisten_delete1
        hlisten_delete2

        % api and hggroup
        hgroup = [];

        % associated ancestors (figure/axes)
        hfig = [];
        hax  = [];

        % interactive groups & context menus
        hptgroup = [];
        hlngroup = [];
        hptmenu  = [];
        hlnmenu  = [];

        hpt = [];
        hln = [];

        % disabled display (continuous line)
        hline = [];

        % default appearance & highlight structures
        defappearance = struct(...
            'Color','b','LineStyle','-','LineWidth',2,...
            'Marker','o','MarkerEdgeColor','auto',...
            'MarkerFaceColor','b','MarkerSize',6);
        defhighlight = struct(...
            'Color','y','LineStyle','-','LineWidth',2,...
            'Marker','x','MarkerEdgeColor','auto',...
            'MarkerFaceColor','y','MarkerSize',10);

        % redraw enable flag
        redrawenable = false;

        % current selection
        indices = [];
        selectiontype = '';
        selectionidx  = [];
        dragiptids = [0 0];
        undocache = [];

        % initial number of objects
        % creating some objects right away helps reduce
        % initialization time
        Ninitial = 12;
    end

    % hidden event
    events (Hidden=true)
        DragEvent
    end

    % public methods
    methods

        % CONSTRUCTOR & DESTRUCTOR
        function obj = imcline(varargin)
            obj = imclineFcn(obj,varargin{:});
        end
        function delete(obj)
            deleteFcn(obj);
        end

        % ACTION FUNCTIONS
        function redraw(obj)
            redrawFcn(obj);
        end

        % GET functions
        function val = get.Parent(obj)
            val = obj.hax;
        end
        function val = get.cLine(obj)
            val = obj.hcline;
        end

        % SET functions
        function set.Appearance(obj,val)
            obj.Appearance = setAppearanceFcn(obj,val);
            redraw(obj);
        end
        function set.Highlight(obj,val)
            obj.Highlight = setHighlightFcn(obj,val);
            redraw(obj);
        end
        function set.Resolution(obj,val)
            obj.Resolution = checkResolution(val);
            redraw(obj);
        end
        function set.Visible(obj,val)
            obj.Visible = checkStrings(val,'Visible',{'on','off'});
            if strcmpi(obj.Visible,'on')
                startFcn(obj);
            else
                stopFcn(obj);
            end
        end
        function set.Enable(obj,val)
            obj.Enable = checkStrings(val,'Enable',{'on','off'});
            redraw(obj);
        end

        function set.ContextOpenClosed(obj,val)
            obj.ContextOpenClosed = checkStrings(val,...
                'ContextOpenClosed',{'on','off'});
            redraw(obj);
        end
        function set.ContextSmoothCorner(obj,val)
            obj.ContextSmoothCorner = checkStrings(val,...
                'ContextSmoothCorner',{'on','off'});
            redraw(obj);
        end
        function set.ContextStraightCurved(obj,val)
            obj.ContextStraightCurved = checkStrings(val,...
                'ContextStraightCurved',{'on','off'});
            redraw(obj);
        end
        function set.ContextAdd(obj,val)
            obj.ContextAdd = checkStrings(val,...
                'ContextAdd',{'on','off'});
            redraw(obj);
        end
        function set.ContextDelete(obj,val)
            obj.ContextDelete = checkStrings(val,...
                'ContextDelete',{'on','off'});
            redraw(obj);
        end

        function set.IndependentDrag(obj,val)
            obj.IndependentDrag = setIndependentDrag(val);
            redraw(obj);
        end
    end

    % private methods
    methods (Access='private')

        function drag(obj)
            dragFcn(obj);
        end
        function enter(obj,h)
            enterFcn(obj,h);
        end
        function exit_imcline(obj)
            exitFcn(obj);
        end
    end
end

%% CONSTRUCTOR
% The IMCLINE constructor creates the necessary drawing objects to display
% a given cLINE object. This function does not create its own cLINE
% object, but instead accepts a reference to a previously constructed
% cLINE. In addition to drawing objects, this function also creates an
% "event.listener" object to update the IMCLINE appearance whenever the
% referenced cLINE object triggers its 'NewProperty' event.

function obj = imclineFcn(obj,hcline,h)

    % input check, default input
    narginchk(2, 3);
    if nargin < 3, h = gca; end

    % check cLINE input
    if ~isa(hcline, 'cline')
        error(sprintf('%s:invalidObject',mfilename),...
            'Invalid cLINE object.');
    end

    % check handle input
    if ~ishghandle(h, 'axes')
        error(sprintf('%s:invalidAxesHandle',mfilename),...
            'Invalid axes handle.');
    end

    % figure/axes ancestors
    obj.hax  = ancestor(h,'axes');
    obj.hfig = ancestor(h,'figure');
    if ~ishandle(obj.hax) || ~ishandle(obj.hfig)
        error(sprintf('%s:invalidAxesHandle',mfilename),...
            'Invalid axes handle.');
    end

    % hggroup parent
    obj.hgroup = hggroup('hittest','off','Parent',obj.hax);

    % point/line groups
    obj.hlngroup = hggroup('hittest','off','Parent',obj.hgroup);
    obj.hptgroup = hggroup('hittest','off','Parent',obj.hgroup);

    % empty uicontext menus
    obj.hptmenu = uicontextmenu(...
        'parent',obj.hfig,'Tag','PointMenu',...
        'Callback',@(varargin)ptContextOpen(obj));
    obj.hlnmenu = uicontextmenu(...
        'parent',obj.hfig,'Tag','LineMenu',...
        'Callback',@(varargin)lnContextOpen(obj));

    % create some initial objects
    hpt = createPoints(obj,obj.Ninitial);
    hln = createLines(obj,obj.Ninitial);
    set([hpt(:); hln(:)],'visible','off');

    obj.hpt = hpt;
    obj.hln = hln;

    % disabled line
    obj.hline = [];

    % default curve resolution
    lmt = axis(obj.hax);
    obj.Resolution = min([abs(lmt(2)-lmt(1)),abs(lmt(4)-lmt(3))])/1000;

    % save handle references to object
    obj.hcline = hcline;

    % When the cLINE object updates a property, we ensure that the
    % IMCLINE object updates its display
    obj.hlisten_cline = addlistener(hcline,'NewProperty',...
        @(varargin)redraw(obj));
%     obj.hlisten_cline.Enabled = false;

    % When the hggroup that is part of the HG tree is destroyed,
    % the object is no longer valid and must be deleted.
    obj.hlisten_delete1 = addlistener(obj.hgroup,...
        'ObjectBeingDestroyed',@(varargin)obj.delete());

    % Additionally, when the cLINE object is destroyed, the object
    % is no longer valid and must be deleted.
    obj.hlisten_delete2 = addlistener(hcline,...
        'ObjectBeingDestroyed',@(varargin)obj.delete());

    % Cache handle to imcline object in hg hierarchy so that if
    % user loses handle to imcline object, the object still lives
    % in HG hierarchy and can be retrieved.
    setappdata(obj.hgroup,'imclineObjectReference',obj);

    % display
    obj.Appearance = obj.defappearance;
    obj.Highlight  = obj.defhighlight;
end

%% DESTRUCTOR
% Ensure all listeners, HGGROUP (and children), and context menu
% objects are all deleted.  Note to avoid recursion we must delete all
% listeners first.

function deleteFcn(obj)

    % objects to delete
    tags = {'hlisten_cline','hlisten_delete1','hlisten_delete2',...
        'hgroup','hptmenu','hlnmenu'};

    % attempt to delete objects
    for ti = 1:numel(tags)
        try
            h = obj.(tags{ti});
            if isobject(h)
                if isvalid(h), delete(h); end
            elseif ishandle(h)
                delete(h);
            end
        catch
            % fprintf('could not delete imcline.%s\n',tags{ti});
        end
    end
end

%% START & STOP
% These functions, accessed through the 'Visible' property, allow the
% user to activate and deactivate the imcline object. These methods are
% helpful when the user wants to make multiple updates to the cLine object
% or to the IMcLine object properties without redrawing after every step.
%
% Stop makes all objects invisible, stops the cLine listener, and
% disables the redraw function via the "redrawenable" flag.  Start
% reverses these steps.

function startFcn(obj)

    % enable redraw/listener & redraw
    obj.redrawenable = true;
    redraw(obj)
end

function stopFcn(obj)

    % stop redraw
    obj.redrawenable = false;

    % make all graphics invisible
    set([obj.hpt(:);obj.hln(:);obj.hline(:)],'visible','off');
end

%% REDRAW
% This function controls all display aspects of the IMCLINE object. It is
% called whenever the referenced cLINE object triggers its 'NewProperty'
% event, a number of times within the IMCLINE code, and may be called by
% the user externally to update the object appearance.
%
% Note that at any given time, we have AT LEAST the number of graphic
% objects required to correctly display the cLine.  In reality, we have the
% highest number of graphic objects required by the cLine over the entire
% lifetime of the cLine.  To elaborate, if we display a cLine with 8
% control points, and subsequently delete a control point, we still have 8
% point objects (7 visible, 1 invisible).  This is done to avoid the
% constant deletion/creation of new graphics, a time consuming process.

function redrawFcn(obj)
    %tobj = tic;

    % check for enabled redraw
    if ~obj.redrawenable, return; end

    % object data
    nline = obj.hcline.NumberOfLines;
    pos   = obj.hcline.Position;

    % gather all data into single lists
    if iscell(pos)
        npos = cellfun(@(p)size(p,1),pos);
        pos = cat(1,pos{:});
    else
        npos = size(pos,1);
    end

    % total number of control points
    N = size(pos,1);

    % gather graphics
    hpt = obj.hpt;
    hln = obj.hln;

    % if we're invisible (or no positions),
    % make all objects invisible and quit
    if N==0 || strcmpi(obj.Visible,'off')
        set([hpt(:);hln(:);obj.hline(:)],'visible','off');
        return
    end

    % ensure we have (at least) the proper number of points
    % make all extra points invisible
    if numel(hpt) < N
        h = createPoints(obj,N-numel(hpt));
        hpt = [h(:); hpt(:)];
        obj.hpt = hpt;
    elseif numel(hpt) > N
        set(hpt(N+1:end),'visible','off');
        hpt = hpt(1:N);
    end

    % ensure we have (at least) the proper number of lines
    % make all extra lines invisible
    if numel(hln) < N
        h = createLines(obj,N-numel(hln));
        hln = [h(:); hln(:)];
        obj.hln = hln;
    elseif numel(hln) > N
        set(hln(N+1:end),'visible','off');
        hln = hln(1:N);
    end

    % ensure we have exactly the proper number of disabled lines
    if numel(obj.hline) < nline
        for k = numel(obj.hline)+1 : N
           obj.hline(k) = line('parent',obj.hgroup,...
                'xdata',[],'ydata',[],'visible','off');
        end
    elseif numel(obj.hline) > nline
        delete(obj.hline(nline+1:end));
        obj.hline = obj.hline(1:nline);
    end

    % update "disabled" line
    if strcmpi(obj.Enable,'off')
        set([hpt(:);hln(:)],'visible','off');

        for k = 1:nline
            crv = obj.hcline.getContour(obj.Resolution,k);
            appidx = mod(k-1,numel(obj.Appearance))+1;
            set(obj.hline(k),obj.Appearance(appidx),'marker','none',...
                'xdata',crv(:,1),'ydata',crv(:,2),'visible','on');
        end
        return;

    else
        set(obj.hline,'visible','off');
    end

    % gather line segments
    xseg = cell(nline,1);
    yseg = xseg;
    for k = 1:nline
        [xseg{k},yseg{k}] = obj.hcline.getSegments(obj.Resolution,k);
    end
    xseg = cat(1,xseg{:});
    yseg = cat(1,yseg{:});

    % determine indices of each object
    indices = arrayfun(@(idx,n)[idx*ones(n,1), (1:n)'],...
        1:numel(npos),npos,'uniformoutput',0);

    obj.indices = cat(1,indices{:});

    % position properties
    set(hpt(:),...
        {'xdata'},num2cell(pos(:,1)),...
        {'ydata'},num2cell(pos(:,2)),...
        {'userdata'},num2cell(1:N)');
    set(hln(:),...
        {'xdata'},xseg,...
        {'ydata'},yseg,...
        {'userdata'},num2cell(1:N)',...
        'visible','on');

%     % set appearance
%     rng = [0,cumsum(npos)];
%     for k = 1:nline
%         idx = rng(k)+1 : rng(k+1);
%         appidx = mod(k-1,numel(obj.Appearance))+1;
%         set(hpt(idx),obj.Appearance(appidx),'linestyle','none',...
%             'visible','on');
%         set(hln(idx),obj.Appearance(appidx),'marker','none');
%     end
%
%     % highlight control
%     idx = obj.selectionidx;
%     if ~isempty(idx) && 1 <= idx && idx <= N
%         switch lower(obj.selectiontype)
%             case 'point'
%                 set(hpt(idx),obj.Highlight,'linestyle','none');
%             case 'segment'
%                 set(hln(idx),obj.Highlight,'marker','none');
%             case 'line'
%                 tf = (obj.indices(:,1) == obj.indices(idx,1));
%                 set(hpt(tf),obj.Highlight,'linestyle','none');
%                 set(hln(tf),obj.Highlight,'marker','none');
%                 set(hpt(tf),'visible','off');
%             case 'all'
%                 set(hpt(:),obj.Highlight,'linestyle','none');
%                 set(hln(:),obj.Highlight,'marker','none');
%                 set(hpt(:),'visible','off');
%         end
%     end

    % determine objects to highlight
    idx = obj.selectionidx;

    tfpth = false(N,1);
    tflnh = false(N,1);
    tfptv = true(N,1);

    if ~isempty(idx) && 1 <= idx && idx <= N
        switch lower(obj.selectiontype)
            case 'point',
                tfpth(idx) = 1;
            case 'segment'
                tflnh(idx) = 1;
            case 'line'
                tf = (obj.indices(:,1) == obj.indices(idx,1));
                tfpth = tf;
                tflnh = tf;
                tfptv = ~tf;
            case 'all'
                tfpth(:) = true;
                tflnh(:) = true;
                tfptv(:) = false;
        end
    end

    % set appearance
    rng = [0,cumsum(npos)];
    for k = 1:nline
        idx = rng(k)+1 : rng(k+1);
        appidx = mod(k-1,numel(obj.Appearance))+1;

        idxpt = idx(~tfpth(idx));
        set(hpt(idxpt),obj.Appearance(appidx),'linestyle','none');

        idxln = idx(~tflnh(idx));
        set(hln(idxln),obj.Appearance(appidx),'marker','none');
    end

    % set highlight
    set(hpt(tfpth),obj.Highlight,'linestyle','none');
    set(hln(tflnh),obj.Highlight,'marker','none');

    % set visibility
    set(hpt( tfptv),'visible','on');
    set(hpt(~tfptv),'visible','off');

% fprintf('imcline toc final: %0.4f\n',toc(tobj))
end

%% CREATE DRAWING OBJECTS
% These two functions create default points and lines with the necessary
% properties, including pointer manager behaviors, context menus, button
% down behaviors, and appearance.

function h = createPoints(obj,N)
% CREATE POINTS initialize N line objects for control point display

    % create object array
    h = preAllocateGraphicsObjects(N,1);
    for k = N:-1:1
        h(k) = line('parent',obj.hptgroup,'tag','point',...
            'linestyle','none');
    end

    % pointer manager behavior
    pb = struct('enterFcn',[],'traverseFcn',[],'exitFcn',[]);
    for k = 1:N
        pb.enterFcn = @(varargin)enter(obj,h(k));
        pb.exitFcn  = @(varargin)exit_imcline(obj);
        iptSetPointerBehavior(h(k), pb);
    end

    % context menu, button down behavior
    set(h,'UIContextMenu',obj.hptmenu,...
        'ButtonDownFcn',@(varargin)drag(obj));
end

function h = createLines(obj,N)
% CREATE LINES initialize N line objects for line segment display

    % create lines
    h = preAllocateGraphicsObjects(N,1);
    for k = N:-1:1
        h(k) = line('parent',obj.hlngroup,'tag','segment',...
            'marker','none');
    end

    % pointer manager behavior
    pb = struct('enterFcn',[],'traverseFcn',[],'exitFcn',[]);
    for k = 1:N
        pb.enterFcn = @(varargin)enter(obj,h(k));
        pb.exitFcn  = @(varargin)exit_imcline(obj);
        iptSetPointerBehavior(h(k), pb);
    end

    % context menu, button down behavior
    set(h,'UIContextMenu',obj.hlnmenu,...
        'ButtonDownFcn',@(varargin)drag(obj));
end

%% POINTER MANAGER BEHAVIOR: ENTER/EXIT DRAWING OBJECTS
% When the Pointer Manager for the IMCLINE figure is enabled, the IMCLINE
% object will respond to user clicks. The figure pointer & IMCLINE will
% change appearance as the user highlights different portions of the
% IMCLINE object.  These functions control the pointer behavior as the
% user ENTERS and EXITS the IMCLINE display.

function enterFcn(obj,hobj)
% ENTER IMCLINE OBJECT - record selection & update appearance

    % clear current selection
    obj.selectionidx = [];
    obj.selectiontype = '';

    % get zoom/pan objects
    hzoom = zoom(obj.hfig);
    hpan  = pan(obj.hfig);
    hrot  = rotate3d(obj.hfig);
    state = {hzoom.Enable,hpan.Enable,hrot.Enable};

    % check if we should ignore the selection
    if any(strcmpi(state,'on'))
        return;
    end

    % check for valid object
    if ~ischild(obj.hgroup,hobj), return; end

    % update figure pointer
    type = get(hobj,'tag');
    switch lower(type)
        case 'segment',
            set(obj.hfig,'pointer','fleur');
        case 'point',
            set(obj.hfig,'pointer','crosshair');
        otherwise
            return
    end

    % set current index & type
    indices = get(hobj,'userdata');
    obj.selectionidx  = indices(1);
    obj.selectiontype = type;

    % update display
    redraw(obj);
end

function exitFcn(obj)
% EXIT IMCLINE OBJECT - clear & update

    % clear selection variables
    obj.selectionidx = [];
    obj.selectiontype = '';

    % update display
    redraw(obj);
end

function tf = ischild(hparent,hchild)
% HELPER FUNCTION: is HCHILD under HPARENT hierarchy
    hchildren = findall(hparent);
    hchildren = hchildren(2:end);

    tf = ishandle(hparent) && ishandle(hchild) && ...
        ~isempty(hchildren) && any(hchildren == hchild);
end

%% IMCLINE DRAG
% After a user initiates a single left-click on a portion of the IMCLINE
% display, they may then drag the cLINE object around the axes. Control
% points can be moved independently, while line segments shift the entire
% object.

function dragFcn(obj)
    cleanupObj = onCleanup(@()dragCleanup(obj));
    dragSubFcn(obj);
    delete(cleanupObj);
end

function dragSubFcn(obj)

    % check for valid object & normal single click
    if isempty(obj.selectionidx) || ...
       ~any(strcmpi(obj.selectiontype,{'segment','point'})) || ...
       ~strcmpi(get(obj.hfig,'SelectionType'),'normal')
        return;
    end

    % stop PointerManager
    iptPointerManager(obj.hfig, 'disable')

    % disable cLINE save
    obj.undocache = obj.hcline.UndoEnable;
    obj.hcline.UndoEnable = false;

    % current index/type
    type = obj.selectiontype;
    idx  = obj.selectionidx;
    lidx = obj.indices(idx,1);
    pidx = obj.indices(idx,2);

    % current point & position
    pt0  = get(obj.hax,'currentpoint');
    pt0  = pt0([1 3]);
    pos0 = obj.hcline.Position;

    % determine selection type & drag event data
    switch lower(type)
        case 'segment'
            if lidx <= numel(obj.IndependentDrag) && ...
               isequal(obj.IndependentDrag{lidx},'on')
                obj.selectiontype = 'line';
                data = {'line',[],[]};
            else
                obj.selectiontype = 'all';
                data = {'all',[],[]};
            end
        otherwise
            data = {'point',lidx,pidx};
    end

    % initialize buttonmotion/buttonup functions
    obj.dragiptids(1) = iptaddcallback(obj.hfig, ...
        'WindowButtonMotionFcn',@(varargin)buttonMotion());
    obj.dragiptids(2) = iptaddcallback(obj.hfig,...
        'WindowButtonUpFcn',@(varargin)buttonUp());

    % clear error/user data
    set(obj.hgroup,'UserData',[]);

    % create motion cancellation id
    cancelid = 0;

    % redraw
    redraw(obj);

    % notify listeners
    % note that listeners block execution, so to avoid error we notify
    % the event just prior to the the "waitfor" command
    if strcmpi(obj.selectiontype,'all')
        notify(obj,'DragEvent',dragEventData(data{:}));
    end

    % wait for completion
    try
        waitfor(obj.hgroup,'UserData','DragComplete');
    catch
    end

    % ----------SUBFUNCTION: BUTTON MOTION----------
    function buttonMotion()

        % allow interruption if a new event has been called
        % this simple technique depends on the PAUSE, allowing pending
        % buttonmotion events to execute, cancelling old unneccessary
        % graphics updates
        id = cancelid + 1;
        if id > 255, id = 0; end
        cancelid = id;
        drawnow
        if id ~= cancelid, return; end

        % get current point
        pt = get(obj.hax,'currentpoint');
        pt = pt([1 3]);

        % line selection - move entire object
        % point selection - move point only
        switch lower(obj.selectiontype)
            case 'point'
                obj.hcline.Position{lidx}(pidx,:) = pt;
            case 'line'
                shft = pt - pt0;
                newpos = pos0{lidx} + shft(ones(size(pos0{lidx},1),1),:);
                obj.hcline.Position{lidx} = newpos;

            case 'all'
                shft = pt - pt0;
                newpos = pos0;
                for k = 1:obj.hcline.NumberOfLines
                    newpos{k} = pos0{k} + shft(ones(size(pos0{k},1),1),:);
                end
                obj.hcline.Position = newpos;
        end
    end

    %----------SUBFUNCTION: BUTTON RELEASE----------
    function buttonUp()

        % cleanup
        ids = obj.dragiptids;
        iptremovecallback(obj.hfig,'WindowButtonMotionFcn',ids(1));
        iptremovecallback(obj.hfig,'WindowButtonUpFcn',ids(2));
        obj.dragiptids = [0 0];

        % notify waitfor command
        set(obj.hgroup,'UserData','DragComplete');
    end
end

function dragCleanup(obj)

    % ensure dragSubFcn has ended
    set(obj.hgroup,'UserData','DragComplete');

    % cleanup callbacks
    % note that doing this more than once (e.g. by the buttonUp and
    % dragCleanup functions) doesn't result in an error.
    ids = obj.dragiptids;
    iptremovecallback(obj.hfig,'WindowButtonMotionFcn',ids(1));
    iptremovecallback(obj.hfig,'WindowButtonUpFcn',ids(2));
    obj.dragiptids = [0 0];

    % replace selection type
    if any(strcmpi(obj.selectiontype,{'line','all'}))
        obj.selectiontype = 'segment';
    end

    % re-enable undo
    if ~isempty(obj.undocache)
        obj.hcline.UndoEnable = obj.undocache;
        obj.undocache = [];
    end

    % restart pointer manager
    iptPointerManager(obj.hfig, 'enable')

    % notify listeners
    notify(obj,'DragEvent',dragEventData('complete',[],[]));

    % update display
    % note this is the LAST thing we do - if the user pressed CTRL-C, this
    % function can sometimes not completely finish.  Even if we aren't able
    % to complete the redraw, we still need to make sure the state of the
    % object is back to normal.
    redraw(obj);
end

%% LINE CONTEXT MENU
% If the user right-clicks on a line segment, they are offered
% several choices from a context menu:
%   ADD POINT...........add a control point to the line segment
%   STRAIGHTEN SEGMENT..straighten the current line segment
%   CURVE SEGMENT.......curve the current line segment
%   CLOSED cLINE........close the cLINE object
%   OPEN cLINE..........open the cLINE object

function lnContextOpen(obj)

    % clear context menu of existing children
    hmenu = obj.hlnmenu;
    delete(allchild(hmenu));

    % cline object, current index, current point
    hcline = obj.hcline;
    idx = obj.selectionidx;
    lidx = obj.indices(idx,1);
    pidx = obj.indices(idx,2);

    pt = get(obj.hax,'currentpoint');
    pt = pt([1 3]);

    % check for valid indices
    if isempty(idx) || ~strcmpi(obj.selectiontype,'segment')
        return;
    end

    % add point option
    sep = 'off';
    if strcmpi('on',obj.ContextAdd)
        uimenu(hmenu,'Tag','AddPoint',...
            'Label','Add Point',...
            'Callback',@(varargin)addPoint());
        sep = 'on';
    end

    % straight/curved option
    if strcmpi('on',obj.ContextStraightCurved)
        hstr = uimenu(hmenu,'Tag','StraightSeg',...
            'separator',sep,...
            'Label','Straight Segment',...
            'Callback',@(varargin)straightSegment());
        hcrv = uimenu(hmenu,'Tag','CurvedSeg',...
            'Label','Curved Segment',...
            'Callback',@(varargin)curvedSegment());
        if hcline.IsCurved{lidx}(pidx)
            set(hcrv,'Checked','on');
        else
            set(hstr,'Checked','on');
        end
        sep = 'on';
    end

    % open/closed option
    if strcmpi('on',obj.ContextOpenClosed)
        hopn = uimenu(hmenu,'Tag','OpenLine',...
            'separator',sep,...
            'Label','Open Contour',...
            'Callback',@(varargin)openLine());
        hcls = uimenu(hmenu,'Tag','CloseLine',...
            'Label','Closed Contour',...
            'Callback',@(varargin)closeLine());
        if hcline.IsClosed{lidx}
            set(hcls,'Checked','on');
        else
            set(hopn,'Checked','on');
        end
    end

    % ----------SUBFUNCTION: STRAIGHTEN SEGMENT-------
    function straightSegment()
        hcline.IsCurved{lidx}(pidx) = 0;
    end

    % ----------SUBFUNCTION: CURVE SEGMENT------------
    function curvedSegment()
        hcline.IsCurved{lidx}(pidx) = 1;
    end

    % ----------SUBFUNCTION: ADD POINT----------------
    function addPoint()

        % get current segment
        seg = hcline.getSegments(obj.Resolution,lidx);
        x = seg{pidx}(:,1);
        y = seg{pidx}(:,2);

        % if curved, find two closest points to user selection
        if hcline.IsCurved{lidx}(pidx)
            d = (x-pt(1)).^2 + (y-pt(2)).^2;
            [~,ind] = sort(d(:),'ascend');
            x = x(ind(1:2));
            y = y(ind(1:2));
        end

        % new point
        v1 = [diff(x),diff(y)];
        v2 = [pt(1)-x(1),pt(2)-y(1)];
        newpt = (dot(v1,v2)./dot(v1,v1)).*v1 + [x(1) y(1)];

        % add point to curve
        hcline.addPoint(lidx,pidx+1,newpt);
    end

    % ----------SUBFUNCTION: OPEN CLINE---------------
    function openLine()
        hcline.IsClosed{lidx} = 0;
    end

    % ----------SUBFUNCTION: CLOSE CLINE--------------
    function closeLine()
        hcline.IsClosed{lidx} = 1;
    end
end

%% POINT CONTEXT MENU
% If the user right-clicks a control point, they are offered
% three choices from a context menu:
%   DELETE POINT........delete the selected control point
%   SMOOTH POINT........smooth control point
%   CORNER POINT........corner control point

function ptContextOpen(obj)

    % clear context menu
    hmenu = obj.hptmenu;
    delete(allchild(hmenu));

    % cline object, current index, point
    hcline = obj.hcline;
    idx = obj.selectionidx;
    lidx = obj.indices(idx,1);
    pidx = obj.indices(idx,2);

    % check for valid indices
    if isempty(idx) || ~strcmpi(obj.selectiontype,'point')
        return;
    end

    % delete point option
    sep = 'off';
    if size(obj.hcline.Position{lidx},1) > 3 && ...
       strcmpi('on',obj.ContextDelete)
        uimenu(hmenu,'Tag','DeletePoint',...
            'Label','Delete Point',...
            'Callback',@(varargin)deletePoint());
        sep = 'on';
    end

    % smooth/corner option
    if strcmpi('on',obj.ContextSmoothCorner)
        hsmo = uimenu(hmenu,'Tag','SmoothPoint',...
            'Label','Smooth Point',...
            'Callback',@(varargin)smoothPoint(),...
            'separator',sep);
        hcrn = uimenu(hmenu,'Tag','CornerPoint',...
            'Label','Corner Point',...
            'Callback',@(varargin)cornerPoint());

        % turn on checkmark
        if hcline.IsCorner{lidx}(pidx)
            set(hcrn,'Checked','on');
        else
            set(hsmo,'Checked','on');
        end
    end

    %----------SUBFUNCTION: SMOOTH POINT----------
    function smoothPoint()
        hcline.IsCorner{lidx}(pidx) = 0;
    end

    %----------SUBFUNCTION: CORNER POINT----------
    function cornerPoint()
        hcline.IsCorner{lidx}(pidx) = 1;
    end

    %----------SUBFUNCTION: DELETE POINT----------
    function deletePoint()
        hcline.deletePoint(lidx,pidx);
    end
end

%% SET PROPERTIES
% These functions control the more complex property SET behaviors,
% including APPEARANCE, HIGHLIGHT, and INDEPENDENT DRAG.
% These functions return valid corrected versions of the inputs, as the
% IMCLINE values can only be set within the actual SET function (otherwise
% resulting in infinite recursion).

function s = setAppearanceFcn(obj,s)
% SET APPEARANCE

    % test structure
    if ~isstruct(s)
        error(sprintf('%s:invalidAppearance',mfilename),...
            'Appearance must be a structure.');
    end

    % ensure that the appearance structure contains all and only
    % the expected fields
    tags = fieldnames(obj.defappearance);
    c = setxor(tags,fieldnames(s));

    if ~isempty(c)
        error(sprintf('%s:invalidAppearance',mfilename),...
            'One or more Appearance fields are invalid or missing.');
    end

    % locate any empty fields within the input structure and
    % replace with default values
    for k = 1:numel(s)
        for ti = 1:numel(tags)
            tag = tags{ti};
            if isempty(s(k).(tag))
                s(k).(tag) = obj.defappearance.(tag);
            end
        end
    end

    % check fields for compliance
    for k = 1:numel(s)
        [tf,errstr] = checkAppearance(s(k));
        if ~tf
            error(sprintf('%s:invalidAppearance',mfilename),'%s',...
                'The ''', errstr, ''' field of element ', num2str(k), ...
                ' of the new Appearance structure is invalid. ',...
                'IMCLINE Appearance will not be updated.');
        end
    end
end

function s = setHighlightFcn(obj,s)
% SET HIGHLIGHTED APPEARANCE

    % test structure
    if ~isstruct(s) || numel(s) ~= 1
        error(sprintf('%s:invalidHighlight',mfilename),...
            'Highlight must be a [1x1] structure.');
    end

    % ensure that the highlight structure contains all and only
    % the expected fields
    tags = fieldnames(obj.defhighlight);
    c = setxor(tags,fieldnames(s));

    if ~isempty(c)
        error(sprintf('%s:invalidHighlight',mfilename),...
            'One or more Highlight fields are invalid or missing.');
    end

    % check fields for compliance
    [tf,errstr] = checkAppearance(s);
    if ~tf
        error(sprintf('%s:invalidHighlight',mfilename),'%s',...
            'The ''', errstr, ''' field of the new Highlight ',...
            'structure is invalid. The IMCLINE will not be updated.');
    end
end

function val = setIndependentDrag(val)

    % test for cell array
    if ~iscell(val)
        error(sprintf('%s:invalidIndependentDrag',mfilename),'%s',...
            'IndependentDrag must be a cell array of strings ',...
            'containing the strings [on|off].');
    end

    % locate empty cells, fill with "off"
    val(cellfun(@isempty,val)) = {'off'};

    % test for cellstr constaining expected values
    if ~iscellstr(val) || ~all(strcmpi(val,'on') | strcmpi(val,'off'))
        error(sprintf('%s:invalidIndependentDrag',mfilename),'%s',...
            'IndependentDrag must be a cell array of strings ',...
            'containing the strings [on|off].');
    end
end

%% HELPER FUNCTIONS: CHECK PROPERTIES
% The following validation functions check various user inputs for
% acceptable values. If validation is successful, each function
% outputs the final form of the property in question.
%
% CHECKAPPEARANCE merely validates the input structure, outputting a
% TRUE/FALSE value and error string.

function val = checkResolution(val)
% CHECK CURVED LINE SEGMENT RESOLUTION
    if ~isnumeric(val) || numel(val) ~= 1
        error(sprintf('%s:invalidResolution',mfilename),...
            'Invalid ''Resolution'' value, must be scalar number.');
    end
end

function val = checkStrings(val,name,vals)
% CHECK STRING INPUT
% val....input string
% name...property name (for error)
% vals...allowable input strings

    if ~ischar(val) || ~any(strcmpi(val,vals))
        str = sprintf('%s|',vals{:});
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            'Invalid ''', name,''' value - valid values are [',...
            str(1:end-1),'].');
    end
end

function [tf,errstr] = checkAppearance(s)
% check appearance structure s, where s has the following fields:
%   Color, LineStyle, LineWidth, Marker, MarkerEdgeColor,
%   MarkerFaceColor, and MarkerSize.
%
% tf.......true/false validation output
% errstr...error string, indicating invalid structure field

    % allowable values
    linestyle = set(0,'DefaultLineLineStyle');
    marker = set(0,'DefaultLineMarker');
    markeredgecolor = set(0,'DefaultLineMarkerEdgeColor');
    markerfacecolor = set(0,'DefaultLineMarkerFaceColor');

    % default output
    tf = true;
    errstr = [];

    % test all properties
    if ~iscolor(s.Color)

        errstr = 'Color';

    elseif ~ischar(s.LineStyle) || ...
       ~any(strcmpi(s.LineStyle,linestyle))

        errstr = 'LineStyle';

    elseif ~isnumeric(s.LineWidth) || ...
       ~isscalar(s.LineWidth) || ...
       s.LineWidth <= 0

        errstr = 'LineWidth.';

    elseif ~ischar(s.Marker) || ...
       ~any(strcmpi(s.Marker,marker))

        errstr = 'Marker';

    elseif ~iscolor(s.MarkerEdgeColor) && ...
       (~ischar(s.MarkerEdgeColor) || ...
        ~any(strcmpi(s.MarkerEdgeColor,markeredgecolor)))

        errstr = 'MarkerEdgeColor';

    elseif ~iscolor(s.MarkerFaceColor) && ...
       (~ischar(s.MarkerFaceColor) || ...
        ~any(strcmpi(s.MarkerFaceColor,markerfacecolor)))

        errstr = 'MarkerFaceColor';

    elseif ~isnumeric(s.MarkerSize) || ...
       ~isscalar(s.MarkerSize) || ...
       s.MarkerSize <= 0

        errstr = 'MarkerSize';
    end

    % return in error
    if ~isempty(errstr)
       tf = false;
       return
    end
end
