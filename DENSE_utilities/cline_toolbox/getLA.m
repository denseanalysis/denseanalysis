function [outervert,innervert] = getLA(varargin)

%GETLA interactive selection of cardiac long axis contours
%   (see GETSELECTION for additional information on interactivity)
%
%INPUT PARAMETERS
%
%   'ConstrainToAxes'.....true/false, constrain user selections to axes
%   'PointsPerContour'....scalar integer, output size
%
%   General appearance:
%       'Color'......a [3x1] cell array or [3x3] array of color values
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
%           each lines can be controlled separately with a [3x1] cellstr
%       'ConstructionLineStyle'..contruction line style (see 'LineStyle')
%       'ConstructionLineWidth'..construction line width
%
%DEFAULT INPUT PARAMETERS
%   'ConstrainToAxes'..........true
%   'PointsPerContour'.........9
%   'Color'....................{'b','r','g'}
%   'MarkerVisible'............'on'
%   'Marker'...................'x'
%   'MarkerSize'...............10
%   'MarkerLineWidth'..........2
%   'MarkerFill'...............'on'
%   'LineWidth'................2
%   'LineStyle'................'-'
%   'ConstructionVisible'......{'on','on','on'}
%   'ConstructionLineStyle'....'--'
%   'ConstructionLineWidth'....0.5
%
%OUTPUTS
%   outervert....[Nx2] outer contour vertices
%   innervert....[Nx2] inner contour vertices
%
%USAGE
%
%   [OUTERVERT,INNERVERT] = GETLA(HAX) allows the user to interactively
%   select cardiac long-axis contour from the axes HAX via 4 clicks:
%       1) center of basal level
%       2) apical point
%       3) extents of epicardial border
%       4) extents of endocardial border
%
%   [...] = GETLA(HFIG) initiates selection on the current axes of HFIG
%
%   [...] = GETLA is the same as GETLA(GCA)
%
%   [...] = GETLA(...,'ConstrainToAxes',TF)
%   constrains control point selection to the visible axes.
%
%   [...] = GETLA(...,'PointsPerContour',N)
%   defines the number of points per output contour,
%   i.e. OUTERVERT and INNERVERT are both [Nx2]
%
%   [...] = GETLA(...,param1,val1,param2,val2,...) additional
%   properties specifies the control point, contour, and construction
%   line appearance.
%
%
%NOTES ON GETCONSTRUCT
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
%     --primary control transferred to GETCONSTRUCT
%     --input parsing passed to private/PARSESLAINPUTS



    %% MAIN CODE

    % initialize construction containers
    hpt        = NaN(4,1);
    hconstruct = NaN(3,1);
    hcontour   = NaN(2,1);
    args       = [];
    M          = 1001;

    % parse inputs
    args = struct(...
        'Color',                {{'b','r',[0 0.75 0]}},...
        'ConstructionVisible',  {{'on','on','on'}},...
        'PointsPerContour',     9);
    args = parseSLAinputs(args,varargin{:});


    % functions for GETCONSTRUCT
    api.initializeFcn = @init;
    api.redrawFcn     = @redraw;

    % other variables for GETCONSTRUCT
    api.NumberOfPoints  = [4 4];
    api.ConstrainToAxes = args.ConstrainToAxes;

    % default contour recovery limits
    xlim = [-Inf Inf];
    ylim = [-Inf Inf];

    % call general construction function
    position = getselection(args.handle,api);


    % build construction lines
    [orect,ocont,irect,icont] = contourrecovery(...
        position(:,1),position(:,2),M,...
        api.ConstrainToAxes,xlim,ylim);

    % resample contours at uniform spacing with natural splines
    pp = cscvn2(ocont','variational');
    s = linspace(0,pp.breaks(end),args.PointsPerContour);
    outervert = fnval(pp,s)';

    pp = cscvn2(icont','variational');
    s = linspace(0,pp.breaks(end),args.PointsPerContour);
    innervert = fnval(pp,s)';
    innervert = flipud(innervert);



    %% NESTED FUNCTION: INITIALIZE DISPLAY
    function hgroup = init(hax)

        % group container
        hgroup = hggroup('parent',hax,'Tag','getLA');

        % user selections (4 single point lines)
        clridx = [1 1 2 3];
        for k = 1:4
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

        % construction objects (center line, 2 rectangles)
        hconstruct(1) = line(...
            'parent',    hgroup,...
            'xdata',     NaN(2,1),...
            'ydata',     NaN(2,1),...
            'color',     args.Color{1});
        for k = 2:3
            hconstruct(k) = line(...
                'parent',    hgroup,...
                'xdata',     NaN(4,1),...
                'ydata',     NaN(4,1),...
                'color',     args.Color{k});
        end
        set(hconstruct,...
            'linestyle', args.ConstructionLineStyle,...
            'linewidth', args.ConstructionLineWidth,...
            {'visible'}, args.ConstructionVisible);

        % contour objects (2 lines)
        for k = 1:2
           hcontour(k) = line(...
                'parent',    hgroup,...
                'xdata',     NaN(M,1),...
                'ydata',     NaN(M,1),...
                'linestyle', args.LineStyle,...
                'linewidth', args.LineWidth,...
                'color',     args.Color{k+1});
        end

        % save axes limits
        xlim = get(hax,'xlim');
        ylim = get(hax,'ylim');

    end


    %% NESTED FUNCTION: REDRAW DISPLAY
    function redraw(pos,dbl)

        x = pos(:,1);
        y = pos(:,2);

        set(hpt,{'xdata'},num2cell(x),{'ydata'},num2cell(y));

        [orect,ocont,irect,icont] = ...
            contourrecovery(x,y,M,api.ConstrainToAxes,xlim,ylim);

        set(hconstruct(1),'xdata',x(1:2),'ydata',y(1:2));
        set(hconstruct(2),'xdata',orect([1:end 1],1),...
            'ydata',orect([1:end 1],2));
        set(hconstruct(3),'xdata',irect([1:end 1],1),...
            'ydata',irect([1:end 1],2));

        set(hcontour(1),'xdata',ocont(:,1),'ydata',ocont(:,2));
        set(hcontour(2),'xdata',icont(:,1),'ydata',icont(:,2));

    end


end



%% CONTOUR RECOVERY
function [orect,ocont,irect,icont] = contourrecovery(x,y,N,flag,xlim,ylim)
% subfunction to recover contruction and contour objects from user
% selected points. X and Y are 4x1 vectors of user selections, N is a
% scalar input indicating the number of contour points to be recovered.

    % centerline vector
    vec  = [x(2)-x(1),y(2)-y(1)];
    vmag = sqrt(sum(vec.^2));
    vec  = vec ./ (vmag+eps);

    % centerline angle
    phi = atan2(vec(2),vec(1));

    % normal to centerline
    n   = [-vec(2),vec(1)];

    % outer distance from centerline
    ro = [x(3)-x(1),y(3)-y(1)];
    do = abs(sum(n.*ro));

    % contrained outer distance from centerline
    if flag && ~isnan(do)
        a = abs((xlim - x(1)) / n(1));
        b = abs((ylim - y(1)) / n(2));
        c = abs((xlim - x(2)) / n(1));
        d = abs((ylim - y(2)) / n(2));
        do = min([do,a,b,c,d]);
    end

    % outer rectangle coordinates
    xo = x([1 1 2 2]) + do*n(1)*[-1 1 1 -1]';
    yo = y([1 1 2 2]) + do*n(2)*[-1 1 1 -1]';
    orect = [xo(:),yo(:)];


    % inner distance to centerline
    % (not greater than outer distance)
    ri = [x(4)-x(1),y(4)-y(1)];
    di = abs(sum(n.*ri));
    if di > do, di = do; end

    % non-negative thickness
    thick = do - di;
    if thick < 0, thick = 0; end

    % inner rectangle coordinates
    xi = xo - thick*n(1)*[-1 1 1 -1]' - thick*vec(1)*[0 0 1 1]';
    yi = yo - thick*n(2)*[-1 1 1 -1]' - thick*vec(2)*[0 0 1 1]';
    irect = [xi(:),yi(:)];


    % contour coordinates
    ocont = contourvertices(x(1),y(1),vmag,do,phi,N);
    icont = contourvertices(x(1),y(1),vmag-thick,di,phi,N);

end



%% CONTOUR VERTICES
function vert = contourvertices(xc,yc,a,b,phi,N)
% subfunction to recover contour vertices from a rectangluar construction
% region, given the region center [XC,YC], axial radius A, lateral
% radius B, orientation PHI, and number of contour points N.

    theta = linspace(-pi/2,pi/2,N);

    xtmp = a*cos(theta)*cos(phi) - b*sin(theta)*sin(phi) + xc;
    ytmp = a*cos(theta)*sin(phi) + b*sin(theta)*cos(phi) + yc;

    vert = [xtmp(:),ytmp(:)];

end


%% END OF FILE=============================================================
