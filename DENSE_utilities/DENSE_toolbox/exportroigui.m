function output = exportroigui(varargin)
% output = exportroigui(varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors


    % close figure on output?
    FLAG_close = true;

    % parse the application data
    defapi = struct(...
        'ExportPath',   pwd,...
        'LastName',     'Unknown',...
        'SeriesNumber', 1,...
        'Partition',    1,...
        'SeriesRange',  [1 1],...
        'Nphase',       1);
    api = parseinputs(defapi,[],varargin{:});
    api.outputtags = fieldnames(defapi);

    % check application data
    if ~ischar(api.ExportPath) || ~isdir(api.ExportPath)
        api.ExportPath = defapi.ExportPath;
    end

    if ~checkName(api.LastName)
        api.LastName = defapi.LastName;
    end

    checkfcn = @(x)isnumeric(x) && isscalar(x) && x>0;
    tags = {'SeriesNumber','Partition','Nphase'};
    for ti = 1:numel(tags)
        tag = tags{ti};
        if ~checkfcn(api.(tag)), api.(tag) = defapi.(tag); end
    end

    checkfcn = @(x)isnumeric(x) && numel(x)==2 && ...
        all(isfinite(x)) && all(x>0) && x(end)>=x(1);
    if ~checkfcn(api.SeriesRange)
        api.SeriesRange = api.SeriesRange;
    end


    % load gui
    try
        hfig = hgload([mfilename '.fig']);
        api.hfig = hfig;

        % force close after output (on function cleanup)
        if FLAG_close
            cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
        end

        % gather controls
        hchild = findobj(hfig);
        tags = get(hchild,'tag');
        for ti = 1:numel(hchild)
            if ~isempty(tags{ti}) && strcmpi(tags{ti}(1),'h')
                api.(tags{ti}) = hchild(ti);
            end
        end

        % pass to the subfunction
        set(hfig,'visible','off');
        guidata(hfig,api);
        output = mainFcn(api);

    catch ERR
        close(hfig(ishandle(hfig)),'force');
        rethrow(ERR);
    end

end


function output = mainFcn(api)

    % place figure in screen center
    posscr = get(0,'ScreenSize');
    posfig = getpixelposition(api.hfig);
    posfig(1:2) = (posscr(3:4)-posfig(3:4))/2;
    setpixelposition(api.hfig,posfig);

    % set the note text
    str = {...
        ['This tool will attempt to export your current short-axis ',...
         'cardiac ROI to a set of MATLAB data files (*.mat) compatible ',...
         'with the “VolumetricCineDENSEanalysis” tool. One file will be ',...
         'exported for each frame in this particular dataset, each file ',...
         'containing the endocardial and epicardial border definitions ',...
         '(x/y pixel coordinates) for the corresponding frame.'];
        ' ';
        ['The "VolumetricCineDENSEanalysis" tool requires a specific ',...
         'naming convention for these MAT-files. Edit the information ',...
         'below to ensure compatability.'];
        };
    str = textwrap(api.hnote,str);
    set(api.hnote,'String',str);

    % update


    % set callbacks
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));

    set(api.hlastname,'Callback',@(varargin)lastnameCallback(api.hfig));

    set(api.hseries,'Callback',...
        @(varargin)numericCallback(api.hfig,api.hseries,'SeriesNumber'));
    set(api.hpartition,'Callback',...
        @(varargin)numericCallback(api.hfig,api.hpartition,'Partition'));
    set([api.hseriesmin,api.hseriesmax],'Callback',...
        @(varargin)rangeCallback(api.hfig));
    set(api.hbrowse,'Callback',@(varargin)browse(api.hfig));

    % update the display
    lastnameCallback(api.hfig,false);
    numericCallback(api.hfig,api.hseries,'SeriesNumber',false);
    numericCallback(api.hfig,api.hpartition,'Partition',false);
    numericCallback(api.hfig,api.hframe,'Nphase',false)
    rangeCallback(api.hfig,false);
    updateDisplay(api.hfig);

    % browse for folder
    if ~browse(api.hfig)
        output = [];
        return;
    end

    % wait for figure to finish
    set(api.hfig,'visible','on');
    waitfor(api.hfig,'userdata')

    % output
    if ~ishandle(api.hfig) || ~isequal(get(api.hfig,'userdata'),'complete')
        output = [];
    else
        api = guidata(api.hfig);
        output = struct;
        for k = 1:numel(api.outputtags)
            tag = api.outputtags{k};
            output.(tag) = api.(tag);
        end

        files = generateFiles(api,1:api.Nphase);
        output.Filenames = cellfun(@(f)fullfile(api.ExportPath,f),...
            files(:),'uniformoutput',0);
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



%% EDIT CALLBACKS

% last name
function lastnameCallback(hfig,updateflag)
    if nargin < 2, updateflag = true; end
    api = guidata(hfig);

    str = get(api.hlastname,'String');
    if checkName(str)
        api.LastName = str;
        guidata(hfig,api);
    else
        set(api.hlastname,'String',api.LastName);
    end

    if updateflag, updateDisplay(hfig); end
end

% numeric input
function numericCallback(hfig,hobj,tag,updateflag)
    if nargin < 4, updateflag = true; end
    api = guidata(hfig);

    val = ceil(str2double(get(hobj,'String')));
    if isfinite(val) && val>0
        api.(tag) = val;
        guidata(hfig,api);
    end
    set(hobj,'string',api.(tag));

    if updateflag, updateDisplay(hfig); end
end

% series range input
function rangeCallback(hfig,updateflag)
    if nargin < 2, updateflag = true; end
    api = guidata(hfig);

    vals = round([str2double(get(api.hseriesmin,'String')),...
                  str2double(get(api.hseriesmax,'String'))]);
    if all(isfinite(vals)) && all(vals>0)
        if vals(1)~=api.SeriesRange(1) && vals(end)<vals(1)
            vals(end) = vals(1);
        elseif vals(end)~=api.SeriesRange(end) && vals(1)>vals(end)
            vals(1) = vals(end);
        end
        api.SeriesRange(1)   = vals(1);
        api.SeriesRange(end) = vals(end);
        guidata(hfig,api);
    end

    set(api.hseriesmin,'String',api.SeriesRange(1));
    set(api.hseriesmax,'String',api.SeriesRange(end));

    if updateflag, updateDisplay(hfig); end
end


function tf = checkName(name)
    badchar = '\/:*?"<>|';
    badexp = ['[',sprintf('\\%c',badchar),']'];

    tf = ~isempty(name) && ischar(name) && ...
        isempty(regexp(name,badexp,'once'));
end


function updateDisplay(hfig)
    api = guidata(hfig);
    str = generateFiles(api);
    set(api.hfile,'string',str);
end


function tf = browse(hfig)
    api = guidata(hfig);

    uipath = uigetdir(api.ExportPath,'Select Folder for ROI Export');
    if isequal(uipath,0) || ~isdir(uipath)
        tf = false;
        return;
    end

    api.ExportPath = uipath;
    set(api.hfolder,'String',api.ExportPath);
    guidata(hfig,api);
    tf = true;

end


function strs = generateFiles(api,idx)
    if nargin < 2, idx = 1; end

    lastname  = api.LastName;
    seriesmin = api.SeriesRange(1);
    partition = api.Partition;

    strs = arrayfun(...
        @(x)sprintf('%s%d_phase%d_partition%d.mat',...
            lastname,seriesmin,x,partition),...
        idx,'uniformoutput',0);
end
