function [Iunwrap,seeds] = unwrap2mov(Iwrap, varargin)

%UNWRAP2MOV unwrap a 2D+time image sequence
%
%REFERENCE
%   Quality-guided path following phase unwrapping:
%   D. C. Ghiglia and M. D. Pritt, Two-Dimensional Phase Unwrapping:
%   Theory, Algorithms and Software. New York: Wiley-Interscience, 1998.
%
%   Repeated in:
%   B. S. Spottiswoode, X. Zhong, A. T. Hess, C. M. Kramer,
%   E. M. Meintjes, B. M. Mayosi, and F. H. Epstein,
%   "Tracking Myocardial Motion From Cine DENSE Images Using
%   Spatiotemporal Phase Unwrapping and Temporal Fitting,"
%   Medical Imaging, IEEE Transactions on, vol. 26, pp. 15, 2007.
%
%INPUTS
%   Iwrap......wrapped image  (MxNxT)
%
%INPUT PARAMETERS
%   'Mask'..........mask to unwrap  (logcical MxNxT)
%   'SearchRadius'..integer spatial range for seed point time-path unwrapping
%   'PixelSize'.....pixel size (1x2 [isz jsz]), for use by phasequality2
%   'Seed'..........seed point data
%                   'manual'   manually choose seeds from SeedFrame phase-quality map
%                   'auto'     choose highest phase-quality within SeedFrame
%                   [Nseedx3]  row/col/frame user-defined seed points
%   'SeedFrame'.....frame for seed point data choice (only valid when
%                   'Seed' parameter is 'auto' or 'manual')
%   'Name'..........string for figure title during manual seed input
%   'Connectivity'..neighbor connectivity [4|8]
%
%DEFAULT INPUTS
%   'Mask'..........true(MxNxT)
%   'SearchRadius'..2
%   'PixelSize'.....[1 1]
%   'Seed'..........'auto'
%   'SeedFrame'.....1
%   'Connectivity'..4
%
%OUTPUT
%   Iunwrap........unwrapped image    (MxNxT, NaNs at pts not unwrapped)
%   seeds..........seed points used   (Nseedx3)
%
%USAGE
%   IUNWRAP = UNWRAP2MOV(IWRAP) unwraps the 2D+time image sequence IWRAP
%   using the method decribed in the above references. Results are returned
%   in the matrix IUNWRAP, containing NaNs at all points not unwrapped.
%
%   There are a number of additional inputs and outputs available to the
%   user.  The user may define a MASK of the same size as IWRAP indicating
%   the area to be unwrapped, a SEARCHRADIUS indicating the allowable
%   spatial range for the time-path seed point unwrapping, as well as SEED
%   parameters ('maunal','auto',or user-defined seed points).  The
%   SEEDFRAME input allows the user to manually or automatically select
%   seed points from an arbitrary frame. SEEDS points may be also be
%   returned upon request.
%
%NOTE ON SEED POINT
%   To maintain backward compatability, an [Nseedx2] input for the 'Seed'
%   input parameter is valid, assuming seed points on the first frame.
%
%NOTE ON MEX FILES
%   This function uses MEX files to significantly decrease execution time.
%   If the user receives errors from these files (quickfind_mex or
%   quickmax_mex), include the following code at the beginning of the
%   m-file script to disable MEX usage:
%       global UNWRAPTOOLBOX_NOMEX;
%       UNWRAPTOOLBOX_NOMEX = true;


%% "UNDOCUMENTED" INPUT PARAMETERS
%   These next inputs are provided for debugging and are not generally
%   useful (or suggested) for the casual user.
%
%   'DisplayProgress'..display unwrapping progress
%       'time'...........display UNWRAP2MOV_TIMEPATH debugging figure
%       'space'..........display UNWRAP2 debugging figure
%       'timeandspace'...display all debugging figures
%       'none'...........no debugging figures
%       logical..........true = display all debugging figures
%   'NumberAutoSeed'...Maximum number of timepaths to test.
%       Unwrapping through time with respect to some seed points may fail,
%       due to limited connectivity of the user-supplied mask.  When the
%       user has selected the 'auto' seed parameter, we therefore include
%       the ability to test more than one timepath.  In general the
%       function attempts to unwrap at most 5 time paths.  It is not
%       recommended to change this number, but we include this parameter
%       just in case.

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2007.09     Drew Gilliam
%     --creation
%   2008.03     Drew Gilliam
%     --renamed to "unwrap2mov"
%     --general update
%   2008.11     Drew Gilliam
%     --added arbitrary seed frame capability
%     --changed 'localradius' to 'searchradius'
%     --added 'SeedFrame' input
%     --multiple automatic seed points accepted
%     --use SEEDPARSE2 function
%   2008.12     Drew Gilliam
%     --debugging figure inputs
%   2009.03     Drew Gilliam
%     --'Name' addition
%   2013.03     Drew Gilliam
%     --added 'Connectivity' input


    %% SETUP

    % check minimum number of inputs
    error(nargchk(1,Inf,nargin));

    % input size
    if ~any(ndims(Iwrap) == [2 3])
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Input must be 2D+time image sequence.');
    end
    Isz = size(Iwrap(:,:,1));
    Nfr = size(Iwrap,3);

    % parameter inputs
    defargs = struct(...
        'Mask',             true([Isz,Nfr]),...
        'SearchRadius',     2,...
        'PixelSize',        [1 1],...
        'Connectivity',     [],...
        'Seed',             'auto',...
        'SeedFrame',        [],...
        'DisplayProgress',  false,...
        'NumberAutoSeed',   5,...
        'Name',             '');
    [args,other_args] = parseinputs(fieldnames(defargs),...
        struct2cell(defargs),varargin{:});

    if ~isempty(other_args)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Invalid input parameters.');
    end

    mask       = args.Mask;
    searchrad  = args.SearchRadius;
    pxsz       = args.PixelSize;
    conn       = args.Connectivity;
    seedinput  = args.Seed;
    seedframe  = args.SeedFrame;
    dispinput  = args.DisplayProgress;
    Nautoseed  = args.NumberAutoSeed;
    name       = args.Name;

    % check mask
    if ndims(mask) ~= ndims(Iwrap) || ...
       any(size(mask) ~= size(Iwrap)) || ...
       ~islogical(mask)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            '''Mask'' must be logical of IWRAP size.');
    end

    if all(~mask(:))
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'The ''Mask'' is completely false.');
    end

    % check searchrad
    if ~isnumeric(searchrad) || mod(searchrad,1)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'SearchRadius must be integer value.');
    end

    % check pixel size
    if ~isnumeric(pxsz) || numel(pxsz) ~= 2
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'PixelSize must be a 2-element numeric vector.');
    end

    % check connectivity
    flag_conn = ~isempty(conn);
    if ~flag_conn
        conn = 4;
    elseif ~isnumeric(conn) || ~isscalar(conn) || ~any(conn==[4 8])
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Connectivity accepts [4|8].');
    end

    % check seedframe
    if isempty(seedframe)
        frame = 1;
    else
        if ~isnumeric(seedframe) || ~isscalar(seedframe) || ...
           mod(seedframe,1) ~= 0 || ...
           seedframe < 1 || Nfr < seedframe
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'SeedFrame must on the range [%d,%d].',1,Nfr);
        end
        frame = seedframe;
    end

    % parse display input
    FLAG_displaytime  = false;
    FLAG_displayspace = false;
    err = false;

    if islogical(dispinput(1))
        FLAG_displaytime  = dispinput(1);
        FLAG_displayspace = dispinput(1);

    elseif ischar(dispinput)
        switch lower(dispinput)
            case 'time'
                FLAG_displaytime  = true;
            case 'space'
                FLAG_displayspace = true;
            case 'timeandspace'
                FLAG_displaytime  = true;
                FLAG_displayspace = true;
            case 'none'

            otherwise
                err = true;
        end

    else
        err = true;
    end

    if err
        warning(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Unrecognized ''DisplayProgress'' input.');
    end

    % phase quality calculation
    % (if the CONNECTIVITY input was used, we use the "masked"
    %  phase quality option)
    qual = zeros([Isz,Nfr]);
    if flag_conn
        for k = 1:Nfr
            qual(:,:,k) = phasequality2_mask(...
                Iwrap(:,:,k),pxsz,mask(:,:,k),conn);
        end
    else
        for k = 1:Nfr
            qual(:,:,k) = phasequality2(...
                Iwrap(:,:,k),pxsz,mask(:,:,k));
        end
    end

    % parse seed input
    api = struct('seedinput',seedinput,'mask',mask,...
        'seedframe',seedframe,'Iwrap',Iwrap(:,:,frame),...
        'qual',qual(:,:,frame),'nbrauto',Nautoseed,'name',name);
    seeds = seedparse2(api);
    indseeds = seeds(:,1) + Isz(1)*(seeds(:,2)-1) + ...
        Isz(2)*Isz(1)*(seeds(:,3)-1);




    %% UNWRAPPING

    % create unwrapped matrix
    Iunwrap = NaN([Isz,Nfr]);

    % unwrap seed points through time
    success = false(size(seeds,1),1);
    ERR = [];
    for n = 1:size(seeds,1)
        Iunwrap(indseeds(n)) = Iwrap(indseeds(n));
        try
            Iunwrap = unwrap2mov_timepath(...
                Iwrap, Iunwrap, qual, mask, ...
                seeds(n,1), seeds(n,2), seeds(n,3), ...
                searchrad, pxsz, conn, FLAG_displaytime);
            success(n) = true;
            if isequal(seedinput,'auto'), break; end
        catch ERR
        end
    end

    % check for at least one successful timepath
    if ~isempty(ERR)
        if ~any(success)
            ERR = addCause(ERR,...
                MException(sprintf('UNWRAP:%s:timepatherr',mfilename),...
                    'No seed timepath was successful'));
            rethrow(ERR);
        else
            warning(sprintf('UNWRAP:%s:timepatherr',mfilename),...
                'There was an error unwrapping one or more timepath.');
%             ERR.getReport()
        end
    end


    % spatially unwrap each frame
    for k = 1:Nfr
        Iunwrap(:,:,k) = unwrap2(...
            Iwrap(:,:,k), ...
            'Mask',             mask(:,:,k),...
            'PhaseQuality',     qual(:,:,k),...
            'PixelSize',        pxsz,...
            'Connectivity',     conn,...
            'UnwrappedImage',   Iunwrap(:,:,k),...
            'DisplayProgress',  FLAG_displayspace);
        drawnow;
    end


end % end of function


%**************************************************************************
% END OF FILE
%**************************************************************************
