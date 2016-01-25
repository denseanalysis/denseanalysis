function shft = DENSEtranslate(varargin)
% shft = DENSEtranslate(varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
    % default error id
    errid = sprintf('%s:invalidInput',mfilename);

    % parse inputs
    defapi = struct(...
        'xmag', [],...
        'ymag', [],...
        'zmag', [],...
        'shift', NaN(2,3));

    [api,other_args] = parseinputs(defapi,[],varargin{:});


    % check for at least two non-empty images
    tags = {'xmag','ymag','zmag'};
    tf = cellfun(@(t)~isempty(api.(t)),tags);

    if sum(tf) < 2
        error(errid,'%s','At least two image sequences are ',...
            'required for proper registration.');
    end

    % check imagery
    checkfcn = @(m)isempty(m) || (isnumeric(m) && any(ndims(m)==[2 3]));

    if ~checkfcn(api.xmag) || ~checkfcn(api.ymag) || ~checkfcn(api.zmag)
        error(errid,'%s','Invalid imagery; function expects 2D+time ',...
            ' X/Y/Z magnitude information of the same size.');
    end

    % base imagery (imagery to be registered against)
    baseidx = find(tf,1,'first');
    api.Isz = size(api.(tags{baseidx})(:,:,1));
    api.Nfr = size(api.(tags{baseidx}),3);

    % check other imagery against base imagery
    checkfcn = @(m)isempty(m) || ...
        (all(size(m(:,:,1)) == api.Isz) && size(m,3) == api.Nfr);

    if ~checkfcn(api.xmag) || ~checkfcn(api.ymag) || ~checkfcn(api.zmag)
        error(errid,'%s','Invalid imagery; function expects 2D+time ',...
            'X/Y/Z magnitude information of the same size.');
    end

    % check shift
    checkfcn = @(s)~isempty(s) && isnumeric(s) && ndims(s)==2 && ...
        all(size(s)==[2 3]);

    if ~checkfcn(api.shift)
        error(errid,'Invalid shift values.');
    end

    api.shift(isnan(api.shift)) = 0;
    tmp = mod(api.shift,1);
    if any(tmp(:) ~= 0)
        error(errid,'Invalid shift values (non-integer).');
    end

    api.x_ijshift = api.shift(:,1);
    api.y_ijshift = api.shift(:,2);
    api.z_ijshift = api.shift(:,3);



    % load the arrow display
    if exist('arrows.mat','file')
        api.arrows = load('arrows.mat');
    end


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
    shft = mainFcn(api);


end


function shft = mainFcn(api)

    % translation button images
    if isfield(api,'arrows')
        set([api.hxN,api.hyN,api.hzN],'cdata',api.arrows.up,   'string',[]);
        set([api.hxS,api.hyS,api.hzS],'cdata',api.arrows.down, 'string',[]);
        set([api.hxW,api.hyW,api.hzW],'cdata',api.arrows.left, 'string',[]);
        set([api.hxE,api.hyE,api.hzE],'cdata',api.arrows.right,'string',[]);
    end

    % zoom/pan images
    I = get(api.hzoomintool,'Cdata');
    set(api.hzoomin,'Cdata',I,'string',[]);
    I = get(api.hzoomouttool,'Cdata');
    set(api.hzoomout,'Cdata',I,'string',[]);
    I = get(api.hpantool,'Cdata');
    set(api.hpan,'Cdata',I,'string',[]);

    % figure colormap
    set(api.hfig,'colormap',gray(256));

    % link enable properties
    h = [api.hxN,api.hxS,api.hxW,api.hxE];
    hlink = linkprop(h,'Enable');
    setappdata(h(1),'graphics_enablelink',hlink);

    h = [api.hyN,api.hyS,api.hyW,api.hyE];
    hlink = linkprop(h,'Enable');
    setappdata(h(1),'graphics_enablelink',hlink);

    h = [api.hzN,api.hzS,api.hzW,api.hzE];
    hlink = linkprop(h,'Enable');
    setappdata(h(1),'graphics_enablelink',hlink);

    % draw images
    api.hax    = [api.hxmag;api.hymag;api.hzmag];
    api.him    = NaN(3,1);
    api.htitle = NaN(3,1);
    labels = {'x','y','z'};
    for k = 1:numel(api.him)
        imtag = [labels{k} 'mag'];
        tgtag = ['h' labels{k} 'N'];
        if ~isempty(api.(imtag))
            api.him(k) = image('parent',api.hax(k),...
                'cdata',api.(imtag)(:,:,1),'cdatamapping','scaled');
            set(api.(tgtag),'enable','on');
        end
        api.htitle(k) = title(api.hax(k),'temp');
    end
    set(api.hax,'xlim',[0 api.Isz(2)]+0.5,'ylim',[0 api.Isz(1)]+0.5);
    linkaxes(api.hax);
    set(api.htitle,'color',get(api.hax(1),'xcolor'),...
        'fontsize',13,'fontweight','bold');

    % create grids
    Nline = 3;
    vals = linspace(0,1,Nline+2);
    vals = vals(2:end-1);

    api.hgrid = NaN(1,3);
    for k = 1:numel(api.hax)
        api.hgrid(k) = axes('parent',api.haxespanel,...
            'units','pixels','position',getpixelposition(api.hax(k)));

        x = [vals; vals];
        y = [zeros(1,Nline); ones(1,Nline)];
        line([x,y],[y,x],'parent',api.hgrid(k),...
            'color','r','linewidth',2,'linestyle','--')
    end

    set(api.hgrid,...
        'units','normalized','visible','off',...
        'hittest','off','handlevisibility','off',...
        'dataaspectratio',[1 1 1],...
        'xlim',[0 1],'ylim',[0 1]);


    % playbar
    api.hplaybar = playbar(api.hzoompanel);
    setpixelposition(api.hplaybar,[100 1 250 30]);
    api.hplaybar.BackgroundColor = get(api.hzoompanel,'BackgroundColor');
    api.hplaybar.BorderType = 'none';
    api.hplaybar.Max = api.Nfr;
    hlisten_playbar = addlistener(api.hplaybar,...
        'NewValue',@(varargin)playbackFcn(api.hfig));


    % set shift functions
    dir  = {'N','S','W','E'};
    shft = [-1 0; 1 0; 0 -1; 0 1];

    for k = 1:numel(labels)
        tags = strcat('h',labels{k},dir);
        for ti = 1:numel(dir)
            set(api.(tags{ti}),'Callback',...
                @(varargin)shiftFcn(api.hfig,labels{k},shft(ti,:)));
        end
    end


    % set callbacks
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));
    set(api.hzero,'Callback',@(varargin)zeroFcn(api.hfig));
    set(api.hauto,'Callback',@(varargin)autoFcn(api.hfig));

    set(api.hfig,'ResizeFcn',@(varargin)resizeFcn(api.hfig));

    set(api.hzoomin,'Callback',@(varargin)zoominCallback(api.hfig));
    set(api.hzoomout,'Callback',@(varargin)zoomoutCallback(api.hfig));
    set(api.hpan,'Callback',@(varargin)panCallback(api.hfig));

    % update application data
    guidata(api.hfig,api);

    % update image shifts
    shiftFcn(api.hfig,'x',api.x_ijshift,1);
    shiftFcn(api.hfig,'y',api.y_ijshift,1);
    shiftFcn(api.hfig,'z',api.z_ijshift,1);


    % wait for figure to finish
    set(api.hfig,'visible','on');

    waitfor(api.hfig,'userdata')

    % cleanup
    delete(hlisten_playbar);

    % output
    if ~ishandle(api.hfig) || ~isequal(get(api.hfig,'userdata'),'complete')
        shft = [];
    else
        api = guidata(api.hfig);

        shft = [api.x_ijshift(:), api.y_ijshift(:), api.z_ijshift(:)];
        tf = isnan(api.him);
        shft(:,tf) = NaN;
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


%% ZOOM/PAN CALLBACKS

function zoominCallback(hfig)
    api = guidata(hfig);
    if get(api.hzoomin,'value')
        set([api.hzoomout,api.hpan],'Value',0);
        zoom(hfig,'inmode');
    else
        zoom(hfig,'off');
    end
end

function zoomoutCallback(hfig)
    api = guidata(hfig);
    if get(api.hzoomout,'value')
        set([api.hzoomin,api.hpan],'Value',0);
        zoom(hfig,'outmode');
    else
        zoom(hfig,'off');
    end
end

function panCallback(hfig)
    api = guidata(hfig);
    if get(api.hpan,'value')
        set([api.hzoomin,api.hzoomout],'Value',0);
        pan(hfig,'on');
    else
        pan(hfig,'off');
    end
end




%% RESIZE FUNCTIONS

function resizeFcn(hfig)

    horz = [10 10 10 10];
    vert = [40 5 5]; % top/mid/bot
    mnsz = [600 350];

    % application data
    api = guidata(hfig);

    % figure position
    pos = getpixelposition(hfig);
    sz = max(pos(3:4),mnsz);
    xy = 1 + [0,pos(4)-sz(2)];

    % place primary panels
    width  = 120;

    poslft = getpixelposition(api.hcontrol);
    poslft = [xy(1) xy(2)+sz(2)-poslft(4) width poslft(4)];
    setpixelposition(api.hcontrol,poslft);

    posrght = [xy(1)+width xy(2) sz(1)-width sz(2)];
    setpixelposition(api.haxespanel,posrght);


    % place zoom panel
    poszoom = getpixelposition(api.hzoompanel);
    poszoom(2) = 1+vert(end);
    poszoom(1) = (posrght(3)-poszoom(3))/2;
    setpixelposition(api.hzoompanel,poszoom);

    % place axes panels
    width  = (posrght(3)-sum(horz))/3;
    height = posrght(4)-poszoom(4)-sum(vert);
    posax = [1+horz(1), poszoom(2)+poszoom(4)+vert(2), width, height];

    for k = 1:3
        setpixelposition(api.hax(k),posax);
        setpixelposition(api.hgrid(k),posax);
        posax(1) = posax(1) + width + horz(k+1);
    end




end



%% SHIFT FUNCTION

function shiftFcn(hfig,tag,ijshft,absolute)

    if nargin<4 || isempty(absolute), absolute = false; end

    api = guidata(hfig);

    stag = [tag '_ijshift'];
    if ~absolute
        api.(stag)(:) = api.(stag)(:) + ijshft(:);
    else
        api.(stag)(:) = ijshft(:);
    end

    i = [1 api.Isz(1)] + api.(stag)(1);
    j = [1 api.Isz(2)] + api.(stag)(2);

    labels = {'x','y','z'};
    tf = strcmpi(tag,labels);

    if ~isnan(api.him(tf))
        set(api.him(tf),'xdata',j,'ydata',i);
    end

    strs = {'X-DATA','Y-DATA','Z-DATA'};
    buf = {strs{tf},sprintf('\\fontsize{10}Row/Col Shift = [%d,%d]',api.(stag))};
    set(api.htitle(tf),'string',buf);

    guidata(hfig,api);
end


%% PLAYBACK FUNCTION
function playbackFcn(hfig)

    api = guidata(hfig);

    fr = api.hplaybar.Value;
    tags = {'xmag','ymag','zmag'};
    for k = 1:numel(api.him)
        if ~isempty(api.(tags{k}))
            set(api.him(k),'cdata',api.(tags{k})(:,:,fr));
        end
    end

end


%% ZERO TRANSLATION
function zeroFcn(hfig)
    shiftFcn(hfig,'x',[0 0],1);
    shiftFcn(hfig,'y',[0 0],1);
    shiftFcn(hfig,'z',[0 0],1);
end


%% AUTOMATICALLY REGISTER
function autoFcn(hfig)
    api = guidata(hfig);
    shft = registerDENSE(api.xmag,api.ymag,api.zmag);

    % build notification buffer
    buf = num2cell(shft);
    tf = ~isnan(shft);
    buf(tf) = cellfun(@(x)sprintf('%3d',x),buf(tf),'uniformoutput',0);
    buf(~tf) = {'  -'};

    tmp = ['Automated registration results [row,col]:\n',...
        '\\fontname{fixedwidth}',...
        'X-shift [%s,%s]\nY-shift [%s,%s]\nZ-shift [%s,%s]'];
    buf = sprintf(tmp,buf{:});

    % message box to accept results
    options.Interpreter = 'tex';
    options.Default = 'Accept';
    button = questdlg(buf,'Automated Registration',...
        'Accept','Cancel',options);
    if ~isequal(button,'Accept'), return; end

    % update figure
    shft(isnan(shft)) = 0;
    shiftFcn(hfig,'x',shft(:,1)',1);
    shiftFcn(hfig,'y',shft(:,2)',1);
    shiftFcn(hfig,'z',shft(:,3)',1);

end
