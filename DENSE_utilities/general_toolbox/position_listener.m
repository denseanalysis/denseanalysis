function listener = position_listener(object, callback)
    % position_listener - Allows user to bind a callback to resize event
    %
    %   HG2 does not allow the user to listen to changes in the Position
    %   property of hg objects (SetObservable = false). Therefore, we have
    %   this function to listen for 'SizeChanged' events instead on HG2.
    %
    % USAGE:
    %   listener = position_listener(object, callback)
    %
    % INPUTS:
    %   object:     Handle, Handle to the graphics object that you want to
    %               listen to size change events.
    %
    %   callback:   Function Handle, Callback to be executed when the size
    %               change event is triggered.
    %
    % OUTPUTS:
    %   listener:   Object, Listener object. The exact type of listener
    %               depends on the version of MATLAB.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    try
        listener = addlistener_mod(object, 'Position', 'PostSet', callback);
    catch ME
        if strcmpi(ME.identifier, 'MATLAB:class:nonSetObservableProp')
            listener = addlistener_mod(object, 'SizeChanged', callback);
        else
            rethrow(ME);
        end
    end
end
