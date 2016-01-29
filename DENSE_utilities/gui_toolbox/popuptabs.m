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
%   BackgroundColor..background color
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
classdef popuptabs < handle

    % set/get properties
    properties

        BackgroundColor = [100 121 162]/255;
        FontAngle       = 'normal';
        FontName        = 'default';
        FontSize        = 8;
        FontWeight      = 'bold';
        FontColor       = [1 1 1];

        TabWidth  = 150;
        TabHeight = 30;
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

    end


    % method prototypes
    methods

        % constructor
        function obj = popuptabs(varargin)
            obj = popuptabsFcn(obj,varargin{:});
        end

        % destructor
        function delete(obj)
            deleteFcn(obj);
        end


        % ACTION functions
        function addTab(obj,varargin)
            addTabFcn(obj,varargin{:});
        end

        function redraw(obj)
            redrawFcn(obj);
        end


        % GET/SET dependent properties
        function val = get.Parent(obj)
            val = obj.hparent;
        end
        function set.Parent(obj,val)
            setParentFcn(obj,val);
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
        function set.BackgroundColor(obj,clr)
            obj.BackgroundColor = checkColorFcn(clr);
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
            obj.FontColor = checkColorFcn(val);
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

    end


    % hidden overloaded properties
    methods (Hidden=true)

        function pos = getpixelposition(obj)
            pos = getpixelposition(obj.hmainpanel);
        end

    end

end


%% CONSTRUCTOR
% This function creates the POPUPTABS object, initializing graphic
% objects and listeners to resize/delete the object.

function obj = popuptabsFcn(obj,hparent)
% obj........POPUPTABS object
% hparent....parent figure/uipanel

    % check number of inputs
    error(nargchk(1,2,nargin));

    % parse parent argument
    % (note this function also creates the parent deletion listener)
    if nargin < 2, hparent = gcf; end
    setParentFcn(obj,hparent);

    % initialize main panel
    obj.hmainpanel = uipanel(...
        'parent',           obj.hparent,...
        'bordertype',       'none');

    % initialize tab panel
    obj.htabpanel = uipanel(...
        'parent',           obj.hmainpanel,...
        'bordertype',       'none');

    % initialize slider object
    obj.hslider = uicontrol(...
        'parent',       obj.hmainpanel,...
        'style',        'slider',...
        'visible',      'off',...
        'callback',     @(varargin)redrawFcn(obj));

    % Cache handle to POPUPTABS object in hg hierarchy so that if
    % user loses handle to imcline object, the object still lives
    % in HG hierarchy and can be retrieved.
    setappdata(obj.hmainpanel,'imclineObjectReference',obj);

    % update display
    obj.redrawenable = true;
    redrawFcn(obj);

end



%% DESTRUCTOR
% ensure all listeners and graphic objects are deleted
% move any reference panels to the parent prior to object deletion

function deleteFcn(obj)

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

function setParentFcn(obj,hparent)
% obj........PLAYBAR objects
% hparent....candidate figure/uipanel

    % check for valid parent
    if ~isscalar(hparent) || ishghandle(hparent) || ...
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

    % move children to new parent (if children exist)
    if ~isempty(obj.hmainpanel) && ishandle(obj.hmainpanel)
        set(obj.hmainpanel,'Parent',hparent);
    end

    % Deletion listener: when the Parent is destroyed,
    % the object is no longer valid and must be destroyed
    obj.hlisten_delete = handle.listener(...
        obj.hparent,'ObjectBeingDestroyed',@(varargin)obj.delete());

    % Property listener: when the parent is Resized, the parent color
    % changes, or the ancestor figure is resized, we need to update
    % the SIDETABS object
    if strcmpi(get(obj.hparent,'type'),'figure')
        h = [obj.hparent,obj.hparent];
        tags = {'Position','Color'};
    else
        h = [obj.hparent,obj.hparent,ancestor(obj.hparent,'figure')];
        tags = {'Position','BackgroundColor','Position'};
    end

    prp = cellfun(@(h,tag)findprop(h,tag),...
        num2cell(handle(h)),tags,'uniformoutput',0);
    obj.hlisten_parent = handle.listener(handle(h),cell2mat(prp),...
        'PropertyPostSet',@(varargin)redrawFcn(obj));

end



%% SET ISOPEN
% programatically open/close the various popuptabs
% opening is only possible on enabled tabs with valid reference panels.

function setIsOpenFcn(obj,val)

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

function addTabFcn(obj,str,href)
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
        'Callback', @(varargin)redrawFcn(obj));

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


%% REMOVE TAB

function removeTab(obj,idx)




end










function redrawFcn(obj)

    slwidth = 15;


    % only allow redraw after setup
    if ~obj.redrawenable || ~ishandle(obj.Parent) || ...
       strcmpi(get(obj.Parent,'BeingDeleted'),'on')
        return;
    end

    obj.redrawenable = false;

    % determine parent position & color
    ppos = getpixelposition(obj.Parent);

    % update main panel
    ppnl = [1+obj.LeftOffset 1 (obj.TabWidth+2*obj.TabMargin) ppos(4)];
    setpixelposition(obj.hmainpanel,ppnl);

    % update background colors
    if strcmpi(get(obj.hparent,'type'),'figure')
        clr = get(obj.hparent,'color');
    else
        clr = get(obj.hparent,'backgroundcolor');
    end
    set([obj.hmainpanel,obj.htabpanel],'backgroundcolor',clr);

    % update the slider position, make invisible
    setpixelposition(obj.hslider,...
        [1+ppnl(3)-slwidth-obj.TabMargin,1,slwidth,ppnl(4)]);

    % quit if no tabs
    if obj.NumberOfTabs <= 0 || all(strcmpi(obj.Visible,'off'))
        set(obj.htabpanel,'visible','off')
        obj.redrawenable = true;
        return;
    else
        set(obj.htabpanel,'visible','on')
    end


    % re-validate the reference panels
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
    if ~isequalwithequalnans(href,obj.hrefpanels)
        warning(sprintf('%s:invalidPanel',mfilename),'%s',...
            'One or more panels under POPUPTABS control became invalid ',...
            '(either the object handle no longer is valid, or the ',...
            'object parent has changed).');
        obj.hrefpanels = href;
    end

    % update the tab appearance
    set(obj.htabs(:),...
        'BackgroundColor',  obj.BackgroundColor,...
        'HighlightColor',   obj.BackgroundColor,...
        {'Visible'},        obj.Visible(:));

    % update the checkbox appearance
    set(obj.hchecks(:),...
        {'String'},         obj.TabNames(:),...
        'FontAngle',        obj.FontAngle,...
        'FontName',         obj.FontName,...
        'FontSize',         obj.FontSize,...
        'FontWeight',       obj.FontWeight,...
        'ForegroundColor',  obj.FontColor,...
        'BackgroundColor',  obj.BackgroundColor,...
        'units',            'normalized',...
        'position',         [0.05 0.05 .9 .9]);

    % disable tabs
    for k = 1:obj.NumberOfTabs
        if strcmpi(obj.Enable{k},'off');
            set(obj.hchecks(k),'Value',0,'enable','off');
        else
            set(obj.hchecks(k),'enable','on');
        end
    end


    for k = 1:obj.NumberOfTabs
        h = obj.hchecks(k);

        % ensure a 5-pixel left-margin
        pos = getpixelposition(h);
        setpixelposition(h,[5,pos(2),pos(3)-5,pos(4)]);

        % set the checkbox image
        if get(h,'Value')
            im = minusimage(obj.BackgroundColor,obj.FontColor);
        else
            im = plusimage(obj.BackgroundColor,obj.FontColor);
        end
        set(h,'Cdata',im);
    end


    % update the reference panel appearance
    h = obj.hrefpanels;
    set(h(ishandle(h)),...
        'BorderType',       'line',...
        'HighlightColor',   obj.BackgroundColor,...
        'ForegroundColor',  obj.BackgroundColor,...
        'visible','off');


    % set the reference panel visibility & gather the reference panel
    % heights (these heights are different from the 'PanelHeights' value,
    % as invisible panels have "0" refheight)
    tabheight = zeros(obj.NumberOfTabs,1);
    refheight = zeros(obj.NumberOfTabs,1);
    for k = 1:obj.NumberOfTabs

        % tab height
        if strcmpi(obj.Visible{k},'on');
            tabheight(k) = obj.TabHeight;
        end

        % reference panel height
        if isnan(obj.hrefpanels(k)), continue; end

        if get(obj.hchecks(k),'Value') && strcmpi(obj.Visible{k},'on')
            set(obj.hrefpanels(k),'Visible','on');
            refheight(k) = obj.PanelHeights(k);
        else
            set(obj.hrefpanels(k),'Visible','off');
            refheight(k) = 0;
        end
    end


    % gather tab/reference panel positions
    % we iterate up the tabpanel, determining where every tab & reference
    % panel should be placed. Note the indices go in reverse order, as tabs
    % are defined from the top down.

    xy = [1,1] + obj.TabMargin;
    tpos = zeros(obj.NumberOfTabs,4);
    rpos = tpos;

    for k = obj.NumberOfTabs:-1:1

        rpos(k,:) = [xy,obj.TabWidth,refheight(k)];
        if refheight(k) > 0
            xy(2) = xy(2) + refheight(k);
        end

        tpos(k,:) = [xy,obj.TabWidth,tabheight(k)];
        if tabheight(k) > 0
            xy(2) = xy(2) + tabheight(k) + obj.TabMargin;
        end

    end

    % total tab panel height
    tabpanelheight = xy(2)-1;
    tabpanelwidth  = ppnl(3);

    % if the tabpanel is too tall, we need to
    % decrease the tab widths
    if tabpanelheight > ppnl(4)
        rpos(:,3) = rpos(:,3) - slwidth - obj.TabMargin;
        tpos(:,3) = tpos(:,3) - slwidth - obj.TabMargin;
        tabpanelwidth = ppnl(3) - slwidth - obj.TabMargin;
    end


    % no slider necessary
    if tabpanelheight <= ppnl(4)
        set(obj.hslider,'visible','off','min',-eps,'max',0,'value',0);
        setpixelposition(obj.htabpanel,...
            [1 1+ppnl(4)-tabpanelheight tabpanelwidth tabpanelheight]);

    % update the slider
    else
        maxshft = tabpanelheight - ppnl(4);
        step = min([10 20] ./ maxshft, [0.5 1.0]);
        val  = -get(obj.hslider,'value');
        if val > maxshft, val = maxshft; end

        set(obj.hslider,'visible','on','min',-maxshft,...
            'sliderstep',step,'value',-val);
        setpixelposition(obj.htabpanel,...
            [1 1+ppnl(4)-tabpanelheight+val tabpanelwidth tabpanelheight]);
    end


    % finally, set the tab/reference panel positions within the new
    % tabpanel. Note we at least "wobble" the reference panel position
    % to ensure its internal resize function is triggered.
    for k = 1:obj.NumberOfTabs
        if tpos(k,4) > 0
            setpixelposition(obj.htabs(k),tpos(k,:));
        end
        if rpos(k,4) > 0
            p = getpixelposition(obj.hrefpanels(k));
            if all(p == rpos(k,:));
                setpixelposition(obj.hrefpanels(k),rpos(k,:)+1);
            end
            setpixelposition(obj.hrefpanels(k),rpos(k,:));
        end
    end

    % reorder children
%     uistack(obj.htabs,'top');
%     uistack(obj.hslider,'top');
    obj.redrawenable = true;

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





%% VALIDATION FUNCTIONS
% these functions validate certain PLAYBAR properties, ensuring
% that user inputs are as expected.


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
