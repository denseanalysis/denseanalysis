function tf = checklimits(hax,pt)

%CHECKLIMITS helper function to determine if a specifed point lies
%   within the current displayed axes limits
%
%INPUTS
%   hax....handle to axes
%   pt.....[1x2] point within axes
%
%OUTPUT
%   tf....."true" if point lies within current axes limits
%
%USAGE
%
%   TF = CHECKLIMITS(HAX,PT) determine if the 2D point PT lies within the
%   current XLIM and YLIM parameters of the axes HAX.
%

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation

    % check for valid inputs
    if ~ishandle(hax) || ~strcmpi(get(hax,'type'),'axes') || ...
       ~isnumeric(pt) || numel(pt) ~= 2
        tf = false;
        return;
    end

    xlim = get(hax,'xlim');
    ylim = get(hax,'ylim');
    tf = (xlim(1) <= pt(1)) && (pt(1) <= xlim(2)) && ...
         (ylim(1) <= pt(2)) && (pt(2) <= ylim(2));
end
