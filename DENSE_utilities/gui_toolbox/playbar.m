%% PLAYBAR HANDLE CLASS DEFINITION
% Create a panel containing interactive video playback controls,
% including a play/pause button, a frame slider, and a direct
% frame number editable text field.
%
%
%NOTE ON PLAY/PAUSE ICONS:
%   The PLAYBAR class requires the "playbar.mat" file, which stores the
%   play/pause icons.  The class will still work without that file, but the
%   icons won't look as good!
%
%
%PROPERTIES
%
%   Parent...........parent figure/uipanel of SIDETABS object
%       Set/Get enabled,  defaults to GCF
%
%   BackgroundColor..background color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [.8 .8 .8]
%
%   BorderColor......border color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [1 1 1]
%
%   ShadowColor......3D border shadow color
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to [.5 .5 .5]
%
%   BorderType.......border type
%       Set/Get enabled
%       [none | etchedin | etchedout | beveledin | beveledout | {line}]
%
%   FontAngle........text font angle
%       Set/Get enabled, [{normal} | italic | oblique]
%
%   FontSize.........text font size (in points)
%       Set/Get enabled, defaults to 8
%
%   FontName.........text font
%       See LISTFONTS for your available fonts
%       Set/Get enabled, defaults to 'default' system font
%
%   FontWeight.......text font weight
%       Set/Get enabled, [light | {normal} | demi | {bold}]
%
%   FontColor........text font color (applies to non-editable text only)
%       See COLORSPEC for valid color inputs
%       Set/Get enabled, defaults to 'black'
%
%   Enable...........enable/disable control
%       Set/Get enabled, [ {on} | off ]
%
%   Visible..........control visibility
%       Set/Get enabled, [ {on} | off ]
%
%   Positon..........[1x4] position vector, [x,y,width,height]
%       Set/Get enabled, defaults to [1,1,250,30] (in pixels)
%
%   Units............units of Position vector
%       Set/Get enabled
%       [ inches | centimeters | normalized | points | {pixels} | characters ]
%
%   Min..............minimum playbar range (positive integer)
%       Set/Get enabled, defaults to 1
%       Tool will not be enabled until Max is greater than 1Min
%
%   Max..............maximum playbar range (positive integer)
%       Set/Get enabled, defaults to 0
%       Tool will not be enabled until Max is greater than 1Min
%       Setting Max to 0 effectively resets the playbar
%
%   Value............current frame (on range [1,Max])
%       Set/Get enabled, defaults to 1
%
%   TimerPeriod......[1x2] timer period
%       [interframe delay, end-of-sequence delay]
%       Set/Get enabled, defaults to [0.1 1]
%
%   IsPlaying........logical indicating if the play timer is active
%       Get enabled only, "true" indicates the timer is active
%
%
%EVENTS
%
%   NewValue....indicates when the playbar object has changed value, either
%       through the interactive controls or programmatically.
%
%
%METHODS
%
%   OBJ = PLAYBAR(HPARENT) instantiate a playbar object OBJ in the figure
%   or uipanel object HPARENT.
%
%   OBJ = PLAYBAR() is the same as OBJ = PLAYBAR(GCF)
%
%   OBJ.PLAY start playback
%   (same action as pressing the "play" toggle button)
%
%   OBJ.STOP stop playback
%   (same action as pressing the "stop" toggle button)
%
%   OBJ.REDRAW redraw the PLAYBAR object. Generally, the object will
%   automatically redraw when necessary. However, the user may externally
%   initiate a redraw via this function.  Note that this redraw will
%   stop the playback timer.
%
%
%EXAMPLE
%
%   This example uses the MATLAB example video 'cellsequence',
%   creating a simple image/playbar display for video exploration.
%
%     % load sample video
%     load cellsequence
%
%     % initialize display
%     hfig = figure;
%     hax  = axes('parent',hfig,'units','normalized',...
%                 'position',[0 .1 1 .9]);
%     hI   = imshow(cellsequence(:,:,1),'parent',hax);
%
%     % initialize playbar object
%     obj = playbar(hfig);
%     obj.Max = size(cellsequence,3);
%     obj.Units = 'normalized';
%     obj.Position = [0.2 0 0.6 0.1];
%
%     % add listener to update image
%     fcn = @(varargin)set(hI,'cdata',cellsequence(:,:,obj.Value));
%     h = addlistener(obj,'NewValue',fcn);
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY:    Drew Gilliam
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation


%% CLASS DEFINITION
classdef playbar < handle

    % external set/get properties
    properties

        BackgroundColor = [236 233 216]/255;
        BorderColor     = [1 1 1];
        ShadowColor     = [.5 .5 .5];
        BorderType      = 'line';

        FontAngle       = 'normal';
        FontName        = 'default';
        FontSize        = 8;
        FontWeight      = 'bold';
        FontColor       = [0 0 0];

        Enable          = 'on';
        Visible         = 'on';

        Position        = [1 1 200 30];
        Units           = 'pixels';

        Min             = 1;
        Max             = 0;

        TimerPeriod     = [1/8, 1];

    end

    % dependent set/get properties
    % this properties help us avoid recursion in the functions below
    properties (Dependent=true)
        Parent
        Value
    end

    % get-only properties
    properties (SetAccess='private')
        IsPlaying = false;
    end


    % internal properties
    properties (Hidden=true,SetAccess='private',GetAccess='private')

        % internal parent/value
        hparent
        value = 1;

        % graphic objects
        hpanel
        htoggle
        hslider
        hedit
        htext

        % timer object
        htimer

        % parent listener object
        hlisten_delete

        % redraw enable flag
        redrawenable = false;

        % icons
        playicon = cat(3,zeros(16),ones(16),zeros(16));
        stopicon = cat(3,ones(16),zeros(16),zeros(16));

    end


    % observable events
    events
        NewValue
    end


    % method prototypes
    methods

        % constructor
        function obj = playbar(varargin)
            obj = playbarFcn(obj,varargin{:});
        end

        % destructor
        function delete(obj)
            deleteFcn(obj);
        end


        % ACTION functions
        function play(obj)
            playFcn(obj);
        end
        function stop(obj)
            stopFcn(obj);
        end
        function redraw(obj)
            redrawFcn(obj);
        end


        % GET functions
        function val = get.Parent(obj)
            val = obj.hparent;
        end
        function val = get.Value(obj)
            if obj.Max < obj.Min
                val = [];
            else
                val = obj.value;
            end
        end


        % SET functions

        function set.BackgroundColor(obj,clr)
            obj.BackgroundColor = checkColorFcn(clr);
            redrawFcn(obj);
        end
        function set.BorderColor(obj,clr)
            obj.BorderColor = checkColorFcn(clr);
            redrawFcn(obj);
        end
        function set.ShadowColor(obj,clr)
            obj.ShadowColor = checkColorFcn(clr);
            redrawFcn(obj);
        end
        function set.BorderType(obj,val)
            obj.BorderType = checkStringsFcn(val,'BorderType',...
                set(0,'DefaultUIPanelBorderType'));
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
            obj.FontSize = checkFontSizeFcn(val);
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

        function set.Enable(obj,val)
            obj.Enable = checkStringsFcn(val,'Enable',{'on','off'});
            redrawFcn(obj);
        end
        function set.Visible(obj,val)
            obj.Visible = checkStringsFcn(val,'Visible',{'on','off'});
            redrawFcn(obj);
        end

        function set.Position(obj,val)
            obj.Position = checkPositionFcn(val);
            redrawFcn(obj);
        end
        function set.Units(obj,val)
            obj.Units = checkStringsFcn(val,'Units',...
                set(0,'DefaultUIPanelUnits'));
            redrawFcn(obj);
        end


        function set.Min(obj,val)
            obj.Min = checkRngFcn(val,[-Inf Inf],'Min');
            redrawFcn(obj,true);
        end
        function set.Max(obj,val)
            obj.Max = checkRngFcn(val,[-Inf Inf],'Max');
            redrawFcn(obj,true);
        end
        function set.TimerPeriod(obj,val)
            obj.TimerPeriod = checkTimerPeriodFcn(val);
            redrawFcn(obj);
        end

        function set.Parent(obj,val)
            obj = setParentFcn(obj,val);
            redrawFcn(obj);
        end
        function set.Value(obj,val)
            obj = setValueFcn(obj,val);
            redrawFcn(obj);
        end

    end


    % hidden overloaded functions
    methods (Hidden=true)

        function setpixelposition(obj,pos)
            setpixelposition(obj.hpanel,pos);
            obj.Position = get(obj.hpanel,'Position');
        end
        function pos = getpixelposition(obj)
            pos = getpixelposition(obj.hpanel);
        end
        function pos = getunitposition(obj,varargin)
            pos = getunitposition(obj.hpanel,varargin{:});
        end

    end

end



%% CONSTRUCTOR
% This function creates the PLAYBAR object, initializing necessary
% UIPANEL and UICONTROL objects, a playback timer, and the initial parent
% deletion listener. Additionally,

function obj = playbarFcn(obj,hparent)
% obj........PLAYBAR object
% hparent....figure/uipanel parent

    % check number of inputs
    error(nargchk(1,2,nargin));

    % attempt to load better icons
    file = 'playbar.mat';
    if exist(file,'file')==2
        try
            s = load(file);
            obj.playicon = s.playicon;
            obj.stopicon = s.stopicon;
        catch ERR
        end
    end

    % parse parent argument
    % (note this function also creates the parent deletion listener)
    if nargin < 2, hparent = gcf; end
    obj = setParentFcn(obj,hparent);

    % create graphics
    obj.hpanel = uipanel(...
        'parent',obj.Parent,...
        'ResizeFcn',@(varargin)resizeFcn(obj),...
        'units',    'pixels',...
        'tag',      'Playbar');

    obj.htoggle = uicontrol(...
        'parent',               obj.hpanel,...
        'style',                'togglebutton',...
        'BackgroundColor',      [236 233 216]/255,...
        'Callback',             @(varargin)toggleControl(obj));
    obj.hslider = uicontrol(...
        'parent',               obj.hpanel,...
        'style',                'slider',...
        'Interruptible',        'on',...
        'BusyAction',           'queue',...
        'Callback',             @(varargin)sliderControl(obj));
    obj.hedit = uicontrol(...
        'parent',               obj.hpanel,...
        'style',                'edit',...
        'BackgroundColor',      'w',...
        'HorizontalAlignment',  'left',...
        'Callback',             @(varargin)editControl(obj));
    obj.htext = uicontrol(...
        'parent',               obj.hpanel,...
        'style',                'text',...
        'HorizontalAlignment',  'left');

    % create timer
    obj.htimer = timer(...
        'TimerFcn',         @(varargin)timerCallback(obj),...
        'period',           obj.TimerPeriod(1),...
        'BusyMode',         'queue',...
        'ExecutionMode',    'fixedDelay');

    % Cache handle to sidetabs object in hg hierarchy so that if
    % user loses handle to imcline object, the object still lives
    % in HG hierarchy and can be retrieved.
    setappdata(obj.hpanel,'playbarObjectReference',obj);

    % update display
    obj.redrawenable = true;
    redrawFcn(obj);


end



%% DESTRUCTOR
% before deletion, we must clean up the parent listener, the timers, and
% any necessary graphics.

function deleteFcn(obj)

    % cleanup listeners
    h = [obj.hlisten_delete];
    delete(h(ishandle(h)));

    % cleanup timers
    if ~isempty(obj.htimer)
        stop(obj.htimer);
        delete(obj.htimer);
    end

    % cleanup graphics
    h = [obj.hpanel];
    delete(h(ishandle(h)));

end



%% SET PARENT
% The user is able to move the PLAYBAR object to various figures or
% uipanels by changing the 'Parent' property. We must ensure that the new
% parent is valid, as well as create a new listener on the parent to delete
% the PLAYBAR if the parent is deleted.

function obj = setParentFcn(obj,hparent)
% obj........PLAYBAR objects
% hparent....candidate figure/uipanel

    % check for valid parent
    if ~ishandle(hparent) || ...
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

    % save parent
    obj.hparent = hparent;

    % move children to new parent (if children exist)
    if ~isempty(obj.hpanel) && ishandle(obj.hpanel)
        set(obj.hpanel,'Parent',hparent);
    end

    % Deletion listener: when the Parent is destroyed,
    % the object is no longer valid and must be destroyed
    obj.hlisten_delete = handle.listener(...
        obj.hparent,'ObjectBeingDestroyed',@(varargin)obj.delete());

end



%% SET VALUE
% here, we check and set the PLAYBAR value (i.e. the current frame). We use
% the internal variable "value" rather than the external variable "Value"
% to avoid recursion when value is set internally.  If the value changes,
% we notify the "NewValue" event.

function obj = setValueFcn(obj,val)
% obj.....PLAYBAR object
% val.....new value

    if obj.Max < obj.Min
        error(sprintf('%s:invalidValue',mfilename),'%s',...
            '''Value'' cannot be set while ''Max'' is less than ''Min''.');
    elseif ~isnumeric(val) || ~isscalar(val) || ...
        val < obj.Min || obj.Max < val
        error(sprintf('%s:invalidValue',mfilename),'%s',...
            '''Value'' must be a positive scalar integer, ',...
            'on the range [',num2str([obj.Min,obj.Max]),'].');
    end
    val = round(val);

    % check for new value
    flag = (val ~= obj.value);

    % save value, update objects
    obj.value = val;
    set(obj.hslider,'value',obj.value);
    set(obj.hedit,'string',obj.value);

    % notify of NewValue
    if flag, notify(obj,'NewValue'); end

end



%% DISPLAY FUNCTIONS
% These functions control the appearance update of the PLAYBAR object.
% Additionally, 'redrawFcn' resets the PLAYBAR state (disabling the timer,
% redrawing the graphics, returning the object to the "ready" state.

function redrawFcn(obj,updateval)
% every time a PLAYBAR appearance property is changed, we need to redraw
% the entire PLAYBAR to reflect any changes.  Note that this function stops
% any playback.

    % default input
    if nargin < 2 || isempty(updateval), updateval = false; end
    updateval = isequal(updateval,true);

    % only allow redraw after setup
    if ~obj.redrawenable || ~ishandle(obj.Parent) || ...
       strcmpi(get(obj.Parent,'BeingDeleted'),'on')
        return;
    end

    % ingore recursive redraw calls
    obj.redrawenable = false;

    % stop timer
    stop(obj.htimer);
    obj.IsPlaying = false;

    % update the value
    if updateval
        if obj.Max < obj.Min
            obj.value = 0;
        else
            obj.value = obj.Min;
        end
    end

    % update all objects
    set(obj.hpanel,...
        'units',            obj.Units,...
        'position',         obj.Position,...
        'Visible',          obj.Visible,...
        'BackgroundColor',  obj.BackgroundColor,...
        'HighlightColor',   obj.BorderColor,...
        'ForegroundColor',  obj.BorderColor,...
        'ShadowColor',      obj.ShadowColor,...
        'BorderType',       obj.BorderType);

    set([obj.htext,obj.hedit],...
        'FontAngle',    obj.FontAngle,...
        'FontName',     obj.FontName,...
        'FontSize',     obj.FontSize,...
        'FontWeight',   obj.FontWeight);

    if obj.Max < obj.Min
        str = '--:--';
    else
        str = sprintf('%d:%d',obj.Min,obj.Max);
    end

    set(obj.htext,...
        'ForegroundColor',  obj.FontColor,...
        'BackgroundColor',  obj.BackgroundColor,...
        'String',           str);



    % general enable/disable
    h = [obj.htoggle,obj.hslider,obj.htext,obj.hedit];
    if strcmpi(obj.Enable,'off') || obj.Max <= obj.Min
        set(h,'Enable','off');
    else
        set(h,'enable','on')
    end

    % update toggle tool
    set(obj.htoggle,'cdata',obj.playicon,'value',0);

    % update slider & edit object
    eps = 1e-4;
    if obj.Max < obj.Min
        set(obj.hslider,'min',0,'max',eps,'value',0);
        set(obj.hedit,'string','-');
    elseif obj.Min == obj.Max
        set(obj.hslider,'min',obj.Min,'max',obj.Min+eps,'value',obj.Min);
        set(obj.hedit,'string',obj.Min);
    else
        step = [1,2]./(obj.Max-obj.Min);
        set(obj.hslider,'min',obj.Min,'max',obj.Max,...
            'SliderStep',step,'Value',obj.value);
        set(obj.hedit,'string',obj.value)
    end

    % reenable redraw
    obj.redrawenable = true;

    % update object position
    resizeFcn(obj);

end


function resizeFcn(obj)
% every time HPANEL control is resized, the inner PLAYBAR
% controls need to be repositioned.

    % control horiztonal separation
    margin = 5;

    % determine (saturated) pixel position of panel
    mnsz = [200 30];
    pos = getpixelposition(obj.hpanel);
    pos = [pos(1:2), max(pos(3:4),mnsz)];

    % text extents
    postxt = get(obj.htext,'Extent');

    % width & height
    width  = [25 0 30 postxt(3)];
    width(2) = pos(3) - sum(width) - 5*margin;
    height = [25 15 21 15];

    % x/y position
    x = cumsum(margin + [1 width(1:3)]);
    y = ((pos(4)-height)./2);
    if any(strcmpi(obj.BorderType,{'none','line'}))
        y = y+1;
    end

    % update position
    childpos = [x(:),y(:),width(:),height(:)];
    h = [obj.htoggle,obj.hslider,obj.hedit,obj.htext];
    for k = 1:numel(h)
        setpixelposition(h(k),childpos(k,:));
    end

end



%% CONTROL CALLBACK FUNCTIONS
% These functions are executed every time a control object is activated,
% including the play/pause toggle, the frame slider, and the frame editbox.

function toggleControl(obj)
% play or stop depending on the current toggle state
    if get(obj.htoggle,'Value')
        playFcn(obj)
    else
        stopFcn(obj)
    end
end


function sliderControl(obj)
% get the new slider value,
% update graphics, and notify 'NewValue'

    % new value, change in value
    val = round(get(obj.hslider,'value'));
    flag = (val ~= obj.value);

    % save value, update objects
    obj.value = val;
    set(obj.hslider,'value',obj.value);
    set(obj.hedit,'string',obj.value);

    % notify of NewValue
    if flag, notify(obj,'NewValue'); end

end


function editControl(obj)
% get the user-inputted value, check validity,
% upate graphics, and notify 'NewValue'

    % new value, chnage in value
    val = str2double(get(obj.hedit,'string'));
    if ~isnan(val) && obj.Min <= val && val <= obj.Max
        val = round(val);
    else
        val = obj.value;
    end
    flag = (val ~= obj.value);

    % save value, update objects
    obj.value = val;
    set(obj.hslider,'value',obj.value);
    set(obj.hedit,'string',obj.value);

    % notify of NewValue
    if flag, notify(obj,'NewValue'); end


end



%% PLAYBACK FUNCTIONS
% Initialize and stop automated playback

function playFcn(obj)

    % if the toggle is not enabled, this function should not be executed.
    if ~strcmpi(get(obj.htoggle,'enable'),'on')
        redrawFcn(obj);
        return;
    end

    % disable controls
    set([obj.hslider,obj.hedit,obj.htext],'enable','off');

    % ensure the toggle button is pressed and has the "stopicon"
    set(obj.htoggle,'value',1,'cdata',obj.stopicon);

    % reset the timer values
    set(obj.htimer,'StartDelay',0,'Period',obj.TimerPeriod(1));

    % start the timer
    obj.IsPlaying = true;
    start(obj.htimer);

end


function stopFcn(obj)
% stop the timer
    obj.IsPlaying = false;
    redrawFcn(obj);
end


function timerCallback(obj)
% timer callback
%     tobj = tic;

    % check for cancellation
    if ~obj.IsPlaying
        if strcmpi(obj.htimer.Running,'on');
            stop(obj.htimer);
        end
        return
    end

    % increment current value
    obj.value = obj.value+1;

    % cycle back to start of sequence
    if obj.value > obj.Max
        obj.value = obj.Min;

    % at the end of the sequence, pause for TimerPeriod(2)
    elseif obj.value == obj.Max
        stop(obj.htimer);
        set(obj.htimer,'StartDelay',obj.TimerPeriod(2));
    end

    % update the graphics
    set(obj.hslider,'value',obj.value);
    set(obj.hedit,'string',obj.value);

    % notify 'NewValue'
    notify(obj,'NewValue')
    drawnow

    % restart timer
    if obj.value == obj.Max && obj.IsPlaying
        start(obj.htimer);
    end

    % display
    % fprintf('%2d playback complete (%0.4f sec)\n',...
    %     obj.value,toc(tobj));
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

    if ~ischar(val) || ~any(strcmpi(val,vals))
        str = sprintf('%s,',vals{:});
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


function val = checkFontSizeFcn(val)
% check for a scalar numeric fontsize

    if ~isnumeric(val) || ~isscalar(val) || val<=0
        error(sprintf('%s:invalidFontSize',mfilename),'%s',...
            '''FontSize'' must be a non-negative numeric value.');
    end
end


function val = checkPositionFcn(val)
% check for a valid Position vector

    if ~isnumeric(val) || numel(val) ~= 4 || any(val(3:4) < 0)
        error(sprintf('%s:invalidPosition',mfilename),'%s',...
            '''Position'' must be a [1x4] vector, of ',...
            'the form [x,y,width,height].');
    end
    val = val(:)';
end


function val = checkRngFcn(val,rng,str)
% check for valid positive integer

    if ~isnumeric(val) || ~isscalar(val) || ...
        val < rng(1) || rng(2) < val || mod(val,1) ~= 0
        error(sprintf('%s:invalid%s',mfilename,str),'%s',...
            'Invalid ',str,' value.');
    end

end

function val = checkTimerPeriodFcn(val)
% check for positive [1x2] TimerPeriod

    if ~isnumeric(val) || numel(val)~=2 || any(val<=0)
        error(sprintf('%s:invalidTimerPeriod',mfilename),'%s',...
            '''TimerPeriod'' must be a [1x2] vector of ',...
            'non-negative values');
    end
    val = val(:)';
end






%% END OF FILE=============================================================
