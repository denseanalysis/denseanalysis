function jmenu = getJavaMenu(parent, varargin)
    % getJavaMenu - Get underlying java object of uimenu
    %
    %   There is no built-in way to get the java object that underlies a
    %   given uimenu object. This function uses some of the underlying java
    %   functionality of MATLAB to search for the uimenu item that you
    %   want. Searches can be performed by specifying either a uimenu
    %   handle or a series of strings that indicate the menu path.
    %
    %   For example, if you want to look for the Save menu item you could
    %   do.
    %
    %       m = getJavaMenu(gcf, 'File', 'Save');
    %
    %   Or by uimenu
    %
    %      m = getJavaMenu(findall(gcf, 'Label', '&Save'));
    %
    %   Once you have this java handle you can then use that to alter the
    %   appearance and functionality of the uimenu item as needed.
    %
    % USAGE:
    %   jmenu = getJavaMenu(parent, label1, label2, ...)
    %   jmenu = getJavaMenu(hmenu)
    %
    % INPUTS:
    %   parent:     Handle, handle to the parent figure
    %
    %   label1..N:  Strings representing the text labels at the various
    %               levels with the first being the label in the figure
    %               menubar and the last being the label that you want.
    %
    %   hmenu:      Handle, handle to a specific uimenu object

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    if isjava(parent)
        parent_class = class(parent);
        if isempty(regexp(parent_class, 'JMenu$', 'once'))
            error(sprintf('%s:InvalidMenu', mfilename), ...
                'Input must be a valid JMenu not "%s"', parent_class);
        end

        % Absorb parent into varargin
        jmenu = parent;
    elseif ishghandle(parent, 'uimenu')
        % Compute the parent labels and then perform search again
        hmenu = parent;
        hfig = ancestor(hmenu, 'figure');
        parents = hierarchy(hmenu, 'figure');
        parents = parents(parents ~= hfig);

        labels = flipud(get(parents, 'Label'));
        if ischar(labels); labels = {labels}; end
        jmenu = getJavaMenu(hfig, labels{:});

        return;
    else
        menubar = javaMethodEDT('getMenuBar', getFigureClient(parent));

        % Make sure that the figure is drawn so that the menus are rendered
        drawnow

        components = javaMethodEDT('getComponents', menubar);
        jmenu = findComponent(components, varargin{1});
    end

    if numel(varargin) > 1
        jmenu = getMenuItem(jmenu, varargin{2:end});
    end
end

function component = findComponent(components, label)
    % Get the main component

    % Remove ampersands from labels
    label = regexprep(label, '&', '');

    % Remove all separators
    classes = arrayfun(@class, components, 'uniform', false);
    nonSeparator = cellfun(@isempty, regexp(classes, 'Separator$'));
    components = components(nonSeparator);

    if numel(components) > 1
        labels = arrayfun(@(x)char(x.getLabel()), components, 'uniform', false);
    else
        labels = {char(components.getLabel())};
    end
    [tf, ind] = ismember(label, labels);

    if ~tf
        error(sprintf('%s:MenuNotFound', mfilename), ...
            'Unable to find menu with label "%s"', label);
    end

    component = components(ind);
end

function jmenu = getMenuItem(parentmenu, plabel, varargin)
    components = javaMethodEDT('getMenuComponents', parentmenu);
    jmenu = findComponent(components, plabel);

    if numel(varargin)
        jmenu = getMenuItem(jmenu, varargin{:});
    end
end
