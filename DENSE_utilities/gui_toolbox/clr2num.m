function num = clr2num(clr)

%CLR2NUM translate any color string to RGB color specification
%   see COLORSPEC for color transformations
%
%INPUTS
%   clr.......color string
%
%OUTPUTS
%   num.......[1x3] color specification
%
%USAGE
%
%   NUM = CLR2NUM(CLR) translates the color string CLR into a [1x3]
%   RGB color vector NUM.  Valid inputs strings are:
%       'yellow','y','magenta','m','cyan','c','red','r',
%       'green','g','blue','b','white','w','black','k'
%   Note if CLR is aleady a 3-element color vector, NUM==CLR.
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

    % test for valid color string
    [tf,errstr] = iscolor(clr);
    if ~tf
        error(sprintf('%s:invalidColor',mfilename),errstr);
    end

    % if the clr is already a [1x3] vector, return
    % otherwise, transform the string into a numeric vector
    if isnumeric(clr)
        num = clr(:)';
    elseif numel(clr)==1
        tags = {'y','m','c','r',...
                'g','b','w','k'}';
        clrs = [1 1 0; 1 0 1; 0 1 1; 1 0 0; ...
                0 1 0; 0 0 1; 1 1 1; 0 0 0];
        idx = find(strcmpi(tags,clr),1,'first');
        num = clrs(idx,:);
    else
        tags = {'yellow','magenta','cyan','red',...
                'green','blue','white','black'}';
        clrs = [1 1 0; 1 0 1; 0 1 1; 1 0 0; ...
                0 1 0; 0 0 1; 1 1 1; 0 0 0];
        idx = find(strwcmpi(tags,[clr '*']),1,'first');
        num = clrs(idx,:);
    end

end
