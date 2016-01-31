%% WAITBAR TIMER
% This object contains a waitbar for functions that take an unspecified
% amount of time, with no logical waitbar progression. Create the
% waitbartimer object, start it, and wtch the progress move back and forth
% in a completely meaningless way.
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
% MODIFICATION HISTORY:
%   2009.03     Drew Gilliam
%       --creation



%% CLASS DEFINITION
classdef waitbartimer < hgsetget

    % set/get properties
    properties

        BackgroundColor = [.8 .8 .8];
        EdgeColor       = [0 0 1];
        OnColor         = [0 1 0];
        OffColor        = [1 1 1];

        FontAngle       = 'normal';
        FontName        = 'default';
        FontSize        = 8;
        FontWeight      = 'bold';
        FontColor       = [0 0 0];

        Visible         = 'on';
        WindowStyle     = 'normal';

        String          = 'Loading...';
        FigureName      = '';
        AllowClose      = true;

    end

    % private properties
    properties (SetAccess='private',GetAccess='private');

        % graphics
        hfig   = NaN;
        haxes  = NaN;
        htext  = NaN;
        hpatch = NaN;

        % timer object
        htimer = NaN;

        % other values
        Nmarker  = 12;
        marker = 's';
        timerdelay  = 0.05;
        cycledelay  = 1.0;
        pausedelay  = 0.2;
        size = [360 60];

    end

    % available methods
    methods

        % constructor
        function obj = waitbartimer(varargin)
            obj = waitbartimerFcn(obj,varargin{:});
        end

        % destructor
        function delete(obj)
            deleteFcn(obj);
        end

        % start the waitbar
        function obj = start(obj)
            obj = startFcn(obj);
        end

        % stop the waitbar
        function obj = stop(obj)
            obj = stopFcn(obj);
        end

        % refresh the waitbar
        function obj = redraw(obj)
            obj = redrawFcn(obj);
        end

        % set functions
        function obj = set.BackgroundColor(obj,val)
            obj.BackgroundColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end
        function obj = set.EdgeColor(obj,val)
            obj.EdgeColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end
        function obj = set.OnColor(obj,val)
            obj.OnColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end
        function obj = set.OffColor(obj,val)
            obj.OffColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end

        function obj = set.FontAngle(obj,val)
            obj.FontAngle = checkEnumFcn(val,'FontAngle',...
                set(0,'DefaultUIControlFontAngle'));
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
            obj.FontWeight = checkEnumFcn(val,'FontWeight',...
                set(0,'DefaultUIControlFontWeight'));
            obj = redrawFcn(obj);
        end
        function obj = set.FontColor(obj,val)
            obj.FontColor = checkColorFcn(val);
            obj = redrawFcn(obj);
        end

        function obj = set.Visible(obj,val)
            obj.Visible = checkEnumFcn(val,'Visible',...
                {'on','off'});
            obj = redrawFcn(obj);
        end
        function obj = set.WindowStyle(obj,val)
            obj.WindowStyle = checkEnumFcn(val,'WindowStyle',...
                {'normal','modal'});
            obj = redrawFcn(obj);
        end

        function obj = set.String(obj,val)
            obj.String = checkStringFcn(val,'String');
            obj = redrawFcn(obj);
        end
        function obj = set.FigureName(obj,val)
            obj.FigureName = checkStringFcn(val,'FigureName');
            obj = redrawFcn(obj);
        end

        function obj = set.AllowClose(obj,val)
            obj.AllowClose = checkEnumFcn(val,'AllowClose',...
                {true,false});
            obj = redrawFcn(obj);
        end


    end

    % static function
    methods (Static=true)

        % retrieve missing objects
        function obj = find()
           h = findall(0,'type','figure','-and','tag','WaitbarTimer');
           if numel(h) > 0
               for k = 1:numel(h)
                    obj(k) = getappdata(h,'waitbartimerObjectReference');
               end
           else
               obj = [];
           end
        end

    end

end



%% CONSTRUCTOR
function obj = waitbartimerFcn(obj,varargin)

    % screen size
    units = get(0,'units');
    set(0,'units','pixels');
    screenSize = get(0,'screensize');
    set(0,'units',units);

    % figure position
    pos = [screenSize(3)/2 - obj.size(1)/2, ...
           screenSize(4)/2 - obj.size(2)/2, ...
           obj.size];

    % axes limits
    ylim = [-1 1];
    xlim = [-1 1];

    % determine marker position
    x = linspace(-.6,.6,obj.Nmarker);
    xymarker = [x(:),-0.3*ones(obj.Nmarker,1)];

    % determine current highlight position
    N = obj.cycledelay/obj.timerdelay;
    xrng  = linspace(x(1),x(end),N+1);
    width = 0.3;
    idx = 1;
    dir = true;

    % initialize figure
    obj.hfig = figure(...
        'ToolBar',          'none',...
        'MenuBar',          'none',...
        'Resize',           'off',...
        'DeleteFcn',        @(varargin)obj.delete(),...
        'KeyPressFcn',      @(src,evt)keyPressFcn(evt,obj),...
        'HandleVisibility', 'callback',...
        'Interruptible',    'off',...
        'DockControls',     'off',...
        'Tag',              'WaitbarTimer',...
        'IntegerHandle',    'off',...
        'NumberTitle',      'off',...
        'Visible',          'off');
    setpixelposition(obj.hfig,pos);

    % initialize invisible axes
    obj.haxes = axes(...
        'parent',           obj.hfig,...
        'units',            'normalized',...
        'position',         [0 0 1 1],...
        'hittest',          'off',...
        'handlevisibility', 'off',...
        'xlim',             xlim,...
        'ylim',             ylim,...
        'visible',          'off');
    pos = getpixelposition(obj.haxes);
    set(obj.haxes,'units','pixels','position',pos);

    % create text
    obj.htext = text(...
        'parent',               obj.haxes,...
        'Position',             [0 0.4],...
        'HorizontalAlignment',  'center',...
        'VerticalAlignment',    'middle');

    % create display circle patches
    clr = clr2num(obj.OffColor);
    obj.hpatch = patch(...
        'parent',           obj.haxes,...
        'vertices',         xymarker,...
        'faces',            (1:obj.Nmarker)',...
        'marker',           'o',...
        'linestyle',        'none',...
        'markersize',       10,...
        'MarkerEdgeColor',  obj.EdgeColor,...
        'FaceVertexCData',  clr(ones(obj.Nmarker,1),:),...
        'MarkerFaceColor',  'flat');


    % create timer
    obj.htimer = timer('TimerFcn',@(varargin)timerFcn(obj),...
        'period',obj.timerdelay,'ExecutionMode','fixedDelay',...
        'BusyMode','drop');


    % Cache handle to object in hg hierarchy so that if
    % user loses handle to object, the object still lives
    % in HG hierarchy and can be retrieved.
    setappdata(obj.hfig,'waitbartimerObjectReference',obj);


    % update the objects
    obj = redrawFcn(obj);


    %
    function timerFcn(obj)
        tf = false;

        if dir
            idx = idx+1;
            if idx == numel(xrng)
                dir = false;
                tf = true;
            end
        else
            idx = idx-1;
            if idx == 1
                 dir = true;
                 tf = true;
            end
        end

        blend = min(1,abs(xymarker(:,1)-xrng(idx))/width);
        cdata = (blend)   * clr2num(obj.OffColor) + ...
                (1-blend) * clr2num(obj.OnColor);
        set(obj.hpatch,'FaceVertexCData',cdata);

        if tf
            stop(obj.htimer);
            set(obj.htimer,'StartDelay',obj.pausedelay);
            start(obj.htimer);
        end

    end

end


%% DESTRUCTOR
function deleteFcn(obj)
    tol = 1e-5;

    if isvalid(obj.htimer)
        stop(obj.htimer);
        delete(obj.htimer);
    end
    pause(tol)

    if ishandle(obj.hfig) && ...
       ~strcmpi(get(obj.hfig,'BeingDeleted'),'on')
        set(obj.hfig,'DeleteFcn',[]);
        delete(obj.hfig);
    end
    pause(tol);

end


%% START & STOP FUNCTIONS
function obj = startFcn(obj)
    if ~strcmpi(obj.Visible,'on')
        error(sprintf('%s:cannotStart',mfilename),...
            'Cannot start invisible waitbar.');
    elseif strcmpi(obj.htimer.Running,'off')
        start(obj.htimer);
    end
end

function obj = stopFcn(obj)
    stop(obj.htimer);
    obj = redrawFcn(obj);
end



%% REFRESH WAITBAR FIGURE

function obj = redrawFcn(obj)

    % test for invisible & running
    if strcmpi(obj.Visible,'off') && strcmpi(obj.htimer.Running,'on')
        warning(sprintf('%s:invisibleRunning',mfilename),...
            'The waitbar has been stopped, as Visible is ''off''');
        stop(obj.htimer);
    end

    % update objects
    set(obj.hfig,...
        'Color',        obj.BackgroundColor,...
        'Visible',      obj.Visible,...
        'WindowStyle',  obj.WindowStyle,...
        'Name',         obj.FigureName);
    if obj.AllowClose
        set(obj.hfig,'CloseRequestFcn',@(varargin)closereq);
    else
        set(obj.hfig,'CloseRequestFcn',[]);
    end

    set(obj.htext,...
        'FontAngle',    obj.FontAngle,...
        'FontName',     obj.FontName,...
        'FontSize',     obj.FontSize,...
        'FontWeight',   obj.FontWeight,...
        'Color',        obj.FontColor,...
        'String',       obj.String);

    clr = clr2num(obj.OffColor);
    set(obj.hpatch,...
        'MarkerEdgeColor', obj.EdgeColor,...
        'FaceVertexCData', clr(ones(obj.Nmarker,1),:));

end



%% UNDOCUMENTED DELETE - PRESS CONTROL-F
% this function lets us kill the waitbar even if the figure is modal and
% not allowed to close.
function keyPressFcn(evt,obj)
    key = 'f';  mod = {'control','shift'};
    tf = all(strcmpi(evt.Key,key)) && ...
        all(cellfun(@(x)any(strcmpi(evt.Modifier(:),x)),mod));
    if tf, obj.delete();  end
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


function val = checkEnumFcn(val,name,vals)
% check for a string matching a set of strings
% val.....string to check
% name....name of external function (e.g. 'FontWeight')
% vals....valid enumerated values

    tf = false;
    for k = 1:numel(vals)
        tf = isequal(val,vals{k});
        if tf, break; end
    end

    % character array
    if ~tf
        try
            vals = cellfun(@num2str,vals,'uniformoutput',0);
            str = sprintf('%s|',vals{:});
        catch ERR
            str = '';
        end
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            'Invalid ''', name, ''' parameter. Valid values are: ',...
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

function val = checkStringFcn(val,name)
% just check for a string

    if ~ischar(val)
        error(sprintf('%s:invalid%s',mfilename,name),'%s',...
            '''',name,''' must be a valid string.');
    end
end



%% END OF FILE=============================================================
