function pos = plotboxpos(hax,varargin)

%PLOTBOXPOS return pixel position of a 2D axes plot box
%
%INPUTS
%   hax....axes handle
%
%OUTPUTS
%   pos....axes position in pixels [x,y,width,height]
%
%USAGE
%
%   POS = PLOTBOXPOS(HAX) returns the pixel position of the actual plotted
%   region of the axes HAX. This may differ from the actual axes position,
%   as defined by the axis limits, data aspect ratio, and plot box aspect
%   ratio.
%

%WRITTEN BY:  Kelly Kearney, Copyright 2006
%ADAPTED BY:  Drew Gilliam
%
% Original License:  
% The MIT License (MIT)
% 
% Copyright (c) 2015 Kelly Kearney
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy of
% this software and associated documentation files (the "Software"), to deal in
% the Software without restriction, including without limitation the rights to
% use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
% the Software, and to permit persons to whom the Software is furnished to do so,
% subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
% FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
% COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
% IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  
%MODIFICATION HISTORY:
%   2006        Kelly Kearney
%     --creation
%   2009.02     Drew Gilliam
%     --eliminate GETINUNITS and temporary axes,
%       rather we merely return the information in pixels
%     --add error checking & comments


    % check for valid axes
    if ~isnumeric(hax) || ~isscalar(hax) || ~ishandle(hax)
        error(sprintf('%s:invalidAxes',mfilename),...
            'Function requires single Axes handle as input.')
    end

    % axes pixel position
    axisPos = getpixelposition(hax,varargin{:});

    % aspect ratio modes
    darismanual  = strcmpi(get(hax, 'DataAspectRatioMode'),    'manual');
    pbarismanual = strcmpi(get(hax, 'PlotBoxAspectRatioMode'), 'manual');


    % dar/pbar = [auto/auto]
    if ~darismanual && ~pbarismanual
        pos = axisPos;

    else

        % properties
        dx = diff(get(hax, 'XLim'));
        dy = diff(get(hax, 'YLim'));
        dar = get(hax, 'DataAspectRatio');
        pbar = get(hax, 'PlotBoxAspectRatio');

        % x/y aspect ratios
        limDarRatio = (dx/dar(1))/(dy/dar(2));
        pbarRatio   = pbar(1)/pbar(2);
        axisRatio   = axisPos(3)/axisPos(4);

        % dar/pbar = [manual/auto] OR [manual/manual]
        if darismanual
            if limDarRatio > axisRatio
                pos(1) = axisPos(1);
                pos(3) = axisPos(3);
                pos(4) = axisPos(3)/limDarRatio;
                pos(2) = (axisPos(4) - pos(4))/2 + axisPos(2);
            else
                pos(2) = axisPos(2);
                pos(4) = axisPos(4);
                pos(3) = axisPos(4) * limDarRatio;
                pos(1) = (axisPos(3) - pos(3))/2 + axisPos(1);
            end

        % dar/pbar = [auto/manual]
        else
            if pbarRatio > axisRatio
                pos(1) = axisPos(1);
                pos(3) = axisPos(3);
                pos(4) = axisPos(3)/pbarRatio;
                pos(2) = (axisPos(4) - pos(4))/2 + axisPos(2);
            else
                pos(2) = axisPos(2);
                pos(4) = axisPos(4);
                pos(3) = axisPos(4) * pbarRatio;
                pos(1) = (axisPos(3) - pos(3))/2 + axisPos(1);
            end
        end
    end

end


%% END OF FILE=============================================================
