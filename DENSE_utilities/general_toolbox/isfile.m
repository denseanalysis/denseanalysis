function result = isfile(file)
%ISFILE  True if argument is a file.
%   ISFILE(FILE) returns a 1 if FILE is a file and 0 otherwise.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
result = exist(file,'file') ~= 0;
