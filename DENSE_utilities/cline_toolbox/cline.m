%% cLINE HANDLE CLASS DEFINITION
%Create a set of piece-wise continuous contours, each specifed by
%a different set of control points.
%
%cLINE offers the following features and abilities:
%   • Any number of contours within a single cLINE
%   • Closed or Open contours
%   • Curved or Straight connecting line segments
%   • Corners or Smooth control points
%   • Add/Delete individual control points
%   • Notify other functions of property changes
%   • Constrain the Position according to some function
%
%
%HANDLE CLASS NOTE
%
%   cLINE is not a "value" class (like 'int32' or 'double'), but rather
%   a "handle" class (though cLINE itself features no interactive drawing
%   capabilities).  Copies of a cLINE object will therefore reference
%   the original object.  For example, both C1 and C2 in the following
%   code refer to the same object:
%       C1 = cline;
%       C2 = C1;
%   Editing C1 will affect C2, and vice versa. This design decision allows
%   for multiple instances of the IMCLINE tool to operate on a single
%   cLINE object, useful for interactive  editing of the cLINE object
%   in multiple axes.
%
%   To copy a cLINE object, users must use the copy constructor:
%       C1 = cline;
%       C2 = cline(C1);
%   In this case, C1 and C2 refer to separate cLINE objects.
%
%
%PROPERTIES
%
%   NumberOfLines...number of contours within cLine object
%       Get enabled, defaults to 1
%       Set available through RESET method
%
%   Position....cell array of control point locations
%       Set/Get enabled, {1xNumberOfLines} cell array, where the "ith"
%       cell containins an [Ni x 2] matrix of control point locations
%
%   IsClosed....cell array indicating closed/open line
%       Set/Get enabled, {1xNumberOfLines} cell array, where the "ith"
%       cell containins a single logical value
%
%   IsCurved....cell array indicating curved or straight
%       connecting line segments (true = curved, false = straight).
%       Set/Get enabled, {1xNumberOfLines} cell array, where the "ith"
%       cell containins an [Ni x 1] logical vector.
%
%   IsCorner....cell array indicating if control points are corners
%       or smooth (true = corner point, false = smooth point)
%       Set/Get enabled, {1xNumberOfLines} cell array, where the "ith"
%       cell containins an [Ni x 1] logical vector.
%
%   UndoEnable..single logical value indicating if the cLine object should
%       save previous states toward the "undo" operation.  Useful if the
%       user desires to change several properties at once, but allow a
%       single undo of all changes.
%
%   PositionConstraintFcn...function defining contraints on the cLine
%       positions (see notes below for more information)
%
%
%EVENTS
%
%   NewProperty...After the initial object construction, a valid change
%       of any property on any child contour triggers the 'NewProperty'
%       event.  This allows dependent objects (such as IMCLINE)
%       to update accordingly.
%
%
%METHODS
%
%   OBJ = CLINE
%       empty constructor, creates a closed cLINE object containing
%       a single contour with no control points, no corners, and
%       no connecting line segments.
%
%   OBJ = CLINE(COPYOBJ)
%       copy constructor, duplicating the COPYOBJ cLINE object.
%       Note that OBJ and COPYOBJ refer to distinct cLINE objects (see
%       "handle class note" above).
%
%   OBJ = CLINE(POS)
%       creates a cLine object containing a single closed & curved
%       contour with no corners, specified by the [Nx2] control point
%       position matrix POS.
%
%   OBJ = CLINE(...,property,val,...)
%       creates a cLINE object specified by property/value pairs,
%       with valid property strings including 'NumberOfLines','Position',
%       'IsClosed','IsCurved', and 'IsCorner'.  If some properties are
%       not specified, each contour defaults (respectively) to zero
%       control points, closed, all line segments curved, and no corners.
%
%   OBJ.RESET
%       reset the cLINE oject, using the same available inputs as the
%       constructor (i.e. no input, POS, COPYOBJ, and property/value
%       pairs).  This allows the user to set all properties at once, or to
%       simply clear the current properties.  A cLINE reset cannot be
%       undone.
%
%   OBJ.ADDPOINT(CIDX,PIDX,NEWPT,...)
%       Add a new control point to the cLINE object.  The 2D position
%       NEWPT will be added at the index PIDX to the contour CIDX.
%       CIDX must be a scalar integer on the range [1,obj.NumberOfPoints].
%       PIDX must be on the range [1,size(obj.Position{CIDX},1].
%       The user may additionally enter property/value pairs. Valid
%       properties include 'IsCorner' and 'IsCurved', defining the corner
%       property of the new control point and the curved property of the
%       new following line segment, respectively. Note the special cases
%       of adding points to the end of an open cLINE, when the 'IsCurved'
%       property defines the curve of the new final line segment.
%
%   OBJ.DELETEPOINT(CIDX,PIDX)
%       delete the control point specified by the index PIDX from the
%       CIDX contour of the cLINE object.  CIDX must be a scalar integer
%       on the range [1,obj.NumberOfPoints].  PIDX must be on the range
%       [1,size(obj.Position{CONTOURIDX},1].
%
%   OBJ.UNDO()
%       undo changes to the cLINE object. Currently, a cLINE object will
%       allow users to undo the past 5 changes. If the user desires to
%       temporarily suspend the saving of changes, see the UndoEnable
%       property.
%
%   OBJ.UNDORESET()
%       Resets the undo data. After an undo reset, all previous changes to
%       the cLINE object cannot be undone.
%
%   CRV = OBJ.GETCONTOUR(CIDX)
%       returns an [Mx2] matrix of contour positions specifing the CIDX
%       contour, calculated according to the cLINESEGMENTS function.
%       To plot this curve: plot(CRV(:,1),CRV(:,2));
%
%   SEG = OBJ.GETSEGMENTS(CIDX)
%       returns an [Nx1] cell vector, where N=size(obj.Position{CIDX},1).
%       Each cell contains a 2D connecting line segment definition
%       (of varying length).  SEG is calculated according to the
%       cLINESEGMENTS function. Alternatively, the user  may output the
%       x/y data to two separate cell vectors via:
%           [XSEG,YSEG] = OBJ.GETSEGMENTS();
%       Note is the contour is open, the final segment is an empty array:
%           zeros(0,2)
%
%   PLOT(OBJ,...) plots the cLINE object, defaulting to the current axes.
%       Users may input additional parameters as in LINESPEC.
%       To plot to a specific axes, define the 'Parent' parameter.
%       To change the contour resolution, define the 'CurveResolution'.
%
%
%NOTE ON POSITION CONSTRAINT FUNCTION
%
%   Similar to IMPOLY, IMLINE, etc., this function allows the user to enter
%   a PositionConstraintFcn. Note the user should be very careful in this
%   function definition - as much error checking as possible is included to
%   ensure the output is as expected, but it is up to the user to ensure
%   that the function definition is correct.
%
%   Two distinct options are available for this function:
%
%     1) PositionConstraintFcn takes the entire cell array of positions as
%        input, and outputs a constrained cell array of positions:
%           fcn = @(pos)constraintFcn(pos);
%        This function will be called as such:
%           obj.Position = fcn(obj.Position);
%
%     2) PositionConstraintFcn is a cell array of functions, each taking a
%        single contour position as input and outputting the constrained
%        contour position:
%           fcn = {@(pos)cFcn1(pos), @(pos)cFcn2(pos), ...};
%       This function will be called as such
%           for k = 1:obj.NumberOfLines
%               obj.Position{k} = fcn{k}(obj.Position{k});
%           end
%
%   A useful example of the first function is included within the cline
%   toolbox, CLINECONSTRAINTORECT.  See this function for more information.
%
%
%EXAMPLE
%
%   This example creates a cLine object containing two contours. Various
%   changes are then made to the object, and displayed in a set of
%   subplots.
%
%     % define position & create cLINE object
%     pos = [1 0; 0 -1; -1 0; 0 1];
%     hcline = cline({pos,0.5*pos});
%
%     % alter cLine & display changes
%     hfig = figure;
%     for k = 1:6
%
%         % alter cLINE object
%         switch k
%             case 1
%                 % do nothing
%             case 2
%                 hcline.addPoint(1,1,[1 1]);
%             case 3
%                 hcline.Position{1} = hcline.Position{1}+0.5;
%             case 4
%                 hcline.undo;
%                 hcline.undo;
%             case 5
%                 hcline.UndoEnable = false;
%                 hcline.IsClosed{1}    = false;
%                 hcline.IsCurved{1}(3) = false;
%                 hcline.IsCorner{2}(1) = true;
%                 hcline.UndoEnable = true;
%             case 6
%                 hcline.undo;
%         end
%
%         % display
%         hax(k) = subplot(2,3,k);
%         plot(hcline,'Marker','s','CurveResolution',0.1);
%         axis equal, axis([-2 2 -2 2])
%     end
%
%     % link zoom/pan
%     linkaxes(hax);
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.01     Drew Gilliam
%     --creation
%   2009.03     Drew Gilliam
%     --modification to multi-contour cLINE



%% CLASS DEFINITION
classdef cline < handle

    % not directly settable properties
    properties (Dependent=true,SetAccess='private',GetAccess='public')
        NumberOfLines
    end

    % visible dependent properties
    properties (Dependent=true,SetAccess='public',GetAccess='public')
        Position
        IsClosed
        IsCurved
        IsCorner
        UndoEnable
        PositionConstraintFcn
    end

    % private properties
    properties (SetAccess = 'private',GetAccess = 'private')

        % We use this "double" property technique to provide an extra
        % layer of protection to the actual properties, as well as
        % eliminate confusion when the code below gets or sets properties.
        nbrline  = 1;
        nbrpos   = 0;
        position = {zeros(0,2)};
        isclosed = {true};
        iscurved = {true(0,1)};
        iscorner = {false(0,1)};

        % saved state property
        undoenable = true;
        undoptr = 0;
        undostruct = struct(...
            'nbrpos',  cell(5,1),...
            'position',[],...
            'isclosed',[],...
            'iscurved',[],...
            'iscorner',[]);

        % default position constraint function
        pcfcn = [];

        % segment cache
        % we have this to improve the speed of multiple calls the
        % getSegments or getContour functions by multiple imclines for the
        % same properties
        segcache = [];

    end

    % events
    events
        NewProperty
    end


    % method protoypes
    methods

        % constructor
        function obj = cline(varargin)
            obj = resetFcn(obj,false,varargin{:});
        end

        % destructor
        function delete(obj)
            obj.pcfcn = [];
        end

        % reset
        function obj = reset(obj,varargin)
            obj = resetFcn(obj,true,varargin{:});
        end


        % GET individual properties
        function n = get.NumberOfLines(obj)
            n = obj.nbrline;
        end
        function pos = get.Position(obj)
            pos = obj.position;
        end
        function tf = get.IsClosed(obj)
            tf = obj.isclosed;
        end
        function tf = get.IsCurved(obj)
            tf = obj.iscurved;
            for k = 1:obj.nbrline
                if ~obj.isclosed{k}, tf{k} = tf{k}(1:end-1); end
            end
        end
         function tf = get.IsCorner(obj)
             tf = obj.iscorner;
        end
        function tf = get.UndoEnable(obj)
            tf = obj.undoenable;
        end
        function val = get.PositionConstraintFcn(obj)
            val = obj.pcfcn;
        end


        % GET additional values
        function crv = getContour(obj,varargin)
            seg = obj.getSegments(varargin{:});
            crv = cell2mat(seg);
            tf  = [true; all(crv(2:end,:)~=crv(1:end-1,:),2)];
            crv = crv(tf,:);
        end

        function varargout = getSegments(obj,varargin)
            [varargout{1:nargout}] = getSegmentsFcn(obj,varargin{:});
        end


        % SET individual property arrays
        function set.Position(obj,pos)
            if ~iscell(pos), pos = {pos}; end
            obj.position = checkPosition(...
                constrainPosition(obj.pcfcn,pos),...
                obj.nbrline,obj.nbrpos);
            obj = saveState(obj);
            clearSegCache(obj);
            notify(obj,'NewProperty');
        end
        function set.IsClosed(obj,iscls)
            obj.isclosed = checkIsClosed(iscls,...
                obj.nbrline);
            obj = saveState(obj);
            clearSegCache(obj);
            notify(obj,'NewProperty');
        end
        function set.IsCurved(obj,iscrv)
            obj.iscurved = checkIsCurved(iscrv,...
                obj.nbrline,obj.nbrpos,obj.isclosed);
            obj = saveState(obj);
            clearSegCache(obj);
            notify(obj,'NewProperty');
        end
        function set.IsCorner(obj,iscrn)
            obj.iscorner = checkIsCorner(iscrn,...
                obj.nbrline,obj.nbrpos);
            obj = saveState(obj);
            clearSegCache(obj);
            notify(obj,'NewProperty');
        end
        function set.UndoEnable(obj,tf)
            setUndoEnableFcn(obj,tf);
        end
        function set.PositionConstraintFcn(obj,fcn)
            setPosConFcn(obj,fcn);
        end



        % ADD/DELETE POINTS
        function obj = addPoint(obj,lidx,pidx,newpt,varargin)
            obj = addPointFcn(obj,lidx,pidx,newpt,varargin{:});
        end
        function obj = deletePoint(obj,lidx,pidx)
            obj = deletePointFcn(obj,lidx,pidx);
        end


        % UNDO functions
        function obj = undo(obj)
            obj = undoFcn(obj);
        end
        function obj = undoReset(obj)
            obj = undoResetFcn(obj);
        end


        % OVERLOADED functions
        function varargout = plot(obj,varargin)
            h = plotFcn(obj,varargin{:});
            if nargout > 1, varargout{1} = h; end
        end

    end


end



%% HELPER FUNCTION: RESET FUNCTIONS
% RESET reset the object, setting all properties at once


function obj = resetFcn(obj,nFLAG,varargin)
% nFLAG triggers the 'NewProperty' event:
%   On an actual RESET call, we likely want to trigger 'NewProperty'.
%   However, when initially constructing the object we do not want to
%   prematurely trigger update listeners.
% The first VARARGIN input may be another cLINE object (to accomdate the
%   copy constructor) or a position matrix.
% Acceptable input properties are 'Position','IsClosed','IsCurved',
%   and 'IsCorner'.


    % no VARARGIN = clear properties
    % note we do NOT change the NumberOfLines here
    if nargin == 2

        pos   = checkPosition(zeros(0,2),obj.NumberOfLines);
        iscls = true;
        iscrv = true;
        iscrn = false;


    % copy constructor
    elseif isobject(varargin{1})

        % error check
        if numel(varargin)~=1 || ~isa(varargin{1}, mfilename)
            error(sprintf('%s:invalidInput',mfilename),...
                'Copy constructor does not accept additional inputs.');
        end

        % copy & validate position
        copyobj = varargin{1};
        pos = checkPosition(copyobj.Position);

        % other properties
        iscls = copyobj.IsClosed;
        iscrv = copyobj.IsCurved;
        iscrn = copyobj.IsCorner;


    % position-only constructor
    elseif isnumeric(varargin{1}) || iscell(varargin{1})

        % error check
        if numel(varargin)~=1
            error(sprintf('%s:invalidInput',mfilename),'%s',...
                'Position-only constructor does not accept ',...
                'additional inputs.');
        end

        % check position, with no constraints on number of lines or
        % number of positions per line
        pos = checkPosition(varargin{1});

        % default inputs
        iscls = true;
        iscrv = true;
        iscrn = false;


    % standard parameter/value
    elseif ischar(varargin{1})

        % default input
        data = struct(...
            'NumberOfLines',    [],...
            'Position',         zeros(0,2),...
            'IsClosed',         true,...
            'IsCurved',         true,...
            'IsCorner',         false);

        % parse input
        [args,other_args] = parseinputs(...
            fieldnames(data),struct2cell(data),varargin{:});

        if ~isempty(other_args)
             error(sprintf('%s:invalidInput',mfilename),...
                'One or more invalid input parameters.');
        end


        % check NumberOfLines
        N = args.NumberOfLines;
        if ~isempty(N) && (~isnumeric(N) || ~isscalar(N) || rem(N,1)~=0)
            error(sprintf('%s:invalidNumberOfLines',mfilename),...
                'Invalid NumberOfLines specification.');
        end

        % validate position
        pos = checkPosition(args.Position,args.NumberOfLines);

        % other inputs
        iscls = args.IsClosed;
        iscrv = args.IsCurved;
        iscrn = args.IsCorner;


    % unrecognized input
    else
        error(sprintf('%s:invalidInput',mfilename),...
            'Unrecognized input.');
    end


    % number of lines/positions
    nline = numel(pos);
    npos  = cellfun(@(p)size(p,1),pos);


    % validate other inputs against position
    iscls = checkIsClosed(iscls,nline);
    iscrv = checkIsCurved(iscrv,nline,npos,iscls);
    iscrn = checkIsCorner(iscrn,nline,npos);


    % save to object
    obj.nbrline  = nline;
    obj.nbrpos   = npos;
    obj.position = pos;
    obj.isclosed = iscls;
    obj.iscurved = iscrv;
    obj.iscorner = iscrn;

    % reset position constraint function
    obj.pcfcn = @(p)p;

    % reset undo structure
    obj = undoResetFcn(obj);

    % initialize the segcache
    obj.segcache = struct(...
        'isValid',      repmat({false},[nline 1]),...
        'xseg',         [],...
        'yseg',         [],...
        'Resolution',   []);

    % trigger event
    if nFLAG, notify(obj,'NewProperty'); end

end


%% GET SEGMENTS

function varargout = getSegmentsFcn(obj,res,idx)

    if nargin < 2 || isempty(res), res = [];  end
    if nargin < 3 || isempty(idx), idx = []; end

    if obj.segcache(idx).isValid && ...
       (isempty(res) || isequal(res,obj.segcache(idx).res))
        xseg = obj.segcache(idx).xseg;
        yseg = obj.segcache(idx).yseg;
    else
        [xseg,yseg] = clinesegments(obj.position{idx}, ...
            obj.isclosed{idx}, obj.iscurved{idx}, ...
            obj.iscorner{idx}, res);

        obj.segcache(idx).isValid = true;
        obj.segcache(idx).xseg = xseg;
        obj.segcache(idx).yseg = yseg;
        obj.segcache(idx).res  = res;
    end

    if nargout == 1
        varargout{1} = cellfun(@(x,y)cat(2,x,y),...
            xseg,yseg,'uniformoutput',0);
    else
        varargout{1} = xseg;
        varargout{2} = yseg;
    end

end

function clearSegCache(obj)
    [obj.segcache.isValid] = deal(false);
end



%% SET/APPLY POSITION CONSTRAINT FUNCTION
% here, we ensure that the user-defined position constraint function
% is of an allowable form, and doesn't mess-up the current state of the
% cLINE object. We also include a helper function for applying the FCN
% to the contours.

function obj = setPosConFcn(obj,fcn)

    % define standard error
    ERR = MException(...
        sprintf('%s:invalidPositionConstraintFcn',mfilename),...
        '%s','Candidate PositionConstraintFcn failed to ',...
        'produce a valid output position, based on the  ',...
        'current state of the cLINE object.');

    % helper function
    isfcn = @(f)isa(f,'function_handle');


    % reset position constraint function (note in this case, the
    % position won't change so we don't update the object
    if isempty(fcn)
        fcn = @(p)p;
        return

    % test for cell functionality
    elseif isfcn(fcn)

        try
            checkPosition(fcn(obj.position),obj.nbrline,obj.nbrpos);
        catch ME1
            ERR.addCause(ME1);

            if obj.nbrline == 1
                try
                    pos = obj.position;
                    pos{1} = fcn(pos{1});
                    checkPosition(pos,obj.nbrline,obj.nbrpos);
                    fcn = {fcn};
                catch ME2
                    ERR.addCause(ME2);
                    throw(ERR)
                end
            else
                throw(ERR);
            end
        end

    % cell array of functions
    elseif iscell(fcn) && all(cellfun(isfcn,fcn))
        try
            pos = obj.position;
            for k = 1:obj.nbrline
                pos{k} = fcn{k}(pos{k});
            end
            checkPosition(pos,obj.nbrline,obj.nbrpos);
        catch ME1
            ERR.addCause(ME1);
            throw(ERR);
        end

    % general error
    else
        throw(ERR);
    end

    % save function, update position
    obj.pcfcn = fcn;
    obj.position = constrainPosition(...
        obj.pcfcn,obj.position);

    % update & notify
    obj = saveState(obj);
    clearSegCache(obj);
    notify(obj,'NewProperty');

end



function pos = constrainPosition(fcn,pos)
% APPLY POSITION CONSTRAINT FUNCTION

    if ~iscell(fcn)
        pos = fcn(pos);
    else
        for k = 1:numel(pos)
            pos{k} = fcn{k}(pos{k});
        end
    end

end



%% HELPER FUNCTIONS: ADD/DELETE POINTS
% These two functions allow the user to add or delete single control
% points from the selected cLINE object.


function obj = addPointFcn(obj,lidx,pidx,newpt,varargin)
% ADDPOINT add the specified point NEWPT to the object at the index IDX

    % validate line index
    if ~isnumeric(lidx) || ~isscalar(lidx) ...
       || rem(lidx,1)~=0 || lidx<1 || obj.nbrline<lidx

        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'addPoint line index must be a single integer on the ',...
            'range [1..',num2str(obj.nbrline),'].');
    end

    % current line values
    N = obj.nbrpos(lidx);
    pos   = obj.position{lidx};
    iscls = obj.isclosed{lidx};
    iscrv = obj.iscurved{lidx};
    iscrn = obj.iscorner{lidx};


    % validate point index & value
    if ~isnumeric(pidx) || ~isscalar(pidx) || rem(pidx,1)~=0 ...
       || pidx<1 || N+1<pidx || ~isnumeric(newpt) || numel(newpt)~=2;

        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'addPoint requires a single integer index, between 1 and ',...
            num2str(N+1), ' , and a single 2D numeric position.');
    end



    % default iscurved:
    %   empty cLINE                     -> true
    %   1 element cLINE                 -> 1st IsCurved
    %   Closed cLINE, pidx == 1 or N+1  -> Nth IsCurved
    %   Open cLINE, pidx == 1           -> 1st IsCurved
    %   Open cLINE, pidx = N+1          -> (N-1)th IsCurved
    %   Other pidx                      -> (pidx-1)th IsCurved
    if N == 0
        newcrv = true;
    elseif N == 1
        newcrv = iscrv(1);
    elseif iscls && any(pidx == [1,N+1])
        newcrv = iscrv(end);
    elseif ~iscls && pidx == 1
        newcrv = iscrv(1);
    elseif ~iscls && pidx == N+1
        newcrv = iscrv(end-1);
    else
        newcrv = iscrv(pidx-1);
    end

    % parse remaining arguments
    tags = {'IsCurved','IsCorner'};
    vals = {newcrv,false};
    [args,other_args] = parseinputs(tags,vals,varargin{:});
    if ~isempty(other_args)
        error(sprintf('%s:invalidParameter',mfilename),...
            'Invalid parameter input.');
    end

    % new values
    newcrv = (args.IsCurved(1) == true);
    newcrn = (args.IsCorner(1) == true);

    % update last IsCurved entry if adding new point to end of open cLINE
    if ~iscls && pidx == N+1
        iscrv(end) = newcrv;
    end

    % update line values
    N = N+1;
    pos   = [pos(1:pidx-1,:); newpt(:)'; pos(pidx:end,:)];
    iscrv = [iscrv(1:pidx-1);    newcrv; iscrv(pidx:end)];
    iscrn = [iscrn(1:pidx-1);    newcrn; iscrn(pidx:end)];

    % apply position constraint
    fullN   = obj.nbrpos;
    fullpos = obj.position;
    fullN(lidx)   = N;
    fullpos{lidx} = pos;
    fullpos = checkPosition(constrainPosition(obj.pcfcn,fullpos),...
        obj.nbrline,fullN);

    % add point
    obj.nbrpos(lidx)   = N;
    obj.position       = fullpos;
    obj.iscurved{lidx} = iscrv;
    obj.iscorner{lidx} = iscrn;

    % trigger event
    obj = saveState(obj);
    clearSegCache(obj);
    notify(obj,'NewProperty');

end


function obj = deletePointFcn(obj,lidx,pidx)
% DELETEPOINT delete the control point at the index IDX from the object.

    % validate line index
    if ~isnumeric(lidx) || ~isscalar(lidx) ...
       || rem(lidx,1)~=0 || lidx<1 || obj.nbrline<lidx

        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'addPoint line index must be a single integer on the ',...
            'range [1..',num2str(obj.nbrline),'].');
    end

    % current values
    N = obj.nbrpos(lidx);

    % check for deletion allowance
    if N <= 3
         error(sprintf('%s:invalidDeletion',mfilename),'%s',...
            'A valid cLINE must have at least 3 points; ',...
            'cannot complete the deletion request.');

    elseif ~isnumeric(pidx) || ~isscalar(pidx) ...
       || rem(pidx,1)~=0 || pidx<1 || N<pidx

         error(sprintf('%s:invalidInput',mfilename),'%s',...
            'deletePoint requires a single integer index, between 1 ',...
            'and ',num2str(N), '.');
    end

    % delete point
    obj.nbrpos(lidx)           = N-1;
    obj.position{lidx}(pidx,:) = [];
    obj.iscurved{lidx}(pidx)   = [];
    obj.iscorner{lidx}(pidx)   = [];

    % trigger event
    obj = saveState(obj);
    clearSegCache(obj);
    notify(obj,'NewProperty');

end


%% HELPER FUNCTIONS: UNDO
% These functions save, reload, and clear previous cLINE states,
% allowing users to undo a certain number of their actions.


function obj = saveState(obj)
% SAVESTATE save the Position,IsClosed,IsCurved, and IsCorner values to the
%   "undostruct" structure. Users may then reload these previous states
%   using the obj.undo() command.

    % check for enabled state save
    if ~obj.undoenable, return; end

    % undostruct fields
    tags = fieldnames(obj.undostruct);

    % increment undoptr
    obj.undoptr = obj.undoptr + 1;

    % shift undostruct if full
    if obj.undoptr >= numel(obj.undostruct)
        for k = 2:numel(obj.undostruct)
            for ti = 1:numel(tags)
                obj.undostruct(k-1).(tags{ti}) = ...
                    obj.undostruct(k).(tags{ti});
            end
        end
        obj.undoptr = numel(obj.undostruct);
    end

    % save data
    for ti = 1:numel(tags)
        obj.undostruct(obj.undoptr).(tags{ti}) = obj.(tags{ti});
    end

end


function obj = undoFcn(obj)
% UNDO reload previous save cLINE states into the object

    % check for enabled undo
    if ~obj.undoenable
        warning(sprintf('%s:undoDisabled',mfilename),...
            'Cannot undo while undoEnable is set to ''false''.');
        return;
    end

    % decrement pointer
    obj.undoptr = obj.undoptr - 1;

    % check for valid saved data
    if obj.undoptr == 0
        obj.undoptr = 1;
        return;
    end

    % reset position
    tags = fieldnames(obj.undostruct);
    for ti = 1:numel(tags)
        obj.(tags{ti}) = obj.undostruct(obj.undoptr).(tags{ti});
    end

    % trigger event
    clearSegCache(obj);
    notify(obj,'NewProperty');

end


function obj = undoResetFcn(obj)
% UNDO RESET clear the undo structure, save the current state

    % reset undo properties
    obj.undoptr = 0;
    obj.undoenable = true;
    [obj.undostruct.nbrpos]   = deal(0);
    [obj.undostruct.position] = deal(zeros(0,2));
    [obj.undostruct.isclosed] = deal(true);
    [obj.undostruct.iscurved] = deal(true(0,1));
    [obj.undostruct.isclosed] = deal(false(0,1));

    % save current state
    obj = saveState(obj);

end


function obj = setUndoEnableFcn(obj,tf)
% SET UNDOENABLE
% validate, set flag, save current structure if necessary

    % validate input
    tf = (tf(1) == true);

    % if turning on save, make sure to save the state
    if tf && ~obj.undoenable
        obj.undoenable = tf;
        obj = saveState(obj);

    % set UndoEnable flag
    else
        obj.undoenable = tf;
    end

end



%% HELPER FUNCTION: PLOT
% This function creates a simple plot of the cLINE object, using three
% graphical objects (one HGGROUP, two LINE)


function hgroup = plotFcn(obj,varargin)
% PLOT plot the contour object
% this allows similar inputs of the PLOT command (see LINESPEC for more
% information). Note the first input must always be a valid object.

    % parse the 'Parent' & 'CurveResolution' fields
    tags = {'Parent','CurveResolution'};
    vals = {[],[]};
    [args,other_args] = parseinputs(tags,vals,varargin{:});

    if isempty(args.Parent)
        haxes = gca;
    elseif ishandle(args.Parent) && strcmpi(get(args.Parent,'type'),'axes')
        haxes = args.Parent;
    else
        error(sprintf('%s:badParent',mfilename),...
            'Bad value for line property: ''Parent''.');
    end

    % create container object
    hgroup = hggroup('tag','contour plot','parent',haxes);

    % test current hold state
    tf = ishold(haxes);

    % plot control points & contour
    hold(haxes,'on');
    for k = 1:obj.nbrline
        if obj.nbrpos(k) > 1
            pos = obj.position{k};
            crv = obj.getContour(args.CurveResolution,k);
            plot(crv(:,1),crv(:,2),...
                other_args{:},'marker','none','parent',hgroup);
            plot(pos(:,1),pos(:,2),...
                other_args{:},'linestyle','none','parent',hgroup);
        end
    end
    if ~tf, hold(haxes,'off'); end

end



%% HELPER FUNCTIONS: CHECK PROPERTIES
% The following validation functions check various user inputs (i.e.
% Position, IsClosed, IsCurved, IsCorner) for acceptable forms. If
% validation is successful, each function outputs the final form of the
% property in question.

function pos = checkPosition(pos,nline,npos)
% check position matrix
% note the position check does not require the NLINE or NPOS inputs, as
% during reset we may need to check the input position matrix for
% consistency without constraints on these parameters.

    % default inputs
    if nargin < 2 || isempty(nline), nline = []; end
    if nargin < 3 || isempty(npos),  npos  = []; end


    % replicate non-cell position matrix in cell array
    if ~iscell(pos)
        pos = {pos};
        if ~isempty(nline), pos = repmat(pos,[1 nline]); end
    end

    % check for expected number of cells
    if ~isempty(nline) && numel(pos)~=nline
        if isempty(nline), str = 'N';
        else               str = num2str(nline);
        end
        error(sprintf('%s:invalidPosition',mfilename),'%s',...
            'Invalid control point input. Function expects [1x',...
            str,'] cell array of control points.');
    end

    % validate all candidate positions
    for k = 1:numel(pos)

        % current control point matrix
        p = pos{k};

        % check for valid position input
        tf = isnumeric(p) && all(isfinite(p(:))) ...
            && ndims(p)==2 && size(p,2)==2 ...
            && (size(p,1)==0 || size(p,1) >= 3) ...
            && (isempty(npos) || size(p,1) == npos(k));

        % error on invalid input
        if ~tf
            if isempty(npos), str = 'N';
            else              str = num2str(npos(k));
            end
            error(sprintf('%s:invalidPosition',mfilename),'%s',...
                'Invalid control point input. Line ', num2str(k),...
                ' requires [',str,'x2] numeric control point matrix. ',...
                'To change the number of control points, ',...
                'use the "reset" function.');
        end

    end

    % ensure horizontal vector
    pos = pos(:)';

end


function iscls = checkIsClosed(iscls,nline)

    % replicate non-cell input for every line
    if ~iscell(iscls), iscls = repmat({iscls},[1 nline]); end

    % check for proper number of cells
    if numel(iscls)~=nline
        error(sprintf('%s:invalidIsClosed',mfilename),'%s',...
            'Invalid ''IsClosed''. Input cannot be reconciled ',...
            'with the NumberOfLines.');
    end

    % ensure each cell contains single logical argument
    for k = 1:nline
        iscls{k} = isequal(iscls{k}(1),true);
    end

    % ensure horizontal cell array
    iscls = iscls(:)';

end


function iscrv = checkIsCurved(iscrv,nline,npos,iscls)

    % replicate non-cell input for every line
    if ~iscell(iscrv), iscrv = repmat({iscrv},[1 nline]); end

    % check for proper number of cells
    if numel(iscrv)~=nline
        error(sprintf('%s:invalidIsCurved',mfilename),'%s',...
            'Invalid ''IsCurved''. Input cannot be reconciled ',...
            'with the NumberOfLines.');
    end

    % check each cell for expected input
    for k = 1:nline

        % current values
        tf = iscrv{k};
        N = npos(k);

        % expand single input
        if numel(tf) == 1
            tf = tf(ones(N,1));

        % maintain zero input
        elseif N==0 && numel(tf)==0
            % do nothing

        % open contour accepts [N-1] or N elements
        % (replicate final element to maintain consistency)
        elseif ~iscls{k} && numel(tf) == N-1
            tf = tf([1:end end]);
        elseif ~iscls{k} && numel(tf) == N
            tf = tf([1:end-1 end-1]);

        % closed contour accepts N elements
        elseif iscls{k} && numel(tf) == N
            % do nothing


        % error on invalid input
        else
            if iscls{k}, str = num2str(N);
            else         str = num2str(N-1);
            end
            error(sprintf('%s:invalidIsCurved',mfilename),'%s',...
                'Invalid ''IsCurved'' input. Line ', num2str(k),...
                'requires [',str,'x1] logical matrix.');
        end

        % ensure logical matrix
        tf = (tf(:)==true);
        iscrv{k} = tf;

    end

    % ensure horizontal cell array
    iscrv = iscrv(:)';

end


function iscrn = checkIsCorner(iscrn,nline,npos)

    % replicate non-cell input for every line
    if ~iscell(iscrn), iscrn = repmat({iscrn},[1 nline]); end

    % check for proper number of cells
    if numel(iscrn)~=nline
        error(sprintf('%s:invalidIsCorner',mfilename),'%s',...
            'Invalid ''IsCorner''. Input cannot be reconciled ',...
            'with the NumberOfLines.');
    end

    % check each cell for expected input
    for k = 1:nline

        % current values
        tf = iscrn{k};
        N  = npos(k);

        % expand single input
        if numel(tf) == 1
            tf = tf(ones(N,1));

        % error on invalid input
        elseif numel(tf) ~= N
            error(sprintf('%s:invalidIsCorner',mfilename),'%s',...
                'Invalid ''IsCorner'' input. Line ', num2str(k),...
                'requires [',num2str(N),'x1] logical matrix.');
        end

        % ensure logical matrix
        tf = (tf(:)==true);
        iscrn{k} = tf;

    end

    % ensure horizontal cell array
    iscrn = iscrn(:)';

end



%% END OF FILE=============================================================
