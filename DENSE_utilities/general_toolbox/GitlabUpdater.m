classdef GitlabUpdater < Updater
    % Gitlab-specific updater
    %
    %   This class provides a Updater implementation that interfaces with
    %   the Gitlab API.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties (Constant)
        PATTERN = '(?<=gitlab.com\/)[^/]*/[^/]*';
    end

    properties (Access = 'protected')
        Token
        config
    end

    methods (Hidden)
        function url = getURL(self, path, varargin)
            varargin(end+1:end+2) = {'private_token', self.Token};
            querystring = sprintf('&%s=%s', varargin{:});
            url = getURL@Updater(self, strcat(path, '?', querystring(2:end)));
        end
    end

    methods
        function self = GitlabUpdater(varargin)
            self@Updater(varargin{:});

            confile = fullfile(userdir(), '.denseanalysis', 'gitlab.json');
            self.config = Configuration(confile);

            self.Token = getfield(self.config, 'token', '');

            % The repo name needs to be URL encoded
            repo = regexprep(self.Repo, '/', '%2F');

            id = [];

            while isempty(id)
                % The base API address
                try
                    self.API = ['https://gitlab.com/api/v3/projects/', repo];
                    id = self.request('');
                catch ME
                    if ~strcmpi(ME.identifier, 'Updater:APIError')
                        rethrow(ME);
                    end

                    self.fetchToken()
                end
            end

            % Make a request to get the real ID
            self.API = sprintf('https://gitlab.com/api/v3/projects/%d/repository', id.id);
        end

        function release = latestRelease(self)
            releases = self.request('tags');

            if isempty(releases)
                ref = 'master';
                branch = self.request(['branches/', ref]);
                commit = branch.commit;

                release = struct(...
                    'URL',          {self.getURL('archive', 'sha1', commit.id)}, ...
                    'Version',      {commit.id}, ...
                    'VersionString',{sprintf('%s (%s)', ref, commit.id)}, ...
                    'Notes',        {commit.message});

                self.Config.type= 'commit';
                self.Config.branch = ref;
            else
                % Get all of the tags that are releases (i.e. have release
                % notes included)
                releases = releases(~cellfun(@isempty, releases));
                dates = cellfun(@(x)x.commit.authored_date, releases, 'uni', 0);

                % Sort them based upon the date
                [~, sortind] = sort(dates);
                latest = releases{sortind(end)};

                commit = latest.commit.id;

                release = struct(...
                    'URL',              {self.getURL('archive', 'sha1', commit)}, ...
                    'Version',          latest.name, ...
                    'VersionString',    latest.name, ...
                    'Notes',            commit2markdown(latest.release.description));

                self.Config.type = 'releases';
            end

            self.Config.checked = now;
        end

        function str = readFile(self, filepath, ref)
            file = self.request('files', 'file_path', filepath, 'ref', ref);

            % Convert the base64-encoded content to a string
            import org.apache.commons.codec.binary.Base64.*
            str = char(decodeBase64(uint8(file.content))).';
        end

        function [bool, newest] = updateAvailable(self, current, ref)

            if ~exist('current', 'var');
                current = getfield(self.Config, 'version', '');
            end

            if ~exist('ref', 'var');
                ref = getfield(self.Config, 'branch', 'master');
            end

            newest = self.latestRelease();

            if strcmpi(self.Config.type, 'releases')
                bool = VersionNumber(newest.Version) > current;
            else
                if isempty(current) || isequal(current, '0.0')
                    bool = true;
                else
                    comparison = self.request('compare', ...
                        'from', current, 'to', ref);

                    bool = numel(comparison.commits) > 0;
                end
            end

            if ~bool
                newest = repmat(newest, 0);
            end
        end
    end

    methods (Access = 'private')
        function fetchToken(self)
            % fetchToken - Method for retrieving the API key from gitlab

            width = 400;
            height = 250;

            scrsize = get(0, 'ScreenSize');

            left = (scrsize(1,3) - width) / 2;
            bottom = (scrsize(1,4) - height) / 2;

            dlg = dialog('Units', 'pixels', ...
                         'Position', [left bottom width height]);

            msg = ['<html>Gitlab requires the use of a token ', ...
                   'to access the API.<br> You can view this ', ...
                   'token at  the following address:</html>'];

            url = 'https://gitlab.com/profile/account';

            msg2 = sprintf('<html><a href="">%s</a></html>', url);

            msg3 = ['<html>Copy and paste the <b>Private Token</b> value ', ...
                    'into the text box below to access the API</html>'];

            f = uiflowcontainer('v0', 'Parent', dlg, ...
                                'Margin', 20, ...
                                'FlowDirection', 'topdown');

            jLabel = javaObjectEDT('javax.swing.JLabel', msg);
            javacomponent(jLabel, [100,100,40,20],f);

            jLabel = javaObjectEDT('javax.swing.JLabel', msg2);
            javacomponent(jLabel, [100,100,40,20],f);

            % Hyperlink to account page
            import java.awt.Cursor.*
            jLabel.setCursor(getPredefinedCursor(HAND_CURSOR));
            set(jLabel, 'MouseClickedCallback', @(h,e)web(url, '-browser'))

            jLabel = javaObjectEDT('javax.swing.JLabel', msg3);
            javacomponent(jLabel, [100,100,40,20],f);

            htoken = uicontrol('style', 'edit', 'Parent', f);
            set(htoken, 'HeightLimits', [25 25])

            btnflow = uiflowcontainer('v0', 'Parent', f, ...
                                'FlowDirection', 'lefttoright');

            uicontrol('style', 'text', 'parent', btnflow)

            hok = uicontrol('parent', btnflow, ...
                'String', 'OK', ...
                'Callback', @(s,e)set(dlg, 'UserData', 'OK'));

            set(hok, 'WidthLimits', [100 100])

            hcancel = uicontrol('parent', btnflow, 'string', 'Cancel', ...
                'Callback', @(s,e)set(dlg, 'UserData', 'CANCEL'));
            set(hcancel, 'WidthLimits', [100 100])
            set(btnflow, 'HeightLimits', [30 30])
            uicontrol('style', 'text', 'parent', btnflow)

            waitfor(dlg, 'UserData')

            self.config.token = get(htoken, 'String');
            self.Token = self.config.token;

            delete(dlg)
        end
    end
end

function markdown = commit2markdown(commit)
    % commit2markdown - Helper function for displaying commit messages
    author = commit.author;
    markdown = sprintf('**%s**  \n%s (%s), %s\n\n', commit.message, ...
                        author.name, author.email, author.date);
end
