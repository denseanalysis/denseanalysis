function bool = ishg2()
    % ishg2 - Determines whether the current version of MATLAB uses HG2
    %
    %   This is an easy compatibility check based on the version number.
    %   It should be used in cases where functionality is present in HG2
    %   but not in previous versions of MATLAB.
    %
    % USAGE:
    %   bool = ishg2
    %
    % OUTPUTS:
    %   bool:   Logical, indicates whether HG2 is being used (true) or not
    %           (false)

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    bool = ~verLessThan('matlab', '8.4.0');
end
