function [tf,errstr] = iscolor(clr)

%ISCOLOR test for valid color specification
%
%INPUTS
%   clr.......value to test
%
%OUTPUTS
%   tf........true/false test for valid color value
%   errstr....error string
%
%USAGE
%
%   TF = ISCOLOR(CLR) tests the input value CLR for a valid color
%   specification, according to COLORSPEC.  Valid input strings include:
%       'yellow','y','magenta','m','cyan','c','red','r',
%       'green','g','blue','b','white','w','black','k'
%   CLR may additional be a 3-element vector of numeric values on the
%   range [0,1].
%
%   [TF,ERRSTR] = ISCOLOR(CLR) additionally returns the error string
%   ERRSTR, indicating any problems with the color value CLR.  If CLR is
%   valid, ERRSTR is empty [].
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

    % initialize empty error string
    errstr = [];

    % validate character input
    if ischar(clr)

        tags = {'y','m','c','r','g','b','w','k'};
        tf_short = strcmpi(tags,clr);

        tags = {'yellow','magenta','cyan','red',...
                'green','blue','white','black'};
        tf_long = strwcmpi(tags,[clr '*']);

        if ~any(tf_short) && ~any(tf_long)
            errstr = 'Unrecognized color string.';
        end

    % validate 3-element numeric input
    elseif isnumeric(clr)
        if numel(clr) ~= 3
            errstr = 'Color value must be a 3 element numeric vector.';
        elseif ~all(isfinite(clr)) || any(clr<0) || any(1<clr)
            errstr = sprintf('%s',...
                'Color value contains NaN, or element out of',...
                'range 0.0 <= value <= 1.0');
        end

    % other inputs
    else
        errstr = 'Unrecognized color input.';
    end

    % return true/false
    if ~isempty(errstr)
        tf = false;
    else
        tf = true;
    end

end
