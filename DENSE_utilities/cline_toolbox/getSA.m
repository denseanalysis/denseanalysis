function [outervert,innervert] = getSA(varargin)

%GETSA interactive selection of cardiac short-axis contours
%   (see GETSELECTION for additional information on interactivity)
%
%INPUT PARAMETERS
%
%   'ConstrainToAxes'.....true/false, constrain user selections to axes
%   'PointsPerContour'....scalar integer, output size
%
%   General appearance:
%       'Color'......a [2x1] cell array or [2x3] array of color values
%           where each row specifies a color for a different object
%           (centerline/outer contour/inner contour)
%           This parameter specifies the color for control points,
%           contruction lines, and contours.
%
%   Control point appearance
%       'MarkerVisible'.....control point visibility ('on','off')
%       'Marker'............see LINE PROPERTIES
%       'MarkerSize'........control point size, in points
%       'MarkerLineWidth'...control point line width
%       'MarkerFill'........fill control points with color ('on','off')
%
%   Contour appearance:
%       'LineWidth'.........contour line width
%       'LineStyle'.........see LINE PROPERTIES
%
%   Construction line appearance:
%       'ConstructionVisible'....construction line visibility ('on','off')
%           each lines can be controlled separately with a [2x1] cellstr
%       'ConstructionLineStyle'..contruction line style (see 'LineStyle')
%       'ConstructionLineWidth'..construction line width
%
%DEFAULT INPUT PARAMETERS
%   'ConstrainToAxes'..........true
%   'PointsPerContour'.........9
%   'Color'....................{'r','g'}
%   'MarkerVisible'............'on'
%   'Marker'...................'x'
%   'MarkerSize'...............10
%   'MarkerLineWidth'..........2
%   'MarkerFill'...............'on'
%   'LineWidth'................2
%   'LineStyle'................'-'
%   'ConstructionVisible'......{'on','on'}
%   'ConstructionLineStyle'....'--'
%   'ConstructionLineWidth'....0.5
%
%OUTPUTS
%   outervert....[Nx2] outer contour vertices
%   innervert....[Nx2] inner contour vertices
%
%USAGE
%
%   [OUTERVERT,INNERVERT] = GETSA(HAX) allows the user to interactively
%   select cardiac short-axis contour from the axes HAX via 3 clicks:
%       1) one corner of epicardial extents
%       2) second corner of epicardial extents
%       3) endocardial extents
%
%   [...] = GETSA(HFIG) initiates selection on the current axes of HFIG
%
%   [...] = GETSA is the same as GETSA(GCA)
%
%   [...] = GETSA(...,'ConstrainToAxes',TF)
%   constrains control point selection to the visible axes.
%
%   [...] = GETSA(...,'PointsPerContour',N)
%   defines the number of points per output contour,
%   i.e. OUTERVERT and INNERVERT are both [Nx2]
%
%   [...] = GETSA(...,param1,val1,param2,val2,...) additional
%   properties specifies the control point, contour, and construction
%   line appearance.
%
%NOTES ON GETSELECTION
%
%   The main functionailty of this function is containted within the
%   GETSELECTION function. GETSELECTION controls user interaction
%   and returns control after the user had completed their  selection.
%
%   This function defines the drawing methods for the object of interest,
%   using a set number of control points to define the object.  We
%   initialize an API structure with references to the INIT and REDRAW
%   functions necessary for GETSELECTION to complete successfully.
%

%NOTES ON LINES
%   Quick note - we use lines only, since patch objects don't
%   seem to clip correctly.
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
%   2008        Drew Gilliam
%     --creation
%   2009.02     Drew Gilliam
%     --general update
%     --primary control transferred to GETSELECTION
%     --input parsing passed to private/PARSESLAINPUTS



    %% MAIN CODE

    % initialize construction containers
    hpt        = NaN(3,1);
    hconstruct = NaN(2,1);
    hcontour   = NaN(2,1);
    M          = 1001;

    % parse inputs
    args = struct(...
        'Color',                {{'r',[0 0.75 0]}},...
        'ConstructionVisible',  {{'on','on'}},...
        'PointsPerContour',     8);
    args = parseSLAinputs(args,varargin{:});


    % functions for GETSELECTION
    api.initializeFcn = @init;
    api.redrawFcn     = @redraw;

    % other variables for GETSELECTION
    api.NumberOfPoints  = [3 3];
    api.ConstrainToAxes = args.ConstrainToAxes;

    % call general construction function
    position = getselection(args.handle,api);

    % build construction lines
    [orect,ocont,irect,icont] = contourrecovery(...
        position(:,1),position(:,2),M);

    % resample contours at uniform spacing with natural splines
    pp = cscvn2(ocont','periodic');
    s = linspace(0,pp.breaks(end),args.PointsPerContour+1);
    s = s(1:end-1);
    outervert = fnval(pp,s)';

    pp = cscvn2(icont','periodic');
    s = linspace(0,pp.breaks(end),args.PointsPerContour+1);
    s = s(1:end-1);
    innervert = fnval(pp,s)';



    %% NESTED FUNCTION: INITIALIZE DISPLAY
    function hgroup = init(hax)

        % group container
        hgroup = hggroup('parent',hax,'Tag','getSA');

        % user selections (3 single point lines)
        clridx = [1 1 2];
        for k = 1:3
            hpt(k) = line(...
                'Parent',     hgroup, ...
                'XData',      NaN, ...
                'YData',      NaN, ...
                'marker',     args.Marker,...
                'markersize', args.MarkerSize,...
                'LineStyle',  'none',...
                'linewidth',  args.MarkerLineWidth,...
                'visible',    args.MarkerVisible,...
                'color',      args.Color{clridx(k)});
        end

        if isequal(args.MarkerFill,'on') || isequal(args.MarkerFill,true)
            set(hpt,{'markerfacecolor'},args.Color(clridx));
        end

        % construction objects (2 rectangular patches)
        for k = 1:2
            hconstruct(k) = line(...
                'parent',    hgroup,...
                'xdata',     NaN(4,1),...
                'ydata',     NaN(4,1),...
                'color',     args.Color{k},...
                'linestyle', args.ConstructionLineStyle,...
                'linewidth', args.ConstructionLineWidth,...
                'visible',   args.ConstructionVisible{k});
        end

        % contour objects (2 lines)
        for k = 1:2
           hcontour(k) = line(...
                'parent',    hgroup,...
                'xdata',     NaN(M,1),...
                'ydata',     NaN(M,1),...
                'linestyle', args.LineStyle,...
                'linewidth', args.LineWidth,...
                'color',     args.Color{k});
        end
    end


    %% NESTED FUNCTION: REDRAW DISPLAY
    function redraw(pos,dbl)

        x = pos(:,1);
        y = pos(:,2);

        set(hpt,{'xdata'},num2cell(x),{'ydata'},num2cell(y));

        [orect,ocont,irect,icont] = contourrecovery(x,y,M);

        set(hconstruct(1),'xdata',orect([1:end,1],1),...
            'ydata',orect([1:end,1],2));
        set(hconstruct(2),'xdata',irect([1:end,1],1),...
            'ydata',irect([1:end,1],2));

        set(hcontour(1),'xdata',ocont([1:end,1],1),...
            'ydata',ocont([1:end,1],2));
        set(hcontour(2),'xdata',icont([1:end,1],1),...
            'ydata',icont([1:end,1],2));

    end


end



%% CONTOUR RECOVERY
function [orect,ocont,irect,icont] = contourrecovery(x,y,N)
% subfunction to recover contruction and contour objects from user
% selected points. X and Y are 4x1 vectors of user selections, N is a
% scalar input indicating the number of contour points to be recovered.

    % outer rect vertices
    orect = [x([1 2 2 1]),y([1 1 2 2])];

    % center point
    xc = mean(x(1:2));
    yc = mean(y(1:2));

    % control point unsigned distance to center
    dx = abs(x-xc);
    dy = abs(y-yc);

    % object non-negative thickness
    xthick = dx(1)-dx(3);
    ythick = dy(1)-dy(3);
    thick = min(xthick,ythick);
    if thick < 0, thick = 0; end

    % new inner rectangle distance to center
    dx(3) = dx(1) - thick;
    dy(3) = dy(1) - thick;

    % inner rectangle coordinates
    xi = xc + [-dx(3) dx(3) dx(3) -dx(3)];
    yi = yc + [-dy(3) -dy(3) dy(3) dy(3)];
    irect = [xi(:),yi(:)];

    % contour coordinates
    ocont = contourvertices(xc,yc,dx(1),dy(1),N);
    icont = contourvertices(xc,yc,dx(3),dy(end),N);


end



%% CONTOUR VERTICES
function vert = contourvertices(xc,yc,a,b,N)
% subfunction to recover contour vertices from a rectangluar construction
% region, given the region center [XC,YC], axial radius A, lateral
% radius B, and number of contour points N.

    theta = linspace(-pi,pi,N);
    theta = theta(1:end-1);

    xtmp = xc + a*cos(theta);
    ytmp = yc + b*sin(theta);

    vert = [xtmp(:),ytmp(:)];

end



%% END OF FILE=============================================================
