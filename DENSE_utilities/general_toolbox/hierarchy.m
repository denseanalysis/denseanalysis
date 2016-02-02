function hhier = hierarchy(h,type,varargin)

%HIERARCHY  Get object ancestor hierarhy.
%
%    P = HIERARCHY(H,TYPE) returns the handles between and including
%    the handle H and the closest ancestor of H that matches one of the
%    types in TYPE (or empty if there is no matching ancestor).
%    TYPE may be a single string (single type) or cell array of strings
%    (types).  If H is one of the specified types then ancestor returns H.
%
%    If H is not an Handle Graphics object, the function returns empty.
%
%SEE ALSO: ANCESTOR

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam

    % determine final ancestor
    % additionally, check for any invalid inputs
    hancestor = ancestor(h,type,varargin{:});
    if isempty(hancestor)
        hhier = [];
        return;
    end

    % determine hierarchy from h to ancestor
    hhier = [];
    while 1
        hhier = cat(2, hhier, h);
        if h == hancestor
            break;
        end
        h = get(h,'Parent');
    end
end
