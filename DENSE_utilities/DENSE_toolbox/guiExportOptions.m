function opts = guiExportOptions(type,varargin)
% opts = guiExportOptions(type,varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    if numel(varargin)==1 && isempty(varargin{1})
        varargin = {};
    end

    switch lower(type)
        case 'image'
            formats = imageformats;
        case 'video'
            formats = videoformats;
        otherwise
            error(sprintf('%s:invalidType',mfilename),...
                'Invalid type input.');
    end


    % default options
    defopts = struct(...
        'Filename',         fullfile(pwd,'untitled'),...
        'Background',       [1 1 1],...
        'Format',           'bmp',...
        'Resolution',       0,...
        'LineWidth',        NaN,...
        'MarkerSize',       NaN,...
        'FPS',              15,...
        'AVIProfile',       'None');

    % parse options (ignoring additional fields)
    [opts,other_args] = parseinputs(fieldnames(defopts),...
        struct2cell(defopts),varargin{:});

    % test format
    if isempty(opts.Format) || ~ischar(opts.Format)
        opts.Format = defopts.Format;
    end
    tf = strcmpi(opts.Format,{formats.HGExportFormat});
    if ~any(tf)
        opts.Format = formats(1).HGExportFormat;
        idx = 1;
    else
        idx = find(tf,1,'first');
    end
    opts.FormatUID = formats(idx).UID;

    % ensure filename matches Export Format
    [p,f,e] = fileparts(opts.Filename);
    if ~any(strcmpi(e,formats(idx).Extension))
        opts.Filename = fullfile(p,[f, formats(idx).Extension{1}]);
    end

    % test backgroundcolor
    if ~iscolor(opts.Background)
        opts.Background = defopts.Background;
    end
    opts.Background = clr2num(opts.Background);

    % test other parameters
    tags = {'Resolution','LineWidth','MarkerSize','FPS'};
    for ti = 1:numel(tags)
        tag = tags{ti};
        val = opts.(tag);
        if ~isnumeric(val) || ~isscalar(val) || val < 0
            opts.(tag) = defopts.(tag);
        end
    end

    % translate parameters into strings
    if opts.Resolution == 0
        opts.Resolution = 'screen';
    end
    if opts.LineWidth == 0
        opts.LineWidth = 'none';
    elseif isnan(opts.LineWidth)
        opts.LineWidth = 'auto';
    end
    if opts.MarkerSize == 0
        opts.MarkerSize = 'none';
    elseif isnan(opts.MarkerSize)
        opts.MarkerSize = 'auto';
    end


    % open figure
    scrsz = get(0,'ScreenSize');
    figsz  = [330 210];
    figpos = [(scrsz(3:4)-figsz)/2, figsz];
    hfig = figure(...
        'Color',[236 233 216]/255,...
        'Name', 'Export Options',...
        'NumberTitle',  'off',...
        'resize',       'off',...
        'position',     figpos,...
        'visible',      'off');
    cleanupObj = onCleanup(@()close(hfig(ishandle(hfig))));

    % run GUI (we run the GUI in a separate function to ensure the GUI
    % figure is always closes by the cleanup object)
    opts = guiImageExportSub(type,formats,opts,hfig);

    % return
    if ishandle(hfig) && strcmpi(get(hfig,'userdata'),'cancel')
        opts = [];
        return
    end

    % remove format ID
    opts = rmfield(opts,'FormatUID');

    % append additional fields
    opts.LockAxes = 'on';
    opts.FontMode = 'none';

    % edit other fields
    if isequal(opts.Resolution,'screen')
        opts.Resolution = 0;
    end
    if isequal(opts.LineWidth,'auto')
        opts.LineWidth = NaN;
    elseif isequal(opts.LineWidth,'none')
        opts.LineWidth = 0;
    end
    if isequal(opts.MarkerSize,'auto')
        opts.MarkerSize = NaN;
    elseif isequal(opts.MarkerSize,'none')
        opts.MarkerSize = 0;
    end


end


function opts = guiImageExportSub(type,formats,opts,hfig)

    % create objects
    obj = figureSetup(hfig,opts);

    % assign callbacks
    callbacks = {...
        obj.hfile,          @(varargin)fileCallback();
        obj.hbrowse,        @(varargin)browseCallback();
        obj.hcolor,         @(varargin)colorCallback();
        obj.hresolution,    @(varargin)resolutionCallback();
        obj.hlinewidth,     @(varargin)linewidthCallback();
        obj.hmarkersize,    @(varargin)markersizeCallback();
        obj.hfps,           @(varargin)fpsCallback();
        obj.hcompression,   @(varargin)compressionCallback();
        obj.hok,            @(varargin)okCallback();
        obj.hcancel,        @(varargin)cancelCallback()};

    set([callbacks{:,1}]',{'Callback'},callbacks(:,2));

    % video options
    switch lower(type)
        case 'image'
            set([obj.hcompression,obj.hfps],'enable','off');
            N = numel(get(obj.hcompression,'string'));
            set(obj.hcompression,'value',N);
            set(obj.htext(end-1:end),'Color',[0.7 0.7 0.7],...
                'fontweight','normal');

        case 'video'
            set([obj.hcompression,obj.hfps],'enable','on');

            % assign context menu
            hmenu = uicontextmenu('parent',hfig);
            uimenu('parent',hmenu,'Label','Add Codec',...
                'Callback',@(varargin)newCodec());
            set(obj.hcompression,'uicontextmenu',hmenu);

    end


    % initial browse for file
    file = browseCallback();
    if isempty(file)
        set(hfig,'userdata','cancel');
        return;
    end

    % make figure visible/modal
    set(hfig,'windowstyle','modal','visible','on');

    % wait for completion
    waitfor(hfig,'userdata');


    % BACKGROUND COLOR-----------------------------------------------------
    function colorCallback()
        clr = uisetcolor(opts.Background,'Background');
        if isequal(clr,0), return; end

        opts.Background = clr;
        cdata = get(obj.hcolor,'cdata');
        cdata(2:end-1,2:end-1,1) = clr(1);
        cdata(2:end-1,2:end-1,2) = clr(2);
        cdata(2:end-1,2:end-1,3) = clr(3);
        set(obj.hcolor,'cdata',cdata);

    end

    % RESOLUTION
    function resolutionCallback()
        editCallbacks(obj.hresolution,'Resolution',...
            {'screen'},'screen');
    end

    % LINE WIDTH
    function linewidthCallback()
        editCallbacks(obj.hlinewidth,'LineWidth',...
            {'auto','none'},'none');
    end

    % MARKER SIZE
    function markersizeCallback()
        editCallbacks(obj.hmarkersize,'MarkerSize',...
            {'auto','none'},'none');
    end

    % FPS
    function fpsCallback()
        editCallbacks(obj.hfps,'FPS',{},[]);
    end


    % GENERAL EDIT UICONTROL CALLBACK
    function editCallbacks(h,tag,strs,zeroopt)

        val = get(h,'String');
        nbr = str2double(val);
        tf  = strwcmpi(strs,[val '*']);

        if any(tf)
            opts.(tag) = strs{find(tf,1,'first')};
        elseif ~isnan(nbr)
            if nbr > 0
                opts.(tag) = nbr;
            elseif ~isempty(zeroopt) && nbr == 0
                opts.(tag) = zeroopt;
            end
        end
        set(h,'String',opts.(tag));

    end

    % COMPRESSION
    function compressionCallback()
        str = get(obj.hcompression,'String');
        val = get(obj.hcompression,'value');
        opts.AVIProfile = str{val};
    end

    % NEW CODEC
    function newCodec()
        prompt = {'Enter 4-digit compression codec'};
        answer = inputdlg(prompt,'New Codec',1,{''});
        if isempty(answer) || isempty(answer{1}), return; end

        codec = answer{1};
        if numel(codec) ~= 4
            errstr = 'Codec must be 4-digit string';
            herr = errordlg(errstr,'Invalid Codec','modal');
            waitfor(herr);
        end

        str = get(obj.hcompression,'string');
        str = [str(:); codec];
        set(obj.hcompression,'string',str,'value',numel(str));
        opts.AVIProfile = codec;
    end


    % FILE POPUP
    function fileCallback()
        str = get(obj.hfile,'String');
        val = get(obj.hfile,'Value');
        str  = str{val};

        [p,f,e] = fileparts(str);
        tf = cellfun(@(ext)any(strcmpi(e,ext)),{formats.Extension});
        idx = find(tf,1,'first');

        opts.Filename  = str;
        opts.Format  = formats(idx).HGExportFormat;
        opts.FormatUID = formats(idx).UID;
    end

    % FILE BROWSER
    function file = browseCallback()

        % locate current format, reorder formats
        idx = find(opts.FormatUID == [formats.UID],1,'first');
        order = [idx, setdiff(1:numel(formats),idx)];

        % title string
        ttl = ['Export ' upper(type(1)), lower(type(2:end))];

        % save dialog box
        filter = [{formats(order).Filter};
                  {formats(order).Description}]';
        [uifile,uipath,idx] = uiputfile(...
            filter,ttl,opts.Filename);
        if isequal(uifile,0),
            file = [];
            return;
        end
        idx = order(idx);

        % ensure proper file extension
        ext = formats(idx).Extension;
        if ~any(strwcmpi(uifile,strcat('*',ext)))
            uifile = strcat(uifile, ext{1});
        end

        % filename & HGEXPORT format
        opts.Filename  = fullfile(uipath,uifile);
        opts.Format    = formats(idx).HGExportFormat;
        opts.FormatUID = formats(idx).UID;

        % output filename
        file = opts.Filename;

        % add filename to popup menu
        str = get(obj.hfile,'String');
        tf = strcmpi(str,opts.Filename);
        str = str(~tf);
        str = [opts.Filename;str(:)];
        set(obj.hfile,'string',str,'value',1);

    end

    % CANCEL BUTTON
    function cancelCallback()
        set(hfig,'UserData','cancel');
    end

    % OK BUTTON
    function okCallback()
        set(hfig,'UserData','complete');
    end

end











%%
function obj = figureSetup(hfig,opts)



    margin = 20;
    height = 20;
    yspace = 25;

    strs = {'File:';
            'Background Color:';
            'Resolution (dpi):';
            'Line width (points):';
            'Marker size (points):';
            'AVI Compression:';
            'Frames per second:'};

    N = numel(strs);
    pos = [margin * ones(1,N); margin + yspace * (0:N-1);...
           150*ones(1,N); height*ones(1,N)]';
    pos = flipud(pos);
    pos(1,2) = pos(1,2)+5;

    p = pos;
    p(:,2) = p(:,2) + (p(:,4)/2) + 1;
    for k = 1:N
        obj.htext(k) = textfig(hfig,...
            'string',   strs{k},...
            'units',    'pixels',...
            'position', p(k,1:2),...
            'HorizontalAlignment','left',...
            'VerticalAlignment',  'middle',...
            'FontWeight','bold',...
            'FontSize',  8);
    end

    % file controls
    p = pos(1,:);
    p([1 3]) = [60 220];
    obj.hfile = uicontrol('parent',hfig,...
            'style','popupmenu',...
            'units','pixels',...
            'position',p,...
            'horizontalalignment','left',...
            'backgroundcolor','w',...
            'string',{opts.Filename},...
            'fontname','tahoma');

    p([1 3]) = [285 25];
    obj.hbrowse = uicontrol('parent',hfig,...
        'style','pushbutton',...
        'String','...',...
        'TooltipString','Browse',...
        'units','pixels',...
        'position',p);

    % background color control
    p = pos(2,:);
    p([1 3]) = [150 30];

    cdata = zeros([9,18,3]);
    cdata(2:end-1,2:end-1,1) = opts.Background(1);
    cdata(2:end-1,2:end-1,2) = opts.Background(2);
    cdata(2:end-1,2:end-1,3) = opts.Background(3);

    obj.hcolor = uicontrol('parent',hfig,...
        'style','pushbutton',...
        'units','pixels',...
        'position',p,...
        'horizontalalignment','left',...
        'cdata',cdata);

    % additional controls
    p = pos(3:end,:);
    p(:,1) = p(:,1) + 130;
    p(:,3) = 50;
    for k = 1:size(p,1)
        hctrl(k) = uicontrol(...
            'parent',               hfig,...
            'style',                'edit',...
            'units',                'pixels',...
            'position',             p(k,:),...
            'backgroundcolor',      'w',...
            'horizontalalignment',  'left');
    end

    set(hctrl([1:3,5]),...
        {'String'},{opts.Resolution; opts.LineWidth; opts.MarkerSize; opts.FPS});

    compress = {'Motion JPEG AVI', ...
                'MPEG-4', ...
                'Uncompressed AVI', ...
                'Indexed AVI', ...
                'Grayscale AVI'};
    tf = strcmpi(compress, opts.AVIProfile);

    if ~any(tf)
        compress = [compress(:); opts.AVIProfile];
        val = numel(compress);
    else
        val = find(tf,1,'first');
    end
    set(hctrl(4),'style','popupmenu','string',compress,...
        'position',p(4,:)+[0 0 15 0],'value',val)

%         'string');



    obj.hresolution  = hctrl(1);
    obj.hlinewidth   = hctrl(2);
    obj.hmarkersize  = hctrl(3);
    obj.hcompression = hctrl(4);
    obj.hfps         = hctrl(5);




    p = [235 115 75 30];
    p = cat(1,p,p+[0 -35 0 0]);
    strs = {'OK','CANCEL'};
    hctrl = NaN(2,1);
    for k = 1:2
        hctrl(k) = uicontrol(...
            'parent',       hfig,...
            'style',        'pushbutton',...
            'String',       strs{k},...
            'units',        'pixels',...
            'position',     p(k,:),...
            'FontWeight',   'bold');
    end
    obj.hok     = hctrl(1);
    obj.hcancel = hctrl(2);

end



%% AVAILABLE IMAGE FORMAT INFORMATION
function f = imageformats()

    % initialize structure
    N = 8; idx = 0;
    f = repmat(struct,[N 1]);

    % BITMAP
    idx = idx+1;
    f(idx).Extension        = {'.bmp'};
    f(idx).Description      = 'Bitmap image (*.bmp)';
    f(idx).Filter           = '*.bmp';
    f(idx).HGExportFormat   = 'bmp';

    % EMF
    idx = idx+1;
    f(idx).Extension        = {'.emf'};
    f(idx).Description      = 'Enhanced Metafile (*.emf)';
    f(idx).Filter           = '*.emf';
    f(idx).HGExportFormat   = 'meta';

    % EPS
    idx = idx+1;
    f(idx).Extension        = {'.eps'};
    f(idx).Description      = 'EPS file (*.eps)';
    f(idx).Filter           = '*.eps';
    f(idx).HGExportFormat   = 'eps';

    % JPEG
    idx = idx+1;
    f(idx).Extension        = {'.jpg','.jpeg'};
    f(idx).Description      = 'JPEG image (*.jpg)';
    f(idx).Filter           = '*.jpg;*.jpeg';
    f(idx).HGExportFormat   = 'jpeg75';

    % PDF
    idx = idx+1;
    f(idx).Extension        = {'.pdf'};
    f(idx).Description      = 'Portable Document Format (*.pdf)';
    f(idx).Filter           = '*.pdf';
    f(idx).HGExportFormat   = 'pdf';

    % PNG
    idx = idx+1;
    f(idx).Extension        = {'.png'};
    f(idx).Description      = 'Portable Network Graphics image (*.png)';
    f(idx).Filter           = '*.png';
    f(idx).HGExportFormat   = 'png';

    % TIFF
    idx = idx+1;
    f(idx).Extension        = {'.tiff','.tif'};
    f(idx).Description      = 'TIFF image (*.tiff)';
    f(idx).Filter           = '*.tif;*.tiff';
    f(idx).HGExportFormat   = 'tiff';

    % TIFF (no compression)
    idx = idx+1;
    f(idx).Extension        = {'.tiff','.tif'};
    f(idx).Description      = 'TIFF no compression image (*.tiff)';
    f(idx).Filter           = '*.tif;*.tiff';
    f(idx).HGExportFormat   = 'tiffn';

    % add ID field
    id = num2cell(1:N);
    [f.UID] = deal(id{:});

end



%%
function f = videoformats()

    % initialize structure
    N = 2; idx = 0;
    f = repmat(struct,[N 1]);

    % AVI
    idx = idx+1;
    f(idx).Extension        = {'.avi'};
    f(idx).Description      = 'AVI file (*.avi)';
    f(idx).Filter           = '*.avi';
    f(idx).HGExportFormat   = 'avi';

    % GIF
    idx = idx+1;
    f(idx).Extension        = {'.gif'};
    f(idx).Description      = 'GIF image (*.gif)';
    f(idx).Filter           = '*.gif';
    f(idx).HGExportFormat   = 'gif';

    % add ID field
    id = num2cell(1:N);
    [f.UID] = deal(id{:});

end
