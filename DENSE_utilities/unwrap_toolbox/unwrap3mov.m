function [Vunwrap,seeds] = unwrap3mov(Vwrap, varargin)

%UNWRAP3MOV fully unwrap a 3D+time sequence
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
%   Vwrap...........wrapped image       [Ni x Nj x Nk x T]
%
%INPUT PARAMETERS
%   'Mask'..........mask to unwrap      [Ni x Nj x Nk x T] logical
%   'SearchRadius'..integer allowable range for seed point unwrapping
%   'VoxelSize'.....voxel size (1x3), for use by phasequality3
%   'Seed'..........seed point data
%                   'manual'   choose seed values from phase-quality map
%                   'auto'     choose highest phase-quality within mask
%                   (Nseedx4)  i/j/k/frame user-defined seed points
%   'SeedFrame'.....frame for seed point data choice (only valid when
%                   'Seed' parameter is 'auto' or 'manual');
%
%DEFAULT INPUTS
%   'Mask'..........true([Ni x Nj x Nk x T])
%   'SearchRadius'..2
%   'VoxelSize'.....[1 1 1]
%   'Seed'..........'auto'
%   'SeedFrame'.....1
%
%OUTPUT
%   Vunwrap.........unwrapped image     [Ni x Nj x Nk x T] NaNs at pts not unwrapped)
%   seeds...........seed points used    [Nseed x 3]
%
%USAGE
%   VUNWRAP = UNWRAP3MOV(VWRAP) unwraps the 3D+time sequence VWRAP
%   using the method decribed in the above references. Results are returned
%   in the matrix VUNWRAP, containing NaNs at all points not unwrapped.
%
%   There are a number of additional inputs and outputs available to the
%   user.  The user may define a MASK of the same size as Iwrap indicating
%   the area to be unwrapped, a LOCALRADIUS indicating the allowable range
%   for the time-path seed point unwrapping, as well as SEED parameters
%   ('maunal','auto',or user-defined seed points).  The SEED points may be
%   also be returned upon request.
%
%NOTE ON SEED POINT
%   To maintain backward compatability, an [Nseedx3] input for the 'Seed'
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
%       'time'...........display UNWRAP3MOV_TIMEPATH debugging figure
%       'space'..........display UNWRAP3 debugging figure
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

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%
%MODIFICATION HISTORY:
%   2008.03     Drew Gilliam
%     --creation, based on "unwrap2mov"
%   2008.11     Drew Gilliam
%     --added arbitrary seed frame capability
%     --changed 'localradius' to 'searchradius'
%     --added 'SeedFrame' input
%     --multiple automatic seed points accepted
%   2008.12     Drew Gilliam
%     --undocumented inputs DISPLAYPROFRESS and NUMBERAUTOSEED



    %% SETUP

    % check minimum number of inputs
    error(nargchk(1,Inf,nargin));

    % input size
    if ndims(Vwrap) ~= 4
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Input must be 3D+time image sequence.');
    end
    Vsz = size(Vwrap(:,:,:,1));
    Nfr = size(Vwrap,4);

    % parameter inputs
    valid_param   = {'Mask','SearchRadius','VoxelSize','Seed','SeedFrame',...
        'DisplayProgress','NumberAutoSeed'};
    valid_default = {true([Vsz,Nfr]), 2, [1 1 1], 'auto',1,...
        false,5};
    [args,other_args] = parseinputs(valid_param,valid_default,varargin{:});

    if ~isempty(other_args)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Invalid input parameters.');
    end

    mask       = args.Mask;
    searchrad  = args.SearchRadius;
    vxsz       = args.VoxelSize;
    seedinput  = args.Seed;
    seedframe  = args.SeedFrame;
    dispinput  = args.DisplayProgress;
    Nautoseed  = args.NumberAutoSeed;

    % check mask size
    if ndims(mask) ~= ndims(Vwrap) || ...
       any(size(mask) ~= size(Vwrap)) || ...
       ~islogical(mask)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            '''Mask'' must be logical of VWRAP size.');
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

    % check voxel size
    if ~isnumeric(vxsz) || numel(vxsz) ~= 3
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'VoxelSize must be a 3-element numeric vector.');
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

    % phase quality
    qual = zeros([Vsz,Nfr]);
    for fr = 1:Nfr
        qual(:,:,:,fr) = phasequality3(...
            Vwrap(:,:,:,fr),vxsz,mask(:,:,:,fr));
    end

    % parse seed input
    [seeds,FLAG_seed] = seedparse3(seedinput,qual,mask,seedframe,Nautoseed);
    indseeds = seeds(:,1) + Vsz(1)*(seeds(:,2)-1) + ...
        Vsz(2)*Vsz(1)*(seeds(:,3)-1) + Vsz(3)*Vsz(2)*Vsz(1)*(seeds(:,4)-1);



    %% UNWRAPPING

    % initialize unwrapped matrix, add seed points
    Vunwrap = NaN([Vsz,Nfr]);

    % unwrap seed points through time
    success = false(size(seeds,1),1);
    ERR = [];
    for n = 1:size(seeds,1)
        Vunwrap(indseeds(n)) = Vwrap(indseeds(n));
        try
            Vunwrap = unwrap3mov_timepath(...
                Vwrap, Vunwrap, qual, mask, ...
                seeds(n,1), seeds(n,2), seeds(n,3), seeds(n,4), ...
                searchrad, FLAG_displaytime);
            success(n) = true;
            if FLAG_seed == 2, break; end
        catch ERR
        end
    end

    % check for at least one successful timepath
    if ~isempty(ERR)
        if ~any(success)
            ERR = addCause(ERR,...
                MException(sprintf('UNWRAP:%s:timepatherr',mfilename),...
                    'No seed timepath was successful'));
            ERR.throw;
        else
            warning(sprintf('UNWRAP:%s:timepatherr',mfilename),...
                'There was an error unwrapping one or more timepath.');
        end
    end

    % start waitbar & timer
    hwait = waitbar(0,'Unwrapping 3D sequence...');
    tic

    % spatially unwrap each frame
    for fr = 1:Nfr
        Vunwrap(:,:,:,fr) = unwrap3(...
            Vwrap(:,:,:,fr),  ...
            'Mask',             mask(:,:,:,fr),...
            'PhaseQuality',     qual(:,:,:,fr),...
            'UnwrappedVolume',  Vunwrap(:,:,:,fr),...
            'DisplayProgress',  FLAG_displayspace);

        % warning
        tmp1 = mask(:,:,:,fr);
        tmp2 = ~isnan(Vunwrap(:,:,:,fr));
        if any(tmp1(:) ~= tmp2(:))
            fprintf(1,'warning occured at frame %d\n',fr);
        end

        % update waitbar
        if ishandle(hwait)
            str = sprintf('Unwrapping 3D sequence (~%.1fsec remaining)',...
                toc*(Nfr-fr)/fr);
            waitbar(fr/Nfr,hwait,str);
        end
    end

    % close waitbar
    if ishandle(hwait), close(hwait); end


end  % end of function


%**************************************************************************
% END OF FILE
%**************************************************************************
