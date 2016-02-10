classdef Updater < hgsetget
    % Updater - Class which handles all update logic for the application
    %
    %   This class is designed to handle the multiple stages of automatic
    %   updates:
    %
    %       1) Check for new release via a RESTful API
    %       2) Prompt the user to approve the update
    %       3) Download the update from the web
    %       4) Install the update into the specified directory
    %
    % USAGE:
    %   updater = Updater('URL',        url, ...
    %                     'Version',    version, ...
    %                     'InstallDir', folder)
    %
    % INPUTS:
    %   url:        String, Full URL to where the software exists (for now
    %               this is required to be a Github URL.)
    %
    %   version:    String, Version number of the current release. Can be
    %               of any form accepted by VersionNumber.
    %
    %   folder:     String, Path to the folder in which to install the
    %               update. By default this is the base directory of the
    %               installation of this file.
    %
    % OUTPUTS:
    %   updater:    Object, Handle to the Updater object which can be used
    %               by the user to actually launch the updater and perform
    %               other actions.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties
        URL         % Full URL to where the software exists
        Version     % Current version of the software
        Repo        % Repository name of the form: {username}/{reponame}
        API         % URL of the RESTful API for updates
        InstallDir  % Directory in which to install the data
    end

    methods
        function set.Version(self, val)
            % Convert all Versions to VersionNumber instances
            self.Version = VersionNumber(val);
        end

        function self = Updater(varargin)
            % Updater - Updater constructor
            %
            % USAGE:
            %   updater = Updater('URL',        url, ...
            %                     'Version',    version, ...
            %                     'InstallDir', folder)
            %
            % INPUTS:
            %   url:        String, Full URL to where the software exists
            %               (for now this is required to be a Github URL.)
            %
            %   version:    String, Version number of the current release.
            %               Can be of any form accepted by VersionNumber.
            %
            %   folder:     String, Path to the folder in which to install
            %               the update. By default this is the base
            %               directory of the installation of this file.
            %
            % OUTPUTS:
            %   updater:    Object, Handle to the Updater object which can
            %               be used by the user to actually launch the
            %               updater and perform other actions.

            % The base DENSEanalysis installation directory
            basedir = fullfile('..', '..', fileparts(mfilename('fullpath')));

            strcheck = @(x)ischar(x) && ~isempty(x);

            ip = inputParser('KeepUnmatched', true);
            ip.addParamValue('URL', '', strcheck);
            ip.addParamValue('Version', '', strcheck);
            ip.addParamValue('InstallDir', basedir, strcheck);
            ip.parse(varargin{:});
            set(self, ip.Results)

            % Get the project out of the URL (Assumes Github)
            pattern = '(?<=github.com\/)[^/]*/[^/]*';
            self.Repo = regexp(self.URL, pattern, 'match', 'once');

            if isempty(self.Repo)
                error(sprintf('%s:UnsupportedHost', mfilename), ...
                    ['Malformed URL. \nNOTE: ', ...
                     'Currently only Github is supported for updates']);
            end

            % TODO: Implement APIs other than Github's
            self.API = 'https://api.github.com';
        end

        function [bool, versionNumber] = launch(self)
            % launch - Actually launch the updater
            %
            %   This method uses the information provided to the
            %   constructor to check for updates, prompt the user to
            %   upgrade, and perform the installation in place.
            %
            % USAGE:
            %   [success, version] = Updater.launch()
            %
            % OUTPUTS:
            %   success:    Integer, Indicates whether the update was
            %               performed (1), whether the current version
            %               udpates should be ignored (-1), or if the
            %               update failed (0).
            %
            %   version:    String, Represents the latest release version
            %               that was found on the remote server.

            bool = false;
            versionNumber = '';
            [hasupdate, release] = self.updateAvailable();

            if ~hasupdate
                return;
            end

            versionNumber = release.tag_name;
            proceed = self.prompt(release);

            switch lower(proceed)
                case 'update'
                    folder = self.download(release.zipball_url);
                    bool = self.install(folder, self.InstallDir);
                case 'ignore'
                    % Notify the caller that we don't want to check
                    % automatically
                    bool = -1;
                case 'remind'
                    bool = 0;
            end
        end

        function data = latestRelease(self)
            % latestRelease - Retrieve information about the latest release
            %
            %   This will return a structure containing information about
            %   the latest STABLE release. It will not include any draft or
            %   pre-releases.
            %
            % USAGE:
            %   data = Updater.latestRelease()
            %
            % OUTPUTS:
            %   data:   struct, Structure containing the JSON response from
            %           the server.

            data = self.request('repos', self.Repo, 'releases', 'latest');
            if ~isempty(data)
                data.Version = VersionNumber(data.tag_name);
            end
        end

        function [bool, newest] = updateAvailable(self)
            % updateAvailable - Determines whether there is an update
            %
            % USAGE:
            %   [bool, data] = Updater.updateAvailable()
            %
            % OUTPUTS:
            %   bool:   Logical, Indicates whether an update is available
            %           (true) or not (false)
            %
            %   data:   Struct, JSON response that represents the latest
            %           version.

            newest = self.latestRelease();

            if isempty(newest)
                bool = false;
            else
                % Now compare to our version
                bool = newest.Version > self.Version;
            end
        end
    end

    methods (Access = 'protected')
        function [data, status] = request(self, varargin)
            % request - Make a request to the API
            %
            %   This method forms an API request and returns the JSON
            %   response from the server. If any errors occur, they are
            %   thrown by this method.
            %
            % USAGE:
            %   [data, status] = Updater.request(parts)
            %
            % INPUTS:
            %   parts:  Multiple String, this should be multilpe inputs
            %           that are all strings and will be concatenated to
            %           form a URL: i.e. Updater.request('repos', 'all')
            %           becomes https://api.github.com/repos/all
            %
            % OUTPUTS:
            %   data:   Struct or Cell Array, Data structure containing the
            %           response. If a list of values was returned, this
            %           will be a cell array of structs.
            %
            %   Status: Struct, Contains information regarding the status
            %           of the HTTP request as returned by URLREAD2

            req = sprintf('/%s', varargin{:});
            [data, status] = urlread2([self.API, req]);

            if ~status.isGood
                error(sprintf('%s:APIError', mfilename), ...
                    'Message from server: "%s"', status.status.msg);
            end

            if strcmp(data, '[]')
                data = [];
            else
                data = loadjson(data);
            end
        end
    end

    methods (Static)
        function bool = prompt(release)
            % prompt - Prompt the user to update to the specified release
            %
            % USAGE:
            %   update = Updater.prompt(release)
            %
            % INPUTS:
            %   release:    Struct, Data obtained from the server about the
            %               latest release.
            %
            % OUTPUTS:
            %   update:     String, Indicates the user's selection. This
            %               can be 'update', 'remind', or 'ignore'.

            bgcolor = get(0, 'DefaultFigureColor');

            dlg = dialog( ...
                    'Position', [0 0 600 300], ...
                    'Color',    bgcolor, ...
                    'Name',     'Update Available');

            container = uiflowcontainer('v0', ...
                    'Parent',           dlg, ...
                    'BackgroundColor',  bgcolor, ...
                    'Margin',           5, ...
                    'FlowDirection',    'topdown');

            message = { ''; ...
                'An update is available for DENSEanalysis';
                sprintf('Version %s', char(release.Version)); ''};

            h = uicontrol( ...
                    'Style',            'text', ...
                    'FontWeight',       'bold', ...
                    'Parent',           container, ...
                    'BackgroundColor',  bgcolor, ...
                    'String',           message);

            set(h, 'HeightLimits', [60 60])

            h = uicontrol( ...
                    'Style',            'text', ...
                    'Parent',           container, ...
                    'BackgroundColor',  bgcolor, ...
                    'String',           'Release Notes:', ...
                    'HorizontalAlign',  'left', ...
                    'FontSize',         8);

            set(h, 'HeightLimits', [20 20])

            % Create a scrollable text panel for changelog information
            jtext = javax.swing.JTextPane();
            jtext.setContentType('text/html');
            jtext.setText(markdown2html(release.body));

            jscroll = javacomponent('javax.swing.JScrollPane', [], container);
            viewport = jscroll.getViewport();
            viewport.add(jtext);

            hgroup = uiflowcontainer('v0', ...
                    'Parent',           container, ...
                    'FlowDirection',    'lefttoright', ...
                    'Margin',           5, ...
                    'BackgroundColor',  bgcolor);

            % Set a fixed height of the button bar
            set(hgroup, 'HeightLimits', [35 35])

            % Dialog buttons
            inputs = {'Parent', hgroup, 'BackgroundColor', bgcolor};

            % Ignore update button
            uicontrol(inputs{:}, ...
                    'String',   'Ignore this Version', ...
                    'Callback', @(s,e)set(dlg, 'UserData', 'ignore'));

            % Remind later button
            uicontrol(inputs{:}, ...
                    'String',   'Remind Me Later', ...
                    'Callback', @(s,e)set(dlg, 'UserData', 'remind'));

            % Update button
            update_button = uicontrol(inputs{:}, ...
                    'String',   'Update', ...
                    'Callback', @(s,e)set(dlg, 'UserData', 'update'));

            % Center the GUI within the user's monitor
            movegui(dlg, 'center');

            % Set focus to the last button
            uicontrol(update_button);

            % Modal wait until user select a button or closes window
            waitfor(dlg, 'UserData');

            if ~ishghandle(dlg)
                % Then the user closed the window
                bool = 'remind';
            else
                bool = get(dlg, 'UserData');
                delete(dlg)
            end
        end

        function folder = download(url)
            % download - Downloads the ZIP file to a temporary folder
            %
            % USAGE:
            %   folder = Updater.download(url)
            %
            % INPUTS:
            %   url:    String, URL to a zip file to be downloaded
            %
            % OUTPUTS:
            %   folder: String, Path to where the zip file was extracted.

            files = unzip(url, tempname);

            % Downloaded information
            folder = basepath(files);
        end

        function bool = install(src, destination)
            % install - Install files from the destination into the source
            %
            % USAGE:
            %   bool = Updater.install(src, dest)
            %
            % INPUTS:
            %   src:    String, Path to where the new files to store
            %           reside.
            %
            %   dest:   String, Path to the location in which to install
            %           the files.
            %
            % OUTPUTS:
            %   bool:   Logical, Indicates whether the files were
            %           successfully installed (true) or not (false)

            try
                % Now copy all of these to the destination directory
                util = org.apache.commons.io.FileUtils;
                util.copyDirectory(java.io.File(src), ...
                                   java.io.File(destination));

                % Now clear out the source
                rmdir(src, 's');

                bool = true;
            catch
                bool = false;
            end
        end
    end
end
