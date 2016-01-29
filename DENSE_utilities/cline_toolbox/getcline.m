function obj = getcline(h,varargin)

%GETCLINE interactive selection of single cLINE with mouse.
%   This function is similar to the matlab function GETLINE, with
%   significantly more user functionality. The user may specify a closed or
%   open contour, with curved of straight connecting line segments, as
%   well as both corners and smooth control points. Additionally, the user
%   may specify the contour appearance, especially useful on cluttered
%   imagery where the line must stand out.
%
%INPUTS
%   h....axes/figure handle
%
%INPUT PARAMETERS
%
%   'IsClosed'..........draw closed contour (true = closed)
%   'IsCurved'..........draw curved contour (true = curved)
%   'ConstrainToAxes'...contstrain contor to axes
%   'CurveResolution'...user defined curve resoltuion
%
%   contour appearance parameters (see LINE PROPERTIES)
%       'Color','LineStyle','LineWidth','Marker','MarkerEdgeColor'
%       'MarkerFaceColor','MarkerSize','Clipping'
%
%OUTPUTS
%   obj.........cLINE object
%
%USAGE
%
%   OBJ = GETCLINE(FIG)
%   lets you select a contour in the current axes of figure FIG
%   using the mouse.  The final contour is returned in the
%   cLINE object OBJ.
%
%   [...] = GETCLINE(AX) lets you select a contour in the axes
%   specified by the handle AX.
%
%   [...] = GETCLINE is the same as [X,Y] = GETCLINE(GCF).
%
%   [...] = GETCLINE(...,'IsClosed',tf)
%   lets the user specify a closed or open contour
%   (tf is logical scalar, defaults to "true")
%
%   [...] = GETCLINE(...,'IsCurved',tf)
%   lets the user specify a continuous curve or polyline
%   (tf is logical scalar, defaults to "true")
%
%   [...] = GETCLINE(...,'ConstrainToAxes',tf)
%   lets the user specify if all points must be within visible axes
%   (tf is logical scalar, defaults to "true")
%
%   [...] = GETCLINE(...,'CurveResolution',res)
%   lets the user specify the curve display resolution
%   (res is scalar, defaults to 1/1000th of the larger axis)
%
%   [...] = GETCLINE(...,param1,val1,param2,val2,...) specifies the
%   contour appearance, see LINE PROPERTIES for more information.
%   Valid appearance properties are:
%       'Color','LineStyle','LineWidth','Marker','MarkerEdgeColor',...
%       'MarkerFaceColor','MarkerSize','Clipping'
%
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

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2008.02     Drew Gilliam
%     --creation
%   2008.02     Drew Gilliam
%     --update of comments
%   2008.09     Drew Gilliam
%     --conversion to nested functions
%   2009.02     Drew Gilliam
%     --changed name to GETCLINE
%     --added curved/corner functionality
%     --limited allowable change of appearance
%     --massive cleanup, comment overhaul
%     --move point selection functionality to GETSELECTION


    % initialize construction containers
    hpt = [];
    hln = [];

    % default appearance
    % this structure also defines all the fields
    % users are allowed to change.
    appearance = struct(...
        'Color',            'r',...
        'LineStyle',        '-',...
        'LineWidth',        0.5,...
        'Marker',           'x',...
        'MarkerEdgeColor',  'auto',...
        'MarkerFaceColor',  'r',...
        'MarkerSize',       6,...
        'Clipping',         'on');

    % default inputs
    if nargin <= 0 || isempty(h), h = gca; end

    % check for valid handle
    if ~ishghandle(h, 'figure') && ~ishghandle(h, 'axes')
        error(sprintf('%s:expectedFigureOrAxesHandle',mfilename), ...
            'First argument should be a figure or axes handle');
    end

    % parse inputs
    args = appearance;
    args.IsClosed        = true;
    args.IsCurved        = true;
    args.ConstrainToAxes = true;
    args.CurveResolution = NaN;
    [args,other_args] = parseinputs(fieldnames(args),...
        struct2cell(args),varargin{:});

    if ~isempty(other_args)
        error(sprintf('%s:invalidParameters',mfilename),...
            'Invalid input parameters.');
    end

    % flags
    FLAG_ISCLOSED = logical(args.IsClosed(1));
    FLAG_ISCURVED = logical(args.IsCurved(1));
    curveres      = args.CurveResolution(1);

    % update appearance struct
    tags = fieldnames(appearance);
    for ti = 1:numel(tags)
        appearance.(tags{ti}) = args.(tags{ti});
    end


    % functions for GETSELECTION
    api.initializeFcn = @init;
    api.redrawFcn     = @redraw;

    % other variables for GETSELECTION
    api.NumberOfPoints  = [3 Inf];
    api.ConstrainToAxes = args.ConstrainToAxes;

    % call general construction function
    [position,iscorner] = getselection(h,api);

    obj = cline('Position',position,'IsClosed',FLAG_ISCLOSED,...
        'IsCurved',FLAG_ISCURVED,'IsCorner',iscorner);



    %% NESTED FUNCTION: INITIALIZE DISPLAY
    function hgroup = init(hax)

        % default resolution
        if isnan(curveres)
            lmt = axis(hax);
            curveres = min([abs(lmt(2)-lmt(1)),abs(lmt(4)-lmt(3))])/1000;
        end

        % group container
        hgroup = hggroup('parent',hax,'Tag','getcline');

        % display objects
        tags = fieldnames(appearance);
        vals = struct2cell(appearance);
        hpt = line(...
            'Parent',     hgroup, ...
            'XData',      [], ...
            'YData',      [], ...
            tags(:)',     vals(:)',...
            'linestyle', 'none');
        hln = line(...
            'Parent',     hgroup, ...
            'XData',      [], ...
            'YData',      [], ...
            tags(:)',     vals(:)',...
            'marker',     'none');

    end



    %% NESTED FUNCTION: REDRAW CONTOUR DISPLAY
    function redraw(pos,iscrn)
    % update the contour display. we include the following inputs to
    % accomodate temporary position/corners of the ButtonMove function:
    %   pos.....control point position
    %   iscrn...current corner matrix (double clicks_

        % eliminate invalid pts
        tf = any(isnan(pos),2);
        pos = pos(~tf,:);
        iscrn = iscrn(~tf,:);

        % calculate curve
        if size(pos,1) <= 1
            crv = zeros(0,2);
        else
            crvseg = clinesegments(...
                pos,FLAG_ISCLOSED,FLAG_ISCURVED,iscrn,curveres);
            crv = cell2mat(crvseg);
        end

        % update display objects
        set(hpt,'xdata',pos(:,1),'ydata',pos(:,2));
        set(hln,'xdata',crv(:,1),'ydata',crv(:,2));

    end



end



%% END OF FILE=============================================================
