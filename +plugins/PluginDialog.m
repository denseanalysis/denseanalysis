classdef PluginDialog < hgsetget

    properties
        Manager
        Handles
    end

    properties (Dependent)
        Plugins
        CurrentPlugin
    end

    properties (Hidden)
        UUID
        listeners
    end

    properties (Access = 'protected')
        current_
    end

    methods
        function self = PluginDialog(manager)
            self.Manager = manager;

            % Update the UUID
            self.UUID = char(java.util.UUID.randomUUID.toString());

            initGUI(self)

            % Make sure that if a plugin is removed, it disappears from the
            % list on the left
            addlistener(self.Manager, 'PluginRemoved', @(s,e)self.refresh());

            % Update the menu when a new item is added
            addlistener(self.Manager, 'PluginAdded', @(s,e)self.refresh());

            addlistener(self.Manager, 'PluginUpdated', @(s,e)self.refresh());
        end

        function res = get.CurrentPlugin(self)
            res = self.current_;
        end

        function res = get.Plugins(self)
            plugins = self.Manager.Plugins;
            [~, sortind] = sort({plugins.Name});
            res = plugins(sortind);
        end

        function initGUI(self)
            dlg = dialog('Name', 'Plugin Manager', 'Visible', 'on');
            set(dlg, 'Position', [100 100 850 425])
            set(dlg, 'Resize', 'on')

            set(dlg, 'tag', self.UUID, 'UserData', self);

            self.Handles.fig = dlg;

            vbox = uiflowcontainer('v0', ...
                'FlowDirection', 'topdown', ...
                'Parent', dlg);

            hbox = uiflowcontainer('v0', ...
                'FlowDirection', 'lefttoright', ...
                'Margin', 10, ...
                'Parent', vbox);

            % The OK and cancel buttons

            hbutton_box = uiflowcontainer('v0', ...
                'FlowDirection', 'lefttoright', ...
                'Parent', vbox);

            set(hbutton_box, 'HeightLimits', [40 40])

            himport = uicontrol('String', 'Import', 'parent', hbutton_box);

            uicontrol('style', 'text', 'Parent', hbutton_box, 'String', '')

            hcancel = uicontrol( ...
                'Parent', hbutton_box, ...
                'String', 'Cancel');

            hok = uicontrol( ...
                'Parent', hbutton_box, ...
                'String', 'OK');

            % Make sure that the buttons all remain a fixed-width
            set([himport, hok, hcancel], 'WidthLimits', [100 150])

            hlistpanel = uipanel('Parent', hbox, 'BorderType', 'none');
            hdescpanel = uipanel('Parent', hbox, 'BorderType', 'none');

            set(hlistpanel, 'WidthLimits', [150 300])

            % Create the menu for modifying the plugins
            self.Handles.listmenu = uicontextmenu('Parent', dlg);
            uimenu('Parent', self.Handles.listmenu, 'Label', 'Import Plugin');
            uimenu('Parent', self.Handles.listmenu, 'Label', 'Remove Plugin');

            self.Handles.list = uicontrol( ...
                'Parent', hlistpanel, ...
                'Style', 'listbox', ...
                'Units', 'normalized', ...
                'BackgroundColor', 'white', ...
                'FontSize', 10, ...
                'FontName', 'Arial', ...
                'Value', 1, ...
                'Callback', @(s,e)self.changeItem(s), ...
                'UIContextMenu', self.Handles.listmenu, ...
                'Position', [0 0 1 1]);

            % Create the markdown panel on the right to display info
            self.Handles.markdown = MarkdownPanel('Parent', hdescpanel);

            % Get the custom stylesheets
            thisdir = fileparts(mfilename('fullpath'));
            privdir = fullfile(thisdir, 'private');

            self.Handles.markdown.StyleSheets = {
                fullfile('file://', fullfile(privdir, 'style.css'));
            };

            % Make sure that the markdown panel is rendered before we try
            % to set the content
            drawnow

            % Make sure that we select the top menu
            changeItem(self, self.Handles.list);

            self.refresh();
        end

        function changeItem(self, src)
            % Get the name of the displayed plugin
            value = min(numel(self.Plugins), get(src, 'Value'));

            if value == 0
                self.current_ = [];
            else
                self.current_ = self.Plugins(value);
            end

            set(src, 'Value', value);

            self.refresh();
        end

        function refresh(self)
            % Make sure that the current plugin and the selected plugin
            % match
            set(self.Handles.list, 'String', self.shortNames());

            if isempty(self.CurrentPlugin)
                self.Handles.markdown.Content = '';
                return
            elseif ~isvalid(self.CurrentPlugin)
                %#set(self.Handles.list, 'Value', 1);
                changeItem(self, self.Handles.list);
                return
            end

            set(self.Handles.markdown, 'Content', ...
                self.markdownDescription(self.CurrentPlugin));
        end

        function names = shortNames(self)
            plugins = self.Plugins;

            names = cell(size(plugins));



            for k = 1:numel(names)
                plugin = plugins(k);

                verstr = plugin.Version(1:min(10, end));


                names{k} = sprintf('<html><strong>%s</strong> <font color="#CCCCCC">(%s)</font></html>', plugin.Name, verstr);
            end
        end

        function delete(self)
            % Close the dialog
            if isfield(self.Handles, 'fig') && ishghandle(self.Handles.fig)
                delete(self.Handles.fig);
            end
        end

        function desc = markdownDescription(self, plugin)

            titlestr = sprintf('## %s\n', plugin.Name);

            author = sprintf('[%s](mailto:%s)', plugin.Author, plugin.Email);

            url = strrep(plugin.URL, '_', '\\_');

            % Check to see if we have an update (that we know of)
            if getfield(plugin.Config.updater, 'hasUpdate', false)
                version_text = [plugin.Version, ' ([Update Available](matlab:plugins.PluginDialog.performUpdate(''', self.UUID, ''')))'];
            else
                % Display text to check for an update
                version_text = [plugin.Version, ' ([Check for Updates](matlab:plugins.PluginDialog.checkUpdate(''', self.UUID, ''')))'];
            end

            parameters = sprintf('**%s: %s**  \n', ...
                'Version', version_text, ...
                'Author', author, ...
                'Website', sprintf('[%s](%s)', url, plugin.URL));

            desc = sprintf('%s %s\n------\n', titlestr, parameters);

            % Check to see if there is a README
            readme = fullfile(plugin.InstallDir, 'README.md');
            if exist(readme, 'file')
                fid = fopen(readme, 'r');

                readme = fread(fid, '*char').';

                % Remove any straight-up links
                %readme = regexprep(readme, '<a.*?a>', '');
                desc = [desc, readme];

                fclose(fid);
            else
                desc = [desc, plugin.Description];
            end
        end
    end

    methods (Static)

        function dlg = find(key)
            % find - Locate the plugins.PluginDialog instance by uuid
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

            dlg = get(hfig, 'UserData');
        end

        function performUpdate(key)
            self = plugins.PluginDialog.find(key);

            if isempty(self); return; end

            % Actually perform the update
            if self.CurrentPlugin.update()
                % We want to refresh this one then

                delete(self.CurrentPlugin)
                self.Manager.refresh();
            end
        end

        function checkUpdate(key)

            self = plugins.PluginDialog.find(key);

            if isempty(self); return; end

            % Now get the plugin that we want to update
            self.CurrentPlugin.hasUpdate();
            self.refresh();
        end
    end
end
