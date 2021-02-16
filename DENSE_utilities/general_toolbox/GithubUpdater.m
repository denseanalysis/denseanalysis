classdef GithubUpdater < Updater
    % Github-specific updater
    %
    %   This class provides a Updater implementation that interfaces with
    %   the public Github API.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties (Constant)
        PATTERN = '(?<=github.com\/)[^/]*/[^/]*';
    end

    properties (Access = 'protected')
        Cache
    end

    methods
        function self = GithubUpdater(varargin)
            self@Updater(varargin{:});

            % The base API address
            self.API = ['https://api.github.com/repos/', self.Repo];

            % Create or retrieve the github cache
            cachefile = fullfile(userdir(), '.denseanalysis', 'github.cache');
            self.Cache = Configuration(cachefile);
        end

        function release = latestRelease(self)
            % First check to see if there is a latest release via the API
            try
                latest = self.request('releases', 'latest');
                release = struct('URL', {latest.zipball_url}, ...
                                 'Version', {latest.tag_name}, ...
                                 'VersionString', {latest.tag_name}, ...
                                 'Notes', {latest.body});

                self.Config.type = 'releases';

            % If there was no release (at all), then simply use master
            catch
                ref = 'master';

                % Retrieve information about the HEAD commit
                sha1 = self.request('commits', ref);
                release = struct(...
                    'URL',           {self.getURL('zipball', ref)}, ...
                    'Version',       {sha1.sha}, ...
                    'VersionString', {sprintf('%s (%s)', ref, sha1.sha)}, ...
                    'Notes',         {sha1.commit.message});

                self.Config.type = 'commit';
                self.Config.branch = ref;
            end

            self.Config.checked = now;
        end

        function str = readFile(self, filepath, ref)
            % Get information on the file to download
            file = self.request('contents', [filepath, '?ref=', ref]);

            % Actually download the file to a temporary location
            tmpname = urlwrite(file.download_url, tempname);

            % Extract contents of file and remove
            fid = fopen(tmpname, 'r');
            str = fread(fid, '*char')';
            fclose(fid);
            delete(tmpname);
        end

        function [bool, newest] = updateAvailable(self, current, ref)

            if ~exist('current', 'var') || isempty(current);
                current = getfieldr(self.Config, 'version', self.Version);
            end

            if ~exist('ref', 'var');
                ref = getfieldr(self.Config, 'branch', 'master');
            end

            % First try to grab the latest release
            try
                self.setStatus('Looking for updates...');

                release = self.request('releases', 'latest');
                bool = VersionNumber(release.tag_name) > current;

                newest.URL = release.zipball_url;
                newest.Version = release.tag_name;
                newest.VersionString = release.tag_name;
                newest.Notes = release.body;

            % Otherwise we need to compare git commits
            catch
                self.setStatus('Using commit hashes as a backup...');
                if isempty(current) || isequal(current, '0.0')
                    % Then we don't CARE about the current version
                    commit = self.request('commits', ref);
                    commits = {commit};
                    bool = true;
                else
                    % Now do a comparison of the current commit with HEAD
                    comparison = self.request('compare', [current,'...',ref]);
                    commits = comparison.commits;
                    bool = comparison.ahead_by > 0;

                    if ~bool
                        self.setStatus('Everything is up-to-date.')
                        newest = struct();
                        return
                    end
                end

                % Create a response object
                newest.URL = self.getURL('zipball', ref);
                sha = commits{end}.sha;
                newest.Version = sha;
                newest.VersionString = sprintf('%s (%s)', ref, sha(1:10));

                % Convert git log to notes
                func = @(x)commit2markdown(x.commit);
                comments = cellfun(func, commits, 'uniform', 0);
                comments = [comments{:}];
                newest.Notes = comments;
            end

            if bool
                self.setStatus( ...
                    sprintf('Latest version is %s.', newest.VersionString));
            else
                self.setStatus('Everything is up-to-date.')
            end
        end
    end

    methods (Hidden)
        function [data, status] = request(self, varargin)
            % Overloaded request method so we can cache results

            url = self.getURL(varargin{:});

            % Determine the key that we used to store this in the cache
            fieldname = sprintf('sha1%s', sha1(url));

            % Now look to see if this is in the cache
            cache = getfieldr(self.Cache, fieldname, struct);

            % By default we don't use any headers
            headers = repmat(struct('name', {}, 'value', {}), [0 1]);


            % If there was a cached value, pass the ETag with the request
            hasCache = isfield(cache, 'ETag') && isfield(cache, 'data');
            if hasCache
                % Create the new header
                headers(end+1) = struct('name', 'If-None-Match', ...
                                        'value', cache.ETag);
            end

            [data, status] = urlread2(url, 'GET', '', headers);

            % Check if the status was a 304 (Not Modified) and we have a
            % cached response to send
            if status.status.value == 304 && hasCache && ~isempty(cache.data)
                data = cache.data;
            elseif isfield(status.firstHeaders, 'ETag')
                % Otherwise we cache the current value
                cache = struct('ETag', status.firstHeaders.ETag, ...
                                'data', data);

                self.Cache.(fieldname) = cache;
            end

            if ~status.isGood
                error(sprintf('%s:APIError', mfilename), ...
                    'Message from server: "%s"', status.status.msg);
            end

            if strcmp(data, '[]') || isempty(data)
                data = [];
            else
                data = loadjson(data);
            end
        end
    end
end

function markdown = commit2markdown(commit)
    % commit2markdown - Helper function for displaying commit messages
    author = commit.author;
    markdown = sprintf('**%s**  \n%s (%s), %s\n\n', commit.message, ...
                        author.name, author.email, author.date);
end
