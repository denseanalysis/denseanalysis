function position = getunitposition(h,units,recursive)
    % GETUNITPOSITION Get the position of an HG object in arbitrary units.
    % GETUNITPOSITION(HANDLE,UNITS) gets the position of the object
    % specified by HANDLE in UNITS units.
    %
    %   GETUNITPOSITION(HANDLE,UNITS,RECURSIVE) gets the position as above.
    %   If RECURSIVE is true, the returned position is relative to the
    %   parent figure of HANDLE.
    %
    %   POSITION = GETPIXELPOSITION(...) returns the pixel position in
    %   POSITION.
    %

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    % Verify that getpixelposition is given between 1 and 2 arguments
    narginchk(2, 3);

    % Verify that "h" is a handle
    if ~ishghandle(h)
        error('MATLAB:getpixelposition:InvalidHandle', ...
            'Input argument "h" must be a HANDLE')
    end

    if nargin < 3
        recursive = false;
    end

    parent = get(h, 'Parent');

    % Use hgconvertunits to get the position in pixels (avoids recursion
    % due to unit changes trigering resize events which re-call
    % getpixelposition)
    position = hgconvertunits(ancestor(h, 'figure'), ...
                              get(h, 'Position'), ...
                              get(h, 'Units'), ...
                              units, parent);

    if recursive && ~ishghandle(h,'figure') && ~ishghandle(parent,'figure')
        parentPos = getunitposition(parent,units,recursive);
        position = position + [parentPos(1) parentPos(2) 0 0];
    end
end
