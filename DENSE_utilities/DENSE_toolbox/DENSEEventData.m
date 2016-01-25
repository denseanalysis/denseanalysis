%  Class definition DENSEEventData

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

classdef DENSEEventData < event.EventData
   properties
       Action
       Field
   end

   methods
      function obj = DENSEEventData(action,field)
         obj.Action = action;
         obj.Field  = field;
      end
   end
end
