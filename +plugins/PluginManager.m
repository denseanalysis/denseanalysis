classdef PluginManager < handle
    % PluginManager - Class for finding and displaying all plugins
    %
    %   This controller searches for all plugins which are subclasses of
    %   the specified plugin and provides the user with access to all of
    %   the plugins as well as option to create a multi-tier uimenu with
    %   items for each plugin.
    %
    % USAGE:
    %   pm = plugins.PluginManager()
    %
    % OUTPUTS
    %   pm:     Object, handle to the PluginManager object that can be used
    %           to find and access information about all plugins

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties (Dependent)
        Plugins     % List of handles to all plugin instances
        BaseClass   % Class that is used as the base plugin class
    end

    properties (SetAccess = 'private')
        Classes     % List of all meta.class objects pertaining to plugins
        Menu        % Handle to the generated uimenu (if any)
    end

    properties
        Data        % Data object to pass to plugins
    end

    properties (Hidden, SetAccess = 'private')
        plugins_            % Shadowed version of plugins array
        baseclass_          % Shadowed (char) version of baseclass
        listeners           % Listeners for destruction of plugins
        statuslisteners     % Listeners for status events from plugins
    end

    events
        Status              % Event to be fired when a status is received
        PluginAdded         % Event fired when a plugin is added/imported
        PluginRemoved       % Event when a plugin is removed or invalidated
        PluginUpdated       % Event when a plugin is updated
    end

    methods
        function self = PluginManager(base, data)
            % PluginManager - Constructor for the PluginManager
            %
            % USAGE:
            %   pm = plugins.PluginManager(baseplugin)
            %
            % INPUTS:
            %   baseplugin: String or meta-class, Name of the
            %
            % OUTPUTS
            %   pm:     Object, handle to the PluginManager object that can
            %           be used to find and access information about all
            %           plugins

            if ~ischar(base) && ~isa(base, 'meta.class')
                error(sprintf('%s:InvalidClassName', mfilename), ...
                    'Base class must be a metaclass or string');
            end

            if ischar(base)
                baseclass = meta.class.fromName(base);

                if isempty(baseclass)
                    error(sprintf('%s:InvalidClassName', mfilename), ...
                        '%s is an invalid class', base)
                end
            end

            self.BaseClass = base;

            if exist('data', 'var')
                self.Data = data;
            end

            self.initializePlugins();
        end

        function initializePlugins(self)
            % initializePlugins - Locates all plugins
            %
            % USAGE:
            %   self.initializePlugins()


            self.Classes = self.findAllPlugins(self.BaseClass);

            % Now actually construct them all
            plugs = arrayfun(@(x)feval(x.Name), self.Classes, 'uni', 0);
            self.Plugins = cat(1, plugs{:});
        end

        function clear(self)
            % clear - Clears all plugins from the manager
            %
            % USAGE:
            %   self.clear()

            delete(self.listeners);
            delete(self.Plugins);
            self.Plugins(1:end) = [];
            self.Classes(1:end) = [];
            self.listeners = [];
            self.statuslisteners = [];
        end

        function h = uimenu(self, varargin)
            % uimenu - Construct a menu containing all plugins
            %
            %   The menu is created automatically and is based upon the
            %   location of each of the plugins. Plugins which are in
            %   sub-packages of +plugins will appear in sub-menus that are
            %   titled based on the getName() function within the
            %   sub-package.
            %
            % USAGE:
            %   h = self.uimenu(parent)
            %
            % INPUTS:
            %   parent: Handle, handle to the parent menu to use
            %
            % OUTPUTS:
            %   h:      plugins.PluginMenu, Handle to the menu object

            h = plugins.PluginMenu(self, varargin{:});
            self.Menu = h;
        end

        function delete(self)
            delete(self.listeners);
            delete(self.statuslisteners);
            delete@handle(self);
        end
    end

    %--- Set / Get Methods ---%
    methods
        function set.Plugins(self, val)
            delete(self.listeners)
            delete(self.statuslisteners)

            self.plugins_ = val;

            % Add listeners for deleted plugins
            cback = @(s,e)pluginDestroyed(self, s);
            func = @(x)addlistener(x, 'ObjectBeingDestroyed', cback);
            listens = arrayfun(func, val, 'uni', 0);
            self.listeners = cat(1, listens{:});

            % Now add listeners to the Status event
            cback = @(s,e)self.notify('Status', e);
            func = @(x)addlistener(x, 'Status', cback);
            listens = arrayfun(func, val, 'uni', 0);
            self.statuslisteners = cat(1, listens{:});
        end

        function res = get.Plugins(self)
            res = self.plugins_;
        end

        function set.BaseClass(self, value)
            if isa(value, 'meta.class')
                value = value.Name;
            end

            self.baseclass_ = value;
        end

        function res = get.BaseClass(self)
            res = meta.class.fromName(self.baseclass_);
        end
    end

    methods (Static)
        function classes = findAllPlugins(pluginType, package)
            % Search the plugin directory for all third-party plugins
            %
            % USAGE:
            %   classes = findAllPlugins(type, package)
            %
            % INPUTS:
            %   type:       String or meta.class, Base plugin type
            %
            %   package:    The package in which plugins are stored
            %               (Default = 'plugins')

            if ~exist('package', 'var')
                package = meta.package.fromName('plugins');
            end

            % Now find the classes derived from base plugin
            if ischar(pluginType)
                pluginType = meta.class.fromName(pluginType);
            else
                pluginType = meta.class.fromName(pluginType.Name);
            end

            classes = package.ClassList;

            valid = arrayfun(@(x)issubclass(x, pluginType), classes);

            classes = classes(valid);

            % Add any sub-package if they exist
            func = @(x)plugins.PluginManager.findAllPlugins(pluginType, x);
            moreclasses = arrayfun(func, package.PackageList, 'uni', 0);
            classes = cat(1, classes, moreclasses{:});

            [~, sortind] = sort({classes.Name});
            classes = classes(sortind);
        end

        function result = update(plugin, varargin)
            % update - Checks and performs updates for the requested plugin
            %
            % USAGE:
            %   result = PluginManager.update(plugin, force)
            %
            % INPUTS:
            %   plugin: Object, Instance of the plugin to update
            %
            %   force:  Logical, Inicates whether to prompt the user in
            %           case of an update (false) or not (true)
            %
            % OUTPUTS:
            %   result: Integer, Whether an update was downloaded and
            %           installed (1), whether the user cancelled the
            %           update (0), or if the user requested to not be
            %           notified again for this update (-1)

            result = plugin.update(varargin{:});
        end

        function [result, info] = import(url, callback)
            % import - Import a plugin from a remote URL
            %
            %   This static method allows the user to download and install
            %   a plugin from the remote URL.
            %
            % USAGE:
            %   result = PluginManager.import(url)
            %
            % INPUTS:
            %   url:    String, URL provided for the plugin. Typically,
            %           this will point to a hosted gitlab or github
            %           project.
            %
            % OUTPUTS:
            %   result: Logical, Indicates whether the import was
            %           successful (true) or not (false)
            %
            %   info:   Struct, Information about the plugin that was
            %           installed (or not)

            configobj = structobj();

            % If no plugin was specified, then open a load dialog
            if ~exist('url', 'var') || isempty(url)
                [fname, pname] = uigetfile({'*.zip'}, 'Select a plugin');
                if isequal(pname, 0) || isequal(fname, 0)
                    result = false;
                    info = [];
                    return;
                end

                url = fullfile(pname, fname);
            end

            % If this is a file, we need a specific prefix
            if exist(url, 'file')
                url = sprintf('file:%s', url);
            end

            updater = Updater.create('URL', url, 'Config', configobj);

            % For an import we'll simply print status to the command line
            if ~exist('callback', 'var')
                callback = @(s,e)fprintf('%s\n', e.Message);
            end

            listener = addlistener(updater, 'Status', callback);

            % Get the latest release
            newest = updater.latestRelease();

            % Update the installation directory to the package directory
            folder = updater.download(newest);

            % Determine installation directory using plugin.json config
            info = Configuration(fullfile(folder, 'plugin.json'));

            pluginDir = fileparts(mfilename('fullpath'));
            installDir = fullfile(pluginDir, ['+', info.package]);

            settings = Configuration(fullfile(folder, 'settings.json'));

            if ~isfield(settings, 'updater')
                settings.updater = configobj;
            end

            % Store information about the update
            settings.updater.version = newest.Version;

            % Install the software in the needed location
            result = updater.install(folder, installDir);

            delete(listener);
        end
    end

    methods (Access = 'protected')
        function pluginDestroyed(self, plugin)
            % pluginDestroyed - callback for when a plugin is deleted

            % Find it in the menu and remove if necessary
            toremove = arrayfun(@(x)x == plugin, self.Plugins);
            self.Classes(toremove) = [];

            % Turn off listeners
            delete(self.listeners(toremove));
            self.listeners(toremove) = [];
            self.Plugins(toremove) = [];

            self.notify('PluginRemoved');
        end
    end
end
