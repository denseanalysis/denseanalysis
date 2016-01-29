function Vunwrap = unwrap3mov_timepath(...
    Vwrap, Vunwrap, qual, mask, ...
    iseed, jseed, kseed, frseed, searchrad, FLAG_display)

%UNWRAP3MOV_TIMEPATH unwraps a path through time in 3D+time imagery starting
%   at a user defined seed point
%
%REFERENCES
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
%   Vwrap......wrapped matrix           [Ni x Nj x Nk x xT]
%   Vunwrap0...initial unwrapped matrix [Ni x Nj x Nk x xT] NaNs except seed points in 1st frame
%   qual.......phase quality            [Ni x Nj x Nk x xT]
%   mask.......mask allowed to unwrap   [Ni x Nj x Nk x xT] logical
%   iseed,jseed,kseed...seed point      integer scalars
%   frseed..............seed frame      integer scalar
%   searchrad...allowable range for seed point unwrapping (pixels)
%
%OUTPUT
%   Vunwrap....unwrapped matrix         (MxNxT, NaNs at points not unwrapped)
%
%USAGE
%   VUNWRAP = UNWRAP3MOV_TIMEPATH(VWRAP,VUNWRAP0,QUAL,MASK,I0,J0,K0,LOCALRAD)
%   unwraps a path through time from an initial seed point [I0,J0,K0] defined
%   in frame 1. We are given the 3D+time wrapped imagery IWRAP, an initial
%   unwrapped matrix VUNWRAP0 (containing all NaNs except at the seed
%   points in the first frame), the phase quality matrix QUAL, and a binary
%   matrix indiciating valid areas to unwrap MASK. LOCALRAD defines how far
%   from the seed point we are allowed to look for better phase quality.
%   The results are returned in the matrix VUNWRAP. This output contains
%   at least one unrwapped pixel on every frame.
%
%NOTE ON MULTIPLE SEED POINTS
%   This code assumes a single user-defined seed point.  The user may
%   choose multiple seed points and loop the UNWRAP3MOV_TIMEPATH function
%   externally. However, the paths will not be allowed to overlap.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2008.03     Drew Gilliam
%     --creation, based on "unwrap2mov_timepath"
%   2008.11     Drew Gilliam
%     --added "frseed" input, allowing for the seed point to be selected on
%       an arbitrary frame. required significant modification of code
%     --added ability for time paths to merge (previously unwrapped values
%       are accepted as valid)

    % debug display parameter
    displayzoom = true;


    %% SETUP

    % check if the user has chosen to not use the faster MEX code
    FLAG_nomex = checknomex();

    % check number of inputs, default input
    narginchk(8, 10);
    if nargin < 9  || isempty(searchrad),    searchrad = 2; end
    if nargin < 10 || isempty(FLAG_display), FLAG_display = false;   end

    % check proper number of dimensions
    if any([ndims(Vwrap),ndims(Vunwrap),ndims(qual),ndims(mask)] ~= 4) || ...
       any(size(Vunwrap)~=size(Vwrap)) || ...
       any(size(qual)   ~=size(Vwrap)) || ...
       any(size(mask)   ~=size(Vwrap))
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Input imagery must be 3D+time matrices of equal size.');
    end

    % image size, nbr of frames
    Vsz = size(Vwrap(:,:,:,1));
    Nfr = size(Vwrap,4);

    % check for single seed point
    if any([numel(iseed) numel(jseed) numel(frseed)] ~= 1)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Function accepts only single seed points.');
    end

    % check for valid seed point
    iseed  = round(iseed);
    jseed  = round(jseed);
    kseed  = round(kseed);
    frseed = round(frseed);
    if iseed < 1  || Vsz(1) < iseed || ...
       jseed < 1  || Vsz(2) < jseed || ...
       kseed < 1  || Vsz(3) < kseed || ...
       frseed < 1 || Nfr < frseed
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'invalid seed point.');
    end

    % ensure ~mask region is not considered
    Vunwrap(~mask) = NaN;

    % mask of already unwrapped values
    isunwrap = ~isnan(Vunwrap);

    % check for unwrapped seed point
    if ~isunwrap(iseed,jseed,kseed,frseed)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Seed point is not unwrapped.');
    end

    % variable init
    adjoin  = false([Vsz,Nfr]);
    islocal = false([Vsz Nfr]);

    % local region
    [I,J,K] = ndgrid(-searchrad:searchrad);
    D = I.*I + J.*J + K.*K;
    hlocal = D <= searchrad^2;
    hsz = size(hlocal);

    % local region offset
    cent = searchrad + 1;
    ind = find(hlocal);
    local_ioffset = 1 + rem(ind-1,hsz(1)) - cent;
    local_joffset = 1 + rem(floor((ind-1)/hsz(1)),hsz(2)) - cent;
    local_koffset = 1 + rem(floor((ind-1)/(hsz(1)*hsz(2))),hsz(3)) - cent;

    % 6-connected neighborhood offsets
    nhood_ioffset = [ 0  0 -1  0  1  0  0];
    nhood_joffset = [ 0 -1  0  0  0  1  0];
    nhood_koffset = [-1  0  0  0  0  0  1];
    hnhood = cat(3,...
        [0 0 0; 0 1 0; 0 0 0],...
        [0 1 0; 1 0 1; 0 1 0],...
        [0 0 0; 0 1 0; 0 0 0]);

    % quality to double for quickmax
    qual = double(qual);




    %% UNRWAP TIME PATH

    % debug display
    if FLAG_display
        hfig = initdisplay();
    end

    % we need to iterate through all the frames,
    % forward in time from FRSEED to frame NFR,
    % and backward in time from FRSEED to frame 1.
    frrng = {frseed:Nfr; frseed:-1:1};

    for ci = 1:numel(frrng)
        if numel(frrng) < 2
            continue;
        end

        % initialize starting point to seed point
        i0 = iseed;
        j0 = jseed;
        k0 = kseed;

        % frame loop
        for fi = 1:numel(frrng{ci})-1

            % current/next(or last) frame numbers
            fr0 = frrng{ci}(fi);
            fr1 = frrng{ci}(fi+1);

            % determine pixels in search region
            i = i0 + local_ioffset;
            j = j0 + local_joffset;
            k = k0 + local_koffset;
            ind = i + Vsz(1)*(j-1) + Vsz(2)*Vsz(1)*(k-1);
            valid = 1<=i & i<=Vsz(1) & ...
                    1<=j & j<=Vsz(2) & ...
                    1<=k & k<=Vsz(3);

            % search mask
            tmp = false(Vsz);
            tmp(ind(valid)) = 1;

            islocal(:) = 0;
            islocal(:,:,:,fr0) = tmp;
            islocal(:,:,:,fr1) = tmp;

            % mask islocal area
            islocal = islocal & mask;

            % check for overlapping searchable area after masking
            % (break frame loop on error)
            overlap = islocal(:,:,:,fr0) & islocal(:,:,:,fr1);
            if ~any(overlap(:)), break; end

            % initialize adjoin matrix
            tmp1 = isunwrap(:,:,:,fr0) & islocal(:,:,:,fr0);
            tmp0 = logical(convn(double(tmp1),hnhood,'same'));
            tmp1 = tmp1 & islocal(:,:,:,fr1);
            tmp0 = tmp0 & ~isunwrap(:,:,:,fr0) & islocal(:,:,:,fr0);

            adjoin(:) = 0;
            adjoin(:,:,:,fr0) = tmp0;
            adjoin(:,:,:,fr1) = tmp1;

            % display
            if FLAG_display
                updatedisplay(hfig,[fr0 fr1],k0+[-searchrad searchrad]);
            end


            % repeat unwrapping within the local neighborhood
            % until we move to the next frame
            while 1

                % check for valid adjoining possibilites
                % if there are no adjoining pixels left in the current frame,
                % there should be a valid adjoining pixel in the next frame.
                % Otherwise, we're gonna be stuck.
                if ~any(any(any(adjoin(:,:,:,fr0)))) && ...
                   ~any(any(any(adjoin(:,:,:,fr1))))
                    break;
                end

                % if there is an unwrapped phase within the adjoin matrix
                % on the next frame, find it, move to it, and advance the
                % frame loop
                tf = isunwrap(:,:,:,fr1) & adjoin(:,:,:,fr1);
                if any(tf(:))
                    if FLAG_nomex
                        [val,ind] = quickmax(qual(:,:,:,fr1),tf);
                    else
                        [val,ind] = quickmax_mex(qual(:,:,:,fr1),tf);
                    end
                    i0 = 1 + rem(ind-1, Vsz(1));
                    j0 = 1 + rem(floor((ind-1)/Vsz(1)), Vsz(2));
                    k0 = 1 + rem(floor((ind-1)/(Vsz(2)*Vsz(1))), Vsz(3));
                    break;
                end

                % maximal fr0/fr1 adjoining phase quality
                if FLAG_nomex
                    [val0,ind0] = quickmax(qual(:,:,:,fr0),adjoin(:,:,:,fr0));
                    [val1,ind1] = quickmax(qual(:,:,:,fr1),adjoin(:,:,:,fr1));
                else
                    [val0,ind0] = quickmax_mex(qual(:,:,:,fr0),adjoin(:,:,:,fr0));
                    [val1,ind1] = quickmax_mex(qual(:,:,:,fr1),adjoin(:,:,:,fr1));
                end

                % current frame maximal phase quality
                if val0 >= val1

                    % i/j/k coordinates
                    i = 1 + rem(ind0-1, Vsz(1));
                    j = 1 + rem(floor((ind0-1)/Vsz(1)), Vsz(2));
                    k = 1 + rem(floor((ind0-1)/(Vsz(2)*Vsz(1))), Vsz(3));

                    % 6-connected spatial neighbors
                    inh = i + nhood_ioffset;
                    jnh = j + nhood_joffset;
                    knh = k + nhood_koffset;
                    valid = 1<=inh & inh<=Vsz(1) & ...
                            1<=jnh & jnh<=Vsz(2) & ...
                            1<=knh & knh<=Vsz(3);
                    nhood = inh(valid) + Vsz(1)*(jnh(valid)-1) + ...
                        Vsz(2)*Vsz(1)*(knh(valid)-1) + Vsz(3)*Vsz(2)*Vsz(1)*(fr0-1);

                    ind = ind0 + Vsz(3)*Vsz(2)*Vsz(1)*(fr0-1);
                    nhood_time = ind0 + Vsz(3)*Vsz(2)*Vsz(1)*(fr1-1);
                    FLAG_nextframe = false;

                % next frame maximal phase quality
                else
                    ind   = ind1 + Vsz(3)*Vsz(2)*Vsz(1)*(fr1-1);
                    nhood = ind1 + Vsz(3)*Vsz(2)*Vsz(1)*(fr0-1);

                    FLAG_nextframe = true;
                end

                % unwrapped local neighbors
                nhood_unwrapped = nhood(isunwrap(nhood) & islocal(nhood));

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

                % update adjoin matrix
                if ~FLAG_nextframe
                    adjoin(ind)   = 0;
                    adjoin(nhood) = ~isunwrap(nhood) & islocal(nhood);
                    adjoin(nhood_time) = islocal(nhood_time);
                end

                % display
                if FLAG_display && ~FLAG_nextframe
                    updatedisplay(hfig,[fr0 fr1],k0+[-searchrad searchrad]);
                end

            end


        end % end frame loop

    end % end cell loop

    if FLAG_display
        pause(5);
        if ishandle(hfig), close(hfig); end
        drawnow
    end


    % check to ensure at least one pixel on each frame is unwrapped
    tf = any(reshape(~isnan(Vunwrap),[prod(Vsz),Nfr]));
    if ~all(tf)
        error(sprintf('UNWRAP:%s:unwrapping_problem',mfilename),...
            'One pixel on each frame not unwrapped.')
    end

    return



    %% INITIALIZE DISPLAY
    function hfig = initdisplay()

        % blank image for display
        zeroimage = montage_image(...
            zeros([Vsz(1),Vsz(2)*Vsz(3),1,Nfr]),...
            'size',[Nfr 1]);

        % display requested plots
        hax = NaN(2,1);
        him = NaN(2,1);
        hfig = figure;

        hax(1) = subplot(2,1,1);
        him(1) = imshow(zeroimage,4*[-pi pi]);
        hax(2) = subplot(2,1,2);
        him(2) = imshow(zeroimage(:,:,[1 1 1],:),[0 1]);
        linkaxes(hax);

        % unwrapped display
        if ishandle(hax(1))
           title('Unwrapped Imagery','fontweight','bold');
        end

        % workspace display
        if ishandle(hax(2))
            axes(hax(2));
            hold on
            plot(-1,-1,'s','color',0.25*[1 1 1],'markerfacecolor',0.25*[1 1 1]);
            plot(-1,-1,'sb','markerfacecolor','b');
            plot(-1,-1,'sg','markerfacecolor','g');
            plot(-1,-1,'sr','markerfacecolor','r');
            hold off
            legend({'Mask','Search Region','Unwrapped','Adjoining'},...
                'location','eastoutside');
            title('Workspace','fontweight','bold');
        end

        % limits and labels
        set(hax(ishandle(hax)),'visible','on','xcolor','k','ycolor','k',...
            'ytick',(1:Vsz(1):Vsz(1)*Nfr) - 0.5,...
            'yticklabel',num2cell(1:Nfr),...
            'xtick',(1:Vsz(2):Vsz(2)*Vsz(3)) - 0.5,...
            'xticklabel',num2cell(1:Vsz(3)));
        for k = 1:2
            if ishandle(hax(k))
                axes(hax(k)), xlabel('slice index'), ylabel('frame index');
            end
        end

        % zoom to current frame/slices
        if displayzoom
            frames = [1 2];
            slices = [1 2*searchrad+1];
            set(hax(ishandle(hax)),...
                'xlim',1 + Vsz(2)*(slices + [-1 0]),...
                'ylim',1 + Vsz(1)*(frames + [-1 0]));
        end

        % draw & cleanup
        drawnow
        figdata = struct(...
            'him',him,'hax',hax);
        guidata(hfig,figdata);

    end


    %% UPDATE DISPLAY
    function updatedisplay(hfig,frames,slices)

        % retrieve display data
        data = guidata(hfig);
        him = data.him;
        hax = data.hax;

        % adjoin color image
        if ishandle(him(2))
            sz = [Vsz(1),Vsz(2)*Vsz(3),1,Nfr];

            L = zeros(sz);
            L(reshape(    mask, sz)) = 1;
            L(reshape( islocal, sz)) = 2;
            L(reshape(  adjoin, sz)) = 3;
            L(reshape(isunwrap, sz)) = 4;

            red   = 0.25*(L==1) + 0.00*(L==2) + 1.00*(L==3) + 0.00*(L==4);
            green = 0.25*(L==1) + 0.00*(L==2) + 0.00*(L==3) + 1.00*(L==4);
            blue  = 0.25*(L==1) + 1.00*(L==2) + 0.00*(L==3) + 0.00*(L==4);
            adjdisp = cat(3,red,green,blue);

            set(him(2),'Cdata',montage_image(adjdisp,'size',[Nfr 1]));
        end

        % unwrapped image
        if ishandle(him(1))
            Ireshape = reshape(Vunwrap,[Vsz(1),Vsz(2)*Vsz(3),1,Nfr]);
            set(him(1),'Cdata',montage_image(Ireshape,'size',[Nfr,1]));
        end

        % change limits
        if displayzoom
            frames = sort(frames);
            slices = [min(slices), max(slices)];
            set(hax(ishandle(hax)),...
                'xlim',1 + Vsz(2)*(slices + [-1 0]),...
                'ylim',1 + Vsz(1)*(frames + [-1 0]));
        end

        % draw and pause
        drawnow

    end



end

%**************************************************************************
% END OF FILE
%**************************************************************************
