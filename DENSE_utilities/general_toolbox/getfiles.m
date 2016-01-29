function files = getfiles(startpath,filefilter,absolutepath)
%GETFILES get all file names (absolute) in a given folder tree
%
%INPUTS
%   startpath.......starting path(s)      (optional)
%   filefilter......file filter(s)        (optional)
%   absolutepath....return absolute path  (optional)
%
%OUTPUT
%   files.........Nx1 cell array of file names
%
%USAGE
%   FILES = GETFILES returns all file names from the current directory
%   and all directories below it.  filenames are relative to the current
%   directory.
%
%   ... = GETFILES(STARTPATH) returns all filenames from the directory
%   STARTPATH and all directories below it.
%
%   ... = GETFILES(STARTPATH,FILEFILTER) returns all file names matching
%   the filter FILEFILTER from from the directory STARTPATH and all
%   directories below it.  FILEFILTER is in the format of the DIR function,
%   i.e. '*.mat' to return all MAT files or '*test*.mat' to return all
%   MAT files with "test" in the file name)
%
%   ... = GETFILES(...,ABSOLUTEPATH) defines if the function will
%   return absolute path names (ABSOLUTEPATH = TRUE) from the root drive,
%   or relative path names (ABSOLUTEPATH == FALSE) with respect
%   to the STARTPATH variable.
%
%NOTE
%   STARTPATH and FILEFILTER accept multile input strings, in the form of
%   cell arrays.  This allows us to search multiple paths for multiple
%   filters at the same time.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2006        Drew Gilliam
%       --creation
%   2007.12     Drew Gilliam
%       --modifications to error checking & cellfun statements
%   2008.10     Drew Gilliam
%       --add absolute path flag

% default starting path
if nargin < 1 || isempty(startpath),    startpath = '';    end
if nargin < 2 || isempty(filefilter),   filefilter = [];     end
if nargin < 3 || isempty(absolutepath), absolutepath = true; end

% startpath/filefilter to cells
if ~iscell(startpath),  startpath  = {startpath};  end
if ~iscell(filefilter), filefilter = {filefilter}; end

% ensure all paths are strings (for fileattrib success)
for k = 1:numel(startpath)
    if isempty(startpath{k}), startpath{k} = ''; end
end

% ensure the path(s) exists
validpath = cellfun(@(p)isempty(p) || exist(p,'dir')==7,startpath);

if any(~validpath)
    error(sprintf('%s:missingfolder',mfilename),...
        'Folder not found (%s).\n',startpath{~validpath});
end

% absolute pathnames
abspath = cell(size(startpath));
idx = zeros(size(startpath));
for k = 1:numel(startpath)
    [status,msg,id] = fileattrib(startpath{k});
    abspath{k} = msg.Name;
    idx(k) = numel(abspath{k}) - numel(startpath{k}) + 2;
end

% unique pathnames
if ispc
    abspath = lower(abspath);
end
[abspath,unq] = unique(abspath,'first');
startpath = startpath(unq);
idx = idx(unq);

% % retrieve all files
% files = [];
% for si = 1:numel(startpath)
%     [status,msg] = fileattrib(fullfile(abspath{si},'*'));
%     tmpfiles = {msg.Name}';
%     [P,F,E] = cellfun(@fileparts,tmpfiles,'uniformoutput',0);
%     valid = false(size(tmpfiles));
%     for fi = 1:numel(filefilter)
%         valid = valid | strwcmpi(strcat(F,E),filefilter{fi});
%     end
%     tmpfiles = tmpfiles(valid);
%     files = [files; tmpfiles(:)];
%
% end
%
% files = sort_nat(unique(files));



% return the absolute pathnames
if absolutepath
    startpath = abspath;
end

% recursively get all the files down the subtree
files = [];
for si = 1:numel(startpath)
    tmp = getallfiles(startpath{si},filefilter);
    files = [files(:); tmp(:)];
end
files = sort_nat(unique(files));


end



%% RECURSIVE FILE SEARCH
function files = getallfiles(path,filefilter)
% recursively get all files down the folder tree

    % get all files & folders
    if isempty(path)
        d = dir;
    else
        d = dir(path);
    end
    d(ismember({d.name}, {'.', '..'})) = [];
    isdir = cell2mat({d.isdir});

    % folders
    folders = {d(isdir).name}';
    folders = cellfun(@(x)fullfile(path,x),folders,'UniformOutput',false);

    % all files
    files = {d(~isdir).name}';

    % check filters (if all are non-empty)
    if ~any(cellfun(@isempty,filefilter))
        valid = false(size(files));
        for fi = 1:numel(filefilter)
            valid = valid | strwcmpi(files,filefilter{fi});
        end
        files = files(valid);
    end

    % full file names
    files = cellfun(@(x)fullfile(path,x),files,'UniformOutput',false);

    % recursive folder access
    for k = 1:numel(folders)
        tmp = getallfiles(folders{k},filefilter);
        files = [files(:); tmp(:)];
    end

end

