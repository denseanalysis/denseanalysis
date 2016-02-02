function seeds = seedparse2(api)

%SEEDPARSE2 parse the 'Seed' input of 2D unwrapping functions.
%   unwrap toolbox helper function.
%
%INPUTS
%   api.........application data structure, including the following fields
%     seedinput.....input parameter from 'Seed'
%       'manual'    manually choose seeds from phase-quality map
%       'auto'      choose highest phase-quality from masked phase-quailty
%       (Nseedx3)   row/col/frame user-defined seed points
%     mask..........mask to unwrap                      [MxNxT]
%     seedframe.....'manual'/'auto' frame of choice     scalar integer
%     Iwrap.........wrapped image frame                 [MxN]
%     qual..........phase quality frame                 [MxN]
%     nbrauto.......number of 'auto' seeds              scalar integer
%     name..........'manual' seedinput figure display name
%
%DEFAULT INPUTS
%   seedframe...1
%   nbrauto.....5
%
%OUTPUTS
%   seeds.......valid seed points i/j/frame [Nseedx3]
%
%USAGE
%   SEEDS = SEEDPARSE2(API)
%   parse the 'Seed' parameter of several functions (UNWRAP2, UNWRAP2MOV)
%   into actual numeric valid seed locations, using the application data
%   API.  If the SEEDINPUT is numeric, we return the valid seeds from the
%   input.  If SEEDINPUT is 'manual', the user may manually select seeds
%   from the masked wrapped image IWRAP (masked by MASK) at the selected
%   SEEDFRAME.  If the SEEDINPUT is 'auto', the function automatically
%   chooses NBRAUTO seeds from the masked phase-quality map QUAL (maksed
%   by MASK).  The function returns the valid SEEDS, inside the MASK, as
%   well as a parameter indicating the type of SEEDINPUT.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2008.12     Drew Gilliam
%     --creation
%   2009.03     Drew Gilliam
%     --switch to "api" from multiple inputs


    %% SETUP

    % 'auto' display colors for region outside mask
    blk = [0.00 0.00 0.25];
    wht = [0.50 0.50 1.00];

    % Preference to GETPTS_V2 (if available)
    if exist('getpts_v2','file') == 2
        getptfcn = @(x)getpts_v2(x,'color','r','marker','x',...
            'linewidth',2,'markersize',10);
    else
        getptfcn = @(x)getpts(x);
    end


    % default values
    defapi = struct(...
        'seedinput',    [],...
        'mask',         [],...
        'seedframe',    [],...
        'Iwrap',        [],...
        'qual',         [],...
        'nbrauto',      1,...
        'name',         '');

    % parse new input api
    api = parseinputs(...
        fieldnames(defapi),struct2cell(defapi),api);

    % copy input api to variables
    seedinput = api.seedinput;
    mask      = api.mask;
    seedframe = api.seedframe;
    Iwrap     = api.Iwrap;
    qual      = api.qual;
    nbrauto   = api.nbrauto;
    name      = api.name;

    % validate mask/Iwrap/qual
    Isz = size(mask(:,:,1));
    Nfr = size(mask,3);

    wsz = size(Iwrap);
    qsz = size(qual);
    sz  = [Isz Nfr];

    if ~any(ndims(mask) == [2 3])
        errstr = 'Mask must be an [MxNxT] matrix.';
    elseif ~any(ndims(Iwrap)==[2,3]) || any(wsz~=sz(1:numel(wsz)))
        errstr = 'Wrapped imagery must be [MxN] matrix.';
    elseif ~any(ndims(qual)==[2,3]) || any(qsz~=sz(1:numel(qsz)))
        errstr = 'phase quality must be [MxN] matrix.';
    end

    if exist('errstr','var')
        error(sprintf('%s:invalidInput',mfilename),errstr);
    end


    % validate "seedframe" input
    if isempty(seedframe)
        seedframe = 1;
        FLAG_seedframe = false;
    else
        FLAG_seedframe = true;
    end

    % validate "seedframe"
    if ~isnumeric(seedframe) || numel(seedframe) > 1 || ...
       seedframe < 1 || Nfr < seedframe
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'invalid seedframe.');
    end



    %% PARSE "seedinput" parameter
    err = false;

    % 'manual' or 'auto' inputs
    if ischar(seedinput)
        if ~any(strcmpi(seedinput,{'manual','auto'}))
            err = true;
        end

    % numeric inputs
    elseif isnumeric(seedinput) && ismatrix(seedinput)

        % seed information
        seeds     = seedinput;
        seedsz    = size(seeds);

        % transpose column vector
        if seedsz(2) == 1
            seeds  = seeds';
            seedsz = seedsz([2 1]);
        end

        % inputs should be [Nseed x 3]
        % [Nseed x 2] is also acceptable, assuming
        % all seeds are on the "seedframe".
        if seedsz(2) ~= 3
            if seedsz(2) == 2
                seeds(:,3) = seedframe;
                FLAG_seedframe = false;
            else
                err = true;
            end
        end

        % "seedframe" is ignored if numeric inputs
        if ~err && FLAG_seedframe
            warning(sprintf('UNWRAP:%s:seedframe',mfilename),...
                '''SeedFrame'' input ignored (numeric ''Seed'' input).');
        end

    % general seedinput error
    else
        err = true;
    end

    if err
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Invalid seed input.');
    end




    %% MANUAL/AUTO SEED POINTS

    % manual seed point(s)
    if isequal(seedinput,'manual')

        % title
        if Nfr > 1
            str = sprintf(' from frame %d',seedframe);
        else
            str = [];
        end
        ttl = sprintf('%s%s\n%s',...
            'Select unwrapped pixels within the region of interest',...
            str,'Press Enter to continue');

        % color image
        if size(Iwrap,3) > 1
            im = (Iwrap(:,:,seedframe) + pi)/(2*pi);
        else
            im = (Iwrap + pi)/(2*pi);
        end
        tf = mask(:,:,seedframe);
        R = tf.*im + ~tf.*((im*(wht(1)-blk(1))) + blk(1));
        G = tf.*im + ~tf.*((im*(wht(2)-blk(2))) + blk(2));
        B = tf.*im + ~tf.*((im*(wht(3)-blk(3))) + blk(3));

        % display range
        brdr = 5;
        [i,j] = find(tf);
        xy = [j(:),i(:)];
        rng = [max(1,min(xy)-brdr); min(Isz([2 1]),max(xy)+brdr)];

        % open figure
        hfig = figure('WindowStyle','modal','NumberTitle','off',...
            'Name','Unwrapped Pixel Selection');

        % display
        imshow(cat(3,R,G,B),[0 1],'init','fit');
        hax = gca;
        title(ttl,'fontweight','bold');
        axis(hax, rng(:)' + [-0.5 0.5 -0.5 0.5]);

        % update axes position
        pos = getpixelposition(hax);
        pos(4) = 0.95*pos(4);
        setpixelposition(hax,pos);

        % figure name
        if ~isempty(name)
            set(hfig,'Name',[name ': Unwrapped Pixel Selection']);
        end

        % get points
        [x,y] = getptfcn(gca);
        close(hfig); drawnow;
        seeds = [round(y(:)), round(x(:)), seedframe*ones(numel(x),1)];


    % automatic seed points
    elseif isequal(seedinput,'auto')

        % current masked phase-quality map
        if size(qual,3) > 1
            f = qual(:,:,seedframe);
        else
            f = qual;
        end
        f(~mask(:,:,seedframe)) = -Inf;

        % find at most nbrauto values
        [val,idx] = sort(f(:),'descend');
        N = min(nbrauto,sum(~isinf(val)));
        idx = idx(1:N);

        % seeds
        [iseed,jseed] = ind2sub(Isz,idx(:));
        seeds = [iseed(:), jseed(:), ...
            seedframe*ones(numel(iseed),1)];

    end



    %% SEED POINT VALIDATION

    % unique seeds & 2Dmov indices (same for 2D, where frame=1)
    seeds = sortrows(unique(round(seeds),'rows'),[3 1 2]);
    indseeds = seeds(:,1) + Isz(1)*(seeds(:,2)-1) + Isz(2)*Isz(1)*(seeds(:,3)-1);

    % valid seed points
    valid = 1<=seeds(:,1) & seeds(:,1)<=Isz(1) & ...
            1<=seeds(:,2) & seeds(:,2)<=Isz(2) & ...
            1<=seeds(:,3) & seeds(:,3)<=Nfr;
    valid(valid) = mask(indseeds(valid));

    % valid seeds
    seeds = seeds(valid,:);

    % no valid seeds = error
    if isempty(seeds);
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'No valid seed points selected within mask.');
    end

    % auto - less than requested number of seeds
    % manual/numeric - some seeds were bad.
    if isequal(seedinput,'auto')
        if size(seeds,1) < nbrauto
            warning(sprintf('UNWRAP:%s:seedwarning',mfilename),...
                'Returning fewer seed points than requested.');
        end
    else
        if any(~valid)
            warning(sprintf('UNWRAP:%s:seedwarning',mfilename),...
                'One or more invalid seed points selected.');
        end
    end

    % allow display to update
    drawnow;
    pause(eps);


end % end of function



%% END OF FILE=============================================================
