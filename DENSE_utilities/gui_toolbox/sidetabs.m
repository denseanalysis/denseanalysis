%% SIDETABS HANDLE CLASS DEFINITION
% Create a set of vertical tabs on the left-side of a figure.
% This function allows a user to in essence have multiple figures within a
% single figure, switching between children UIPANEL objects via a simple
% point-and-click interface.
%
%IMPORTANT: To start using the sidetabs, Pointer Manager must be enabled!
%   ex.  iptPointerManager(handle_figure,'enable')
%
%
%PROPERTIES
%
%   Parent...........parent figure of SIDETABS object
%       Get enabled,  defaults to GCF
%
%   BackgroundColor..background color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [.7 .7 .7]
%
%   BorderColor......border color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [100 121 162]/255
%
%   HighlightColor...mouse-over tab highlight color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [1 0.8 0.6]
%
%   FontAngle........tab title font angle
%       Set/Get enabled, [{normal} | italic | oblique]
%
%   FontSize.........tab title font size (in points)
%       Set/Get enabled, defaults to 8
%
%   FontName.........tab title font
%       See LISTFONTS for your available fonts
%       Set/Get enabled, defaults to 'default' system font
%
%   FontWeight.......tab title font weight
%       Set/Get enabled, [light | {normal} | demi | {bold}]
%
%   FontColor........tab title font color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to 'black'
%
%   TabWidth.........tab width (in pixels)
%       Set/Get enabled, defaults to 30
%
%   TabHeight........tab height (in pixels)
%       Set/Get enabled, defaults to 60
%
%   TabNames.........cell array of string tab titles
%       Set/Get enabled (after successful ADDTAB)
%
%   ActiveTab........active tab index
%       Tabs are numbered from 1->N, starting from the top of the figure
%       Set/Get enabled
%
%   Enable...........cell array of 'on'/'off' strings, indicating if each
%       tab is selectable. Set/Get enabled, each new tab defaults to 'on'
%
%   NumberOfTabs.....number of tabs in SIDETABS object
%       Get enabled
%
%   Width............width of SIDETABS object
%       Get enabled
%
%   DistanceToPanel..distance from SIDETABS to reference panels
%       Set/Get enabled, defaults to 0
%
%
%EVENTS
%
%   SwitchTab........indicates if a new tab has been selected, either
%       through an interactive mouse click or programmatic update.
%
%
%METHODS
%
%   OBJ = SIDETABS(HFIG) create an empty SIDETABS object within the figure
%   HFIG. This object will span the entire height of the figure, as wide
%   as necessary to contain the tabs of width TabWidth.  Note that the
%   height of the SIDETABS object is automatically tied to the figure
%   height, and that the SIDETABS object will be deleted upon figure
%   deletion.
%
%   OBJ = SIDETABS() is the same as OBJ = SIDETABS(GCF)
%
%   OBJ.ADDTAB(STR) add a tab with the specified title string STR to
%   the SIDETABS object OBJ.  The appearance of this tab is specified by
%   the various SIDETABS properties.  The color of each new tab is tied to
%   the color of the parent figure.
%
%   OBJ.ADDTAB(STR,HPANEL) additionally adds a reference to an external
%   UIPANEL object HPANEL, passing control of the HPANEL visibility and
%   position to the SIDETABS object. When the new tab is active, HPANEL is
%   visible and takes up the remainder of the available figure space. When
%   the new tab is not active, hpanel is invisible.
%
%   OBJ.REMOVETAB(IDX) removes the IDXth tab from the SIDETABS object.
%   Any external panel related to this tab is removed from the control of
%   the SIDETABS object, but not deleted.
%
%   OBJ.REORDER(PERM) reorder the SIDETABS children according to PERM, a
%   new index vector equal to a permutation of all possible tab indices
%   (i.e. setdiff(1:obj.NumberOfTabs,PERM) == []).
%
%   OBJ.REDRAW redraw the SIDETABS object. Generally, the object will
%   automatically redraw when necessary. However, the user may externally
%   initiate a redraw via this function.
%
%   DELETE(OBJ) delete the SIDETABS object.
%
%
%EXAMPLE
%
%   This example initializes a two-tab system, each displaying a
%   different axes/image.
%
%     % create figure
%     hfig = figure;
%     set(hfig,'DefaultUIPanelBackgroundColor',get(hfig,'color'));
%     set(hfig,'DefaultUIPanelBorderType','none');
%
%     % load demo images
%     images = load('imdemos');
%
%     % panels & axes display
%     hpn1 = uipanel('parent',hfig);
%     hax1 = axes('parent',hpn1);
%     hpn2 = uipanel('parent',hfig);
%     hax2 = axes('parent',hpn2);
%
%     % display images
%     imshow(images.coins2,'parent',hax1);
%     imshow(images.liftbody256,'parent',hax2);
%
%     % init sidetabs
%     obj = sidetabs(hfig);
%     obj.addTab('Coins2',hpn1);
%     obj.addTab({'LiftBody','256'},hpn2);
%     obj.TabHeight = 80;
%     obj.TabWidth  = 40;
%
%     % start pointer manager
%     iptPointerManager(gcf,'enable');
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


%% CLASS DEFINITION
classdef sidetabs < handle

    % general properties
    properties (SetObservable)

        BackgroundColor = [.7 .7 .7];
        BorderColor     = [100 121 162]/255;
        HighlightColor  = [1 0.8 0.6];
        FontAngle       = 'normal';
        FontName        = 'default';
        FontSize        = 8;
        FontWeight      = 'bold';
        FontColor       = [0 0 0];

        TabWidth        = 30;
        TabHeight       = 60;
        DistanceToPanel = 0;

        TabNames  = {};
        ActiveTab = [];
        Enable    = {};

    end

    % other properties
    properties (SetAccess='private')
        NumberOfTabs = 0;
    end
    properties (Dependent=true,SetAccess='private')
        Parent
        Width
    end

    % private properties
    properties (Hidden=true,SetAccess='private',GetAccess='private')

        % parent handle (& saved position)
        hparent
        posparent

        % graphic handles
        hsidepanel
        hline
        hbar
        htabs
        htitles

        % references to external panels
        hrefpanels

        % listeners
        hlisten_parent
        hlisten_delete

        % enable/disable the redraw function
        redrawenable = false;

        % other hidden parameters
        TabMargin     = 5;
        TabSeparation = 5;
        TabGrowth     = 2;

    end


    % public observable events
    events
        SwitchTab
    end


    % method prototypes
    methods

        % CONSTRUCTOR & DESTRUCTOR
        function obj = sidetabs(varargin)
            obj = sidetabsFcn(obj,varargin{:});
        end
        function delete(obj)
            deleteFcn(obj);
        end

        function inds = find(obj, criteria)
            if ischar(criteria)
                objs = findobj(obj.hrefpanels, 'Tag', criteria);

                if isempty(objs)
                    tf = cellfun(@(x)isequal(criteria, x), obj.TabNames);
                    inds = find(tf);
                else
                    inds = find(obj, objs);
                end
            elseif iscellstr(criteria)
                inds = find(cellfun(@(x)isequal(criteria, x), obj.TabNames));
            elseif ishghandle(criteria, 'uicontainer')
                inds = find(ismember(double(obj.hrefpanels), double(criteria)));
            else
                error(sprintf('%s:InvalidCriteria', mfilename), ...
                    'You must specify either a tag, title, or uipanel object');
            end
        end


        % ACTION functions
        function obj = addTab(obj,varargin)
            obj = addTabFcn(obj,varargin{:});
        end

        function obj = removeTab(obj,idx)
            obj = removeTabFcn(obj,idx);
        end

        function obj = reorder(obj,idx)
            obj = reorderFcn(obj,idx);
        end

        function obj = redraw(obj)
            obj = redrawFcn(obj);
        end


        % GET functions
        function val = get.Width(obj)
            pos = getpixelposition(obj.hsidepanel);
            val = pos(3);
        end
        function val = get.Parent(obj)
            val = obj.hparent;
        end


        % SET functions
        function obj = set.Parent(obj,h)
            obj = setParentFcn(obj,h);
            obj = redrawFcn(obj);
        end

        function obj = set.BackgroundColor(obj,val)
            obj.BackgroundColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end
        function obj = set.BorderColor(obj,val)
            obj.BorderColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end
        function obj = set.HighlightColor(obj,val)
            obj.HighlightColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end

        function obj = set.FontAngle(obj,val)
            obj.FontAngle = checkStringsFcn(val,'FontAngle',...
                set(0,'DefaultTextFontAngle'));
            obj = redrawFcn(obj);
        end
        function obj = set.FontName(obj,val)
            obj.FontName = checkFontNameFcn(val);
            obj = redrawFcn(obj);
        end
        function obj = set.FontSize(obj,val)
            obj.FontSize = checkPositiveScalarFcn(val,'FontSize');
            obj = redrawFcn(obj);
        end
        function obj = set.FontWeight(obj,val)
            obj.FontWeight = checkStringsFcn(val,'FontWeight',...
                set(0,'DefaultTextFontWeight'));
            obj = redrawFcn(obj);
        end
        function obj = set.FontColor(obj,val)
            obj.FontColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end

        function obj = set.TabWidth(obj,val)
            obj.TabWidth = checkPositiveScalarFcn(val,'TabWidth');
            obj = redrawFcn(obj);
        end
        function obj = set.TabHeight(obj,val)
            obj.TabHeight = checkPositiveScalarFcn(val,'TabHeight');
            obj = redrawFcn(obj);
        end
        function obj = set.DistanceToPanel(obj,val)
            obj.DistanceToPanel = ...
                checkPositiveScalarFcn(val,'DistanceToPanel');
            obj = redrawFcn(obj);
        end

        function obj = set.ActiveTab(obj,idx)
            obj.ActiveTab = checkActiveTabFcn(obj,idx);
            obj = redrawFcn(obj);
            if obj.NumberOfTabs > 1, notify(obj,'SwitchTab'); end
        end

        function obj = set.TabNames(obj,str)
            obj.TabNames = checkTabNamesFcn(obj,str);
            obj = redrawFcn(obj);
        end

        function obj = set.Enable(obj,val)
            obj.Enable = checkEnableFcn(obj,val);
            obj = redrawFcn(obj);
        end

    end


    % hidden method prototypes
    methods (Hidden=true)

        function val = ishandle(obj)
            val = ishandle(obj.hsidepanel);
        end
    end

    methods (Hidden=true,Access='private');
        function obj = setActiveTab(obj,idx)
            obj.ActiveTab = idx;
        end
        function obj = redrawPrimer(obj,src)
            obj = redrawPrimerFcn(obj,src);
        end
    end

end



%% CONSTRUCTOR
% This function creates the SIDETABS object, initializing the uipanel
% objects used to contain the tabs as well as listeners to resize/delete
% the SIDETABS object.

function obj = sidetabsFcn(obj,hparent)
% obj.....SIDETABS object
% hfig....Figure parent

    % check number of inputs
    narginchk(1, 2);

    % parse parent argument
    % (note this function also creates the parent deletion listener)
    if nargin < 2, hparent = gcf; end
    obj = setParentFcn(obj,hparent);

    % initialize sidebar object
    obj.hsidepanel = uipanel(...
        'parent',           hparent,...
        'bordertype',       'line');

    % initialize separator bar (another panel)
    obj.hbar = uipanel(...
        'parent',           obj.hsidepanel,...
        'bordertype',       'line');

    % initialize "line" (yet another panel)
    obj.hline = uipanel(...
        'parent',           obj.hsidepanel,...
        'bordertype',       'line');

    % Cache handle to sidetabs object in hg hierarchy so that if
    % user loses handle to imcline object, the object still lives
    % in HG hierarchy and can be retrieved.
    setappdata(obj.hsidepanel,'imclineObjectReference',obj);

    % update display
    obj.redrawenable = true;
    redrawFcn(obj);

end



%% DESTRUCTOR
% ensure all listeners and graphic objects are deleted

function obj = deleteFcn(obj)

    % handles to listeners
    h = cat(1, obj.hlisten_parent(:), obj.hlisten_delete(:));
    delete(h(ishandle(h)));

    % delete drawing objects
    h = obj.hsidepanel;
    delete(h(ishandle(h)));
end



%% SET PARENT
% The user COULD move the object to various figures by changing
% the 'Parent' property (we currently do not allow this)
% We must ensure that the new parent is valid, as well as create
% new parent change/deletion listeners.

function obj = setParentFcn(obj,hparent)
% obj........objects
% hparent....candidate figure/uipanel

    % check for valid parent
    if ~isscalar(hparent) || ~ishghandle(hparent, 'figure')
        error(sprintf('%s:invalidParent',mfilename),'%s',...
            'Parent of SIDETABS must be a valid figure.');
    end

    % if the parent has not changed, we're all done
    if isequal(obj.hparent,hparent), return; end

    % delete current parent listeners
    if ~isempty(obj.hlisten_delete)
        delete(obj.hlisten_delete);
        obj.hlisten_delete = [];
    end

    if ~isempty(obj.hlisten_parent)
        delete(obj.hlisten_parent);
        obj.hlisten_parent = [];
    end

    % save parent
    obj.hparent = hparent;
    obj.posparent = getpixelposition(hparent);

    % move children to new parent (if children exist)
    if ~isempty(obj.hsidepanel) && ishandle(obj.hsidepanel)
        set(obj.hsidepanel,'Parent',hparent);
    end

    % Deletion listener: when the Parent is destroyed,
    % the object is no longer valid and must be destroyed
    obj.hlisten_delete = addlistener(obj.Parent, ...
        'ObjectBeingDestroyed',@(varargin)obj.delete());

    % Parent listener: when the parent is Resized, the color changes,
    % or the renderer changes, we need to update the SIDETABS object

    cback = @(src, evnt)obj.redrawPrimer(src);
    obj.hlisten_parent = [...
        position_listener(obj.Parent, cback);
        addlistener_mod(obj.Parent, 'Color', 'PostSet', cback);
        addlistener_mod(obj.Parent, 'Renderer', 'PostSet', cback)];
end



%% ADD TAB
% this function allows the user to add new tabs to the SIDETABS object,
% specifying a new title string as well as an optional UIPANEL object to be
% placed under the SIDETABS control.

function obj = addTabFcn(obj,str,href)
% obj.......SIDETABS object
% str.......tab name
% href......UIPANEL object to be placed under SIDETABS control

    % check string input
    if ~ischar(str) && ~iscellstr(str)
        error(sprintf('%s:invalidTabName',mfilename),...
            '''TabName'' must be a string or cell array of strings.');
    end

    % check handle input
    if nargin < 3 || isempty(href)
        href = NaN;
    elseif ~ishghandle(href, 'uicontainer') || ...
       ~isequal(obj.Parent, get(href, 'Parent'))
        error(sprintf('%s:invalidHandle',mfilename),'%s',...
            '''addTab'' accepts only UIPANEL objects with the same ',...
            'Parent as the SIDETABS object.');
    end

    % pause updates
    obj.redrawenable = false;

    % tab panel
    htab = uipanel(...
        'parent',           obj.hsidepanel,...
        'bordertype',       'line');

    % tab title
    htx = textfig(htab,...
        'position',             [0.5,0.5],...
        'string',               str,...
        'HorizontalAlignment',  'center',...
        'verticalalignment',    'middle',...
        'rotation',             90,...
        'hittest',              'off',...
        'handlevisibility',     'off');


    % increment number of tabs
    obj.NumberOfTabs = obj.NumberOfTabs + 1;
    idx = obj.NumberOfTabs;

    % save new handles to object
    obj.htabs(idx)      = htab;
    obj.htitles(idx)    = htx;
    obj.hrefpanels(idx) = href;

    % update ActiveTab (if empty)
    if isempty(obj.ActiveTab)
        obj.ActiveTab = 1;
    end

    % update other properties
    obj.TabNames{idx} = str;
    obj.Enable{idx}   = 'on';

    % update display
    obj.redrawenable = true;
    redrawFcn(obj);

end



%% REMOVE TABS
% This function allows the user to remove tab via their index.
% multiple tabs may be removed at once.

function obj = removeTabFcn(obj,idx)

    % pause updates
    obj.redrawenable = false;

    % check index
    if obj.NumberOfTabs == 0
        error(sprintf('%s:invalidIndex',mfilename),'%s',...
            'No tabs exist.');
    elseif ~isnumeric(idx) || any(idx<1 | obj.NumberOfTabs<idx)
        error(sprintf('%s:invalidIndex',mfilename),'%s',...
            'Invalid indices. Indices must be between 1 and ',...
            num2str(obj.NumberOfTabs));
    end

    % delete graphics (and children)
    delete(obj.htabs(idx));
    obj.htabs(idx) = [];
    obj.htitles(idx) = [];
    obj.hrefpanels(idx) = [];

    % update number of tabs
    obj.NumberOfTabs = numel(obj.htabs);

    % update index
    if obj.NumberOfTabs == 0
        obj.ActiveTab = [];
    else
        obj.ActiveTab = 1;
    end

    % delete associated properties
    obj.Enable(idx) = [];
    obj.TabNames(idx) = [];

    % resume updates
    obj.redrawenable = true;
    obj = redrawFcn(obj);

end


%% REORDER TABS
% by specifying a new permutation of the available tab indices, users can
% reorder the SIDETABS children.

function obj = reorderFcn(obj,idx)
% obj......object
% idx......new order permutation

    % pause updates
    obj.redrawenable = false;

    % check index
    if obj.NumberOfTabs == 0
        error(sprintf('%s:invalidIndex',mfilename),'%s',...
            'No tabs exist.');
    elseif ~isnumeric(idx) ||  ~isempty(setdiff(1:obj.NumberOfTabs,idx))
        error(sprintf('%s:invalidIndex',mfilename),'%s',...
            'Invalid indices. Indices must be between 1 and ',...
            num2str(obj.NumberOfTabs));

    end

    % reorder children
    obj.htabs = obj.htabs(idx);
    obj.htitles = obj.htitles(idx);
    obj.hrefpanels = obj.hrefpanels(idx);

    % update variables
    obj.Enable = obj.Enable(idx);
    obj.TabNames = obj.TabNames(idx);
    obj.ActiveTab = idx(obj.ActiveTab);

    % resume updates
    obj.redrawenable = true;
    obj = redrawFcn(obj);


end



%% REDRAW DISPLAY
% These functions control the SIDETABS object display refresh, executing
% after every significant property change.  Internally, the class may
% temporarilly  disable the REDRAW via the REDRAWENABLE property.
% The "redrawPrimerFcn" includes additional decisions on automated redraw
% from the "hlisten_parent" listener.


function obj = redrawPrimerFcn(obj,src)
% we want to limit a redraw on a position change, i.e. we should only
% redraw if the parent width/height changes, not its location on screen.

    update = true;
    pos = getpixelposition(obj.hparent);

    if strcmpi(src.Name,'Position') && ...
       all(pos(3:4) == obj.posparent(3:4))
        update = false;
    end

    obj.posparent = pos;
    if update, obj = redrawFcn(obj); end

end


function obj = redrawFcn(obj)

    % only allow redraw after setup
    if ~obj.redrawenable || ~ishandle(obj.Parent) || ...
       strcmpi(get(obj.Parent,'BeingDeleted'),'on')
        return;
    end

    % pause updates
    obj.redrawenable = false;


    %-----SIDE BAR UPDATE-----

    % determine parent position & color
    ppos = getpixelposition(obj.Parent);
    pclr = get(obj.Parent,'Color');

    % update graphics
    set(obj.hsidepanel,...
        'BackgroundColor',  obj.BackgroundColor,...
        'HighlightColor',   obj.BackgroundColor);
    setpixelposition(obj.hsidepanel,...
        [1 1 (obj.TabWidth+2*obj.TabMargin) ppos(4)]);

    set(obj.hline,...
        'BackgroundColor',  obj.BorderColor,...
        'HighlightColor',   obj.BorderColor);
    setpixelposition(obj.hline,...
        [(obj.TabWidth+obj.TabMargin) .5 1 ppos(4)]);

    set(obj.hbar,...
        'BackgroundColor',  pclr,...
        'HighlightColor',   pclr);
    setpixelposition(obj.hbar,...
        [(1+obj.TabWidth+obj.TabMargin) .5 obj.TabMargin ppos(4)]);


    %-----TAB UPDATE-----

    % quit if no tabs
    if obj.NumberOfTabs <= 0
        obj.redrawenable = true;
        return;
    end

    % current tab index
    idx = obj.ActiveTab;

    % upper left position
    xy = [obj.TabMargin+1, ...
          ppos(4)-obj.TabMargin-obj.TabHeight+1];

    % default tab positions
    tpos = zeros(obj.NumberOfTabs,4);
    for k = 1:obj.NumberOfTabs
        tpos(k,:) = [xy,obj.TabWidth,obj.TabHeight];
        xy(2) = xy(2) - obj.TabHeight - obj.TabSeparation;
    end

    % Active tab position
    g = obj.TabGrowth;
    tpos(idx,:) = tpos(idx,:) + [-g -g g+1 2*g];

    % update tabs
    set(obj.htabs,...
        'BackgroundColor',  pclr,...
        'HighlightColor',   obj.BorderColor,...
        'hittest',          'on');
    for k = 1:obj.NumberOfTabs
        setpixelposition(obj.htabs(k),tpos(k,:));
    end

    % update tab titles
    set(obj.htitles(:),...
        {'String'},     obj.TabNames(:),...
        'FontAngle',    obj.FontAngle,...
        'FontName',     obj.FontName,...
        'FontSize',     obj.FontSize,...
        'FontWeight',   obj.FontWeight,...
        'Color',        obj.FontColor);


    % redefine PointerBehavior & ButtonDown functions
    pb = struct('enterFcn',[],'traverseFcn',[],'exitFcn',[]);
    for k = 1:obj.NumberOfTabs
        if k == idx
            iptSetPointerBehavior(obj.htabs(k),[]);
            set(obj.htabs(k),'ButtonDownFcn',[]);
        else
            pb.enterFcn = @(varargin)enterFcn(obj,k);
            pb.exitFcn  = @(varargin)exitFcn(obj);
            iptSetPointerBehavior(obj.htabs(k),pb);
        end
    end

    % disable tabs
    for k = 1:obj.NumberOfTabs
        if strcmpi(obj.Enable{k},'off')
            set(obj.htitles(k),'Color',[165 163 151]/255);
            set(obj.htabs(k),'hittest','off');
        end
    end

    % reorder SIDETABS children
    uistack(obj.hbar,'top');



    %-----UIPANEL UPDATE-----

    % reference panel position
    xy = [(obj.TabWidth+2*obj.TabMargin+obj.DistanceToPanel+1),1];
    pos = [xy,ppos(3)-xy(1)+1,ppos(4)];

    % reference panel visibility
    vis = repmat({'off'},[1 obj.NumberOfTabs]);
    vis{idx} = 'on';

    % update reference panels
    % Note: if the reference panel is not changing position, we still
    % "wobble" the panel by a pixel to ensure the panel's 'ResizeFcn'
    % is triggered.
    tmp = false;
    href = obj.hrefpanels;
    for k = 1:obj.NumberOfTabs
        if ishandle(href(k)) && isequal(obj.Parent,get(href(k),'Parent'))
            set(href(k),'Visible',vis{k});
            p = getpixelposition(href(k));
            if all(p==pos)
                setpixelposition(href(k),pos+1);
            end
            setpixelposition(href(k),pos);
        else
            href(k) = NaN;
        end
    end

    % throw warning if any reference panels stopped exisiting
    if ~isequaln(href,obj.hrefpanels)
        warning(sprintf('%s:invalidPanel',mfilename),'%s',...
            'One or more panels under SIDETABS control became invalid ',...
            '(either the object handle no longer is valid, or the ',...
            'object parent has changed).');
        obj.hrefpanels = href;
    end

    % reallow redraw
    obj.redrawenable = true;


end


function enterFcn(obj,idx)
    set(obj.htabs(idx),'backgroundcolor',obj.HighlightColor);
    set(obj.htabs(idx),'ButtonDownFcn',@(varargin)obj.setActiveTab(idx));
end

function exitFcn(obj)
    set(obj.htabs,'backgroundcolor',get(obj.Parent,'color'));
    set(obj.htabs,'ButtonDownFcn',[]);
end



%% VALIDATION FUNCTIONS
% these functions validate certain SIDETABS properties, ensuring that the
% user inputs are as expected.

function val = checkColorFcn(val)
% check for a valid color specification (see COLORSPEC)
    [tf,errstr] = iscolor(val);
    if ~tf
        error(sprintf('%s:invalidColor',mfilename),errstr);
    end
    val = val(:)';
end

function val = checkStringsFcn(val,name,vals)
% check for a string matching a set of strings
% val.....string to check
% name....name of external function (e.g. 'FontWeight')
% vals....valid strings

    % character array
    if ~ischar(val) || ~any(strcmpi(val,vals))
        str = sprintf('%s|',vals{:});
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            'Invalid ''', name, ''' parameter. Valid strings are: ',...
            '[',str(1:end-1),'].');
    end
end

function val = checkPositiveScalarFcn(val,name)
% check for a positive scalar value

    if ~isnumeric(val) || ~isscalar(val) || val<=0
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            '''', name, ''' must a positive numeric value.');
    end

end


function val = checkFontNameFcn(val)
% check for valid font from LISTFONTS

    vals = listfonts;
    vals = [vals(:);'default';'FixedWidth';'monospaced'];
    if ~ischar(val) || ~any(strcmpi(val,vals))
        error(sprintf('%s:invalidFontName',mfilename),'%s',...
            'Invalid ''FontName'' - use LISTFONTS to determine ',...
            'available fonts for your system.');
    end
end


function idx = checkActiveTabFcn(obj,idx)
% check for valid ActiveTab property

    if obj.NumberOfTabs == 0
        if ~isempty(idx)
            error(sprintf('%s:invalidActiveTab',mfilename),'%s',...
                'Empty SIDETABS only accepts an empty ''ActiveTab''.');
        end
    else
        if ~isnumeric(idx) || ~isscalar(idx) || mod(idx,1)~=0 ...
            || idx<1 || obj.NumberOfTabs<idx
            error(sprintf('%s:invalidActiveTab',mfilename),'%s',...
                '''ActiveTab'' must refer to a valid tab index.');
        end
    end

end

function strs = checkTabNamesFcn(obj,strs)

    if obj.NumberOfTabs == 0
        if ~isempty(strs)
            error(sprintf('%s:invalidTabNames',mfilename),...
                'Empty object requires empty ''TabNames''.');
        end
    else
        if ~iscellstr_recursive(strs) || numel(strs) ~= obj.NumberOfTabs
            error(sprintf('%s:invalidTabNames',mfilename),'%s',...
                '''TabNames'' must be a valid cell array of strings ',...
                'equal to the number of tabs.');
        end
    end
    strs = strs(:)';
end

function val = checkDistanceToPanelFcn(val)
    if ~isnumeric(val) || ~isscalar(val) || val<0
        error(sprintf('%s:invalidDistanceToPanel',mfilename),'%s',...
            '''DistanceToPanel'' must a non-negative numeric value.');
    end
end

function val = checkEnableFcn(obj,val)
% obj....object
% val....cellstr of [on|off] (empty if obj.NumberOfTabs==0)

    N = obj.NumberOfTabs;

    errstr = [];
    if N==0
        if ~isempty(val)
            errstr = 'Empty object requires empty ''Enable''.';
        end
    else
        if numel(val)~=N || ~iscellstr(val) || ...
           ~all(strcmpi(val,'on') | strcmpi(val,'off'))
            errstr = sprintf('%s','''Enable'' must an [', num2str(N),...
                'x1] cell array of ''on'' or ''off'' strings.');
        elseif strcmpi(val{obj.ActiveTab},'off')
            errstr = 'The ''ActiveTab'' cannot be disabled.';
        end
    end

    if ~isempty(errstr)
        error(sprintf('%s:invalidEnable',mfilename),errstr);
    end

    val = val(:)';
end



%% END OF FILE=============================================================
