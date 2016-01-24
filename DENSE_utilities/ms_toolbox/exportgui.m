function varargout = exportgui(varargin)
% varargout = exportgui(varargin)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

    % FIGURE OPTIONS-------------------------------------------------------
    FLAG_close = true;


    % SETUP----------------------------------------------------------------

    % gather compression codecs
    if strcmpi(computer,'PCWIN')
        codec = {'None','Indeo3','Indeo5','Cinepak','MSVC','RLE'};
    elseif strcmpi(computer,'PCWIN64')
        codec = {'None','MSVC','RLE'};
    else
        codec = {'None'};
    end

    % default options
    defapi = struct(...
        'File',                 '',...
        'UseScreenSize',        true,...
        'Height',               5,...
        'Width',                5,...
        'UseScreenResolution',  false,...
        'Resolution',           300,...
        'FramesPerSecond',      15,...
        'AVICodec',             codec{1});
    savetags = [fieldnames(defapi);'Format'];

    % additional fields
    defapi.InitialFileBrowse = true;
    defapi.ScreenHeight      = 0;
    defapi.ScreenWidth       = 0;
    defapi.ScreenResolution  = 0;
    defapi.AllFormats        = [];

    % super-user options
    defapi.ParseOptions = false;

    % parse options (ignoring additional fields)
    [api,other_args] = parseinputs(defapi,[],varargin{:});


    % ensure logical flags
    tags = {'ParseOptions','InitialFileBrowse',...
        'UseScreenSize','UseScreenResolution'};
    for ti = 1:numel(tags)
        api.(tags{ti}) = isequal(true,api.(tags{ti}));
    end

    % file browsing is disabled for super-user option that checks and
    % correct input opttions
    if api.ParseOptions, api.InitialFileBrowse = false; end

    % check scalars
    tags = {'ScreenHeight','ScreenWidth','Height','Width',...
        'ScreenResolution','Resolution','FramesPerSecond'};
    flagzero  = [true,true,false,false,...
                 true,false,false];
    flaground = [false,false,false,false,...
                 true,true,true];
    for ti = 1:numel(tags)
        tag = tags{ti};
        if flagzero(ti)
            fcn = @(v)v>=0;
        else
            fcn = @(v)v>0;
        end
        [tf,api.(tag)] = checkScalar(api.(tag),fcn,flaground(ti));
        if ~tf
            api.(tag) = defapi.(tag);
        end
    end

    % parse screen values into strings
    if api.ScreenHeight==0 || api.ScreenWidth==0
        api.ScreenHeight = '-';
        api.ScreenWidth  = '-';
    end

    if api.ScreenResolution==0
        api.ScreenResolution = '-';
    end

    % test compression codec
    if ~ischar(api.AVICodec)
        api.AVICodec = codec{1};
    elseif ~any(strcmpi(api.AVICodec,codec))
        if numel(api.AVICodec)==4
            codec = [codec, api.AVICodec];
        else
            api.AVICodec = api.codec{1};
        end
    end

    % gather file formats
    if isempty(api.AllFormats)
        api.AllFormats = multimediaformats();
    end

    % browse for file
    [api.File,api.Format] = selectfile(...
        api.File,api.AllFormats,api.InitialFileBrowse);
    if isempty(api.File)
        if nargout>0, varargout{1} = []; end
        return;
    end

    % super-user function - output corrected options
    if api.ParseOptions
        if nargout>0, varargout{1} = copystruct([],api,savetags); end
        return
    end


    % save additional fields
    api.codec = codec;
    api.savetags = savetags;
    api.FLAG_close = FLAG_close;



    % LOAD FIGURE----------------------------------------------------------
    try

        % load figure
        hfig = hgload([mfilename '.fig']);
        api.hfig = hfig;

        % force close after output (on function cleanup)
        if FLAG_close
            cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
        end

        % place figure in screen center
        posscr = get(0,'ScreenSize');
        posfig = getpixelposition(hfig);
        posfig(1:2) = (posscr(3:4)-posfig(3:4))/2;
        setpixelposition(hfig,posfig);

        % gather controls
        hchild = findall(hfig);
        if ~isempty(hchild)
            tags = get(hchild,'tag');
            if ~iscell(tags), tags = {tags}; end
            for ti = 1:numel(hchild)
                if ~isempty(tags{ti}) && strwcmpi(tags{ti},'h*')
                    api.(tags{ti}) = hchild(ti);
                end
            end
        end

        % pass to the subfunction
        set(hfig,'renderer','zbuffer','visible','off');
        guidata(hfig,api);
        setappdata(hfig,'figureSetupComplete',false);
        output = mainFcn(api);

        % output
        if nargout>0
            varargout{1} = output;
        end

    catch ERR
        close(hfig(ishandle(hfig)),'force');
        rethrow(ERR);
    end





end



%% MAIN FUNCTION
function output = mainFcn(api)

    % file
    set(api.hfile,'string',api.File);
    set(api.hbrowse,'callback',@(varargin)browseCallback());

    % size & resolution
    sizeSelection();
    set(api.hsizepanel,'SelectionChangeFcn',@(h,evnt)sizeSelection(evnt));
    resSelection();
    set(api.hrespanel,'SelectionChangeFcn',@(h,evnt)resSelection(evnt));

    % update scalar objects
    set(api.hheight,'Callback',@(h,evnt)editCallback(h,'Height',false));
    set(api.hwidth, 'Callback',@(h,evnt)editCallback(h,'Width',false));
    set(api.hres,   'Callback',@(h,evnt)editCallback(h,'Resolution'));
    set(api.hfps,   'Callback',@(h,evnt)editCallback(h,'FramesPerSecond'),...
        'String',api.FramesPerSecond);


    % compression codecs
    idx = find(strcmpi(api.AVICodec,api.codec),1,'first');
    set(api.hcodec,'string',api.codec,'value',idx,...
        'Callback',@(h,evnt)compressionCallback(h))


    % ok/cancel
    set(api.hok,'Callback',@(varargin)okCallback());
    set(api.hcancel,'Callback',@(varargin)cancelCallback());
    set(api.hfig,'CloseRequestFcn',@(varargin)cancelCallback());

    % codec context menu
    api.hmenu = uicontextmenu('parent',api.hfig);
    uimenu('parent',api.hmenu,'Label','Add Codec',...
        'Callback',@(varargin)newCodec());
    set(api.hcodec,'uicontextmenu',api.hmenu);


    % make figure visible/modal
    set(api.hfig,'windowstyle','modal','visible','on');

    % wait for completion
    while 1
        set(api.hfig,'userdata',[]);
        waitfor(api.hfig,'userdata');

        % check for cancellation
        tf = ishandle(api.hfig) && ...
             isequal(get(api.hfig,'userdata'),'complete');
        if ~tf
            break;
        end

        % warn users if they would export a humongous file
        Nmax = 1e7;
        h = round(api.Height*api.Resolution);
        w = round(api.Width*api.Resolution);
        if h*w <= Nmax
            break
        else
            str = sprintf(['You have requested to export a huge file, ',...
                'of %dx%d pixels (height x width).',...
                'Is this correct?'],h,w);
            answer = questdlg(str,'Large Export File',...
                'Yes','Cancel','Cancel');
            if strcmpi(answer,'Yes'), break; end
        end

    end

    % output
    if tf
        output = struct;
        for k = 1:numel(api.savetags)
            tag = api.savetags{k};
            output.(tag) = api.(tag);
        end
    else
        output = [];
    end


    % FILE SELECTION CALLBACK
    function browseCallback()
        [file,format] = selectfile(api.File,api.AllFormats,true);
        if isempty(file), return; end

        api.File   = file;
        api.Format = format;
        set(api.hfile,'string',api.File);
    end



    % SIZE SELECTION CALLBACK
    function sizeSelection(evnt)
        if nargin>0 && ~isempty(evnt)
            api.UseScreenSize = (evnt.NewValue==api.hscreensize);
        end

        if api.UseScreenSize
            set(api.hscreensize,'Value',1);
            ena    = 'off';
            height = api.ScreenHeight;
            width  = api.ScreenWidth;
        else
            set(api.hmanualsize,'Value',1);
            ena    = 'on';
            height = api.Height;
            width  = api.Width;
        end
        set([api.hheight,api.hsizetext,api.hwidth],'Enable',ena);
        set(api.hheight,'string',height);
        set(api.hwidth,'string',width);

    end


    % RESOLUTION SELECTION CALLBACK
    function resSelection(evnt)
        if nargin>0 && ~isempty(evnt)
            api.UseScreenResolution = (evnt.NewValue==api.hscreenres);
        end

        if api.UseScreenResolution
            set(api.hscreenres,'Value',1);
            ena = 'off';
            res = api.ScreenResolution;
        else
            set(api.hmanualres,'Value',1);
            ena = 'on';
            res = api.Resolution;
        end
        set(api.hres,'Enable',ena,'String',res);

    end

    % GENERAL EDIT UICONTROL CALLBACK
    function editCallback(h,tag,varargin)

        val = get(h,'String');
        [tf,val] = checkScalar(val,@(v)v>0,varargin{:});
        if tf
            api.(tag) = val;
        end
        set(h,'string',api.(tag));

    end


    % COMPRESSION
    function compressionCallback(h)
        str = get(h,'String');
        val = get(h,'value');
        api.AVICodec = str{val};
    end

    % NEW CODEC
    function newCodec()
        prompt = {'Enter 4-digit compression codec'};
        answer = inputdlg(prompt,'New Codec',1,{''});
        if isempty(answer) || isempty(answer{1}), return; end

        newcodec = answer{1};
        tf = strcmpi(api.codec,newcodec);
        if any(tf)
            idx = find(tf,1,'first');
        elseif numel(newcodec)==4
            api.codec = [api.codec,newcodec];
            idx = numel(api.codec);
        else
            errstr = 'Codec must be 4-digit string';
            herr = errordlg(errstr,'Invalid Codec','modal');
            waitfor(herr);
            return
        end
        set(api.hcodec,'string',api.codec,'value',idx);
        api.AVICodec = newcodec;
    end

    % OK/CANCEL BUTTON
    function okCallback()
        set(api.hfig,'UserData','complete');
    end

    function cancelCallback()
        set(api.hfig,'UserData','cancel');
    end

end



%% HELPER FUNCTION: CHECK POSITIVE SCALAR
function [tf,val] = checkScalar(val,fcn,flaground)
    if nargin < 3, flaground = true; end

    % attempt to convert value to numeric
    if ~isnumeric(val), val = str2double(val); end
    if flaground, val = round(val); end

    % check for numeric vector of expected size in expected range
    if ~isnan(val) && fcn(val)
        tf = true;
    else
        tf = false;
        val = [];
    end

end







%% HELPER FUNCTION: BROWSE FOR FILE
function [file,format] = selectfile(file,formats,flag_browse)

    % default input
    if nargin<3 || isempty(flag_browse), flag_browse = true; end

    % break apart file
    [p,f,e] = fileparts(file);

    % check path & file
    if isempty(p) || ~isdir(p),  p = pwd; end
    if isempty(f) || ~ischar(f), f = 'untitled'; end

    % determine current file format
    idx = matchmultimediaformat(e,formats);
    if isempty(idx),
        idx = 1;
        e = formats(1).Extension{1};
    end

    % selected format & save file
    format = formats(idx);
    file = fullfile(p,[f e]);

    % offer file dialog box
    if flag_browse

        % reorder formats
        order   = [idx,setdiff(1:numel(formats),idx)];
        formats = formats(order);

        % save dialog box
        filter = [{formats.Filter};{formats.Description}]';
        [uifile,uipath,filteridx] = uiputfile(...
            filter,'Export Image or Video',file);
        if isequal(uifile,0)
            file = '';
            return;
        end

        % selected format
        format = formats(filteridx);

        % file
        [p,f,e] = fileparts(uifile);
        if isempty(matchmultimediaformat(e,format))
            uifile = [uifile format.Extension{1}];
        end
        file = fullfile(uipath,uifile);

    end


end


