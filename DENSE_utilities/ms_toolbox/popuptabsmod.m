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
%       Set/Get enabled,  defaults to GCF
%
%   TabColor..tab color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [.7 .7 .7]
%
%   BorderColor......border color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [100 121 162]/255
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
classdef popuptabsmod < handle

    % set/get properties
    properties

        TabColor = [100 121 162]/255;
        BackgroundColor = 'none';

        FontAngle       = 'normal';
        FontName        = 'default';
        FontSize        = 8;
        FontWeight      = 'bold';
        FontColor       = [1 1 1];

        TabWidth  = 150;
        TabHeight = 20;
        PanelHeights = [];
        LeftOffset = 0;

        TabNames  = {};
        Visible   = {};
        Enable    = {};

    end



    % get-only properties
    properties (SetAccess='private')
        NumberOfTabs = 0;
    end

    % dependent set/get properties
    properties (Dependent=true)
        Parent
        IsOpen
    end

    properties (Dependent=true,SetAccess='private')
        Position
    end

    % private properties
    properties (Hidden=true,SetAccess='private',GetAccess='private')

        % parent property
        hparent

        % graphic handles
        hmainpanel
        htabpanel
        htabs
        hchecks
        hslider

        % references to external panels
        hrefpanels

        % listeners
        hlisten_parent
        hlisten_delete

        % enable/disable the redraw function
        redrawenable = false;

        % other hidden parameters
        TabMargin = 5;

        posparent = NaN(1,4);

    end


    % method prototypes
    methods

        % constructor
        function obj = popuptabsmod(varargin)
            obj = popuptabsFcn(obj,varargin{:});
        end

        % destructor
        function delete(obj)
            deleteFcn(obj);
        end


        % ACTION functions
        function obj = addTab(obj,varargin)
            obj = addTabFcn(obj,varargin{:});
        end

        function obj = redraw(obj)
            obj = redrawFcn(obj);
        end


        % GET/SET dependent properties
        function val = get.Parent(obj)
            val = obj.hparent;
        end
        function set.Parent(obj,val)
            obj = setParentFcn(obj,val);
            redrawFcn(obj);
        end


        function val = get.IsOpen(obj)
            val = get(obj.hchecks,'Value');
            if iscell(val), val = [val{:}]'; end
        end
        function set.IsOpen(obj,val)
            setIsOpenFcn(obj,val);
            redrawFcn(obj);
        end


        % SET functions
        function set.TabColor(obj,clr)
            obj.TabColor = checkColor(clr,{},'TabColor');
            redrawFcn(obj);
        end
        function set.BackgroundColor(obj,clr)
            obj.BackgroundColor = checkColor(clr,{'none'},'BackgroundColor');
            redrawFcn(obj);
        end

        function set.FontAngle(obj,val)
            obj.FontAngle = checkStringsFcn(val,'FontAngle',...
                set(0,'DefaultUIControlFontAngle'));
            redrawFcn(obj);
        end
        function set.FontName(obj,val)
            obj.FontName = checkFontNameFcn(val);
            redrawFcn(obj);
        end
        function set.FontSize(obj,val)
            obj.FontSize = checkPositiveScalarFcn(val,'FontSize');
            redrawFcn(obj);
        end
        function set.FontWeight(obj,val)
            obj.FontWeight = checkStringsFcn(val,'FontWeight',...
                set(0,'DefaultUIControlFontWeight'));
            redrawFcn(obj);
        end
        function set.FontColor(obj,val)
            obj.FontColor = checkColor(clr,{},'FontColor');
            redrawFcn(obj);
        end

        function set.TabWidth(obj,val)
            obj.TabWidth = checkPositiveScalarFcn(val,'TabWidth');
            redrawFcn(obj);
        end
        function set.TabHeight(obj,val)
            obj.TabHeight = checkPositiveScalarFcn(val,'TabHeight');
            redrawFcn(obj);
        end
        function set.LeftOffset(obj,val)
            obj.LeftOffset = checkLeftOffsetFcn(val);
            redrawFcn(obj);
        end

        function set.TabNames(obj,val)
            obj.TabNames = checkTabNamesFcn(obj,val);
            redrawFcn(obj);
        end

        function set.Visible(obj,val)
            obj.Visible = checkStringArrayFcn(obj,val,...
                'Visible',{'on','off'});
            redrawFcn(obj);
        end
        function set.Enable(obj,val)
            obj.Enable = checkEnableFcn(obj,val);
            redrawFcn(obj);
        end

        function set.PanelHeights(obj,val)
            obj.PanelHeights = val(:);
            redrawFcn(obj);
        end

        % global SET function
        function set(obj,varargin)
            setFcn(obj,varargin{:});
        end


    end


    % hidden overloaded properties
    methods (Hidden=true)

        function pos = getpixelposition(obj)
            pos = getpixelposition(obj.hmainpanel);
        end

    end

    methods (Hidden=true,Access='private');
        function redrawPrimer(obj,src)
            redrawPrimerFcn(obj,src);
        end
    end

end


%% CONSTRUCTOR
% This function creates the POPUPTABS object, initializing graphic
% objects and listeners to resize/delete the object.

function obj = popuptabsFcn(obj,hparent,varargin)
% obj........POPUPTABS object
% hparent....parent figure/uipanel

    % check number of inputs
    narginchk(1, Inf);

    % parse parent argument
    % (note this function also creates the parent deletion listener)
    if nargin < 2, hparent = gcf; end
    obj = setParentFcn(obj,hparent);

    % initialize main panel
    obj.hmainpanel = uipanel(...
        'parent',           obj.hparent,...
        'bordertype',       'none',...
        'BackgroundColor',  'none',...
        'units',            'pixels');

    % initialize tab panel
    obj.htabpanel = uipanel(...
        'parent',           obj.hmainpanel,...
        'bordertype',       'none',...
        'BackgroundColor',  'none',...
        'units',            'pixels');

    % initialize slider object
    obj.hslider = uicontrol(...
        'parent',       obj.hmainpanel,...
        'style',        'slider',...
        'visible',      'off',...
        'callback',     @(varargin)sliderCallback(obj),...
        'units',        'pixels');

    % Cache handle to POPUPTABS object in hg hierarchy so that if
    % user loses handle to imcline object, the object still lives
    % in HG hierarchy and can be retrieved.
    setappdata(obj.hmainpanel,'imclineObjectReference',obj);

    % parse all other input arguements
    set(obj,varargin{:});

    % update display
    obj.redrawenable = true;
    redrawFcn(obj);

end



%% DESTRUCTOR
% ensure all listeners and graphic objects are deleted
% move any reference panels to the parent prior to object deletion

function obj = deleteFcn(obj)

	% handles to listeners
    h = [obj.hlisten_parent, obj.hlisten_delete];
    delete(h(ishandle(h)));

    % move reference panels back to parent
    h = obj.hrefpanels;
    if ~isempty(h) && ishandle(obj.hparent) && ...
       ~strcmpi(get(obj.hparent,'BeingDeleted'),'on')
        try
            set(obj.hrefpanels,'Parent',obj.hparent);
        catch ERR
        end
    end

    % delete drawing objects
    h = obj.hmainpanel;
    delete(h(ishandle(h)));

end



%% SET PARENT
% The user is able to move the object to various figures or uipanels by
% changing the 'Parent' property. We must ensure that the new parent is
% valid, as well as create parent change/deletion listeners.

function obj = setParentFcn(obj,hparent)
% obj........PLAYBAR objects
% hparent....candidate figure/uipanel

    % check for valid parent
    if ~isscalar(hparent) || ~ishghandle(hparent) || ...
       ~any(strcmpi(get(hparent,'type'),{'figure','uipanel'}))
        error(sprintf('%s:invalidParent',mfilename),'%s',...
            'Parent of PLAYBAR must be a figure or uipanel.');
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
    if ~isempty(obj.hmainpanel) && ishandle(obj.hmainpanel)
        set(obj.hmainpanel,'Parent',hparent);
    end

    % Deletion listener: when the Parent is destroyed,
    % the object is no longer valid and must be destroyed
    obj.hlisten_delete = addlistener(obj.hparent, ...
        'ObjectBeingDestroyed',@(varargin)obj.delete());

    % Property listener: when the parent is Resized, the parent color
    % changes, or the ancestor figure is resized, we need to update
    % the object
    if strcmpi(get(obj.hparent,'type'),'figure')
        h = [obj.hparent];
        tags = {'Position'};
    else
        h = [obj.hparent,ancestor(obj.hparent,'figure')];
        tags = {'Position','Position'};
    end

    prp = cellfun(@(h,tag)findprop(h,tag),...
        num2cell(handle(h)),tags,'uniformoutput',0);
    obj.hlisten_parent = addlistener_mod(handle(h),cell2mat(prp),...
        'PostSet',@(src,evnt)obj.redrawPrimer(src));
end


%% SET ISOPEN
% programatically open/close the various popuptabs
% opening is only possible on enabled tabs with valid reference panels.

function obj = setIsOpenFcn(obj,val)

    val = logical(val);
    if numel(val) ~= obj.NumberOfTabs
        error(sprintf('%s:invalidIsOpen',mfilename),...
            'IsOpen requires an [Nx1] logical array.');
    end

    for k = 1:obj.NumberOfTabs
        if strcmpi(obj.Enable{k},'off') && val(k)
            warning(sprintf('%s:cannotOpenDisabledTab',mfilename),...
                'You cannot open a disabled tab.');
            continue;
        else
            set(obj.hchecks(k),'Value',val(k));
        end
    end
end



%% ADD TAB
% this function allows the user to add new tabs to the POPUPTABS object,
% specifying a new title string as well as an optional UIPANEL object to
% be placed under POPUPTABS control.

function obj = addTabFcn(obj,str,href)
% obj.......POPUPTABS object
% str.......tab name
% href......UIPANEL object to be placed under POPUPTABS control

    % check string input
    if ~ischar(str) && ~iscellstr(str)
        error(sprintf('%s:invalidTabName',mfilename),...
            '''TabName'' must be a string or cell array of strings.');
    end

    % check handle input
    if nargin < 3 || isempty(href)
        href = NaN;
    elseif ~ishandle(href) || ...
       ~strcmpi(get(href,'type'),'uipanel')

        error(sprintf('%s:invalidHandle',mfilename),'%s',...
            '''addTab'' accepts only UIPANEL objects with the same ',...
            'Parent as the POPUPTABS object.');
    end

    % pause updates
    obj.redrawenable = false;

    % tab panel
    htab = uipanel(...
        'parent',     obj.htabpanel,...
        'bordertype', 'line',...
        'units',      'pixels');

    % tab checkbox
    hcheck = uicontrol(...
        'parent',   htab,...
        'style',    'checkbox',...
        'value',    1,...
        'Callback', @(varargin)redrawFcn(obj),...
        'units',    'normalized',...
        'position', [0.05 0.05 .9 .9],...
        'cdata',    plusimage(obj.TabColor,obj.FontColor));

    % increment number of tabs
    obj.NumberOfTabs = obj.NumberOfTabs + 1;
    idx = obj.NumberOfTabs;

    % save new handles to object
    obj.htabs(idx)      = htab;
    obj.hchecks(idx)    = hcheck;
    obj.hrefpanels(idx) = href;

    % update other properties
    obj.TabNames{idx} = str;
    obj.Visible{idx} = 'on';


    % default reference panel height
    % move reference panels to POPUPTABS panel
    if isnan(href)
        obj.PanelHeights(idx) = 0;
        obj.Enable{idx} = 'off';
    else
        pos = getpixelposition(href);
        obj.PanelHeights(idx) = pos(4);
        set(href,'Parent',obj.htabpanel);
        obj.Enable{idx} = 'on';
    end

    % update display
    obj.redrawenable = true;
    redrawFcn(obj);

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

    if strcmpi(src.Name,'Position')
        pos = getpixelposition(obj.hparent);
        if any(pos(3:4) ~= obj.posparent(3:4))
            obj.posparent = pos;
            redraw(obj);
        end
    end

end


function obj = redrawFcn(obj)

    slwidth = 15;


    % only allow redraw after setup
    if ~obj.redrawenable || ~ishandle(obj.Parent) || ...
       strcmpi(get(obj.Parent,'BeingDeleted'),'on')
        return;
    end

    obj.redrawenable = false;

    % re-validate reference panels
    % throw warning if any reference panels stopped exisiting
    % or if they have externally changed parent
    href = obj.hrefpanels;
    for k = 1:obj.NumberOfTabs
        if ~ishandle(href(k)) || ...
           ~isequal(obj.htabpanel,get(href(k),'Parent'))
            href(k) = NaN;
            obj.Enable{k} = 'off';
        end
    end
    if ~isequaln(href,obj.hrefpanels)
        warning(sprintf('%s:invalidPanel',mfilename),'%s',...
            'One or more panels under POPUPTABS control became invalid ',...
            '(either the object handle no longer is valid, or the ',...
            'object parent has changed).');
        obj.hrefpanels = href;
    end

    % update main panel appearance
    set(obj.hmainpanel,'BackgroundColor',obj.BackgroundColor);

    % update tab appearance
    set(obj.htabs(:),...
        'BackgroundColor',  obj.TabColor,...
        'HighlightColor',   obj.TabColor);

    % update checkbox appearance
    set(obj.hchecks(:),...
        {'String'},         obj.TabNames(:),...
        'FontAngle',        obj.FontAngle,...
        'FontName',         obj.FontName,...
        'FontSize',         obj.FontSize,...
        'FontWeight',       obj.FontWeight,...
        'ForegroundColor',  obj.FontColor,...
        'BackgroundColor',  obj.TabColor);

    % update reference panel appearance
    h = obj.hrefpanels;
    set(h(ishandle(h)),...
        'BorderType',       'line',...
        'HighlightColor',   obj.TabColor,...
        'ForegroundColor',  obj.TabColor);

    % update check appearance
    for k = 1:obj.NumberOfTabs
        h = obj.hchecks(k);
        if isequal(obj.Enable{k},'on') && get(h,'Value')
            im = minusimage(obj.TabColor,obj.FontColor);
        else
            im = plusimage(obj.TabColor,obj.FontColor);
        end
        set(h,'Cdata',im);
    end

    % figure position
    pfig = getpixelposition(obj.Parent);

    % default main panel position
    ppnl = [1+obj.LeftOffset, 1,...
            (obj.TabWidth+2*obj.TabMargin), pfig(4)];

    % update slider position
    % slider is just outside the default main panel position
    setpixelposition(obj.hslider,...
        [1+ppnl(3),1,slwidth,ppnl(4)]);

    % NO TABS
    if obj.NumberOfTabs <= 0 || all(strcmpi(obj.Visible,'off'))

        % eliminate tab panel & slider
        set([obj.htabpanel,obj.hslider],'visible','off')

        % default panel position
        setpixelposition(obj.hmainpanel,ppnl);

        % quit
        obj.redrawenable = true;
        return;
    end


    % CALCULATE TAB PARAMETERS
    N = obj.NumberOfTabs;
    tvis = cell(N,1);
    tenb = cell(N,1);
    tpos = NaN(N,4);
    rvis = cell(N,1);
    rpos = NaN(N,4);

    xy = [1,1] + obj.TabMargin;
    for k = obj.NumberOfTabs:-1:1

        % visibility of tab & panel
        if isequal(obj.Visible{k},'off')
            tvis{k} = 'off';
            tenb{k} = 'off';
            rvis{k} = 'off';
        else
            tvis{k} = 'on';
            if isequal(obj.Enable{k},'off')
                tenb{k} = 'off';
                rvis{k} = 'off';
            else
                tenb{k} = 'on';
                if ~obj.IsOpen(k)
                    rvis{k} = 'off';
                else
                    rvis{k} = 'on';
                end
            end
        end

        % offset due to visible panel
        if isequal(rvis{k},'on')
            xy(2) = xy(2) + obj.PanelHeights(k);
        end

        % tab/reference panel position
        if isequal(tvis{k},'on')
            tpos(k,:) = [xy, obj.TabWidth obj.TabHeight];
        else
            tpos(k,:) = [1 1 obj.TabWidth obj.TabHeight];
        end

        % tab/reference panel position
%         if isequal(rvis{k},'on')
            rpos(k,:) = [xy - [0,obj.PanelHeights(k)],...
                obj.TabWidth, obj.PanelHeights(k)];
%         else
%             rpos(k,:) = [1 1 obj.TabWidth obj.PanelHeights(k)];
%         end

        % offset due to visible tab
        if isequal(tvis{k},'on')
            xy(2) = xy(2) + obj.TabHeight + obj.TabMargin;
        end

    end

    % size of tab panel
    tabpanelheight = xy(2)-1;
    tabpanelwidth  = obj.TabWidth + 2*obj.TabMargin;

    % update tab panel, adding slider if necessary
    FLAG_resize = false;
    if tabpanelheight > pfig(4)
        ppnl(3) = ppnl(3) + slwidth;

        maxshft = tabpanelheight - ppnl(4);
        step = min([10 20] ./ maxshft, [0.5 1.0]);

        val  = -get(obj.hslider,'value');
        if val > maxshft, val = maxshft; end

%         if val > maxshft, val = maxshft; end
%         if val < 0, val = 0; end

        if isequal(get(obj.hslider,'visible'),'off')
            FLAG_resize = true;
        end

        set(obj.hslider,'visible','on','min',-maxshft,...
            'sliderstep',step,'value',-val);
        ptab = [1 1+ppnl(4)-tabpanelheight+val tabpanelwidth tabpanelheight];

    else
        if isequal(get(obj.hslider,'visible'),'on')
            FLAG_resize = true;
        end
        set(obj.hslider,'visible','off',...
            'sliderstep',[1 2],'min',-eps,'max',eps,'value',0);
        ptab = [1 1+ppnl(4)-tabpanelheight tabpanelwidth tabpanelheight];
    end

    setpixelposition(obj.hmainpanel,ppnl);
    setpixelposition(obj.htabpanel,ptab);
    set(obj.htabpanel,'visible','on');
%     drawnow

    pinvis = [1 2*tabpanelheight];

    for k = 1:obj.NumberOfTabs
        set(obj.htabs(k),'visible',tvis{k});
        if isequal(tvis{k},'on')
            set(obj.hchecks(k),'enable',tenb{k});
            setpixelposition(obj.htabs(k),tpos(k,:));
        end

        if isequal(rvis{k},'on')
            p = rpos(k,:);
        else
            p = [pinvis,rpos(k,3:4)];
        end
        setpixelposition(obj.hrefpanels(k),p);

    end
%     drawnow
%
%     for k = 1:obj.NumberOfTabs
%
%         if isequal(rvis{k},'on')
%              setpixelposition(obj.hrefpanels(k),rpos(k,:));
%         end
%     end

    obj.redrawenable = true;

    if FLAG_resize
        fcn = get(obj.hparent,'ResizeFcn');
        if ~isempty(fcn)
            feval(fcn,obj.hparent,[]);
        end
    end

end




function im = plusimage(clr,bgclr)
    if nargin < 1, clr = [83 101 120]/255; end
    if nargin < 2, bgclr = [1 1 1]; end

    clr = clr2num(clr);
    bgclr = clr2num(bgclr);

    tf = false(10);
    tf(2:end-1,5:6) = 1;
    tf(5:6,2:end-1) = 1;

    im = cat(3,...
        tf*clr(1) + ~tf*bgclr(1),...
        tf*clr(2) + ~tf*bgclr(2),...
        tf*clr(2) + ~tf*bgclr(2));

end

function im = minusimage(clr,bgclr)
    if nargin < 1, clr = [83 101 120]/255; end
    if nargin < 2, bgclr = [1 1 1]; end

    clr = clr2num(clr);
    bgclr = clr2num(bgclr);

    tf = false(10);
    tf(5:6,2:end-1) = 1;

    im = cat(3,...
        tf*clr(1) + ~tf*bgclr(1),...
        tf*clr(2) + ~tf*bgclr(2),...
        tf*clr(2) + ~tf*bgclr(2));
end


%% SLIDER FUNCTION
function sliderCallback(obj)
%     redraw(obj);
    if interruptUIControl(obj.hslider), return; end

    pmain = getpixelposition(obj.hmainpanel);
    ptab = getpixelposition(obj.htabpanel);

    val = -get(obj.hslider,'value');
    ptab(2) = 1+pmain(4)-ptab(4)+val;
    setpixelposition(obj.htabpanel,ptab);

    for k = 1:obj.NumberOfTabs
        if isequal(get(obj.hrefpanels(k),'visible'),'on')
            pos = getpixelposition(obj.hrefpanels(k));
            setpixelposition(obj.hrefpanels(k),pos);
        end
    end
    drawnow
end

function tf = interruptUIControl(h)
    uid = get(h,'Value');
    pause(eps);
    tf = ~isequal(uid,get(h,'Value'));
end




%% GENERIC SET FUNCTION
function setFcn(obj,varargin)

    % current redraw enable state
    redrawenable = obj.redrawenable;

    tags = {'Parent','IsOpen','TabColor','BackgroundColor',...
        'FontAngle','FontName','FontSize','FontWeight','FontColor',...
        'TabWidth','TabHeight','PanelHeights','LeftOffset',...
        'TabNames','Visible','Enable'};

    curapi = struct;
    for ti = 1:numel(tags)
        curapi.(tags{ti}) = obj.(tags{ti});
    end
    [api,other_args] = parseinputs(curapi,[],varargin{:});

    if ~isempty(other_args)
        error(sprintf('%s:invalidSetInput',mfilename),...
            'Invalid "set" input.');
    end

    ERR = [];
    updated = false(size(tags));
    try
        obj.redrawenable = false;
        for ti = 1:numel(tags)
            if ~isequal(obj.(tags{ti}),api.(tags{ti}))
                obj.(tags{ti}) = api.(tags{ti});
                updated(ti) = true;
            end
        end
    catch ERR
        for ti = 1:numel(tags)
            if ~updated(ti), continue; end
            obj.(tags{ti}) = curapi.(tags{ti});
        end
    end

    obj.redrawenable = redrawenable;
    redraw(obj);

    if ~isempty(ERR), rethrow(ERR); end

end



%% VALIDATION FUNCTIONS
% these functions validate certain PLAYBAR properties, ensuring
% that user inputs are as expected.


function val = checkColor(val,vals,name)
% check for a valid color specification (see COLORSPEC)
% val....input value
% vals...cell array of alternative color definitions (e.g. 'auto','flat')
% name...property name (for error)

    if ~iscolor(val) && ...
       (isempty(val) || ~any((cellfun(@(x)isequal(val,x),vals))))
        error(sprintf('%s:invalidColor',mfilename),'%s',...
            'Invalid ',name,' specification.');
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


function val = checkFontNameFcn(val)
% check a string against LISTFONTS
    vals = listfonts;
    vals = [vals(:);'default';'FixedWidth';'monospaced'];
    if ~ischar(val) || ~any(strcmpi(val,vals))
        error(sprintf('%s:invalidFontName',mfilename),'%s',...
            'Invalid ''FontName'' - use LISTFONTS to determine ',...
            'available fonts for your system.');
    end
end


function val = checkPositiveScalarFcn(val,name)
% check for a positive scalar value

    if ~isnumeric(val) || ~isscalar(val) || val<=0
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            '''', name, ''' must a positive numeric value.');
    end

end

function val = checkLeftOffsetFcn(val)
% check for a non-negative scalar value

    if ~isnumeric(val) || ~isscalar(val) || val<0
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            '''LeftOffset'' must a non-negative numeric value.');
    end

end

function strs = checkTabNamesFcn(obj,strs)
    if ~iscellstr_recursive(strs) || numel(strs) ~= obj.NumberOfTabs
        error(sprintf('%s:invalidTabNames',mfilename),'%s',...
            '''TabNames'' must be a valid cell array of strings ',...
            'equal to the number of tabs.');
    end
    strs = strs(:)';
end

function val = checkStringArrayFcn(obj,val,name,vals)
% check cell array of strings property

    % check for valid cell array of strings
    errstr = [];
    if numel(val) ~= obj.NumberOfTabs
        errstr = sprintf('Invalid ''%s'' size.',name);
    elseif obj.NumberOfTabs == 0
        return
    elseif ~iscellstr(val)
        errstr = sprintf('''%s'' must be a cell array of strings.',name);
    else
        tf = cellfun(@(v)any(strcmpi(v,vals)),val);
        if ~all(tf)
            str = sprintf('%s|',vals{:});
            errstr = sprintf('%s','''',name,''' must be a cell ',...
                'array of strings containing [',str(1:end-1),'] only.');
        end
    end

    % throw error
    if ~isempty(errstr)
        error(sprintf('%s:invalid%s',mfilename,name),errstr);
    end

end


function val = checkEnableFcn(obj,val)

    % 1st, check for valid strings
    val = checkStringArrayFcn(obj,val,'Enable',{'on','off'});

    % we cannot enable tabs without valid reference panels
    for k = 1:obj.NumberOfTabs
        if isnan(obj.hrefpanels(k)) && strcmpi(val{k},'on')
            warning(sprintf('%s:cannotEnableWithoutPanel',mfilename),'%s',...
                'A tab cannot be enabled without a valid reference panel.');
        end
    end

end
