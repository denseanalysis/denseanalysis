function str = clr2html(clr)

%CLR2HTML convert MATLAB color specification to HTML color code
%
%INPUTS
%   clr.......color specification (string or [1x3] RGB color)
%
%OUTPUTS
%   str.......HTML color specification (e.g. #FF00CC)
%
%USAGE
%
%   STR = CLR2HTML(CLR) translates the color specification CLR
%   into an HTML color string
%   CLR may be a [1x3] RGB vector, or one of the following strings:
%       'yellow','y','magenta','m','cyan','c','red','r',
%       'green','g','blue','b','white','w','black','k'
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation

    clr = clr2num(clr);
    clr = round(clr*255);
    str = dec2hex(clr)';
    str = ['#', str(:)'];

end
