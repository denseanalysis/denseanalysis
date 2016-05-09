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

    methods
        function self = GithubUpdater(varargin)
            self@Updater(varargin{:});

            % The base API address
            self.API = ['https://api.github.com/repos/', self.Repo];
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
                current = getfield(self.Config, 'version', self.Version);
            end

            if ~exist('ref', 'var');
                ref = getfield(self.Config, 'branch', 'master');
            end

            % First try to grab the latest release
            try
                release = self.request('releases', 'latest');
                bool = VersionNumber(release.tag_name) > current;

                newest.URL = release.zipball_url;
                newest.Version = release.tag_name;
                newest.VersionString = release.tag_name;
                newest.Notes = release.body;

            % Otherwise we need to compare git commits
            catch
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
        end
    end
end

function markdown = commit2markdown(commit)
    % commit2markdown - Helper function for displaying commit messages
    author = commit.author;
    markdown = sprintf('**%s**  \n%s (%s), %s\n\n', commit.message, ...
                        author.name, author.email, author.date);
end
