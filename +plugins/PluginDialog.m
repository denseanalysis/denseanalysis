classdef PluginDialog < hgsetget
    % PluginDialog - Class for managing installed plugins
    %
    %   This class is a wrapper around the PluginManager and allows the
    %   user to see the list of available plugins and perform several
    %   actions on these plugins including uninstalling and upgrading.
    %   Additionally, the user can import new plugins either via a file on
    %   the local system or a URL.
    %
    % USAGE:
    %   dialog = plugins.PluginDialog(manager)
    %
    % INPUTS:
    %   manager:    plugin.PluginManager object, The PluginManager whose
    %               functionality will be wrapped by this dialog.
    %
    % OUTPUTS:
    %   dialog:     Object, Handle to the PluginDialog object that can be
    %               used to manipulate the resulting dialog.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 Jonathan Suever

    properties
        Manager     % The plugins.PluginManager that this dialog controls
    end

    properties (Dependent)
        Plugins         % A list of available plugins
        MenuLabels      % A cell array of labels for each plugin
        CurrentPlugin   % The currently selected plugin
    end

    properties (Hidden)
        Handles     % Structure that contains graphics handles
        Listeners   % Array of event listeners for the PluginManager object
        UUID        % Unique identifier for this PluginDialog instance
    end

    methods
        function self = PluginDialog(manager)
            % PluginDialog - PluginDialog constructor
            %
            % USAGE:
            %   dialog = plugins.PluginDialog(manager)
            %
            % INPUTS:
            %   manager:    plugin.PluginManager object, The PluginManager
            %               whose functionality will be wrapped by this
            %               dialog.
            %
            % OUTPUTS:
            %   dialog:     Object, Handle to the PluginDialog object that
            %               can be used to manipulate the resulting dialog.

            self.Manager = manager;

            % Update the UUID
            self.UUID = char(java.util.UUID.randomUUID.toString());

            initGUI(self)

            % Make sure that if a plugin is removed, it disappears from the
            % list on the left
            self.Listeners = [ ...
                addlistener(manager, 'PluginRemoved', @(s,e)refresh(self))
                addlistener(manager, 'PluginAdded', @(s,e)refresh(self))
                addlistener(manager, 'PluginUpdated', @(s,e)refresh(self))
                addlistener(manager, 'Status', @(s,e)setStatus(self, e))
                addlistener(manager, 'ObjectBeingDestroyed', @(s,e)delete(self))
            ];
        end

        function delete(self)
            % delete - Destroys the dialog and associated controls
            %
            % USAGE:
            %   self.delete()

            delete(self.Listeners)

            % Close the dialog
            if isfield(self.Handles, 'fig') && ishghandle(self.Handles.fig)
                delete(self.Handles.fig);
            end
        end

        function refresh(self)
            % refresh - Updates the MarkdownPanel and other controls
            %
            %   Ensures that the selected plugin and the info displayed on
            %   the right correspond with one another.
            %
            % USAGE:
            %   self.refresh()

            % Update the displayed names (and version)
            set(self.Handles.list, 'String', self.MenuLabels);

            % Strangely, on Windows we need this explicit pause for the
            % graphics to catch up. Also, drawnow isn't sufficient
            if ispc
                pause(0.2)
            end

            % Clear out the plugin if there is no plugin selected
            if isempty(self.CurrentPlugin)
                self.Handles.markdown.Content = '';
                return
            end

            % Update the actual markdown description
            set(self.Handles.markdown, 'Content', ...
                self.markdownDescription(self.CurrentPlugin));
        end
    end

    methods (Hidden)
        function clearStatus(self, time)
            % clearStatus - Clears the status bar after a specified time
            %
            % USAGE:
            %   self.clearStatus(time)
            %
            % INPUTS:
            %   time:   Number, Time (in seconds) after which the contents
            %           of the status bar should be cleared (default = 0)

            if ~exist('time', 'var') || time <= 0
                self.setStatus('');
                return
            end

            original = get(self.Handles.hstatus, 'String');

            tmr = timer('StartDelay', time, 'TimerFcn', @(s,e)callback());
            start(tmr);

            function callback()
                % Go ahead and remove the timer object
                stop(tmr);
                delete(tmr);

                % Only clear it out if the text hasn't been changed
                if ishghandle(self.Handles.hstatus) && ...
                    isequal(original, get(self.Handles.hstatus, 'String'))
                    % Reset the status text
                    self.setStatus('')
                end
            end
        end

        function importPlugin(self, method)
            % importPlugin - Helper method for importing a plugin
            %
            %   Allows the user to import a plugin using either a dialog to
            %   specify a URL or a file selection dialog. This also handles
            %   all of the necessary graphics updates which must occur when
            %   a new plugin is imported.
            %
            % USAGE:
            %   self.importPlugin(method)
            %
            % INPUTS:
            %   method: String, Indicates the source of the import. It
            %           should either be 'url' or 'file'.

            callback = @(s,e)self.setStatus(e);

            switch lower(method)
                case 'url'
                    % URL dialog
                    url = inputdlg( ...
                        'Please enter the plugin URL', ...
                        'Import Plugin from URL');

                    if isempty(url)
                        return
                    end

                    if iscell(url)
                        url = strcat(url{:});
                    end

                    result = self.Manager.import(url, callback);
                case 'file'
                    % Will automatically prompt the user to select the file
                    result = self.Manager.import('', callback);
                otherwise
                    error(sprintf('%s:InvalidMethod', mfilename), ...
                        'Import method must be either "url" or "file".');
            end

            % If it was a successful import, then refresh the plugin
            % manager to trigger the appropriate events

            if ispc; pause(1); end
            self.Manager.refresh();

            if result
                self.setStatus('Import successful.')
                self.clearStatus(3);
            end
        end

        function initGUI(self)
            % initGUI - Initialize all of the graphics controls
            %
            % USAGE:
            %   self.initGUI()

            dlg = figure( ...
                'Name',         'Plugin Manager', ...
                'NumberTitle',  'off', ...
                'Position',     [100 100 850, 425], ...
                'Menubar',      'none', ...
                'Toolbar',      'none', ...
                'DockControls', 'off', ...
                'Visible',      'on');

            % If the figure is removed, then delete the object
            addlistener(dlg, 'ObjectBeingDestroyed', @(s,e)delete(self));

            % Custom menu at the top of the figure
            filemenu = uimenu( ...
                'Parent',   dlg, ...
                'Label',    'File');

            himport = uimenu( ...
                'Parent',   filemenu, ...
                'Label',    'Import Plugin');

            uimenu( ...
                'Parent',       himport, ...
                'Label',        'From File', ...
                'Accelerator',  'o', ...
                'Callback',     @(s,e)self.importPlugin('file'))

            uimenu( ...
                'Parent',       himport, ...
                'Label',        'From URL', ...
                'Accelerator',  'L', ...
                'Callback',     @(s,e)self.importPlugin('url'))

            uimenu( ...
                'Parent',       filemenu, ...
                'Label',        'Refresh Plugins', ...
                'Accelerator',  'r', ...
                'Callback',     @(s,e)self.Manager.refresh())

            uimenu( ...
                'Parent',       filemenu, ...
                'Label',        'Close', ...
                'Separator',    'on', ...
                'Accelerator',  'w', ...
                'Callback',     @(s,e)delete(self))

            editmenu = uimenu( ...
                'Parent',   dlg, ...
                'Label',    'Edit');

            hcheck = uimenu( ...
                'Parent',       editmenu, ...
                'Label',        'Check for Updates', ...
                'Accelerator',  'U', ...
                'Callback',     @(s,e)self.checkUpdate(self.UUID));

            huninstall = uimenu( ...
                'Parent',   editmenu, ...
                'Label',    'Uninstall Plugin', ...
                'Callback', @(s,e)self.CurrentPlugin.uninstall());

            % Necessary to place the object within a struct on some
            % versions of MATLAB
            ud.dialog = self;

            set(dlg, 'tag', self.UUID, 'UserData', ud);

            self.Handles.fig = dlg;

            vbox = uiflowcontainer('v0', ...
                'Parent',           dlg, ...
                'FlowDirection',    'topdown');

            hbox = uiflowcontainer('v0', ...
                'Parent',           vbox, ...
                'FlowDirection',    'lefttoright', ...
                'Margin',           10);

            hbutton_box = uiflowcontainer('v0', ...
                'Parent',           vbox, ...
                'FlowDirection',    'lefttoright');

            % Use a fixed-height for the buttons
            set(hbutton_box, 'HeightLimits', [40 40])

            % Place-holder
            hstatus = uicontrol( ...
                'Parent',               hbutton_box, ...
                'Style',                'text', ...
                'HorizontalAlignment',  'left', ...
                'String',               '');

            self.Handles.hstatus = hstatus;

            % For now both of these buttons do the same thing
            hcancel = uicontrol( ...
                'Parent',   hbutton_box, ...
                'String',   'Cancel', ...
                'Callback', @(s,e)delete(self));

            hok = uicontrol( ...
                'Parent',   hbutton_box, ...
                'String',   'OK', ...
                'Callback', @(s,e)delete(self));

            % Make sure that the buttons all remain a fixed-width
            set([hok, hcancel], 'WidthLimits', [100 150])

            % Create the menu for modifying the plugins
            self.Handles.listmenu = uicontextmenu('Parent', dlg);

            % Make some of the main menus part of the context menu too
            copyobj([huninstall, hcheck, himport], self.Handles.listmenu);

            self.Handles.list = uicontrol( ...
                'Parent',           hbox, ...
                'Style',            'listbox', ...
                'Units',            'normalized', ...
                'BackgroundColor',  'white', ...
                'FontSize',         10, ...
                'FontName',         'Arial', ...
                'Value',            1, ...
                'Callback',         @(s,e)self.refresh(), ...
                'UIContextMenu',    self.Handles.listmenu, ...
                'Position',         [0 0 1 1]);

            % Make the list of plugins be fixed-width but allow the
            % markdown panel containing the descriptions to expand
            set(self.Handles.list, 'WidthLimits', [150 300])

            % Create the markdown panel on the right to display info
            self.Handles.markdown = MarkdownPanel('Parent', hbox);

            % Get the custom stylesheets
            thisdir = fileparts(mfilename('fullpath'));
            privdir = fullfile(thisdir, 'private');

            self.Handles.markdown.StyleSheets = {
                fullfile('file:///', fullfile(privdir, 'style.css'));
            };

            % Make sure that the markdown panel is rendered before we try
            % to set the content
            drawnow

            self.refresh();
        end

        function desc = markdownDescription(self, plugin)
            % markdownDescription - Retrieve the markdown desc of a plugin
            %
            %   This method provides a custom markdown representation of
            %   information about a given plugin including hyperlinks which
            %   allow the user to check for updates and install updates
            %   from within the markdown itself via a hyperlink.
            %
            % USAGE:
            %   desc = self.markdownDescription(plugin)
            %
            % INPUTS:
            %   plugin: Object, The plugin object for which we want to
            %           retrieve the description.
            %
            % OUTPUTS:
            %   desc:   String, Markdown representing the description of
            %           the plugin.

            titlestr = sprintf('## %s\n', plugin.Name);

            author = sprintf('[%s](mailto:%s)', plugin.Author, plugin.Email);

            % Escape the underscores so they aren't replaced by italics
            url = strrep(plugin.URL, '_', '\\_');

            % Check to see if we have an update and place the appropriate
            % helper link within the markdown
            if getfield(plugin.Config.updater, 'hasUpdate', false)

                fmt = '%s.performUpdate(''%s'', ''%s'')';
                cmd = sprintf(fmt, class(self), self.UUID, class(plugin));
                vertext = [plugin.Version, ...
                           ' ([Update Available](matlab:' cmd, '))'];
            else
                % Display text to check for an update
                fmt = '%s.checkUpdate(''%s'', ''%s'')';
                cmd = sprintf(fmt, class(self), self.UUID, class(plugin));
                vertext = [plugin.Version, ...
                           ' ([Check for Updates](matlab:' cmd, '))'];
            end

            % Create the header section
            parameters = sprintf('**%s: %s**  \n', ...
                'Version', vertext, ...
                'Author', author, ...
                'Website', sprintf('[%s](%s)', url, plugin.URL));

            desc = sprintf('%s %s\n------\n', titlestr, parameters);

            % Check to see if there is a README and if there is, we will
            % append the contents of this README to the description
            readme = fullfile(plugin.InstallDir, 'README.md');
            if exist(readme, 'file')
                fid = fopen(readme, 'r');
                desc = [desc, fread(fid, '*char').'];
                fclose(fid);
            else
                % If there is no README, just use the basic description
                desc = [desc, plugin.Description];
            end
        end

        function setStatus(self, message, color)
            % setStatus - Updates the status text within the GUI
            %
            % USAGE:
            %   self.setStatus(message, color)
            %
            % INPUTS:
            %   message:    String, Message to be displayed in the status
            %               bar of the dialog.
            %
            %   color:      ColorSpec, Color to be used to display this
            %               message. (Default = 'black')

            if ~exist('color', 'var')
                color = [0 0 0];
            end

            if isa(message, 'StatusEvent')
                message = message.Message;
            end

            set(self.Handles.hstatus, ...
                'String',           message, ...
                'ForegroundColor',  color);
        end
    end

    %--- Get/Set Methods ---%
    methods
        function res = get.CurrentPlugin(self)
            % Figure out which one was selected in the GUI
            index = get(self.Handles.list, 'Value');

            if index == 0 || index > numel(self.Plugins)
                if numel(self.Plugins)
                    res = self.Plugins(1);
                    set(self.Handles.list, 'Value', 1);
                else
                    res = [];
                end
            else
                res = self.Plugins(index);
            end
        end

        function res = get.MenuLabels(self)
            plugins = self.Plugins;

            res = cell(size(plugins));

            % Use some HTML formatting to alter the display
            fmt = '<html><b>%s</b> <font color="#AAAAAA">(%s)</font></html>';

            for k = 1:numel(res)
                plugin = plugins(k);

                % Truncate the version string if necessary (sha1 hashes)
                verstr = plugin.Version(1:min(10, end));
                res{k} = sprintf(fmt, plugin.Name, verstr);
            end
        end

        function res = get.Plugins(self)
            % Retrieve the plugins from the PluginManager but alphabetize
            plugins = self.Manager.Plugins;
            [~, sortind] = sort({plugins.Name});
            res = plugins(sortind);
        end
    end

    methods (Static)
        function dlg = find(key)
            % find - Locate the plugins.PluginDialog instance by UUID
            %
            % USAGE:
            %   dialog = plugins.PluginDialog.find(key)
            %
            % INPUTS:
            %   key:    String, UUID that is specific to this PluginDialog
            %           instance.
            %
            % OUTPUTS:
            %   dialog: Object, Either a handle to the matching
            %           PluginDialog instance or an empty array if the
            %           dialog was unable to be found.

            hfig = findall(0, 'type', 'figure', 'tag', key);

            dlg = [];

            if isempty(hfig)
                return;
            end

            userdata = get(hfig, 'UserData');

            if isstruct(userdata) && isfield(userdata, 'dialog')
                dlg = userdata.dialog;
            end
        end
    end

    methods (Hidden, Static)
        function performUpdate(key, cls)
            % performUpdate - Static method callback for updating a plugin
            %
            %   This static method accepts a UUID of an existing
            %   PluginDialog instance and serves as a way to update a
            %   plugin from the global workspace. This is useful for being
            %   able to perform an update by clicking a link in the
            %   MarkdownPanel.
            %
            % USAGE:
            %   plugins.PluginDialog.performUpdate(key, cls)
            %
            % INPUTS:
            %   key:    String, UUID of the PluginDialog that we'd like to
            %           manipulate.
            %
            %   cls:    String, Class of the plugin that we'd like to
            %           update. If one is not provided, the current plugin
            %           is used.

            self = plugins.PluginDialog.find(key);

            if isempty(self); return; end

            if ~exist('cls', 'var')
                plugin = class(self.CurrentPlugin);
            else
                plugin = self.Manager.getPlugin(cls);
            end

            % Make sure that we get status updates from the plugin
            func = @(s,e)self.setStatus(e);
            listener = addlistener(plugin , 'Status', func);
            cleanupobj = onCleanup(@()delete(listener));

            % Actually perform the update
            if self.CurrentPlugin.update()
                % We want to refresh this one then
                delete(self.CurrentPlugin)
                self.Manager.refresh();

                self.setStatus('Update successful')
            else
                self.setStatus('Update aborted')
            end

            % Clear out the status
            self.clearStatus(3);
        end

        function checkUpdate(key, cls)
            % checkUpdate - Static method callback for checking for updates
            %
            %   This static method accepts a UUID of an existing
            %   PluginDialog instance and serves as a way to check for
            %   updates for a plugin from the global workspace. This is
            %   useful for being able to perform an update by clicking a
            %   link in the MarkdownPanel.
            %
            % USAGE:
            %   plugins.PluginDialog.checkUpdate(key, cls)
            %
            % INPUTS:
            %   key:    String, UUID of the PluginDialog that we'd like to
            %           manipulate.
            %
            %   cls:    String, Class of the plugin that we'd like to
            %           update. If one is not provided, the current plugin
            %           is used.

            self = plugins.PluginDialog.find(key);

            if isempty(self); return; end

            % Now get the plugin that we want to update
            if ~exist('cls', 'var')
                plugin = self.CurrentPlugin;
            else
                plugin = self.Manager.getPlugin(cls);
            end

            try
                plugin.hasUpdate(@(s,e)self.setStatus(e));
            catch ME
                message = {'Unable to check for updates.', ME.message};
                self.setStatus(message, 'red')
            end

            self.refresh();

            self.clearStatus(3);
        end
    end
end
