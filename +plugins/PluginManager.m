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
    end

    properties (SetAccess = 'private')
        Classes     % List of all meta.class objects pertaining to plugins
        Menu        % Handle to the generated uimenu (if any)
        BaseClass   % Class that is used as the base plugin class
    end

    properties
        Data        % Data object to pass to plugins
    end

    properties (Hidden)
        plugins_            % Shadowed version of plugins array
        listeners           % Listeners for destruction of plugins
        statuslisteners
    end

    events
        Status
        PluginRemoved
        PluginAdded
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

            if ~isa(base, 'meta.class')
                baseclass = meta.class.fromName(base);

                if isempty(baseclass)
                    error(sprintf('%s:InvalidClassName', mfilename), ...
                        '%s is an invalid class', base)
                end

                self.BaseClass = baseclass;
            else
                self.BaseClass = base;
            end

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

            classes = package.ClassList;

            % Now find the classes derived from base plugin
            if ischar(pluginType)
                pluginType = meta.class.fromName(pluginType);
            end

            valid = arrayfun(@(x)issubclass(x, pluginType), classes);

            classes = classes(valid);

            % Add any sub-package if they exist
            func = @(x)plugins.PluginManager.findAllPlugins(pluginType, x);
            moreclasses = arrayfun(func, package.PackageList, 'uni', 0);
            classes = cat(1, classes, moreclasses{:});

            [~, sortind] = sort({classes.Name});
            classes = classes(sortind);
        end
    end
end
