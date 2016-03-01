classdef GithubUpdater < Updater
    % Github-specific updater
    %
    %   This class provides a Updater implementation that interfaces with
    %   the public Github API.

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
            end
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

            if ~exist('current', 'var'); current = self.Version; end
            if ~exist('ref', 'var'); ref = 'master'; end

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
                % Now do a comparison of the current commit with HEAD
                comparison = self.request('compare', [current,'...',ref]);
                bool = comparison.ahead_by > 0;

                if ~bool
                    newest = struct();
                    return
                end

                % Create a response object
                newest.URL = self.getURL('zipball', ref);
                sha_short = comparison.commits{end}.sha(1:10);
                newest.Version = comparison.commits{end}.sha;
                newest.VersionString = sprintf('%s (%s)', ref, sha_short);

                % Convert git log to notes
                func = @(x)commit2markdown(x.commit);
                comments = cellfun(func, comparison.commits, 'uniform', 0);
                comments = [comments{:}];
                newest.Notes = comments;
            end
        end
    end

    methods (Static)
        function res = pattern()
            % Should match the format: *github.com/owner/repo/*
            res = '(?<=github.com\/)[^/]*/[^/]*';
        end
    end
end

function markdown = commit2markdown(commit)
    % commit2markdown - Helper function for displaying commit messages
    author = commit.author;
    markdown = sprintf('**%s**  \n%s (%s), %s\n\n', commit.message, ...
                        author.name, author.email, author.date);
end
