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
        Config      % Configuration object to store update info
    end

    properties (Constant, Abstract)
        PATTERN     % Regex pattern used for determining updater
    end

    events
        Status      % Event fired when there is a status to report
    end

    methods
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

            inputs = Updater.parseinputs(varargin{:});
            set(self, inputs)

            % Get the project out of the URL
            self.Repo = regexp(self.URL, self.PATTERN, 'match', 'once');

            if isempty(self.Repo)
                error(sprintf('%s:UnsupportedHost', mfilename), ...
                    ['Malformed URL. \nNOTE: ', ...
                     'Currently only Github is supported for updates']);
            end
        end

        function [bool, versionNumber] = launch(self, force)
            % launch - Actually launch the updater
            %
            %   This method uses the information provided to the
            %   constructor to check for updates, prompt the user to
            %   upgrade, and perform the installation in place.
            %
            % USAGE:
            %   [success, version] = Updater.launch(force)
            %
            % INPUTS:
            %   force:      Logical, Forces the updater to perform the
            %               installation (if an update is available).
            %               Default = false.
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

            % Ignore if there are no available updates
            if ~hasupdate; return; end

            message = sprintf('Update found (%s)', char(release.Version));
            self.setStatus(message);

            versionNumber = release.Version;

            if exist('force', 'var') && force
                proceed = 'update';
            else
                proceed = self.prompt(release);
            end

            switch lower(proceed)
                case 'update'
                    folder = self.download(release);
                    bool = self.install(folder, self.InstallDir);
                case 'ignore'
                    % Notify the caller that we don't want to check
                    % automatically
                    bool = -1;
                case 'remind'
                    bool = 0;
            end
        end

        function folder = download(self, url)
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

            if isstruct(url); url = url.URL; end

            self.setStatus(sprintf('Downloading update from %s...', url));
            
            % Download the file           
            filename = urlwrite(url, tempname);
            
            try  % First try to unzip it
                files = unzip(filename);
            catch ME
                if ~strcmp(ME.identifier, 'MATLAB:unzip:invalidZipFile')
                    rethrow(ME);
                end
                
                % If that failed, then assume it is a gzipped tarfile.
                files = gunzip(filename, tempname);
                
                % It is only going to contain one file
                tarfile = files{1};
                folder = fileparts(tarfile);
                
                % Untar everything to this folder
                files = untar(tarfile, folder);
                
                % Remove the tarfile
                delete(tarfile);
                
                % Remove the pax_global_header if present
                pgh = fullfile(folder, 'pax_global_header');
                if exist(pgh, 'file'); delete(pgh); end
                
                % Remove any invalid files from the list of extracted files
                files = files(cellfun(@(x)exist(x, 'file'), files) ~= 0);
            end
            
            % Downloaded information
            folder = basepath(files);            
            delete(filename);
        end

        function bool = install(self, src, destination)
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
                message = sprintf('Copying files into place (%s)...', ...
                                  destination);
                self.setStatus(message);

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

    methods (Access = 'public')
        function setStatus(self, message, varargin)
            % setStatus - Fires `Status` event with the supplied string
            %
            % USAGE:
            %   Updater.setStatus(message, type)
            %
            % INPUTS:
            %   message:    String, Message to set as the status
            %
            %   type:       String, Indicates category of status event.
            %               Typical categories include: INFO, WARN, DEBUG,
            %               ERROR. (Default = INFO)

            if isempty(varargin); varargin = {'INFO'}; end
            eventData = StatusEvent('', message, varargin{:});
            self.notify('Status', eventData);
        end
    end

    methods (Abstract)
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
        [bool, newest] = updateAvailable(self);

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
        data = latestRelease(self);

        % readFile - Read the contents of a specific file
        %
        %   By specifying a filepath as well as a version string, it is
        %   possible to get the file contents at a specific version.
        %
        % USAGE:
        %   contents = Updater.readFile(filepath, reference)
        %
        % INPUTS:
        %   filepath:   String, Path to the file relative to the project
        %               root directory.
        %
        %   reference:  String or VersionNumber, Indicates the version to
        %               use to retrieve the file. This can be a string
        %               representation of the version of even a git branch
        %               specification ('master')
        %
        % OUTPUTS:
        %   contents:   String, Contents of the file.
        contents = readFile(self, filepath, reference);
    end

    methods (Hidden)
        function url = getURL(self, varargin)
            % getURL - Helper method for crafting an API URL
            %
            %   This method concatenates all of the inputs and appends them
            %   to the root API URL to generate a valid URL.
            %
            % USAGE:
            %   url = Updater.getURL(part1, part2, ..., partN)
            %
            % INPUTS:
            %   partN:  String, These are the parts of the URL that will
            %           be joined together to craft the URL (ala fullfile)
            %
            % OUTPUTS:
            %   url:    String, URL formed from the root API URL and the
            %           input parameters

            url = [self.API, sprintf('/%s', varargin{:})];
        end

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

            [data, status] = urlread2(self.getURL(varargin{:}));

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
                sprintf('Version %s', char(release.VersionString)); ''};

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

            changelogPanel = MarkdownPanel('Parent', container);

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

            % Actually set the release notes content
            set(changelogPanel, 'Content', release.Notes);

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

        function inputs = parseinputs(varargin)
            % parseinputs - Method for dealing with all input arguments
            %
            %   Focuses all parsing of inputs and input validation in one
            %   place that can be called from any subclass easily.
            %
            % USAGE:
            %   inputs = Updater.parseinputs(varargin)
            %
            % OUTPUTS:
            %   inputs: Struct, Structure containing the parsed outputs

            % The base DENSEanalysis installation directory
            basedir = fullfile('..', '..', fileparts(mfilename('fullpath')));

            strcheck = @(x)ischar(x) && ~isempty(x);

            ip = inputParser();
            ip.KeepUnmatched = true;
            ip.addParamValue('URL', '', strcheck);
            ip.addParamValue('Version', '0.0', strcheck);
            ip.addParamValue('InstallDir', basedir, strcheck);
            ip.addParamValue('Config', structobj(), @isstruct);

            if nargin && isobject(varargin{1})
                warning('off', 'MATLAB:structOnObject');
                varargin{1} = struct(varargin{1});
                warning('on', 'MATLAB:structOnObject');
            end

            ip.parse(varargin{:});
            inputs = ip.Results;
        end

        function obj = create(varargin)
            % create - Static method for creating an updater instance
            %
            %   This method accepts the generic updater inputs, figures out
            %   which subclass is best for handling this data, initializes
            %   it, and returns a handle to the updater.
            %
            % USAGE:
            %   obj = Updater.create('URL', url, 'Version', version, ...
            %                        'InstallDir', install)
            %
            % INPUTS:
            %   url:        String, URL pointing to where updates can be
            %               obtained.
            %
            %   version:    String or VersionNumber, Representation of the
            %               current version to use for comparison to the
            %               version found at URL
            %
            %   install:    String, Path to where updates (if found) should
            %               be installed.
            %
            % OUTPUTS
            %   obj:        Object, This is a subclass of Updater that is
            %               specific to the URL provided.

            inputs = Updater.parseinputs(varargin{:});
            if regexp(inputs.URL, GithubUpdater.PATTERN, 'match', 'once')
                obj = GithubUpdater(inputs);
            elseif regexp(inputs.URL, FileUpdater.PATTERN, 'match', 'once')
                obj = FileUpdater(inputs);
            else
                error(sprintf('%s:UnsupportedSchema', mfilename), ...
                    'Unsupported URL Type');
            end
        end
    end
end
