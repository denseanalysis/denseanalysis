function [seeds,FLAG_seed] = seedparse3(...
    seedinput,qual,mask,seedframe,nbrauto)

%SEEDPARSE3 parse the 'Seed' input of 3D unwrapping functions.
%   unwrap toolbox helper function.
%
%INPUTS
%   seedinput...input parameter from 'Seed'
%       'manual'   manually choose seeds from phase-quality map
%       'auto'     choose highest phase-quality from masked phase-quailty
%       (Nseedx4)  i/j/k/frame user-defined seed points
%   qual........phase quality map                   [NixNjxNk x T]
%   mask........mask to unwrap                      [NixNjxNk x T]
%   seedframe...'manual'/'auto' frame of choice     scalar integer
%   nbrauto.....number of 'auto' seeds              scalar integer
%
%DEFAULT INPUTS
%   seedframe...1
%   nbrauto.....5
%
%OUTPUTS
%   seeds.......valid seed points i/j/k/frame [Nseedx4]
%   FLAG_seed...type of seedinput
%       0 = numeric, 1 = 'manual', 2 = 'auto'
%
%USAGE
%   [SEEDS,FLAG_SEED] = SEEDPARSE3(SEEDINPUT,QUAL,MASK,SEEDFRAME,NBRAUTO)
%   parse the 'Seed' parameter of several functions (UNWRAP3, UNWRAP3MOV)
%   into actual numeric valid seed locations.  If the SEEDINPUT is numeric,
%   we return the valid seeds from the input.  If SEEDINPUT is 'manual',
%   the user may manually select seeds from the masked phase-quality map
%   QUAL (masked by MASK) at the selected SEEDFRAME.  If the SEEDINPUT is
%   'auto', the function automatically chooses NBRAUTO seeds from the
%   masked phase-quality map QUAL (maksed by MASK).  The function returns
%   the valid SEEDS, inside the MASK, as well as a parameter indicating the
%   type of SEEDINPUT.
%
%NOTE ON DISPLAY
%   If the seedinput parameter is 'manual', the phase-quality map
%   corresponding to SEEDFRAME will be displayed as a mosiaic image,
%   on which the user may select any point from any slice.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2008.12     Drew Gilliam
%     --creation


    %% SETUP

    % grid color
    gridclr = [0 1 0];

    % Preference to GETPTS_V2 (if available)
    if exist('getpts_v2','file') == 2
        getptfcn = @(x)getpts_v2(x,'color','r','marker','x',...
            'linewidth',2,'markersize',10);
    else
        getptfcn = @(x)getpts(x);
    end

    % number of inputs
    narginchk(3, 5);

    % default "seedframe" input
    if nargin < 4 || isempty(seedframe)
        seedframe = 1;
        FLAG_seedframe = false;
    else
        FLAG_seedframe = true;
    end

    % default nbrauto
    if nargin < 5 || isempty(nbrauto), nbrauto = 1; end

    % qual & mask of same size
    if ndims(qual) ~= ndims(mask) || any(size(qual) ~= size(mask))
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'phase quality and mask must be of the same size.');
    end

    % 2D or 2Dmov arrays
    if ~any(ndims(qual) == [3 4])
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'phase quality and mask must be 3D or 3Dmov inputs.');
    end

    % sizes
    Vsz = size(qual(:,:,:,1));
    Nfr = size(qual,4);

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

        FLAG_seed = find(strcmpi(seedinput,{'manual','auto'}),1,'first');
        if isempty(FLAG_seed), err = true; end


    % numeric inputs
    elseif isnumeric(seedinput) && ismatrix(seedinput)

        FLAG_seed = 0;
        seeds     = seedinput;
        seedsz    = size(seeds);

        % transpose column vector
        if seedsz(2) == 1
            seeds  = seeds';
            seedsz = seedsz([2 1]);
        end

        % inputs should be [Nseed x 4]
        % [Nseed x 3] is also acceptable, assuming
        % all seeds are on the "seedframe".
        if seedsz(2) ~= 4
            if seedsz(2) == 3
                seeds(:,4) = seedframe;
                FLAG_seedframe = false;
            else
                err = true;
            end
        end

    % general seedinput error
    else
        err = true;
    end

    if err
        error(sprintf('UNWRAP:%s:inputerror',mfilename),...
            'Invalid seed input.');
    end


    % "seedframe" is ignored if numeric inputs
    if FLAG_seedframe && FLAG_seed == 0
        warning(sprintf('UNWRAP:%s:seedframe',mfilename),...
            '''SeedFrame'' input ignored (numeric ''Seed'' input).');
    end



    %% MANUAL/AUTO SEED POINTS

    % get seed point
    switch FLAG_seed

        % manual seed point(s)
        case 1

            % title
            if Nfr > 1
                ttl = sprintf('%s%d\n%s',...
                    'Select seed points from the phase quality map of frame ',...
                    seedframe,'Press Enter to continue');
            else
                ttl = sprintf('%s\n%s',...
                    'Select seed points from the phase quality map below',...
                    'Press Enter to continue');
            end


            % volume montage of current frame
            f = qual(:,:,:,seedframe) .* mask(:,:,:,seedframe);
            [M,msz] = montage_image(reshape(f,[Vsz(1:2) 1 Vsz(3)]));

            % display montage
            hfig = figure;
            haxes = gca;
            imshow(M,[0 1],'init','fit','parent',haxes)
            title(ttl,'fontweight','bold')
            set(haxes,'visible','on',...
                'gridlinestyle','-','xcolor',gridclr,'ycolor',gridclr,...
                'xtick',(1:Vsz(2):Vsz(2)*msz(2)) - 0.5,...
                'ytick',(1:Vsz(1):Vsz(1)*msz(1)) - 0.5,...
                'xticklabel',[],'yticklabel',[]);
            grid(haxes,'on')

            % get points
            [x,y] = getptfcn(gca);
            close(hfig); drawnow
            xy = round([x(:),y(:)]);

            % seed volume indices
            iseed = rem(xy(:,2)-1,Vsz(1)) + 1;
            jseed = rem(xy(:,1)-1,Vsz(2)) + 1;
            kseed = msz(2) * floor((xy(:,2)-1)/Vsz(1)) + ...
                floor((xy(:,1)-1)/Vsz(2)) + 1;

            seeds = [iseed(:), jseed(:), kseed(:), ...
                seedframe*ones(numel(iseed),1)];

        % automatic seed points
        case 2

            % current masked phase-quality map
            f = qual(:,:,:,seedframe);
            f(~mask(:,:,:,seedframe)) = -Inf;

            % find at most nbrauto values
            [val,idx] = sort(f(:),'descend');
            N = min(nbrauto,sum(~isinf(val)));
            idx = idx(1:N);

            % seeds
            [iseed,jseed,kseed] = ind2sub(Vsz,idx(:));
            seeds = [iseed(:), jseed(:), kseed(:), ...
                seedframe*ones(numel(iseed),1)];

    end



    %% SEED POINT VALIDATION

    % unique seeds & 3Dmov indices (same for 3D, where frame=1)
    seeds = sortrows(unique(round(seeds),'rows'),[4 3 1 2]);
    indseeds = seeds(:,1) + Vsz(1)*(seeds(:,2)-1) + ...
        Vsz(2)*Vsz(1)*(seeds(:,3)-1) + Vsz(3)*Vsz(2)*Vsz(1)*(seeds(:,4)-1);

    % valid seed points
    valid = 1<=seeds(:,1) & seeds(:,1)<=Vsz(1) & ...
            1<=seeds(:,2) & seeds(:,2)<=Vsz(2) & ...
            1<=seeds(:,3) & seeds(:,3)<=Vsz(3) & ...
            1<=seeds(:,4) & seeds(:,4)<=Nfr;
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
    if FLAG_seed == 2
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



end % end of function


%**************************************************************************
% END OF FILE
%**************************************************************************
