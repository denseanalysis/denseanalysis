function options = splinemodel(varargin)
% options = splinemodel(varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    %% SETUP

    % use IPT functions
    flag_ipt = true;

    errid = sprintf('%s:invalidInput',mfilename);

    % parse input arguments
    defargs = struct(...
        'FigureType',           'spline',...
        'Name',                 [],...
        'ValidFrames',          [],...
        'FramesForAnalysis',    [],...
        'SeedFrame',            [],...
        'Xpha',                 [],...
        'Ypha',                 [],...
        'Zpha',                 [],...
        'Mask',                 [],...
        'Xseed',                [],...
        'Yseed',                [],...
        'Zseed',                [],...
        'ResampleMethod',       [],...
        'SpatialSmoothing',     [],...
        'TemporalOrder',        [],...
        'Mag',                  [],...
        'UnwrapRect',           []);

    api = parseinputs(defargs,[],varargin{:});

    % VALIDATION-----------------------------------------------------------
    % Xpha, Ypha, Zpha, Mask

    % imagery stage 1 check
    checkfcn = @(p)isempty(p) || (isfloat(p) && any(ndims(p)==[2 3]));
    if ~checkfcn(api.Xpha)
        error(errid,'Invalid X-phase data');
    elseif ~checkfcn(api.Ypha)
        error(errid,'Invalid Y-phase data');
    elseif ~checkfcn(api.Zpha)
        error(errid,'Invalid Z-phase data');
    end

    % stage 2 check
    tags = {'Xpha','Ypha','Zpha'};
    xyzvalid = cellfun(@(tag)~isempty(api.(tag)),tags);
    idx = find(xyzvalid,1,'first');

    if ~any(xyzvalid)
        error(errid,'All phase fields are empty!');
    end

    % image size
    Isz = size(api.(tags{idx})(:,:,1));
    Nfr = size(api.(tags{idx}),3);

    % stage 3 check
    checkfcn = @(p)all(size(p(:,:,1))==Isz) && ...
        size(p,3)==Nfr && all(-pi <= p(:) & p(:) <= pi);
    for ti = 1:numel(tags)
        if xyzvalid(ti)
            if ~checkfcn(api.(tags{ti}))
                error(errid,'Invalid %s-phase data.',tags{ti}(1));
            end
        end
    end

    % check mask
    if ~islogical(api.Mask) || ~any(ndims(api.Mask)==[2 3]) || ...
       ~all(size(api.Mask(:,:,1))==Isz) || size(api.Mask,3)~=Nfr
        error(errid,'Invalid Mask');
    end


    % VALIDATION-----------------------------------------------------------
    % FigureType, Name, ValidFrames, FramesForAnalysis, SeedFrame

    % FigureType
    checkfcn = @(x)ischar(x) && any(strcmpi(x,{'spline','mgs'}));
    if ~checkfcn(api.FigureType)
        error(errid,'Invalid FigureType');
    end

    % Name
    if isempty(api.Name)
        api.Name = sprintf('Spline Model: Frame %d',api.SeedFrame);
    elseif ~ischar(api.Name)
        error(errid,'Invalid Name')
    end

    % ValidFrames
    frvalid = api.ValidFrames;

    if isempty(frvalid) || ~isnumeric(frvalid) || numel(frvalid)~=2 || ...
       ~all(mod(frvalid,1)==0) || frvalid(2)<frvalid(1) || ...
       any(frvalid<1 | Nfr<frvalid)
        error(errid,'Invalid ValidFrames');
    end

    % parse SeedFrame
    seedframe = api.SeedFrame;

    if ~isnumeric(seedframe) || ~isscalar(seedframe) || ...
       mod(seedframe,1)~=0 || seedframe<frvalid(1) || frvalid(2)<seedframe
        error(errid,'Invalid SeedFrame.');
    end

    if ~any(any(api.Mask(:,:,seedframe)))
        error(errid,'Mask specifies no valid locations.');
    end


    % FramesForAnalysis
    frrng = api.FramesForAnalysis;
    checkfcn = @(x)isnumeric(x) && numel(x)==2 && all(mod(x,1)==0) && ...
        all(frvalid(1)<=x & x<=frvalid(end)) && x(2)>=x(1);

    if isempty(frrng)
        frrng = frvalid;
    else
        if ~checkfcn(frrng)
            error(errid,'Invalid FramesForAnalysis');
        end
    end
    api.FramesForAnalysis = frrng;




    % ADDITIONAL SETUP-----------------------------------------------------

    % image space
    x = 1:Isz(2);
    y = 1:Isz(1);
    [X,Y] = meshgrid(x,y);

    % phase display range
    brdr = 2;

    [i,j] = find(any(api.Mask,3));
    ij = [i(:),j(:)];

    mn = max(1, floor(min(ij))-brdr);
    mx = min(Isz, ceil(max(ij))+brdr);
    drng = [mn(2),mx(2),mn(1),mx(1)] + [-.5 .5 -.5 .5];

    % save parameters to the application data
    api.Isz = Isz;
    api.X   = X;
    api.Y   = Y;
    api.drng = drng;

    % save mask points to application data
    mask = api.Mask(:,:,seedframe);
    api.pts = [X(mask),Y(mask)];


    % VALIDATION-----------------------------------------------------------
    % Xseed, Yseed, Zseed

     % parse seeds
    xseed = api.Xseed;
    yseed = api.Yseed;
    zseed = api.Zseed;

    % check seeds are not specifed for empty imagery
    if (isempty(api.Xpha) && ~isempty(xseed)) || ...
       (isempty(api.Ypha) && ~isempty(yseed)) || ...
       (isempty(api.Zpha) && ~isempty(zseed))
        error(errid,'Seeds specifed for empty phase imagery.');
    end

    % validate seed locations
    idxfcn = @(x)x(:,1) + Isz(1)*(x(:,2)-1) + Isz(2)*Isz(1)*(seedframe-1);
    checkfcn = @(x)isnumeric(x) && ismatrix(x) &&  size(x,2)==2 && ...
        all(mod(x(:),1)==0) && all(1<=x(:)) && all(x(:,1)<=Isz(1)) && ...
        all(x(:,2)<=Isz(2)) && all(api.Mask(idxfcn(x)));

    if ~isempty(xseed) && ~checkfcn(xseed)
        error(errid,'Invalid Xseed.');
    elseif ~isempty(yseed) && ~checkfcn(yseed)
        error(errid,'Invalid Yseed.');
    elseif ~isempty(zseed) && ~checkfcn(zseed)
        error(errid,'Invalid Zseed.');
    end

    % default seeds, ensuring "empty" seeds still have dimension
    % (this makes updating the graphics object easier)
    if isempty(xseed)
        api.Xseed = zeros(0,2);
        if ~isempty(api.Xpha), api.Xseed = api.pts(1,[2 1]); end
    end
    if isempty(yseed)
        api.Yseed = zeros(0,2);
        if ~isempty(api.Ypha), api.Yseed = api.pts(1,[2 1]); end
    end
    if isempty(zseed)
        api.Zseed = zeros(0,2);
        if ~isempty(api.Zpha), api.Zseed = api.pts(1,[2 1]); end
    end



    % VALIDATION-----------------------------------------------------------
    % ResampleMethod, SpatialSmoothing, TemporalOrder

    % spatial resampling method
    checkfcn = @(x)ischar(x) && any(strcmpi(x,{'gridfit','tpaps'}));
    if ~checkfcn(api.ResampleMethod)
        error(errid,'ResampleMethod must be [gridfit|tpaps].');
    end

    % spatial smoothing parameter
    checkfcn = @(x)isempty(x) || ...
        (isfloat(x) && isscalar(x) && 0<x && x<=1);
    if ~checkfcn(api.SpatialSmoothing)
        error(errid,'SpatialSmoothing must be a scalar on (0,1].');
    end


    % default smoothing parameters
    pcubic  = 0.9;
    plinear = 0.5;
    if ~isempty(api.SpatialSmoothing)
        if isequal(api.ResampleMethod,'tpaps')
            pcubic = api.SpatialSmoothing;
        else
            plinear = api.SpatialSmoothing;
        end
    end

    api.pcubicedit = num2str(pcubic);
    api.plinearedit = num2str(plinear);


    % temporal polynomial order
    checkfcn = @(x)isnumeric(x) && isscalar(x) && mod(x,1)==0 ...
        && (x>0 || x==-1);
    if ~checkfcn(api.TemporalOrder)
        error(errid,'TemporalOrder must be a positive integer.');
    end



    % VALIDATION-----------------------------------------------------------
    % Mag, UnwrapRect

    if isequal(api.FigureType,'mgs')

        % Mag
        checkfcn = @(m)~isempty(m) && isnumeric(m) && ...
           ndims(m)==3 && all(0 <= m(:));

        if ~checkfcn(api.Mag)
            error(errid,'Invalid Magnitude Data');
        end


        % UnwrapRect
        checkfcn = @(x)isnumeric(x)&& numel(x)==4 && ....
           all(0.5<=x(1:2)) && all(x(1:2)<=Isz([2 1])+0.5) && ...
           all(0<x(3:4));

        if ~checkfcn(api.UnwrapRect)
            error(errid,'Invalid UnwrapRect.')
        end

    end






    %% LOAD GUI & PASS TO MAIN FUNCTION

    % load gui
    hfig = hgload([mfilename '.fig']);
    cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
    api.hfig = hfig;
    set(api.hfig,'renderer','zbuffer','Name',api.Name);
    setappdata(hfig,'flag_ipt',flag_ipt);

    % gather controls
    hchild = findobj(hfig);
    tags = get(hchild,'tag');
    for ti = 1:numel(hchild)
        if ~isempty(tags{ti}) && strcmpi(tags{ti}(1),'h')
            api.(tags{ti}) = hchild(ti);
        end
    end

    % pass to main function
    % this action is performed to allow the "onCleanup" function to
    % gracefully close the figure on exit/error.
    options = mainFcn(api);

end



%% MAIN FUNCTION
function options = mainFcn(api)

    api.clrH = [1 1 0];
    api.clrP = [1 0.5 0];

    % FIGURE APPEARANCE----------------------------------------------------

    % update object appearance based on "FigureType"
    switch lower(api.FigureType)

        % MOTION GUIDED SEGMENTATION
        case 'mgs'

            % shrink phase panel
            pospha = getpixelposition(api.hphapanel);
            pospha(3) = pospha(3)-210;
            setpixelposition(api.hphapanel,pospha);

            set([api.hzpha,api.hzphatext],'visible','off')

            % display first magnitude image
            api.hmagim = image('parent',api.hmag,...
                'cdata',api.Mag(:,:,[1 1 1]),'hittest','off');
            set(api.hmag,'xlim',[0 api.Isz(2)]+0.5,...
                'ylim',[0 api.Isz(1)]+0.5);

            % create draggable rect
            api.hrect = imrect(api.hmag,api.UnwrapRect);
            fcn = makeConstrainToRectFcn('imrect',...
                get(api.hmag,'xlim'),get(api.hmag,'ylim'));
            setPositionConstraintFcn(api.hrect,fcn);
            setColor(api.hrect,api.clrP);
            addNewPositionCallback(api.hrect,@(varargin)rectFcn(api.hfig));

            % create playbar
            api.hplaybar = playbar(api.hmagpanel);
            api.hplaybar.Min = api.ValidFrames(1);
            api.hplaybar.Max = api.ValidFrames(2);

            % position playbar
            pos    = getpixelposition(api.hplaybar.Parent);
            plsz   = [200 30];
            margin = 5;
            p = [(pos(3)+1)/2 - (plsz(1)+1)/2, 1+margin, plsz];
            setpixelposition(api.hplaybar,p);

            % create playbar listener
            api.hlisten = addlistener(api.hplaybar,...
                'NewValue',@(varargin)playbackFcn(api.hfig));

%             % make frame range invisible
%             set(api.hfrrngpanel,'visible','off');

        % STANDARD DISPLAY
        otherwise

            % turn off magnitude panel
            set(api.hmagpanel,'visible','off');

            % reposition phase panel
            posmag = getpixelposition(api.hmagpanel);
            pospha = getpixelposition(api.hphapanel);

            pospha(1:2) = posmag(1:2);
            setpixelposition(api.hphapanel,pospha);

    end

    % shorten figure
    pospha = getpixelposition(api.hphapanel);
    posfig = getpixelposition(api.hfig);
    posfig(3) = pospha(1)+pospha(3)+10;
    setpixelposition(api.hfig,posfig);


    % PHASE IMAGE INITIALIZATION-------------------------------------------

    % display phase imagery
    tf = api.Mask(:,:,api.SeedFrame);
    if ~isempty(api.Xpha)
        rgb = im2rgb(api.Xpha(:,:,api.SeedFrame),tf);
        image('parent',api.hxpha,'cdata',rgb,'hittest','off');
    end
    if ~isempty(api.Ypha)
        rgb = im2rgb(api.Ypha(:,:,api.SeedFrame),tf);
        image('parent',api.hypha,'cdata',rgb,'hittest','off');
    end
    if ~isempty(api.Zpha)
        rgb = im2rgb(api.Zpha(:,:,api.SeedFrame),tf);
        image('parent',api.hzpha,'cdata',rgb,'hittest','off');
    end

    % link axes limits
    linkaxes([api.hxpha,api.hypha,api.hzpha]);
    axis(api.hxpha,api.drng);

    zoom(api.hxpha,'reset');
    zoom(api.hypha,'reset');
    zoom(api.hzpha,'reset');


    % SEED POINT INITIALIZATION--------------------------------------------

    % available axes
    hax = [api.hxpha,api.hypha,api.hzpha];

    % "Add Point" context menu
    api.haddcontext = uicontextmenu(...
        'parent',api.hfig);
    uimenu(...
        'parent',   api.haddcontext,...
        'Label',    'Add Point',...
        'Callback', @(varargin)pointAdd(gco));

    tf = cellfun(@(tag)~isempty(api.(tag)),{'Xpha','Ypha','Zpha'});
    set(hax(tf),'uicontextmenu',api.haddcontext);

    % "Delete Point" context menu
    api.hdelcontext = uicontextmenu(...
        'parent',api.hfig);
    uimenu(...
        'parent',   api.hdelcontext,...
        'Label',    'Delete Point',...
        'Callback', @(varargin)pointDelete(gco));

    % xseed point creation
    Npt = size(api.Xseed,1);
    api.hxseed = NaN(Npt,1);

    hmenu = [];
    if Npt > 1, hmenu = api.hdelcontext; end

    for k = 1:Npt
        api.hxseed(k) = pointCreate(hax(1),hmenu,...
            api.Xseed(k,:),api.clrP);
    end

    % yseed point creation
    Npt = size(api.Yseed,1);
    api.hyseed = NaN(Npt,1);

    hmenu = [];
    if Npt > 1, hmenu = api.hdelcontext; end

    for k = 1:Npt
        api.hyseed(k) = pointCreate(hax(2),hmenu,...
            api.Yseed(k,:),api.clrP);
    end

    % zseed point creation
    Npt = size(api.Zseed,1);
    api.hzseed = NaN(Npt,1);

    hmenu = [];
    if Npt > 1, hmenu = api.hdelcontext; end

    for k = 1:Npt
        api.hzseed(k) = pointCreate(hax(3),hmenu,...
            api.Zseed(k,:),api.clrP);
    end

    % point names
    pointName(api.hxseed,'X.');
    pointName(api.hyseed,'Y.');
    pointName(api.hzseed,'Z.');
%
%     % point creation
%     api.hpoint = NaN(Npt,1);
%     for k = 1:Npt
%
%         % create graphics object
%         api.hpoint(k) = line(...
%             'parent',       hax(k),...
%             'color',        api.clrP,...
%             'marker',       'o',...
%             'markersize',   15,...
%             'linewidth',    3);
%
%         % Mouse Pointer Behavior
%         pb = struct(...
%             'enterFcn',     @(varargin)pointEnter(api.hpoint(k),api.hfig),...
%             'traverseFcn',  [],...
%             'exitFcn',      @(varargin)pointExit(api.hpoint(k),api.hfig));
%         iptSetPointerBehavior(api.hpoint(k),pb);
%
%         % button down behavior
%         set(api.hpoint(k),'ButtonDownFcn',...
%             @(varargin)pointDrag(api.hpoint(k),api.hfig));
%     end


%     % set initial point locations
%     x = {api.Xseed(:,2),api.Yseed(:,2),api.Zseed(:,2)};
%     y = {api.Xseed(:,1),api.Yseed(:,1),api.Zseed(:,1)};
%     set(api.hpoint(:),{'xdata'},x(:),{'ydata'},y(:));

    % ADDITIONAL SETUP-----------------------------------------------------

    % link enable properties
    h = [api.hcubicedit,api.hcubictext];
    hlink = linkprop(h,'Enable');
    setappdata(h(1),'enable_link',hlink);

    h = [api.hlinearedit,api.hlineartext];
    hlink = linkprop(h,'Enable');
    setappdata(h(1),'enable_link',hlink);

    % display the frame
    str = get(api.hphatext,'string');
    str = regexprep(str,'XX',num2str(api.SeedFrame));
    set(api.hphatext,'string',str);

    % callback setup
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));

    set(api.hspacepanel,'SelectionChangeFcn',...
        @(src,evnt)spaceSelection(api.hfig,evnt));
    set(api.hcubicedit,'Callback',...
        @(varargin)spaceEditCallback(api.hfig,api.hcubicedit));
    set(api.hlinearedit,'Callback',...
        @(varargin)spaceEditCallback(api.hfig,api.hlinearedit));

    set(api.htimeedit,'Callback',...
        @(varargin)timeEditCallback(api.hfig));

    set(api.hfrmin,'Callback',...
        @(varargin)minCallback(api.hfig));
    set(api.hfrmax,'Callback',...
        @(varargin)maxCallback(api.hfig));

    % initial resampling method
    h = [api.hcubicedit;api.hlinearedit];
    if isequal(api.ResampleMethod,'gridfit')
        set(api.hlinear,'value',1);
        set(h,{'enable'},{'off';'on'});
    else
        set(api.hcubic,'value',1);
        set(h,{'enable'},{'on';'off'});
    end


    % initial edit values
    set(api.hcubicedit,'string',api.pcubicedit);
    set(api.hlinearedit,'string',api.plinearedit);
    set(api.htimeedit,'string',num2str(api.TemporalOrder))

    set(api.hfrmin,'string',api.FramesForAnalysis(1));
    set(api.hfrmax,'string',api.FramesForAnalysis(2));

    set(api.hfig,'color',get(api.hspacepanel,'backgroundcolor'));
    str = sprintf('Frame Range on [%d:%d]',api.ValidFrames);
    set(api.hfrrngpanel,'Title',str);

    % save to figure
    guidata(api.hfig,api);
    redrawFcn(api.hfig);

    % initialize pointer manager
    if getappdata(api.hfig,'flag_ipt')
        iptPointerManager(api.hfig,'enable');
    else
        api.MotionAPI = figureMotionSetup(api.hfig,...
            'ToolTipFontName','Segoe UI',...
            'ToolTipFontSize',9);
        api.MotionAPI.start();
    end

    % WAIT & CLEANUP-------------------------------------------------------

    % wait for figure to finish
    waitfor(api.hfig,'userdata')
    if isfield(api,'hlisten'), delete(api.hlisten); end

    % output new options
    if ~ishandle(api.hfig) || ...
       ~isequal(get(api.hfig,'userdata'),'complete')
        options = [];
    else
        api = guidata(api.hfig);
        options = struct(...
            'SeedFrame',        api.SeedFrame,...
            'Xseed',            api.Xseed,...
            'Yseed',            api.Yseed,...
            'Zseed',            api.Zseed,...
            'FramesForAnalysis',api.FramesForAnalysis,...
            'ResampleMethod',   api.ResampleMethod,...
            'SpatialSmoothing', api.SpatialSmoothing,...
            'TemporalOrder',    api.TemporalOrder,...
            'UnwrapRect',       api.UnwrapRect);
    end

end



%% BUTTON CALLBACKS (OK/CANCEL/FIGURECLOSE)

function okCallback(hfig)
    set(hfig,'userdata','complete');
end

function cancelCallback(hfig)
    set(hfig,'userdata','cancel');
end

function figCloseRequestFcn(hfig)
    set(hfig,'userdata','cancel');
end



%% SPATIAL SMOOTHING CALLBACKS

function spaceSelection(hfig,evnt)
% uibuttongroup SelectionChangeFcn

    api = guidata(hfig);
    if (evnt.NewValue == api.hcubic)
        set([api.hcubicedit;api.hlinearedit],{'enable'},{'on';'off'});
        api.ResampleMethod = 'tpaps';
        api.SpatialSmoothing = str2double(api.pcubicedit);
    else
        set([api.hcubicedit;api.hlinearedit],{'enable'},{'off';'on'});
        api.ResampleMethod = 'gridfit';
        api.SpatialSmoothing = str2double(api.plinearedit);
    end

    guidata(hfig,api);
end


function spaceEditCallback(hfig,hobj)
% editbox Callback
% ensure the user-entered value is valid, and update the display.  Note we
% keep the entered value as a string, as the STR2NUM function allows the
% user to enter functions as well as numbers (like "1-1e-2" rather than
% "0.99".

    api = guidata(hfig);

    % determine object save tag
    h = [api.hcubicedit,api.hlinearedit];
    tags = {'pcubicedit','plinearedit'};

    tag = tags{h==hobj};

    str = get(hobj,'string');
    val = str2double(str);
    if isempty(val) || val < 0 || 1 < val
        set(hobj,'string',api.(tag));
    else
        api.(tag) = str;
    end

    api.SpatialSmoothing = str2double(api.(tag));
    guidata(hfig,api);
end



%% TEMPORAL SMOOTHING CALLBACKS

function timeEditCallback(hfig)
% editbox Callback: ensure the user-entered value is valid,
% and update the display.

    api = guidata(hfig);

    val = round(str2double(get(api.htimeedit,'string')));
    if ~isnan(val) && mod(val,1)==0 && (val>0 || val==-1)
        api.TemporalOrder = val;
    end
    set(api.htimeedit,'string',api.TemporalOrder);

    guidata(hfig,api);
end



%% POINT UPDATE FUNCTIONS
% Ther functions define the interactive behavior of the user-draggable
% points, including "enter" and "exit" functions for the Pointer Manager,
% and a "drag" function for the ButtonDownFcn.

function hpt = pointCreate(hax,hmenu,ijpos,clr)
% create points

    hfig = ancestor(hax,'figure');

    % create graphics object
    hpt = line(...
        'parent',           hax,...
        'color',            clr,...
        'marker',           'o',...
        'markersize',       15,...
        'linewidth',        3,...
        'Xdata',            ijpos(2),...
        'Ydata',            ijpos(1),...
        'uicontextmenu',    hmenu);

    % Mouse Pointer Behavior
    if getappdata(hfig,'flag_ipt')
        pb = struct(...
            'enterFcn',     @(varargin)pointEnter(hpt,hfig),...
            'traverseFcn',  [],...
            'exitFcn',      @(varargin)pointExit(hpt,hfig));
        iptSetPointerBehavior(hpt,pb);
    else
        setappdata(hpt,'EnterFcn',@(varargin)pointEnter(hpt,hfig));
        setappdata(hpt,'ExitFcn',@(varargin)pointExit(hpt,hfig));
    end

    % button down behavior
    set(hpt,'ButtonDownFcn',@(varargin)pointDrag(hpt,hfig));

end

function pointAdd(hax)

    hfig = ancestor(hax,'figure');
    api = guidata(hfig);

    % default position within mask
    pos = api.pts(1,[2 1]);

    % create point
    hpt = pointCreate(hax,[],pos,api.clrP);

    % add point to proper point listing
    switch hax
        case api.hxpha,
            api.hxseed(end+1,:) = hpt;
            set(api.hxseed,'uicontextmenu',api.hdelcontext);
            pointName(api.hxseed,'X.');
        case api.hypha,
            api.hyseed(end+1,:) = hpt;
            set(api.hyseed,'uicontextmenu',api.hdelcontext);
            pointName(api.hyseed,'Y.');
        case api.hzpha,
            api.hzseed(end+1,:) = hpt;
            set(api.hzseed,'uicontextmenu',api.hdelcontext);
            pointName(api.hzseed,'Z.');
    end

    guidata(hfig,api);
    redrawFcn(hfig)

end

function pointDelete(hpt)

    hfig = ancestor(hpt,'figure');
    api = guidata(hfig);

    delete(hpt);

    api.hxseed = api.hxseed(ishandle(api.hxseed));
    pointName(api.hxseed,'X.');
    api.hyseed = api.hyseed(ishandle(api.hyseed));
    pointName(api.hyseed,'Y.');
    api.hzseed = api.hzseed(ishandle(api.hzseed));
    pointName(api.hzseed,'Z.');

    guidata(hfig,api);
    redrawFcn(hfig)

end


function pointName(hpt,header)
    for k = 1:numel(hpt)
        if ~ishandle(hpt(k)), continue; end
        setappdata(hpt(k),'ToolTip',sprintf('%s%d',header,k));
    end
end


function pointEnter(hpt,hfig)
% enter point - update color & figure pointer
    api = guidata(hfig);
    set(hpt,'color',api.clrH);
    set(api.hfig,'Pointer','fleur');
end

function pointExit(hpt,hfig)
% exit point - reset color
if ~ishandle(hpt), return; end
    api = guidata(hfig);
    set(hpt,'color',api.clrP);
end


function pointDrag(hpt,hfig)
% drag point - initialize an "onCleanup" object for graceful cleanup and
% pass to the main drag function.
    cobj = onCleanup(@()pointDragCleanup(hfig));
    pointDragMain(hpt,hfig);
end

function pointDragMain(hpt,hfig)
% drag point MAIN - allow the user to drag the given point to valid pixel
% locations within the "api.Mask" (already specified by "api.pts"

    % current guidata
    api = guidata(hfig);

    % current axes
    hax = ancestor(hpt,'axes');

    if getappdata(hfig,'flag_ipt')
        % stop PointerManager
        iptPointerManager(api.hfig, 'disable')

        % initialize buttonmotion/buttonup functions
        set(api.hfig,...
            'WindowButtonMotionFcn',@(varargin)buttonMotion(),...
            'WindowButtonUpFcn',@(varargin)buttonUp());

    else
        % create (or locate) the UI mode
        modename = 'splinemodel_drag_mode';
        hmode = getuimode(hfig,modename);
        if isempty(hmode)
            hmode = uimode(hfig,modename);
        end

        % mode functions
        set(hmode,...
            'WindowButtonUpFcn',@(varargin)buttonUp(),...
            'WindowButtonMotionFcn',@(varargin)buttonMotion());

        % activate uimode
        activateuimode(hfig,modename);

    end

    % wait for userdata
    set(hpt,'userdata',[]);
    waitfor(hpt,'userdata');

    % MOTION FUNCTION
    function buttonMotion()
        try
            % current point
            pos = get(hax,'currentpoint');
            pos = pos([1 3]);

            % constrain to nearest masked pixel
            d = (pos(1)-api.pts(:,1)).^2 + (pos(2)-api.pts(:,2)).^2;
            [val,idx] = min(d(:));
            pos = api.pts(idx,:);

            % update point
            set(hpt,'xdata',pos(1),'ydata',pos(2));

        catch ERR
            set(hpt,'userdata','error');
            rethrow(ERR)
        end
    end

    % BUTTON UP FUNCTION
    function buttonUp()
        set(hpt,'userdata','complete')
    end


end


function pointDragCleanup(hfig)
% drag cleanup - return the figure to its initial pre-drag state and force
% the software to recalculate the automated SpatialSmoothing parameter.

    if ~ishandle(hfig) || strcmpi(get(hfig,'BeingDeleted'),'on')
        return;
    end

    if getappdata(hfig,'flag_ipt')
        set(hfig,...
            'WindowButtonMotionFcn',[],...
            'WindowButtonUpFcn',    []);
        iptPointerManager(hfig, 'enable')
    else
        activateuimode(hfig,'');
    end

    api = guidata(hfig);
    api.pspaceauto = [];
    guidata(hfig,api);
    redrawFcn(hfig)
end



%% REDRAW
% This function controls much of the application data updating, running
% after most major events (like changes in the seed position or smoothing
% values).  It will update the x/y/z seed locations.

function redrawFcn(hfig)

    % application data
    api = guidata(hfig);

    % record seeds
    if ~isempty(api.Xseed)
        x = get(api.hxseed,{'xdata'});
        y = get(api.hxseed,{'ydata'});
        api.Xseed = [cat(1,y{:}),cat(1,x{:})];
    end
    if ~isempty(api.Yseed)
        x = get(api.hyseed,{'xdata'});
        y = get(api.hyseed,{'ydata'});
        api.Yseed = [cat(1,y{:}),cat(1,x{:})];
    end
    if ~isempty(api.Zseed)
        x = get(api.hzseed,{'xdata'});
        y = get(api.hzseed,{'ydata'});
        api.Zseed = [cat(1,y{:}),cat(1,x{:})];
    end

    % save application data
    guidata(api.hfig,api);

end



%%  MAGNITUDE PLAYBACK & UNWRAPRECT UPDATE
function playbackFcn(hfig)

    % application data
    api = guidata(hfig);

    % update magnitude display
    fr = api.hplaybar.Value;
    set(api.hmagim,'cdata',api.Mag(:,:,[fr fr fr]));

end

function rectFcn(hfig)
    api = guidata(hfig);
    api.UnwrapRect = getPosition(api.hrect);
    guidata(hfig,api);
end


%% FRAME RANGE CALLBACK
function minCallback(hfig)

    % application data
    api = guidata(hfig);

    val = round(str2double(get(api.hfrmin,'string')));
    if isfinite(val) && api.ValidFrames(1)<=val && val<=api.SeedFrame
        api.FramesForAnalysis(1) = val;
    end
    set(api.hfrmin,'String',api.FramesForAnalysis(1));
    guidata(hfig,api);

end

function maxCallback(hfig)

    % application data
    api = guidata(hfig);

    val = round(str2double(get(api.hfrmax,'string')));
    if isfinite(val) && api.SeedFrame<=val && val<=api.ValidFrames(end)
        api.FramesForAnalysis(2) = val;
    end
    set(api.hfrmax,'String',api.FramesForAnalysis(2));
    guidata(hfig,api);
end



%% HELPER FUNCTION: MASKED RGB IMAGE
function RGB = im2rgb(im,tf)

    % check for empty
    if isempty(im), RGB = []; return; end

    % "black" color where (tf==0)
    blk = [0.25 0.25 0.50];

    % "white" color where (tf==0)
    wht = [0.50 0.50 1.00];

    % normalize image
    mn = -pi;%min(im(:));
    mx = pi;%max(im(:));
    im = (im - mn)/(mx-mn);

    % generate RGB image
    R = tf.*im + ~tf.*((im*(wht(1)-blk(1))) + blk(1));
    G = tf.*im + ~tf.*((im*(wht(2)-blk(2))) + blk(2));
    B = tf.*im + ~tf.*((im*(wht(3)-blk(3))) + blk(3));
    RGB = cat(3,R,G,B);

end



%% END OF FILE=============================================================
