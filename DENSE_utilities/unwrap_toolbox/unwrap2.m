function [Iunwrap,seeds] = unwrap2(Iwrap, varargin)

%UNWRAP2_CONN unwraps a 2D image from various seed points via a
%   guided flood fill algorithm.
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
%   Iwrap......wrapped image (MxN)
%
%INPUT PARAMETERS
%   'Mask'...........mask to unwrap  (logcical MxN)
%   'PixelSize'......pixel size (1x2 [isz jsz]), for use by phasequality2
%   'Seed'...........seed point data
%       'manual'   manually choose seeds from phase-quality map
%       'auto'     choose highest phase-quality from masked phase-quailty
%       (Nseedx2)  row/col user-defined seed points
%   'Name'..........string for figure title during manual seed input
%   'Connectivity'..neighbor connectivity [4|8]
%
%DEFAULT INPUTS
%   'Mask'..........true(MxN)
%   'PixelSize'.....[1 1]
%   'Seed'..........'auto'
%   'Name'..........[]
%   'Connectivity'..4
%
%OUTPUT
%   Iunwrap....unwrapped image    (MxN, NaNs at points not unwrapped)
%   seeds......seed points used   (Nseedx2)
%
%USAGE
%   IUNWRAP = UNWRAP2(IWRAP) unwraps the 2D image IWRAP using the method
%   decribed in the above references. Results are returned in the matrix
%   IUNWRAP, containing NaNs at all points not unwrapped.
%
%   There are a number of additional inputs and outputs available to the
%   user.  The user may define a MASK of the same size as IWRAP indicating
%   the area to be unwrapped, as well as SEED parameters ('maunal','auto',
%   or user-defined seed points).  The SEED points may be also be returned
%   upon request.
%
%   When used, the CONNECTIVITY input allows unwrapping to be performed
%   with respect to
%
%NOTE ON MEX FILES
%   This function uses MEX files to significantly decrease execution time.
%   If the user receives errors from these files (quickfind_mex or
%   quickmax_mex), include the following code at the beginning of the
%   m-file script to disable MEX usage:
%       global UNWRAPTOOLBOX_NOMEX;
%       UNWRAPTOOLBOX_NOMEX = true;


%% "UNDOCUMENTED" INPUT PARAMETERS
%   These next inputs are provided for debugging, or compatability with
%   the UNWRAP2MOV function, and are not generally useful (or suggested)
%   for the casual user.
%
%   'DisplayProgress'..display unwrapping progress (logical)
%   'PhaseQuality'.....previously calculated phase quality image.
%       Note that all values must be in the range [0,1].
%   'UnwrappedImage'...image containing some previously unwrapped values.
%       When this input is used, the "seed" input is ignored.  Instead,
%       the previously unwrapped values serve as unwrapping seeds.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2007.09     Drew Gilliam
%     --creation of "unwrap2" function, derived from
%       "GuidedFloodFillMultipoint" function by Bruce Spottiswoode
%       (created 2004.11, last modified 2004.12)
%   2008.03     Drew Gilliam
%     --general update
%     --added edge/corner functionality
%   2008.11     Drew Gilliam
%     --added single-input functionality
%     --switch to parameter style function (e.g. 'Mask','Seed',etc.)
%   2008.12     Drew Gilliam
%     --added "UNWRAPTOOLBOX_NOMEX" capability
%     --added 'DisplayProgess' undocumented input
%   2013.03     Drew Gilliam
%     --added 'Connectivity' input
%     --added new phase quality calculation
%       (when 'Connectivity' is specified)


    %% SETUP

    % check if the user has chosen to not use the faster MEX code
    FLAG_nomex = checknomex();

    % check number of inputs
    narginchk(1, Inf);

    % input size
    if ~ismatrix(Iwrap)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Input must be 2D');
    end
    Isz = size(Iwrap);

    % parameter inputs
    defargs = struct(...
        'Mask',             true(Isz),...
        'PixelSize',        [1 1],...
        'Seed',             'auto',...
        'Connectivity',     [],...
        'PhaseQuality',     [],...
        'UnwrappedImage',   [],...
        'DisplayProgress',  false,...
        'Name',             '');
    [args,other_args] = parseinputs(defargs,[],varargin{:});

    if ~isempty(other_args)
        error('Invalid Inputs.');
    end

    mask       = args.Mask;
    pxsz       = args.PixelSize;
    conn       = args.Connectivity;
    seedinput  = args.Seed;
    qual       = args.PhaseQuality;
    Iunwrap    = args.UnwrappedImage;
    FLAG_display = logical(args.DisplayProgress);
    name       = args.Name;

    % check mask
    if ndims(mask) ~= ndims(Iwrap) || ...
       any(size(mask) ~= size(Iwrap)) || ...
       ~islogical(mask)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Mask must be logical of IWRAP size.');
    end

    if all(~mask(:))
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'The ''Mask'' is completely false.');
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

    % inputted phase quality
    if ~isempty(qual)

        % check size and values
        if any(size(qual) ~= size(Iwrap)) || any(qual(:) < 0 | 1 < qual(:))
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'Undocumented ''PhaseQuality'' input is invalid.');
        end

    % phase quality calculation
    % (if the CONNECTIVITY input was used, we use the "masked"
    %  phase quality option)
    else
        if flag_conn
            qual = phasequality2_mask(Iwrap,pxsz,mask,conn);
        else
            qual = phasequality2(Iwrap,pxsz,mask);
        end
    end


    % inputted unwrapped image
    if ~isempty(Iunwrap)

        % check size
        if ndims(Iunwrap) ~= ndims(Iwrap) || any(size(Iunwrap) ~= size(Iwrap))
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'Undocumented ''UnwrappedImage'' input is invalid.');
        end

        % empty seeds output, indicates it was not used
        seeds = [];

    % seed selection / unwrap initialization
    else

        % create seed api
        api = struct('seedinput',seedinput,'mask',mask,...
            'Iwrap',Iwrap,'qual',qual,'name',name);

        % select seeds
        seeds = seedparse2(api);
        seeds = seeds(:,1:2);
        indseeds = seeds(:,1) + Isz(1)*(seeds(:,2)-1);

        % unwrapped initialization
        Iunwrap = NaN(Isz);
        Iunwrap(indseeds) = Iwrap(indseeds);

    end


    % ensure ~mask region is not considered
    Iunwrap(~mask) = NaN;

    % unwrap mask
    isunwrap = ~isnan(Iunwrap);

    % check for at least one valid unwrapped value
    if ~any(isunwrap)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'No valid unwrapped values in the initial unwrapped image.');
    end



    %% UNWRAP 2D IMAGERY

    % adjoin search region
    if conn==4
        h = [0 1 0; 1 0 1; 0 1 0];
    else
        h = [1 1 1; 1 0 1; 1 1 1];
    end

    % neighborhood index offsets
    [i,j] = find(h==1);
    nhood_ioffset = i - 2;
    nhood_joffset = j - 2;

    % quality multiplier: favor unwrapped neighbors that are closer
    % to the current pixel
    qualfac = (nhood_ioffset * pxsz(2)).^2 ...
            + (nhood_joffset * pxsz(1)).^2;
    qualfac = 1./sqrt(qualfac);

    % initial adjoin matrix
    tmp = conv2(double(isunwrap),h,'same');
    adjoin = logical(tmp) & ~isunwrap & mask;

    % sort quality matrix once for speed
    % quality indices to uint32 for "quickfind" input
    [~,qual_idx] = sort(qual(:),'descend');
    qual_idx = uint32(qual_idx);

    if FLAG_display
        hfig = initdisplay();
    end

    % Loop until there are no more adjoining pixels
    cnt = 0;
    while any(adjoin(:))

        % index of max phase quality in adjoining matrix
        % [val,ind] = max(qual(:).*adjoin(:)); % MAX IS SLOWER
        % [val,ind] = quickmax(qual,adjoin);   % quickmax is still slower
        if FLAG_nomex
            ind = quickfind(adjoin,qual_idx);
        else
            ind = quickfind_mex(adjoin,qual_idx);
        end


        % The maximum phase quality should always be within the adjoining
        % matrix, but just to be safe...
        if ~adjoin(ind)
            error(sprintf('UNWRAP:%s:codingerror',mfilename),...
                'The maximum phase quality was not in the adjoin matrix.');
        end

        % i/j coordinates
        i0 = rem(ind-1,Isz(1)) + 1;
        j0 = floor((ind-1)/Isz(1)) + 1;

        % valid spatial neighbors to current seed point
        i = i0 + nhood_ioffset;
        j = j0 + nhood_joffset;
        valid = 1<=i & i<=Isz(1) & ...
                1<=j & j<=Isz(2);
        nhood = i(valid) + Isz(1)*(j(valid)-1);
        fac = qualfac(valid);

        % unwrapped neighbors
        tf = isunwrap(nhood);
        nhood_unwrapped = nhood(tf);
        fac = fac(tf);

        switch numel(nhood_unwrapped)

            % no unwrapped neighbor (should be impossible)
            case 0
                adjoin(ind) = 0;
                continue;

            % one unwrapped neighbor
            case 1
                phase_ref = Iunwrap(nhood_unwrapped);
                p = unwrap_2element([phase_ref, Iwrap(ind)]);
                p = p(2);

            % multiple unwrapped neighbors
            otherwise

                % quality factor (distance factor time phase quality)
                f = fac.*qual(nhood_unwrapped);

                % method 1: phase value of maximum factor
                [~,ind_pr]      = max(f(:));
                nhood_unwrapped = nhood_unwrapped(ind_pr(1));
                phase_ref       = Iunwrap(nhood_unwrapped);
                p = unwrap_2element([phase_ref, Iwrap(ind)]);
                p = p(2);
        end

        % unwrap current pixel
        Iunwrap(ind) = p;

        % update wrap mask
        isunwrap(ind) = 1;

        % update adjoining matrix
        adjoin(ind)   = 0;
        adjoin(nhood) = ~isunwrap(nhood) & mask(nhood);

        if FLAG_display
            updatedisplay(hfig);
        end

        cnt = cnt+1;
        if cnt >= 1000
            drawnow
            cnt = 0;
        end

    end

    if FLAG_display
        pause(5)
        if ishandle(hfig), close(hfig); end
    end

    % confirm all masked values were unwrapped
    if any(mask(:) ~= ~isnan(Iunwrap(:)))
        warning(sprintf('UNWRAP:%s:incompleteunwrapping',mfilename),...
            'Not all requested values were unwrapped.');
    end

    return



    %% DISPLAY FUNCTIONS

    function hfig = initdisplay()

        hax = preAllocateGraphicsObjects(2,1);
        him = preAllocateGraphicsObjects(2,1);

        hfig = figure;
        hax(1) = subplot(1,2,1);
        him(1) = imshow(Iunwrap,[-10 10]);
        title('Unwrapped Image');
        hax(2) = subplot(1,2,2);
        him(2) = imshow(zeros([Isz 3]),[0 1]);
        title('Workspace (gray = mask, red = adjoin, green = unwrapped)');

        linkaxes(hax);
        drawnow

        data.him = him;
        guidata(hfig,data);

    end

    function updatedisplay(hfig)
        if ~ishandle(hfig)
            FLAG_display = false;
            return
        end
        data = guidata(hfig);
        him = data.him;

        lbl = zeros(Isz);
        lbl(mask)     = 1;
        lbl(adjoin)   = 2;
        lbl(isunwrap) = 3;

        red   = 0.25*(lbl==1) + 1.00*(lbl==2) + 0.00*(lbl==3);
        green = 0.25*(lbl==1) + 0.00*(lbl==2) + 1.00*(lbl==3);
        blue  = 0.25*(lbl==1) + 0.00*(lbl==2) + 0.00*(lbl==3);

        set(him(1),'cdata',Iunwrap);
        set(him(2),'cdata',cat(3,red,green,blue));
        drawnow
    end



end % end of function


%**************************************************************************
% END OF FILE
%**************************************************************************
