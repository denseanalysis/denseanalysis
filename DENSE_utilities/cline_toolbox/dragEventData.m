%% DRAG EVENT CLASS DEFINITION
%This file defines the DRAGEVENTDATA, a subclass of "event.EventData", used
%within the IMCLINE object.  When the user interactively initiates a drag
%of the reference cLine object, IMCLINE notifies the hidden DRAGEVENT
%event.
%
%ADDITIONAL PROPERTIES
%   Type........drag type [point|segment|line|all]
%   LineIndex...contour index of drag
%               empty if strcmpi(Type,'all')
%   PointIndex..point index on contour of drag
%               empty if  any(strcmp(Type,'line','all'))
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.03     Drew Gilliam
%     --creation


classdef dragEventData < event.EventData
   properties
      Type
      LineIndex
      PointIndex
   end

   methods
      function obj = dragEventData(type,lidx,pidx)
         obj.Type       = type;
         obj.LineIndex  = lidx;
         obj.PointIndex = pidx;
      end
   end
end
