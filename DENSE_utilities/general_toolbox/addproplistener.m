function listener = addproplistener(obj, prop, event, cback)
    % ADDPROPLISTENER - addlistener wrapper for property change events
    %
    %   addlistener works flawlessly on old (hg1) and new (hg2) versions of
    %   MATLAB; however, in hg1, addlistener calls on UDD objects that are
    %   non-hg objects (i.e. uitools.uimodemanager) it fails because
    %   addlistener is expecting an hg object as the first input. The
    %   traditional way to create a listener for a property event was thus
    %   to call handle.listener() directly on the UDD object with the same
    %   inputs as addlistener. Furthermore, when calling handle.listener,
    %   the property event names are preceded by "Property" (e.g.
    %   'PropertyPostSet' vs. 'PostSet').
    %
    %   In hg2, addlistener now supports non-hg objects and handle.listener
    %   is no longer available.
    %
    %   This function simply attempts to call addlistener (the new way) and
    %   if the call fails because the first input isn't an hghandle (is a
    %   UDD object), then it makes the explicit call to handle.listener()
    %
    % USAGE:
    %   L = addproplistener(obj, prop, event, cback)
    %
    % INPUTS:
    %   obj:    Handle, Object to listen to for property changes.
    %
    %   prop:   schema.prop (HG1) or meta.property (HG2), Represents the
    %           property to listen to. This is typically obtained by using
    %           findprop(obj, propname).
    %
    %   event:  String, Name of the event to listen to: 'PostSet',
    %           'PreSet', 'PostGet', 'PreGet'.
    %
    %   cback:  Function, Callback function to be executed when the
    %           property event is triggered.
    %
    % OUTPUTS:
    %   L:      Handle, Handle to the listener (type depends on release)
    %
    %   See also: addlistener

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    if numel(obj) > 1
        func = @(o,p)addproplistener(o, p, event, cback);
        listener = arrayfun(func, obj, prop, 'uniform', 0);
        listener = cat(1, listener{:});
        return
    end

    try
        % addlistener needs a string
        if isa(prop, 'schema.prop')
            strprop = prop.name;
        else
            strprop = prop;
        end
        listener = addlistener(obj, strprop, event, cback);
    catch ME
        if ~all(ishghandle(obj)) && exist('handle.listener', 'class')
            event = strcat('Property', event);
            listener = handle.listener(obj, prop, event, cback);
        else
            rethrow(ME);
        end
    end
end
