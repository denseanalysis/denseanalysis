function Iunwrap = unwrap2mov_timepath(...
    Iwrap, Iunwrap, qual, mask, ...
    iseed, jseed, frseed, ...
    searchrad, pxsz, conn, FLAG_display)

%UNWRAP2MOV_TIMEPATH unwraps a path through time in 2D+time imagery
%   starting at a single user defined seed point.
%   Helper function for UNWRAP2MOV.
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
%   Iwrap.........wrapped matrix           [MxNxT]
%   Iunwrap0......initial unwrapped matrix [MxNxT] NaNs except seed points in 1st frame
%   qual..........phase quality            [MxNxT]
%   mask..........mask allowed to unwrap   [MxNxT] logical
%   iseed,jseed...seed point               integer scalars
%   frseed........seed frame               integer scalar
%   searchrad.....allowable spatial distance for seed point unwrapping, integer scalar
%   pxsz..........pixel size [1x3]
%   conn..........connectivity [4|8]
%   FLAG_display..display unwrapping evolution, logical scalar
%
%DEFAULT INPUTS
%   searchrad......2
%   FLAG_display...false
%
%OUTPUT
%   Iunwrap....unwrapped matrix          [MxNxT] NaNs at points not unwrapped)
%
%USAGE
%   IUNWRAP = UNWRAP2MOV_TIMEPATH(IWRAP,IUNWRAP0,QUAL,MASK,
%       ISEED,JSEED,FRSEED,SEARCHRAD,FLAG_DISPLAY)
%
%   Unwraps a path through time from an initial seed point [ISEED,JSEED]
%   defined in frame FRSEED. We are given the 2D+time wrapped imagery
%   IWRAP, an initial unwrapped matrix IUNWRAP0 (containing NaNs at all
%   points not previously unwrapped), the phase quality matrix QUAL, and
%   a binary matrix MASK indiciating valid areas to unwrap.
%
%   SEARCHRAD defines the spatial distance from the seed point we are
%   allowed to search for better phase quality.
%
%   FLAG_DISPLAY controls the visualization of the unwrapping evolution.
%
%   Results are returned in the matrix IUNWRAP. This output contains
%   at least one unrwapped pixel on every frame.
%
%NOTE ON MULTIPLE SEED POINTS
%   This code assumes a single user-defined seed point.  The user may
%   choose multiple seed points and loop the UNWRAP2MOV_TIMEPATH function
%   externally.  If the current time path intersects a previously unwrapped
%   value, that value will be accepted as valid.
%
%NOTE ON MEX FILES
%   This function uses MEX files to significantly decrease execution time.
%   If the user receives errors from these files (quickfind_mex or
%   quickmax_mex), include the following code at the beginning of the
%   m-file script to disable MEX usage:
%       global UNWRAPTOOLBOX_NOMEX;
%       UNWRAPTOOLBOX_NOMEX = true;

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2007.09     Drew Gilliam
%     --creation of "unwrap_timepath" function, derived from
%       "FindPathThroughTime" and "GuidedFloodFillMultipoint" functions
%       by Bruce Spottiswoode (created 2004.11, last modified 2004.12)
%   2008.03     Drew Gilliam
%     --renamed to "unwrap2mov_timepath"
%     --general update
%     --added edge/corner functionality
%   2008.10     Drew Gilliam
%     --added "frseed" input, allowing for the seed point to be selected on
%       an arbitrary frame. required significant modification of code
%     --added ability for time paths to merge (previously unwrapped values
%       are accepted as valid)
%   2008.12     Drew Gilliam
%     --added "UNWRAPTOOLBOX_NOMEX" capability
%   2013.03     Drew Gilliam
%     --added 'Connectivity' input


    %% SETUP

    % check if the user has chosen to not use the faster MEX code
    FLAG_nomex = checknomex();

    % display pause flag
    FLAG_pause = true;

    % check number of inputs, default input
    narginchk(7, 11);
    if nargin < 8 || isempty(searchrad),     searchrad = 2;          end
    if nargin < 9 || isempty(pxsz),          pxsz = [1 1]; end
    if nargin < 10 || isempty(conn),         conn = 4; end
    if nargin < 11 || isempty(FLAG_display), FLAG_display = false;   end

    % check input sizes
    dim = [ndims(Iwrap),ndims(Iunwrap),ndims(qual),ndims(mask)];
    if ~any(dim==2 | dim==3) || ...
       any(size(Iunwrap)~=size(Iwrap)) || ...
       any(size(qual)   ~=size(Iwrap)) || ...
       any(size(mask)   ~=size(Iwrap))
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Input imagery must be 2D+time matrices of equal size.');
    end

    % image size, nbr of frames
    Isz = size(Iwrap(:,:,1));
    Nfr = size(Iwrap,3);

    % check for single seed point
    if any([numel(iseed) numel(jseed) numel(frseed)] ~= 1)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'function accepts only single seed points.');
    end

    % check for valid seed point
    iseed = round(iseed);
    jseed = round(jseed);
    frseed = round(frseed);
    if iseed < 1 || Isz(1) < iseed || ...
       jseed < 1 || Isz(2) < jseed || ...
       frseed < 1 || Nfr < frseed
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'invalid seed point.');
    end

    % ensure ~mask region is not considered
    Iunwrap(~mask) = NaN;

    % mask of unwrapped values
    isunwrap = ~isnan(Iunwrap);

    % check for unwrapped seed point
    if ~isunwrap(iseed,jseed,frseed)
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Seed point is not unwrapped.');
    end

    % variable init
    adjoin  = false([Isz,Nfr]);
    islocal = false([Isz Nfr]);

    % local region
    [I,J] = ndgrid(-searchrad:searchrad);
    D = I.*I + J.*J;
    hlocal = D <= searchrad^2;

    % local region offset
    cent = searchrad + 1;
    [i,j] = find(hlocal);
    local_ioffset = i-cent;
    local_joffset = j-cent;


    % search kernel (based on connectivity request)
    if conn==4
        hnhood = [0 1 0; 1 0 1; 0 1 0];
        hnhood_time = [0 0 0; 0 1 0; 0 0 0];
    else
        hnhood = [1 1 1; 1 0 1; 1 1 1];
%         hnhood_time = [0 0 0; 0 1 0; 0 0 0];

        hnhood_time = [0 1 0; 1 1 1; 0 1 0];
    end

    % spatial neighborhood index offsets
    [i,j] = find(hnhood==1);
    nhood_ioffset = i - 2;
    nhood_joffset = j - 2;

    % temporal neighborhood index offsets
    [i,j] = find(hnhood_time==1);
    nhood_time_ioffset = i - 2;
    nhood_time_joffset = j - 2;

    % quality multiplier: favor unwrapped neighbors that are closer
    % to the current pixel
    qualfac = (nhood_ioffset * pxsz(2)).^2 ...
            + (nhood_joffset * pxsz(1)).^2;
    qualfac = 1./sqrt(qualfac);

    % quality to "double" for quickmax
    qual = double(qual);



    %% UNRWAP TIME PATH

    % display
    if FLAG_display
        hfig = initdisplay;
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

        % frame loop
        for fi = 1:numel(frrng{ci})-1

            % current/next(or last) frame numbers
            fr0 = frrng{ci}(fi);
            fr1 = frrng{ci}(fi+1);

            % determine pixels in search region
            i = i0 + local_ioffset;
            j = j0 + local_joffset;
            ind = i + Isz(1)*(j-1);
            valid = 1<=i & i<=Isz(1) & ...
                    1<=j & j<=Isz(2);

            % search mask
            tmp = false(Isz);
            tmp(ind(valid)) = 1;

            islocal(:) = 0;
            islocal(:,:,fr0) = tmp;
            islocal(:,:,fr1) = tmp;

            % mask islocal area
            islocal = islocal & mask;

            % check for overlapping searchable area after masking
            % (break frame loop on error)
            tmp = conv2(double(islocal(:,:,fr0)),hnhood_time,'same');
            overlap = logical(tmp) & islocal(:,:,fr1);
            if ~any(overlap(:)), disp('no overlap'), break; end

            % initialize adjoin matrix
            tmp = conv2(double(isunwrap(:,:,fr0)),hnhood,'same');
            ad0 = logical(tmp) & ~isunwrap(:,:,fr0) & islocal(:,:,fr0);

            tmp = conv2(double(isunwrap(:,:,fr0)),hnhood_time,'same');
            ad1 = logical(tmp) & islocal(:,:,fr1);

%             tmp = isunwrap(:,:,fr0) & islocal(:,:,fr0);
%             tmp0 = logical(conv2(double(tmp),hnhood,'same'));
%             tmp1 = tmp & islocal(:,:,fr1);
%             tmp0 = tmp0 & ~isunwrap(:,:,fr0) & islocal(:,:,fr0);

            adjoin(:) = 0;
            adjoin(:,:,fr0) = ad0;
            adjoin(:,:,fr1) = ad1;

            % display
            if FLAG_display
                updatedisplay(hfig);
            end

            % repeat unwrapping within the local neighborhood
            % until we move to the next frame
            while 1

                % check for valid adjoining possibilites
                % if there are no adjoining pixels left in the current frame,
                % there should be a valid adjoining pixel in the next frame.
                % Otherwise, we're gonna be stuck.
                if ~any(any(adjoin(:,:,fr0))) && ...
                   ~any(any(adjoin(:,:,fr1)))
                    break;
                end


                % if there is an unwrapped phase within the adjoin matrix
                % on the next frame, find it, move to it, and advance the
                % frame loop
                tf = isunwrap(:,:,fr1) & adjoin(:,:,fr1);
                if any(tf(:))
                    if FLAG_nomex
                        [val,ind] = quickmax(qual(:,:,fr1),tf);
                    else
                        [val,ind] = quickmax_mex(qual(:,:,fr1),tf);
                    end
                    i0 = rem(ind-1,Isz(1)) + 1;
                    j0 = floor((ind-1)/Isz(1)) + 1;
                    break;
                end

                % maximal fr0/fr1 adjoining phase quality
                if FLAG_nomex
                    [val0,ind0] = quickmax(qual(:,:,fr0),adjoin(:,:,fr0));
                    [val1,ind1] = quickmax(qual(:,:,fr1),adjoin(:,:,fr1));
                else
                    [val0,ind0] = quickmax_mex(qual(:,:,fr0),adjoin(:,:,fr0));
                    [val1,ind1] = quickmax_mex(qual(:,:,fr1),adjoin(:,:,fr1));
                end

                % current frame maximal phase quality
                if val0 >= val1

                    % current pixel
                    ind = ind0 + Isz(2)*Isz(1)*(fr0-1);

                    % i/j coordinates
                    i = rem(ind0-1,Isz(1)) + 1;
                    j = floor((ind0-1)/Isz(1)) + 1;

                    % spatial neighbors (current frame)
                    inh = i + nhood_ioffset;
                    jnh = j + nhood_joffset;
                    valid = 1<=inh & inh<=Isz(1) & ...
                            1<=jnh & jnh<=Isz(2);
                    nhood = inh(valid) ...
                          + Isz(1)*(jnh(valid)-1) ...
                          + Isz(2)*Isz(1)*(fr0-1);
                    fac = qualfac(valid);

                    % temporal neighbors (next frame)
                    inh = i + nhood_time_ioffset;
                    jnh = j + nhood_time_joffset;
                    valid = 1<=inh & inh<=Isz(1) & ...
                            1<=jnh & jnh<=Isz(2);
                    nhood_time = inh(valid) ...
                          + Isz(1)*(jnh(valid)-1) ...
                          + Isz(2)*Isz(1)*(fr1-1);

%                     nhood_time = ind0 + Isz(2)*Isz(1)*(fr1-1);

                    FLAG_nextframe = false;

                % next frame maximal phase quality
                else

                    % current pixel
                    ind = ind1 + Isz(2)*Isz(1)*(fr1-1);

                    % i/j coordinates
                    i = rem(ind1-1,Isz(1)) + 1;
                    j = floor((ind1-1)/Isz(1)) + 1;

                    % temporal neighbors (current frame)
                    inh = i + nhood_time_ioffset;
                    jnh = j + nhood_time_joffset;
                    valid = 1<=inh & inh<=Isz(1) & ...
                            1<=jnh & jnh<=Isz(2);
                    nhood = inh(valid) ...
                          + Isz(1)*(jnh(valid)-1) ...
                          + Isz(2)*Isz(1)*(fr0-1);
                    fac = qualfac(valid);

%                     nhood = ind1 + Isz(2)*Isz(1)*(fr0-1);
%                     fac   = 1;

                    FLAG_nextframe = true;
                end

                % unwrapped local neighbors
                tf = isunwrap(nhood) & islocal(nhood);
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

                        % quality factor (distance factor times phase quality)
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

                % update adjoin matrix
                if ~FLAG_nextframe
                    adjoin(ind)   = 0;
                    adjoin(nhood) = ~isunwrap(nhood) & islocal(nhood);
                    adjoin(nhood_time) = islocal(nhood_time);
                end

                % display
                if FLAG_display && ~FLAG_nextframe
                    updatedisplay(hfig);
                end

            end

        end % end frame loop

    end % end cell loop

    if FLAG_display
        updatedisplay(hfig);
        if FLAG_pause
            pause
        else
            pause(5);
        end
        if ishandle(hfig), close(hfig); end
        drawnow
    end

    % check to ensure at least one pixel on each frame is unwrapped
    tf = any(any(~isnan(Iunwrap)));
    if ~all(tf)
        error(sprintf('UNWRAP:%s:unwrapping_problem',mfilename),...
            'One pixel on each frame not unwrapped.')
    end

    return



    %% INITIALIZE DISPLAY
    function hfig = initdisplay
        indmask = find(any(mask,3));
        [i,j] = ind2sub(Isz,indmask);

        % mask limits
        idisplay = min(i(:)):max(i(:));
        jdisplay = min(j(:)):max(j(:));
        Dsz = [idisplay(end)-idisplay(1)+1,...
               jdisplay(end)-jdisplay(1)+1];

        [zeroimage,msz] = montage_image(zeros([Dsz,1,Nfr]));

        hfig = figure;
        haxes(1) = subplot(1,2,1);
        hI(1) = imshow(zeroimage,4*[-pi pi],'init','fit');
        title('Unwrapped Imagery Montage [-4\pi 4\pi]','fontweight','bold');
        haxes(2) = subplot(1,2,2);
        hI(2) = imshow(zeroimage(:,:,[1 1 1],:),[0 1],'init','fit');
        title('Workspace (gray=mask, blue=search region, red=adjoin)','fontweight','bold');
        linkaxes(haxes);

        set(haxes,'visible','on',...
            'gridlinestyle','-','xcolor','w','ycolor','w',...
            'xtick',(1:Dsz(2):Dsz(2)*msz(2)) - 0.5,...
            'ytick',(1:Dsz(1):Dsz(1)*msz(1)) - 0.5,...
            'xticklabel',[],'yticklabel',[]);
        grid(haxes(1),'on'),grid(haxes(2),'on');

        figdata = struct(...
            'idisplay', idisplay,...
            'jdisplay', jdisplay,...
            'hI',       hI,...
            'Dsz',      Dsz,...
            'msz',      msz);
        guidata(hfig,figdata);
    end


    %% UPDATE DISPLAY
    function updatedisplay(hfig)
        if ~ishandle(hfig)
            FLAG_display = false;
            return
        end
        data = guidata(hfig);

        idisplay = data.idisplay;
        jdisplay = data.jdisplay;
        hI = data.hI;
        Dsz = data.Dsz;

        tmp = isfinite(Iunwrap);

        A = reshape(    mask(idisplay,jdisplay,:), [Dsz,1,Nfr]);
        B = reshape( islocal(idisplay,jdisplay,:), [Dsz,1,Nfr]);
        C = reshape(  adjoin(idisplay,jdisplay,:), [Dsz,1,Nfr]);
        D = reshape(     tmp(idisplay,jdisplay,:), [Dsz,1,Nfr]);

        L = zeros(size(A));
        L(A) = 1;
        L(B) = 2;
        L(C) = 3;
        L(D) = 4;

        red   = 0.25*(L==1) + 0.00*(L==2) + 1.00*(L==3) + 0.00*(L==4);
        green = 0.25*(L==1) + 0.00*(L==2) + 0.00*(L==3) + 1.00*(L==4);
        blue  = 0.25*(L==1) + 1.00*(L==2) + 0.00*(L==3) + 0.00*(L==4);

        adjdisp = cat(3,red,green,blue);
        Ireshape = reshape(Iunwrap(idisplay,jdisplay,:),[Dsz,1,Nfr]);

        set(hI(1),'Cdata',montage_image(Ireshape,'size',data.msz));
        set(hI(2),'Cdata',montage_image(adjdisp, 'size',data.msz));
        drawnow

        if FLAG_pause
            pause
        else
            pause(0.1);
        end
    end



end % end function


%**************************************************************************
% END OF FILE
%**************************************************************************
