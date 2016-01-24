function htools = getzoompan(hfig)

%GETZOOMPAN helper function to retrieve standard Zoom/Pan tool handles
%
%INPUTS
%   hfig....handle to figure
%
%OUTPUT
%   htools..handles to zoom/pan tools, if available
%
%USAGE
%
%   HTOOLS = GETZOOMPAN(HFIG) retreives the standard Zoom & Pan tool
%   handles HTOOLS from the figure HFIG. These tools are identifed as
%   'uitoogletool' or 'uipushtool' children of the figure HFIG with
%   'Tag' identifiers as 'Exploration.ZoomOut', 'Exploration.ZoomIn',...
%   or 'Exploration.Pan'.  Note the search for these tools is not
%   case-sensative or 'HandleVisibility'.
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

    % valid tag identifiers
    strs = {'Exploration.ZoomOut',...
            'Exploration.ZoomIn',...
            'Exploration.Pan'};

    % check for valid figure handle
    if ~ishandle(hfig) || ~strcmpi(get(hfig,'type'),'figure')
        warning(sprintf('%s:invalidFigure',mfilename),...
            'Handle was not a valid figure.');
        htools = [];
        return;
    end

    % gather all children tags
    h = findall(hfig,'type','uipushtool','-or','type','uitoggletool');
    tags = get(h,'tag');

    % identify tools
    tf = false(size(h));
    for k = 1:numel(strs)
        tf = tf | strcmpi(tags,strs{k});
    end
    htools = h(tf);

end

