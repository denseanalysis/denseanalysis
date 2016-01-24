function opts = analysisoptions(varargin)
% opts = analysisoptions(varargin)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------


    % default error id
    errid = sprintf('%s:invalidInput',mfilename);

    % parse inputs
    defapi = struct(...
        'Colormap', 'jet',...
        'XXrng',    [-0.5 0.5],...
        'YYrng',    [-0.5 0.5],...
        'SHrng',    [-0.5 0.5],...
        'p1rng',    [-0.7 0.7],...
        'p2rng',    [-0.3 0.3],...
        'RRrng',    [-0.7 0.7],...
        'CCrng',    [-0.3 0.3],...
        'SSrng',    [-0.3 0.3],...
        'dXrng',    [-3 3],...
        'dRrng',    [-3 3],...
        'dCrng',    [-1 1],...
        'twistrng', [-10 10],...
        'Pixelate', false,...
        'Marker',  false);

    [api,other_args] = parseinputs(defapi,[],varargin{:});

    if ~isempty(other_args)
        error(errid,'Unrecognized Input.');
    end

    % check colormap
    api.mapnames = {'Jet','HSV','Hot','Cool','Spring',...
        'Autumn','Winter','Gray','Bone','Copper','Pink',...
        'StrainCmap'};

    tf = strcmpi(api.Colormap,api.mapnames);
    if ~any(tf)
        str = sprintf('%s|',api.mapnames{:});
        error(errid,'%s','Unrecognized Colormap.  ',...
            'Acceptable values are [',str(1:end-1),'].');
    end

    % check ranges
    tags = fieldnames(defapi);
    tags = tags(strwcmpi(tags,'*rng'));
    api.clrid = regexprep(tags,'rng','');

    checkfcn = @(x)~isempty(x) && isnumeric(x) && ...
        numel(x)==2 && x(1)<x(2);
    for k = 1:numel(tags)
        if ~checkfcn(api.(tags{k}))
            error(errid,['Invalid ' api.clrid{k} ' strain range.']);
        end
    end

    % check pixelate & markers
    api.Pixelate = isequal(api.Pixelate,true);
    api.Marker   = isequal(api.Marker,true);

    % load gui
    hfig = hgload([mfilename '.fig']);
    cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
    api.hfig = hfig;
    set(hfig,'visible','off');

    % gather controls
    hchild = findobj(hfig);
    tags = get(hchild,'tag');
    for ti = 1:numel(hchild)
        if ~isempty(tags{ti}) && strcmpi(tags{ti}(1),'h')
            api.(tags{ti}) = hchild(ti);
        end
    end

    % pass to the subfunction
    opts = mainFcn(api);


end


function opts = mainFcn(api)


    % draw a patch object to represent the colormap
    N = 256;
    x = linspace(0,1,N+1);
    y = [0 1];
    [X,Y] = meshgrid(x,y);

    fvc = surf2patch(X,Y,zeros(size(X)),linspace(0,1,N));
    fvc.vertices = fvc.vertices(:,[1 2]);

    api.hpatch = patch('parent',api.hcoloraxes,...
        fvc,'facecolor','flat','edgecolor','none');

    % populate the colormap listbox

    idx = find(strcmpi(api.Colormap,api.mapnames));
    set(api.hcolormap,'String',api.mapnames,'value',idx);

    map = eval([lower(api.Colormap) '(256)']);
    set(api.hfig,'colormap',map);


    % update strain ranges
    for k = 1:numel(api.clrid)
        tag = api.clrid{k};
        tagmn = ['h' tag 'mn'];
        tagmx = ['h' tag 'mx'];
        tagrng = [tag 'rng'];

        set([api.(tagmn);api.(tagmx)],...
            {'string'}, num2cell(api.(tagrng))',...
            'Callback', @(varargin)rangeCallback(api.hfig,tag));
    end

    % update pixelate/marker
    set(api.hpix,'Value',api.Pixelate);
    set(api.hmark,'Value',api.Marker);


    % set callbacks
    set(api.hcolormap,'Callback',...
        @(varargin)colormapCallback(api.hfig));
    set(api.hpix,'Callback',...
        @(varargin)pixelateCallback(api.hfig));
    set(api.hmark,'Callback',...
        @(varargin)markerCallback(api.hfig));
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));


    % wait for figure to finish
    set(api.hfig,'visible','on');
    guidata(api.hfig,api);
    waitfor(api.hfig,'userdata')

    % output
    if ~ishandle(api.hfig) || ~isequal(get(api.hfig,'userdata'),'complete')
        opts = [];
    else
        api = guidata(api.hfig);

        opts = struct('Colormap',api.Colormap,...
            'Pixelate',api.Pixelate,'Marker',api.Marker);
        for k = 1:numel(api.clrid)
            tag = [api.clrid{k} 'rng'];
            opts.(tag) = api.(tag);
        end

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



%% COLORMAP CALLBACK
function colormapCallback(hfig)
    api = guidata(hfig);

    buf = get(api.hcolormap,'string');
    val = get(api.hcolormap,'value');
    map = eval([lower(buf{val}) '(256)']);

    set(api.hfig,'colormap',map);
    api.Colormap = lower(buf{val});
    guidata(hfig,api);
end



%% STRAIN VALUE CALLBACKS
function rangeCallback(hfig,tag)

    api = guidata(hfig);

    idx = find(strcmpi(api.clrid,tag));

    tagmn = ['h' tag 'mn'];
    tagmx = ['h' tag 'mx'];
    tagrng = [tag 'rng'];

    mn = str2double(get(api.(tagmn),'String'));
    mx = str2double(get(api.(tagmx),'String'));


    if isnumeric(mn) && isnumeric(mx) && mn < mx
        api.(tagrng) = [mn mx];
    else
        mn = api.(tagrng)(1);
        mx = api.(tagrng)(2);
    end

    set(api.(tagmn),'String',mn);
    set(api.(tagmx),'String',mx);
    guidata(hfig,api);

end


%% PIXELATE/MARKER CALLBACK
function pixelateCallback(hfig)
    api = guidata(hfig);
    api.Pixelate = logical(get(api.hpix,'Value'));
    guidata(hfig,api);
end

function markerCallback(hfig)
    api = guidata(hfig);
    api.Marker = logical(get(api.hmark,'Value'));
    guidata(hfig,api);
end
