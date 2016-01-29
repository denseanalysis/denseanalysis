function Vunwrap = unwrap3(Vwrap, varargin)

%UNWRAP3 unwraps a 3D image from various seed points via a
%   guided flood fill algorithm
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
%   Vwrap......wrapped image [Ni x Nj x Nk]
%
%INPUT PARAMETERS
%   'Mask'..........mask to unwrap  (logcical [Ni x Nj x Nk])
%   'VoxelSize'.....voxel size (1x3), for use by phasequality3
%   'Seed'..........seed point data
%       'manual'   manually choose seeds from phase-quality map
%       'auto'     choose highest phase-quality from masked phase-quailty
%       (Nseedx3)  i/j/k user-defined seed points
%
%DEFAULT INPUTS
%   'Mask'..........true([Ni x Nj x Nk])
%   'PixelSize'.....[1 1 1]
%   'Seed'..........'auto'
%
%OUTPUT
%   Vunwrap....unwrapped image    ([Ni x Nj x Nk], NaNs at points not unwrapped)
%   seeds......seed points used   (Nseedx3)
%
%USAGE
%   VUNWRAP = UNWRAP3(VWRAP) unwraps the 3D image VWRAP using the method
%   decribed in the above references. Results are returned in the matrix
%   VUNWRAP, containing NaNs at all points not unwrapped.
%
%   There are a number of additional inputs and outputs available to the
%   user.  The user may define a MASK of the same size as VWRAP indicating
%   the area to be unwrapped, as well as SEED parameters ('maunal','auto',
%   or user-defined seed points).  The SEED points may be also be returned
%   upon request.
%
%NOTE ABOUT MEX FILES
%   This function uses MEX files to significantly decrease execution time.
%   If the user receives errors from these files (quickfind_mex or
%   quickmax_mex), include the following code at the beginning of the
%   m-file script to disable MEX usage:
%       global UNWRAPTOOLBOX_NOMEX;
%       UNWRAPTOOLBOX_NOMEX = true;


%% "UNDOCUMENTED" INPUT PARAMETERS
%   These next inputs are provided for debugging, or compatability with
%   the UNWRAP3MOV function, and are not generally useful (or suggested)
%   for the casual user.
%
%   'DisplayProgress'..display progress (replaces FLAG_display)
%       Use with caution - this will be VERY VERY slow.
%       Also, not guaranteed to work - if your matrix is too large, display
%       may be implausible.
%   'PhaseQuality'.....previously calculated phase quality image.
%       Note that all values must be in the range [0,1].
%   'UnwrappedVolume'..matrix containing some previously unwrapped values.
%       When this input is used, the "seed" input is ignored.  Instead,
%       the previously unwrapped values serve as unwrapping seeds.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2008.03     Drew Gilliam
%     --creation, based on "unwrap2"
%   2008.12     Drew Gilliam
%     --added single-input functionality
%     --switch to parameter style function (e.g. 'Mask','Seed',etc.)
%     --added "UNWRAPTOOLBOX_NOMEX" capability


    %% SETUP

    % grid color for display
    gridclr = 'y';

    % check if the user has chosen to not use the faster MEX code
    FLAG_nomex = checknomex();

    % check number of inputs
    narginchk(1, Inf);

    % input size
    if ndims(Vwrap) ~= 3
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Input must be 3D');
    end
    Vsz = size(Vwrap);

    % parameter inputs
    valid_param   = {'Mask','PixelSize','Seed',...
        'PhaseQuality','UnwrappedVolume','DisplayProgress'};
    valid_default = {true(Vsz), [1 1 1], 'auto', [], [], false};
    [args,other_args] = parseinputs(valid_param,valid_default,varargin{:});

    if ~isempty(other_args)
        error('Invalid Inputs.');
    end

    mask       = args.Mask;
    pxsz       = args.PixelSize;
    seedinput  = args.Seed;
    qual       = args.PhaseQuality;
    Vunwrap    = args.UnwrappedVolume;
    FLAG_display = logical(args.DisplayProgress);


    % check mask
    if ndims(mask) ~= ndims(Vwrap) || ...
       any(size(mask) ~= size(Vwrap)) || ...
       ~islogical(mask)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Mask must be logical of VWRAP size.');
    end

    if all(~mask(:))
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'The ''Mask'' is completely false.');
    end


    % check pixel size
    if ~isnumeric(pxsz) || numel(pxsz) ~= 3
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'PixelSize must be a 3-element numeric vector.');
    end


    % inputted phase quality
    if ~isempty(qual)

        % check size and values
        if any(size(qual) ~= size(Vwrap)) || any(qual(:) < 0 | 1 < qual(:))
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'Undocumented ''PhaseQuality'' input is invalid.');
        end

    % phase quality calculation
    else
        qual = phasequality3(Vwrap,pxsz,mask);
    end


    % inputted unwrapped image
    if ~isempty(Vunwrap)

        % check size
        if ndims(Vunwrap) ~= ndims(Vwrap) || ...
           any(size(Vunwrap) ~= size(Vwrap))
            error(sprintf('UNWRAP:%s:inputerror',mfilename),...
                'Undocumented ''UnwrappedImage'' input is invalid.');
        end
    % seed selection / unwrap initialization
    else

        % select seeds
        seeds = seedparse3(seedinput,qual,mask);
        seeds = seeds(:,1:3);
        indseeds = seeds(:,1) + Vsz(1)*(seeds(:,2)-1) + ...
            Vsz(2)*Vsz(1)*(seeds(:,3)-1);

        % unwrapped initialization
        Vunwrap = NaN(Vsz);
        Vunwrap(indseeds) = Vwrap(indseeds);

    end


    % ensure ~mask region is not considered
    Vunwrap(~mask) = NaN;

    % unwrap mask
    isunwrap = ~isnan(Vunwrap);

    % check for at least one valid unwrapped value
    if ~any(isunwrap)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'No valid unwrapped values in the initial unwrapped volume.');
    end



    %% UNWRAP 3D IMAGERY

    % 6-connected kernel
    h = cat(3,...
        [0 0 0; 0 1 0; 0 0 0],...
        [0 1 0; 1 0 1; 0 1 0],...
        [0 0 0; 0 1 0; 0 0 0]);

    % 6-connected neighborhood indices
    nhood_ioffset = [0 0 -1 1 0 0];
    nhood_joffset = [0 -1 0 0 1 0];
    nhood_koffset = [-1 0 0 0 0 1];

    % initial adjoining matrix
    tmp = convn(double(isunwrap),h,'same');
    adjoin = logical(tmp) & ~isunwrap & mask;

    % quality matrix to double for "quickmax" function
    % qual = double(qual);

    % sort quality matrix once for speed
    % quality indices to uint32 for "quickfind" input
    [qual_sort,qual_idx] = sort(qual(:),'descend');
    qual_idx = uint32(qual_idx);


    % display
    if FLAG_display
        hfig = initdisplay();
    end

    % Loop until there are no more adjoining pixels
    while any(adjoin(:))

        % index of max phase quality in adjoining matrix
        % [val,ind] = max(qual(:).*adjoin(:)); % MAX IS SLOWER
        % [val,ind] = quickmax_mex(qual,adjoin);   % "quickmax" is still slower
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

        % i/j/k coordinates
        i0 = 1 + rem(ind-1,Vsz(1));
        j0 = 1 + rem(floor((ind-1)/Vsz(1)),Vsz(2));
        k0 = 1 + rem(floor((ind-1)/(Vsz(2)*Vsz(1))),Vsz(3));

        % valid 6-connected spatial neighbors to current seed point
        i = i0 + nhood_ioffset;
        j = j0 + nhood_joffset;
        k = k0 + nhood_koffset;
        valid = 1<=i & i<=Vsz(1) & ...
                1<=j & j<=Vsz(2) & ...
                1<=k & k<=Vsz(3);
        nhood = i(valid) + Vsz(1)*(j(valid)-1) + Vsz(2)*Vsz(1)*(k(valid)-1);

        % unwrapped neighbors
        nhood_unwrapped = nhood(isunwrap(nhood));

        switch numel(nhood_unwrapped)

            % no unwrapped neighbor (should be impossible)
            case 0
                adjoin(ind) = 0;
                continue;

            % one unwrapped neighbor
            case 1
                phase_ref = Vunwrap(nhood_unwrapped);

            % multiple unwrapped neighbors
            otherwise
                qual_ref        = qual(nhood_unwrapped);
                [val,ind_pr]    = max(qual_ref(:));
                nhood_unwrapped = nhood_unwrapped(ind_pr(1));
                phase_ref       = Vunwrap(nhood_unwrapped);
        end

        % unwrap current pixel
        p = unwrap_2element([phase_ref, Vwrap(ind)]);
        Vunwrap(ind) = p(2);

        % update wrap mask
        isunwrap(ind) = 1;

        % update adjoining matrix
        adjoin(ind)   = 0;
        adjoin(nhood) = ~isunwrap(nhood) & mask(nhood);

        % debug display
        if FLAG_display
            updatedisplay(hfig);
        end

    end

    if FLAG_display
        pause(5)
        if ishandle(hfig), close(hfig); end
    end

    % confirm all masked values were unwrapped
    if any(mask(:) == isnan(Vunwrap(:)))
        warning(sprintf('UNWRAP:%s:incompleteunwrapping',mfilename),...
            'Not all requested values were unwrapped.');
    end

    return



    %% DISPLAY FUNCTIONS

    function hfig = initdisplay()

        hax = NaN(2,1);
        him = NaN(2,1);

        [zeroimage,msz] = montage_image(zeros([Vsz(1:2) 1 Vsz(3)]));

        hfig = figure;
        hax(1) = subplot(1,2,1);
        him(1) = imshow(zeroimage,2*[-pi pi]);
        title('Unwrapped Volume',...
            'fontweight','bold');
        hax(2) = subplot(1,2,2);
        him(2) = imshow(zeroimage(:,:,[1 1 1],:),[0 1]);
        title('Workspace (gray = mask, red = adjoin, green = unwrapped)',...
            'fontweight','bold');

        set(hax,'visible','on',...
            'gridlinestyle','-','xcolor',gridclr,'ycolor',gridclr,...
            'xtick',(1:Vsz(2):Vsz(2)*msz(2)) - 0.5,...
            'ytick',(1:Vsz(1):Vsz(1)*msz(1)) - 0.5,...
            'xticklabel',[],'yticklabel',[]);
        grid(hax(1),'on'); grid(hax(2),'on');

        linkaxes(hax);
        drawnow

        data.him = him;
        data.msz = msz;
        guidata(hfig,data);

    end


    function updatedisplay(hfig)
        if ~ishandle(hfig)
            FLAG_display = false;
            return
        end

        data = guidata(hfig);
        him = data.him;
        msz = data.msz;

        % unwrapped image
        if ishandle(him(1))
            Idsp = reshape(Vunwrap,[Vsz(1:2) 1 Vsz(3)]);
            set(him(1),'Cdata',montage_image(Idsp,'size',msz));
        end

        % RGB workspace image
        if ishandle(him(2))
            sz = [Vsz(1:2) 1 Vsz(3)];
            L = zeros(sz);
            L(reshape(    mask, sz)) = 1;
            L(reshape(  adjoin, sz)) = 2;
            L(reshape(isunwrap, sz)) = 3;

            red   = 0.25*(L==1) + 1.00*(L==2) + 0.00*(L==3);
            green = 0.25*(L==1) + 0.00*(L==2) + 1.00*(L==3);
            blue  = 0.25*(L==1) + 0.00*(L==2) + 0.00*(L==3);
            Idsp  = cat(3,red,green,blue);

            set(him(2),'Cdata',montage_image(Idsp,'size',msz));
        end

        % redraw display
        drawnow

    end



end



%**************************************************************************
% END OF FILE
%**************************************************************************
