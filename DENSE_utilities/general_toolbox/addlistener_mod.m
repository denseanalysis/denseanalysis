function listener = addlistener_mod(varargin)
    %   ADDLISTENER_MOD - Wrapper for addlistener to account for HG2 and HG1
    %
    %   In HG1, addlistener calls on UDD objects that are non-hg objects
    %   (i.e. uitools.uimodemanager) fail because it is expecting an hg
    %   object as the first input. The traditional way to create a listener
    %   for a property event was thus to call handle.listener() directly on
    %   the UDD object with the same inputs as addlistener. Furthermore,
    %   when calling handle.listener(), the property names are preceded by
    %   "Property" (e.g. 'PropertyPostSet' vs. PostSet').
    %
    %   In HG2, addlistener now supports non-hg objects and handle.listener
    %   is no longer available.
    %
    %   This function simply translates the addlistener_mod call into the
    %   correct functions depending on whether we are using an HG2 release
    %   or not.
    %
    % USAGE:
    %   L = addlistener_mod(obj, prop, event, cback)
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

    if feature('hgusingmatlabclasses')  % HG2

        % event.listener(obj, 'EventName', @callback
        % event.proplistener(obj, Properties, 'PropEvent', @callback)

        if nargin == 3
            listener = event.listener(varargin{:});
        elseif nargin == 4
            if isa(varargin{2}, 'meta.property')
                prop = varargin{2};
            else
                prop = findprop(varargin{1:2});
            end

            listener = event.proplistener(varargin{1}, prop, varargin{3:end});
        else
            error(sprintf('%s:InvalidInput', mfilename), ...
                'Wrong number of input arguments to %s', mfilename);
        end
    else % HG1
        % handle.listener(h, 'ObjectBeingDestroyed', @callback)
        % handle.listener(h, findprop('propname'), 'PropertyPostSet',
        %   @callback)

        h = handle(varargin{1});

        if nargin == 3
            listener = handle.listener(h, varargin{2:end});
        elseif nargin == 4
            type = varargin{3};

            options = {'PostSet', 'PostGet', 'PreSet', 'PreGet'};

            if ~any(strcmpi(type, options))
                error(sprintf('%s:InvalidInput', mfilename), ...
                    'Invalid event type %s', type);
            end

            if isa(varargin{2}, 'schema.prop')
                prop = varargin{2};
            else
                prop = findprop(h(1), varargin{2});
            end
            type = sprintf('Property%s', type);
            listener = handle.listener(h, prop, type, varargin{4});
        else
            error(sprintf('%s:InvalidInput', mfilename), ...
                'Wrong number of input arguments to %s', mfilename);
        end
    end
end
