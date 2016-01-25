function DENSEsetup(varargin)
% DENSESETUP initialize the DENSEanalysis environment.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    %% EXISITING UTILITY FOLDERS ON SEARCH PATH
    % If a folder on the search path contains certain words, or if certain
    % files are found in the search path, we likely have an existing
    % installation of this software. We may need to remove some folders
    % from the MATLAB search path to avoid potential conflicts.

    % current MATLAB search path
    curdir = regexp(path, ['\' pathsep], 'split')';

    % for comparison, absolute search path
    curdirabs = cell(size(curdir));
    for k = 1:numel(curdir)
        if isdir(curdir{k})
            [stat,info] = fileattrib(curdir{k});
            curdirabs{k} = info.Name;
        end
    end


    % strings & files to locate
    strings = {'DENSE_utilities'};
    files   = {'DENSEdata.m'};

    % locate files in search path, translate into strings
    folders = cell(size(files));
    for k = 1:numel(files)
        if exist(files{k},'file')~=0
            F = which(files{k},'-all');
            [P,F,E] = cellfun(@fileparts,F,'uniformoutput',0);
            [P,F,E] = cellfun(@fileparts,P,'uniformoutput',0);
            folders{k} = P(:);
        end
    end
    folders = cat(1,folders{:});

    % all strings to check
    if isempty(strings)
        tmp1 = {};
    else
        tmp1 = strcat('*',strings(:),'*');
    end
    if isempty(folders)
        tmp2 = {};
    else
        tmp2 = strcat(folders(:),'*');
    end

    allstrings = [tmp1;tmp2];
    allstrings = unique(allstrings);

    % search paths similar to candidate toolbox folders
    tf = false(size(curdir));
    for k = 1:numel(allstrings)
        wild = regexptranslate('wildcard',allstrings{k});
        wild = ['^' wild '$'];
        idx  = regexp(curdirabs,wild);
        tf   = tf | cellfun(@(x)~isempty(x),idx);
    end

    % candidate directories to remove
    curdir    = curdir(tf);
    curdirabs = curdirabs(tf);



    %% UPDATE MATLAB SEARCH PATH

    % utility directory
    basedir = fileparts(mfilename('fullpath'));
    utildir = fullfile(basedir, 'DENSE_utilities');

    % absolute folder path
    [stat,info] = fileattrib(utildir);
    if stat==0
        error(sprintf('%s:directoryNotFound',mfilename),...
            'Utility directory could not be located.');
    end
    utildir = info.Name;

    % locate toolbox directories
    % (one folder down from the utility directory)
    d = dir(utildir);
    d = d(3:end);
    d = d([d.isdir]);
    tooldir = cellfun(@(x)fullfile(utildir,x),...
        {d.name},'uniformoutput',0);


    % remove current directories
    rmdir = setdiff(curdirabs,tooldir);
    if ~isempty(rmdir)
        prompt = {'The following folders on the MATLAB search path';...
            'may be due to previous installations of the DENSEanalysis';...
            'program.  Select paths to remove...'};
        [sel,ok] = listdlg(...
            'PromptString', prompt,...
            'ListString',   rmdir,...
            'ListSize',     [500 300],...
            'Name',         'Remove Search Paths',...
            'InitialValue', 1:numel(rmdir));
        drawnow
        if ~ok
            error(sprintf('%s:setupIncomplete',mfilename),...
                'DENSEsetup was cancelled.');
        end
        rmpath(rmdir{sel});
    end

    % add utility directories
    if ~isempty(tooldir)
        adddir = setdiff(tooldir,curdir);
        if ~isempty(adddir)
            fprintf(['The following folders will be added to ',...
            'the MATLAB search path:\n'])
            fprintf('%s\n',adddir{:});
        end

        addpath(tooldir{:});
        if ~isempty(adddir)
            fprintf('Search path updated\n')
        end
    end




    %% PARSE ADDITIONAL INPUT OPTIONS

    defapi = struct(...
        'SavePath',         false,...
        'RecompileMex',     false);
    api = parseinputs(defapi,[],varargin{:});

    api.SavePath = isequal(api.SavePath,true);
    api.RecompileMex = isequal(api.RecompileMex,true);

    % permanently save the modified path
    if api.SavePath
        savepath;
        fprintf('Search path saved\n')
    end



    %% COMPILE MEX FILES

    % compilation options
    if regexp(computer, '64$')
        opts = {'-largeArrayDims'};
    end

    % files to compile
    cfiles = {...
        fullfile(utildir,'unwrap_toolbox','private','quickfind_mex.c');
        fullfile(utildir,'unwrap_toolbox','private','quickmax_mex.c');
        fullfile(utildir,'spline_toolbox','interpnearest.c')};


    % compile files
    compiled = false(size(cfiles));
    for k = 1:numel(cfiles)

        % current file
        cfile = cfiles{k};
        [p,f,e] = fileparts(cfile);

        % output file
        mexfile = fullfile(p,[f '.' mexext]);

        % locate C file for compilation
        if ~isfile(cfile)
            fprintf('Could not locate %s\n',[f e]);
            continue;
        end

        % compile file
        if api.RecompileMex || ~isfile(mexfile)
            try
                mex(cfile,'-outdir',p,opts{:})
                fprintf('Successfully compiled %s\n',[f e]);
            catch ERR
                fprintf('Mex of %s failed:\n',[f e]);
                disp(getReport(ERR));
            end
        end

        % register valid compilation
        compiled(k) = isfile(mexfile);

    end

    if ~all(compiled)
        error(sprintf('%s:failedCompilation',mfilename),...
            'One or more files did not compile correctly.');
    end


    %% CHECK FOR LICENSES





end

