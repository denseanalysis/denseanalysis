function folder = userdir()
    % userdir - Determine the user's home directory in a cross-platform way
    %
    %   On *nix systems this is a very straightforward thing, but the
    %   definition of a home directory on Windows can vary so this function
    %   helps to deal with these cross-platform differences.
    %
    % USAGE:
    %   folder = userdir()
    %
    % OUTPUTS:
    %   folder: String, Absolute path to the user's home directory

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    folder = char(java.lang.System.getProperty('user.home'));
end
