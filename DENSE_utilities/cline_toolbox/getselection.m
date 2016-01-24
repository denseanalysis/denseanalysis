function [position,dblclick] = getselection(h,api)

%GETSELECTION get a user mouse selection of some kind,
%   defined by a user specified external drawing api.
%
%INPUTS
%   h..........axes/figure handle
%   api........external drawing api
%
%EXTERNAL DRAWING API
%
%   The external drawing API must have at least the following fields:
%       initializeFcn....graphic initialization function
%           function prototype: HGROUP = initializeFcn(HAX)
%           where HAX is the parent axes and HGROUP is the hggroup parent
%           of all drawing objects (to be deleted at selection end)
%       redrawFcn........graphic update function
%           function prototype: redrawFcn(POS,DBL)
%           POS is an [Nptsx2] array, with NaN at unspecified points
%           DBL is an [Nptsx1] logical vector of double-clicked points
%
%   Additionally, the api can specify two other parameters
%       NumberOfPoints.....[mininum,maximum] number of points to select
%           0 indicates that no selection is acceptable
%           Inf indicates that any number of points is acceptable
%           (min==max) indicates a specific number of pts
%       ConstrainToAxes....constrain points to visible axes.
%
%
%OUTPUTS
%   position...control point selections
%   dblclick...double click true/false vector
%
%USAGE
%
%   POSITION = GETSELECTION(HFIG,API) interactively select control points
%   from the current axes of figure HFIG, drawing graphics objects
%   according to the  external drawing API. API must contain a reference
%   to an initialization  function (initializeFcn), a graphic update
%   function (redrawFcn), and the required number of points to be
%   selected (Npts).
%
%   ... = GETSELECTION(HAX,API) displays the object on the axes HAX
%
%   [POSITION,DBLCLICK] = GETSELECTION(...) the user may additionally
%   choose to return double-clicks in the logical vector DBLCLICK.
%   If POSITION is [Nptsx2], DBLCLICK is [Nptsx1]
%
%INTERACTIVE CONTROL
%
%   Control point selection:
%   --Left button click defines control points
%   --Pressing BACKSPACE or DELETE removes the previously selected
%     point from the contour
%   --The user can additionally ZOOM and PAN during selection.
%     (see note below)
%
%   After the proper number of points have been selected:
%   --Right-click, RETURN, or ENTER all end contour selection
%     without selecting the current point.
%
%NOTE ON POINTER MANAGER
%
%   This function must disable the pointer manager (IPTPOINTERMANAGER),
%   however MATALB supplied no mechanism to query the pointer manager
%   state. Therefore the user must manually reinitialize the pointer
%   manager if they so desire.
%

%CODING NOTES ON GETCONSTRUCT
%
%   This function holds the interactivity of GETSA and GETLA, which
%   are essentially the same function with different drawing methods.
%   GETSELECTION controls user interaction and returns control after
%   the user had completed their selection.  Graphical updates
%   are controlled by the external API, defined in GETLA or GETSA.
%

%NOTE ON ZOOM/PAN
%
%   We don't allow zoom/pan.
%
%   However, unlike 'GETLINE' or 'GETPTS', this function CAN allow for
%   standard zoom and pan activities during interactive selection.  These
%   tools are identified via the GETZOOMPAN helper function.
%   Note for this functionality to work, the 'Tag' field of the
%   zoom out, zoom in, and pan tools within the figure must be set to
%   'Exploration.ZoomOut','Exploration.ZoomIn','Exploration.Pan'.
%   Such is the case in the standard figure toolbar.
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
%     --move primary interactive control away from GETLA and GETSA to
%       more general function GETSELECTION


    % allow zoom/pan during selection?
    FLAG_zoompan = false;

    % check for valid handle
    if ~ishandle(h)
        error(sprintf('%s:expectedHandle',mfilename), ...
            'First argument is not a valid handle');
    end

    % get figure and axes handles
    switch get(h, 'Type')
        case 'figure'
            hfig  = h;
            haxes = get(hfig, 'CurrentAxes');
            if (isempty(haxes))
                haxes = axes('Parent', hfig);
            end

        case 'axes'
            haxes = h;
            hfig  = ancestor(haxes, 'figure');

        otherwise
            error(sprintf('%s:expectedFigureOrAxesHandle',mfilename), ...
                'First argument should be a figure or axes handle');
    end

    % check API for necessary variables
    tags = {'initializeFcn','redrawFcn'};
    if ~isstruct(api) || ~all(isfield(api,tags))
        error(sprintf('%s:invalidAPI',mfilename),...
            'Invalid external API.');
    end
    if ~isfield(api,'NumberOfPoints')
        api.NumberOfPoints = [5 5];
    end
    if ~isfield(api,'ConstrainToAxes')
        api.ConstrainToAxes = true;
    end
    if ~isfield(api,'Pointer')
        api.Pointer = 'crosshair';
    end
    if ~isfield(api,'PointerShapeHotSpot')
        api.PointerShapeHotSpot = get(hfig,'PointerShapeHotSpot');
    end
    if ~isfield(api,'PointerShapeCData')
        api.PointerShapeCData = get(hfig,'PointerShapeCData');
    end

    % check number of points
    N = api.NumberOfPoints;
    if ~isnumeric(N) || numel(N) ~= 2 || ...
       any(isnan(N)) || isinf(N(1)) || N(1)>N(2)
        error(sprintf('%s:invalidNumberOfPoints',mfilename),...
            'Invalid number of points specification within the API.');
    end

    % ensure logical ContrainToAxes
    api.ConstrainToAxes = logical(api.ConstrainToAxes(1));

    % initialize construction object
    hgroup = api.initializeFcn(haxes);

    % pause automated axis limits update
    xlimorigmode = get(haxes,'xlimmode');
    ylimorigmode = get(haxes,'ylimmode');
    set(haxes,'xlimmode','manual','ylimmode','manual');

    % current figure parameters
    fig_orig = get(hfig);

    % r2008b bug workaround
    fig_orig.DoubleBuffer = get(hfig,'DoubleBuffer');

    % suspend figure
    state = uisuspend(hfig);

    % to ensure that the figure is restored on an error, we need to
    % encapsulate the selection code within a separate function, calling
    % ONCLEANUP prior to that function.
    % we pass important restoration data to ONCLEANUP as app data
    cleanupData = struct(...
        'hfig',         hfig,...
        'haxes',        haxes,...
        'state',        state,...
        'fig_orig',     fig_orig,...
        'xlimorigmode', xlimorigmode,...
        'ylimorigmode', ylimorigmode,...
        'hgroup',       hgroup);
    setappdata(hfig,'getconstructCleanupData',cleanupData);
    cleanupObj = onCleanup(@()cleanupFcn(hfig));


    % reallow zoom & pan
    if FLAG_zoompan
        htools = getzoompan(hfig);
        if ~isempty(htools)
            set(htools,'enable','on');
        end
    end

    % disable pointer manager
    if isappdata(hfig,'iptPointerManager')
        iptPointerManager(hfig,'disable');
    end

    % change figure pointer
    set(hfig,'Pointer','crosshair',...
        'DoubleBuffer','on');


    % get the user selection
    [position,dblclick] = getpoints(hfig,haxes,hgroup,api);

    % just in case, EXPLICITLY delete the cleanup object
    delete(cleanupObj);


end



%% GETPOINTS
%this subfunction performs the actual interactive point
%selection. As a subfunction, ONCLEANUP in the previous function is able to
%nicely recover from any errors.  Note each nested function here makes use
%of the ONCLEANUPMOD function, ensuring that external errors are
%successfully dealt with and do not continue forever.

function [position,dblclick] = getpoints(hfig,haxes,hgroup,api)

    % api parameterss
    Npts = api.NumberOfPoints;
    FLAG_inside = logical(api.ConstrainToAxes(1));

    % persistant variables
    if ~isinf(Npts(2))
        position = NaN(Npts(2),2);
        dblclick = false(Npts(2),1);
    else
        position = NaN(0,2);
        dblclick = false(0,1);
    end
    ptcnt = 0;

    % zoom/pan objects
    hzoom = zoom(hfig);
    hpan  = pan(hfig);

    % initialize figure callbacks
    % note we do not use iptcallbacks, as we want to eliminate any
    % existing callback functions. The current state of the figure was
    % retrieved via UISUSPEND above, and will be replace with UIRESTORE
    % on cleanup.
    set(hfig,'WindowButtonDownFcn',     @ButtonDown,...
             'WindowButtonMotionFcn',   @ButtonMotion,...
             'KeyPressFcn',             @(src,evnt)KeyPress(evnt));

    % Bring target figure forward
    figure(hfig);

    % waitfor the user to complete the drag
    waitfor(hgroup,'UserData');

    % check for error
    if ~ishandle(hgroup) || ...
       ~strcmp(get(hgroup, 'UserData'), 'Completed') || ...
       any(isnan(position(:)))
           error(sprintf('%s:unknownError',mfilename),...
                'Error during selection.');
    end

    return


    % NESTED FUNCTION: KEYPRESS--------------------------------------------
    function KeyPress(evnt)
        try
            % ignore actions during zoom/pan
            if any(strcmpi({hzoom.Enable,hpan.Enable},'on'))
                return;
            end

            switch evnt.Character

                % delete and backspace keys:
                % remove previously selected point
                case {char(8), char(127)}
                    if ptcnt > 0
                        position(ptcnt:end,:) = NaN;
                        dblclick(ptcnt:end,:) = false;
                        ptcnt = ptcnt - 1;
                        if isinf(Npts(2))
                            position = position(1:ptcnt,:);
                            dblclick = dblclick(1:ptcnt,:);
                        end
                        api.redrawFcn(position,dblclick);
                        ButtonMotion(hfig,[]);
                    end

                % enter and return keys
                % return control to line after waitfor
                case {char(13), char(3)}
                    if Npts(1) <= ptcnt && ptcnt <= Npts(2)
                        set(hgroup, 'UserData', 'Completed');
                    end
            end
        catch ERR
            set(hgroup,'UserData','Error');
            rethrow(ERR);
        end
    end


    % NESTED FUNCTION: BUTTON DOWN-----------------------------------------
    function ButtonDown(varargin)
        try
            % ignore actions during zoom/pan
            if any(strcmpi({hzoom.Enable,hpan.Enable},'on'))
                return;
            end

            % selected point
            newpt = get(haxes, 'CurrentPoint');
            newpt = newpt(1,[1 2]);

            % check if selected point is inside of axis
            if FLAG_inside && ~checklimits(haxes,newpt)
                return
            end

            % selection type, complete on double-click
            selectionType = get(hfig, 'SelectionType');

            switch lower(selectionType)

                % completion on right click, only if the correct
                % number of points have been entered
                case 'alt'
                    if Npts(1) <= ptcnt && ptcnt <= Npts(2)
                        set(hgroup, 'UserData', 'Completed');
                    end
                    return;

                % note double clicks
                case 'open'
                    if ptcnt > 1
                        dblclick(ptcnt) = true;
                        api.redrawFcn(position,dblclick);
                    end
                    return;

                % ignore regular clicks after all points are assigned
                case 'normal'
                    if ptcnt >= Npts(2), return; end

                otherwise
                    return;
            end

            % save point & increment point count & save point
            ptcnt = ptcnt + 1;
            position(ptcnt,:) = newpt;
            dblclick(ptcnt,:) = false;

            % update display
            api.redrawFcn(position,dblclick);
            ButtonMotion(hfig,[]);

        catch ERR
            set(hgroup,'UserData','Error');
            rethrow(ERR);
        end
    end


    % NESTED FUNCTION: BUTTONMOTION----------------------------------------
    function ButtonMotion(varargin)
        try
            % ignore actions while zoom/pan
            % check all points are assigned
            if any(strcmpi({hzoom.Enable,hpan.Enable},'on')) || ...
               ptcnt >= Npts(2)
                return;
            end

            % get current location
            newpt = get(haxes, 'CurrentPoint');
            newpt = newpt(1,[1 2]);

            % check if selected point is inside of axis
            if FLAG_inside && ~checklimits(haxes,newpt)
                newpt(:) = NaN;
            end

            pos = position;
            pos(ptcnt+1,:) = newpt;
            dbl = dblclick;
            dbl(ptcnt+1,:) = false;
            api.redrawFcn(pos,dbl);

        catch ERR
            set(hgroup,'UserData','Error');
            rethrow(ERR);
        end

    end


end




%% CLEANUP FUNCTION
% This function is implictly called at the end of the GETSELECTION function
% above upon successful completion or error via the ONCLEANUP class.  Here,
% we delete drawing objects and restore the figure/axes to their former
% states.

function cleanupFcn(hfig)

    % test for cleanup information
    if ~ishandle(hfig) || ...
       ~isappdata(hfig,'getconstructCleanupData')
        return
    end

    % gather cleanup information
    data = getappdata(hfig,'getconstructCleanupData');

    % Delete animation objects
    if any(ishandle(data.hgroup))
        delete(data.hgroup(ishandle(data.hgroup)));
    end

    % restore the axes
    if ishandle(data.haxes)
        set(data.haxes,'xlimmode',data.xlimorigmode,...
            'ylimmode',data.ylimorigmode);
    end

    % restore figure
    if ishandle(data.hfig)
        set(data.hfig,...
            'Pointer',              data.fig_orig.Pointer,...
            'PointerShapeCData',    data.fig_orig.PointerShapeCData,...
            'PointerShapeHotSpot',  data.fig_orig.PointerShapeHotSpot,...
            'DoubleBuffer',         data.fig_orig.DoubleBuffer);
        uirestore(data.state);
    end

    % re-enable pointer manager
    if isappdata(data.hfig,'iptPointerManager')
       iptPointerManager(data.hfig,'enable');
    end

end



%% END OF FILE=============================================================
