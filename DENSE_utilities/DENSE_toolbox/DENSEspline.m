function metadata = DENSEspline(varargin)

%DENSEspline unwrap & spline DENSE imagery
%
%REQUIRED INPUT PARAMETERS
%
%   Xpha/Ypha/Zpha..x/y/z phase data
%       ([RxCxN] double matrices, all values on the range [-pi,pi])
%
%   PixelSpacing...[i/j] pixel spacing in (mm/pixel)
%
%   EncFreq........[xpha/ypha] DENSE encoding frequency
%
%   Scale..........[xpha/ypha] DENSE scale
%
%   Contour........[NxNcontor] cell array of contour data from all frames,
%       each cell containing a 2D contour definition
%       in base-1 pixel coordinates
%
%   MaskFcn...function defining the region of interest
%       See below for more information.
%
%OPTIONAL INPUT PARAMETERS
%
%   FramesForAnalysis...frame range for analysis [min,max]
%       defaults to [1,NumberOfFrames]
%
%   ResampleMethod......spatial resampling method
%       defaults to 'gridfit', [gridfit|tpaps]
%
%   ResampleDistance....spatial resampling distance in pixels
%       defaults to 1, see below for more information
%
%   SpatialSmoothing....spatial smoothing parameter between [0,1]
%       0 = no smoothing, 1 = maximum smoothing.
%       defaults to "0.5" for GRIDFIT resampling method, and
%       "0.9" for TPAPS resampling method
%
%   TemporalOrder...order of temporal polynomial fit (positive integer)
%       higher value = more temporal frequencies / less smooth
%       defaults to an order of 10.
%
%   SeedFrame...........primary frame of interest
%       used for phase-unwrapping (when Xseed/Yseed/Zseed are not
%       specified) and to define the resting configuration.
%       defaults to 1 (the first frame)
%
%   Xseed/Yseed/Zseed...x/y/z-phase unwrapping seeds (each [1x3])
%       specified in [i,j,frame] coordinates.  If not entered, seeds for
%       each encoding direction will be manually defined on "SeedFrame".
%
%   Mask...........overriding unwrap mask
%
%   OptionsPanel........display options panel for smoothing parameter and
%       manual seed selection (on SeedFrame) when "true".
%       Defaults to "false"
%
%   UnwrapConnectivity....pixel connectivity for unwrapping [4|8]
%       Defaults to 4
%
%
%OUTPUTS
%
%   metadata.......spline data structure, containing at least the following:
%       XYZValid.....[1x3] logical indicating available phase information
%       Xwrap/Ywrap/Zwrap.........[RxCxN] wrapped phase imagery
%       Xunwrap/Yunwrap/Zunwrap...[RxCxN] unwrapped phase imagery
%       Multipliers...............[1x3] phase-to-pixel multipliers
%       spldx/spldy/spldx.........output splines (see below for more info)
%       irng/jrng/frrng...........i/j/frame range on which spline is specifed
%       ResampleMethod............spatial resampling method
%       ResampleDistance..........spatial resampling distance
%       SpatialSmooting...........spatial smoothing parameter
%       TemporalOrder.............order of temporal polynomial fit
%       Xseed/Yseed/Zseed.........unwrapping seeds
%
%
%USAGE
%
%   METADATA = DENSESPLINE(OPTIONS) extrapolate tissue motion within a
%   specified region of interest throughout a DENSE image sequence.
%   OPTIONS is a structure containing any or all of the input
%   fields specifed above. Required inputs include X, Y, and/or Z phase
%   information, pixel spacing, DENSE encoding frequencies, DENSE scale
%   values, contours on all frames, and a function indicating how to
%   recover the region of interest mask from that contour.
%
%   METADATA = DENSESPLINE(...,'param',val,...) Inputs may also be offered
%   in the typical MATLAB parameter/value pairs.
%
%
%NOTE ON DEFORMATION RECOVERY
%
%   The most important output of the METADATA structure are the "spldx",
%   "spldy" and "spldz" fields, specifying the deformation of any [x0,y0]
%   point within the resting configuration at all times within the image
%   sequence.
%
%   **********IMPORTANT**********
%   THE SPLINES "spldx", "spldy", "spldz" ARE DEFINED IN [i,j,frame]
%   COORDINATES AND RETURN THE [x,y,z] DEFORMATION, RESPECTIVELY.
%   *****************************
%
%   To recover the x/y/z position of Npt points within the resting
%   configuration, specifed by the [Npt x 1] vectors x0 & y0 (with
%   all(z0==0)), at some later frame "frame", use the  following code
%   (NOTE THE REVERSAL OF X/Y into I/J!!!!):
%
%       Npt = numel(x0);
%       ij0 = [y0(:), x0(:), frame*ones(Npt,1)]';
%       dx = fnvalmod(metadata.spldx,ij0);  x = x0(:)+dy(:);
%       dy = fnvalmod(metadata.spldy,ij0);  y = y0(:)+dy(:);
%       dz = fnvalmod(metadata.spldz,ij0);  z = dz(:);
%
%
%NOTE ON ALGORITHM
%
%   This function consolidates a number of algorithms into a single-shot
%   DENSE analysis, including DENSE unwrapping and deformation recovery
%   within the complete region of interest via spatial & temporal
%   smoothing techniques.
%
%   We first assume that the user has access to DENSE phase imagery
%   (DENSE phase image sequences, all values on the range [-pi,pi])
%   and defined a region of interest on every frame.
%
%   We first unwrap the DENSE imagery via the UNWRAP2MOV function (see this
%   function for more information).  This produces a set of displacement
%   vectors on each frame of the input sequence.
%
%   We next resample the displacement vectors of each frame within a
%   rectangular region enclosing the region of interest. Two separate
%   techniques can be used for this resampling: thin plate smoothing
%   splines via TPAPS or the MATLAB file exchange GRIDFIT function. The
%   amount of spatial smoothing on each frame is controlled via a
%   user-specifed smoothing parameter on the range (0,1]. A smoothing
%   value of zero represents no smoothing; a smoothing value of one
%   represents maximum smoothing (resulting in the least-squares
%   approximation to the data). We resample each frame at an even set
%   of spatial locations within a rectangular region encapsulating the
%   entire contour configuration.  The resampling distance is defined by
%   the "ResampleDistance" parameter.
%
%   After spatial resampling, we are left with a set of tissue trajectories
%   originating within a uniformly sampled rectangular region. We fit each
%   trajectory to a temporal polynomial function of user-specified order.
%   For example, if "TemporalOrder" is 3, the "ith" trajectory as a
%   function of time is given by:
%       trj.ith(t) = a0i + a1i*t + a2i*t^2 + a3i*t^3
%   We generate polynomial coefficents for each trajectory within the
%   rectangular region. We finally interpolate these coefficent maps
%   between the resampled origins via an exact cubic spline.
%
%
%NOTE ON SPATIAL SMOOTHING PARAMETER CHOICE
%
%   The smoothing parameter ('SpatialSmoothing') range is fairly intuitive:
%   0 = no smoothing, 1 = maximal smoothing.  This parameter differs from
%   both the TPAPS and GRIDFIT functions. Let P be the smoothing parameter
%   as it is defined in this function. The corresponding TPAPS smoothing
%   parameter is (1-P), while the corresponding GRIDFIT 'smoothness'
%   parameter is (P/(1-P)).
%
%   Note also that the smoothing paramter affects these two resampling
%   methods differently, as reflected in the default values associated
%   with each method. A P-value of 0.5 is the default for the GRIDFIT
%   method, while a P-value of 0.9 is the efault for TPAPS.
%
%   Note additionally that we do not allow the case of zero smoothing, as
%   GRIDFIT requires a positive smoothness value.
%

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2009.03     Drew Gilliam
%     --creation
%   2009.05     Drew Gilliam
%     --transition to polynomial fit in time
%     --addition of GRIDFIT for spatial fitting
%   2013.03     Drew Gilliam
%     --added 'UnwrapConnectivity' input


    %% INPUT CHECK
    errid = sprintf('%s:invalidInput',mfilename);

    % all default arguments
    defargs = struct(...
        'Xpha',                 [],...
        'Ypha',                 [],...
        'Zpha',                 [],...
        'PixelSpacing',         [],...
        'EncFreq',              [],...
        'Scale',                [],...
        'Contour',              [],...
        'MaskFcn',              [],...
        'Mask',                 [],...
        'FramesForAnalysis',    [],...
        'ResampleMethod',       'gridfit',...
        'ResampleDistance',     1,...
        'SpatialSmoothing',     [],...
        'TemporalOrder',        10,...
        'SeedFrame',            [],...
        'Xseed',                [],...
        'Yseed',                [],...
        'Zseed',                [],...
        'OptionsPanel',         false,...
        'UnwrapConnectivity',   []);

    % parse inputs
    [api,other_args] = parseinputs(defargs,[],varargin{:});



    % VALIDATE-------------------------------------------------------------
    % Xpha, Ypha, Zpha

    % stage 1 check
    checkfcn = @(p)isempty(p) || (isfloat(p) && any(ndims(p)==[2 3]));
    if ~checkfcn(api.Xpha)
        error(errid,'Invalid X-phase data');
    elseif ~checkfcn(api.Ypha)
        error(errid,'Invalid Y-phase data');
    elseif ~checkfcn(api.Zpha)
        error(errid,'Invalid Z-phase data');
    end

    % stage 2 check
    tags = {'Xpha','Ypha','Zpha'};
    xyzvalid = cellfun(@(tag)~isempty(api.(tag)),tags);
    idx = find(xyzvalid,1,'first');

    if ~any(xyzvalid)
        error(errid,'All phase fields are empty!');
    end

    % image size / number of frames
    Isz = size(api.(tags{idx})(:,:,1));
    Nfr = size(api.(tags{idx}),3);

    % stage 3 check
    checkfcn = @(p)all(size(p(:,:,1))==Isz) && size(p,3)==Nfr && ...
        all(-pi <= p(:) & p(:) <= pi);
    for ti = 1:numel(tags)
        if xyzvalid(ti)
            if ~checkfcn(api.(tags{ti}))
                error(errid,'Invalid %s-phase data.',tags{ti}(1));
            end
        end
    end

    % image space
    x = 1:Isz(2);
    y = 1:Isz(1);
    [X,Y] = meshgrid(x,y);



    % VALIDATE-------------------------------------------------------------
    % PixelSpacing, EncFreq, Scale

    checkparamFcn = @(x,tf)~isempty(x) && isnumeric(x) && ...
        numel(x) == numel(tf) && all(isfinite(x(tf))) && all(x(tf) > 0);

    if ~checkparamFcn(api.PixelSpacing,[true true])
        error(errid,'Invalid PixelSpacing.');
    elseif api.PixelSpacing(1) ~= api.PixelSpacing(2)
        error(errid,'Invalid PixelSpacing - square pixels only.');
    elseif ~checkparamFcn(api.EncFreq,xyzvalid)
        error(errid,'Invalid EncFreq.');
    elseif ~checkparamFcn(api.Scale,xyzvalid)
        error(errid,'Invalid Scale.');
    end

    % x/y/z mutlipliers
    pxsz = api.PixelSpacing(1);
    fcn = @(scidx,efidx)1 / (2*pi*api.Scale(scidx)*...
        api.EncFreq(efidx)*pxsz);
    xfac = fcn(1,1);
    yfac = fcn(2,2);
    zfac = fcn(3,3);

    xfac(isnan(xfac)) = 0;
    yfac(isnan(yfac)) = 0;
    zfac(isnan(zfac)) = 0;


    % VALIDATE-------------------------------------------------------------
    % Contour, MaskFcn, Mask

    % input mask or Contour/MaskFcn check
    if ~isempty(api.Mask)
        if ~isempty(api.Contour) || ~isempty(api.MaskFcn)
            error(errid,'Cannot supply both Mask and Contour/MaskFcn.');
        end
        mask = api.Mask;


    else

        % check contour data
        C = api.Contour;
        if isempty(C) || ~iscell(C) || ndims(C)~=2 || size(C,1)~=Nfr
            error(errid,'Invalid Contour data.');
        end

        tfvalid = cellfun(@(c)(~isempty(c) && isnumeric(c) && ...
            ndims(c)==2 && size(c,2)==2), C);
        tfvalid = all(tfvalid,2);

        % MaskFcn
        maskfcn = api.MaskFcn;
        if isempty(maskfcn) || ~isa(maskfcn,'function_handle')
            error(errid,'Invalid MaskFcn.');
        end

        try
            mask = false([Isz,Nfr]);
            for fr = 1:Nfr
                if tfvalid(fr)
                    mask(:,:,fr) = maskfcn(X,Y,C(fr,:));
                end
            end
        catch ERR
            ME = MException(errid,'The MaskFcn failed.');
            ME.addCause(ERR);
            throw(ME);
        end

    end

    % check Mask
    checkfcn = @(m)islogical(m) && any(ndims(m)==[2 3]) && ...
        all(size(m(:,:,1))==Isz) && size(m,3)==Nfr;
    if ~checkfcn(mask)
        error(errid,'Invalid Mask');
    end


    % all valid frames
    tfvalid = squeeze(any(any(mask)));
    frvalid = find(tfvalid);
    frvalid = frvalid([1 end])';
    if ~all(tfvalid(frvalid(1):frvalid(end)))
        error(errid,'The ROI is not defined on a continuous frame range.');
    end


    % VALIDATE-------------------------------------------------------------
    % FramesForAnalysis, SeedFrame

    % FramesForAnalysis
    checkfcn = @(x)isnumeric(x) && numel(x)==2 && ...
        all(mod(x,1)==0) && x(2)>=x(1) && ...
        all(frvalid(1)<=x & x<=frvalid(end));

    if isempty(api.FramesForAnalysis)
        api.FramesForAnalysis = frvalid;
    end

    frrng = api.FramesForAnalysis;
    if ~checkfcn(api.FramesForAnalysis)
        error(errid,'Invalid FramesForAnalysis.');
    end

    % SeedFrame
    seedframe = api.SeedFrame;
    if isempty(seedframe), seedframe = frrng(1); end

    if ~isnumeric(seedframe) || ~isscalar(seedframe) || ...
       mod(seedframe,1)~=0 || seedframe<frrng(1) || frrng(2)<seedframe
        error(errid,'Invalid SeedFrame.');
    end



    % VALIDATE-------------------------------------------------------------
    % ResampleMethod, ResampleDistance, SpatialSmoothing,
    % TemporalOrder, UnwrapConnectivity

    % spatial resampling method
    checkfcn = @(x)ischar(x) && any(strcmpi(x,{'gridfit','tpaps'}));
    method = api.ResampleMethod;

    if ~checkfcn(method)
        error(errid,'ResampleMethod must be [gridfit|tpaps].');
    end

    % spatial resampling distance
    checkfcn = @(x)isnumeric(x) && isscalar(x) && x>0;
    dresamp = api.ResampleDistance;

    if ~checkfcn(dresamp)
        error(errid,'Invalid ResampleDistance');
    end

    % spatial smoothing parameter
    checkfcn = @(x)isempty(x) || ...
        (isfloat(x) && isscalar(x) && 0<x && x<=1);

    pspace = api.SpatialSmoothing;
    if ~checkfcn(pspace)
        error(errid,'SpatialSmoothing must be a scalar on (0,1].');
    end

    if isempty(pspace)
        if isequal(method,'gridfit');
            pspace = 0.50;
        else
            pspace = 0.90;
        end
    end

    % parse temporal polynomial order
    checkfcn = @(x)isnumeric(x) && isscalar(x) && mod(x,1)==0 ...
        && (x>0 || x==-1);
    Npoly = api.TemporalOrder;
    if ~checkfcn(Npoly)
        error(errid,'TemporalOrder must be a positive integer.');
    end

    % parse connectivity
    conn = api.UnwrapConnectivity;
    if ~isempty(conn) && ...
       (~isnumeric(conn) || ~isscalar(conn) || ~any(conn==[4 8]))
        error(errid,'UnwrapConnectivity accepts [4|8].');
    end


    % VALIDATE-------------------------------------------------------------
    % Xseed, Yseed, Zseed

    % parse seeds
    xseed = api.Xseed;
    yseed = api.Yseed;
    zseed = api.Zseed;

    checkfcn = @(x)isnumeric(x) && ndims(x)==2 && ...
        size(x,2)==3 && all(mod(x(:),1)==0) && ...
        all(1<=x(:,1) & x(:,1)<=Isz(1)) && ...
        all(1<=x(:,2) & x(:,2)<=Isz(2)) && ...
        all(frrng(1)<=x(:,3) & x(:,3)<=frrng(2));

    if ~isempty(xseed) && ~checkfcn(xseed)
        error(errid,'Invalid Xseed.');
    elseif ~isempty(yseed) && ~checkfcn(yseed)
        error(errid,'Invalid Yseed.');
    elseif ~isempty(zseed) && ~checkfcn(zseed)
        error(errid,'Invalid Zseed.');
    end

    % remove seeds not within the mask
    % we do not throw an error if the seeds are invalid, we just
    % eliminate them.  This allows users to try and use the last seed
    % points they specified even if they have updated the mask.
    idxfcn = @(x)x(:,1) + Isz(1)*(x(:,2)-1) + Isz(2)*Isz(1)*(x(:,3)-1);
    checkfcn = @(x)x(mask(idxfcn(x)),:);

    if ~isempty(xseed), xseed = checkfcn(xseed); end
    if ~isempty(yseed), yseed = checkfcn(yseed); end
    if ~isempty(zseed), zseed = checkfcn(zseed); end



    %% OPTIONS PANEL
    if isequal(api.OptionsPanel,true)

        % locate single ij seeds from "seedframe"
        seeds = {xseed,yseed,zseed};
        for k = 1:3
            if isempty(seeds{k})
                continue;
            elseif size(seeds{k},2) ~= 2
                tf = (seeds{k}(:,3)==seedframe);
                seeds{k} = seeds{k}(tf,[1 2]);
            end
        end

        % create application data
        str = sprintf('Analysis Parameters: Frame %d',seedframe);
        options = struct(...
            'Name',             str,...
            'SeedFrame',        seedframe,...
            'Xpha',             api.Xpha,...
            'Ypha',             api.Ypha,...
            'Zpha',             api.Zpha,...
            'Mask',             mask,...
            'ValidFrames',      frvalid,...
            'FramesForAnalysis',frrng,...
            'ResampleMethod',   method,...
            'SpatialSmoothing', pspace,...
            'TemporalOrder',    Npoly,...
            'Xseed',            seeds{1},...
            'Yseed',            seeds{2},...
            'Zseed',            seeds{3});

        % pass to interactive options panel
        options = splinemodel(options);

        % return on cancel
        if isempty(options)
            metadata = [];
            return
        end

        % save new values
        method = options.ResampleMethod;
        pspace = options.SpatialSmoothing;
        Npoly  = options.TemporalOrder;
        xseed  = options.Xseed;
        yseed  = options.Yseed;
        zseed  = options.Zseed;
        frrng  = options.FramesForAnalysis;

        % append "seedframe" to returned seeds
        if ~isempty(xseed), xseed(:,3) = seedframe; end
        if ~isempty(yseed), yseed(:,3) = seedframe; end
        if ~isempty(zseed), zseed(:,3) = seedframe; end

    end

    % final check
    tfframes = false(1,Nfr);
    tfframes(frrng(1):frrng(2)) = true;

    if ~tfframes(seedframe)
        error(errid,'SeedFrame is not within FramesForAnalysis.');
    end
    if ~isempty(xseed)
        xseed = xseed(tfframes(xseed(:,3)),:);
        if isempty(xseed)
            error(errid,'No xseed within the FramesForAnalysis.');
        end
    end
    if ~isempty(yseed)
        yseed = yseed(tfframes(yseed(:,3)),:);
        if isempty(yseed)
            error(errid,'No xseed within the FramesForAnalysis.');
        end
    end
    if ~isempty(zseed)
        zseed = zseed(tfframes(zseed(:,3)),:);
        if isempty(zseed)
            error(errid,'No xseed within the FramesForAnalysis.');
        end
    end

    xseed, yseed, zseed


    %% UNWRAP DENSE & GENERATE DISPLACEMENT MATRICES

    % unwrap2mov seed input
    shft = find(tfframes,1,'first')-1;
    manualseed = {'seed','manual','seedframe',seedframe-shft};
    if isempty(xseed)
        xseedinput = manualseed;
    else
        tmp = xseed;
        tmp(:,3) = tmp(:,3) - shft;
        xseedinput = {'seed',tmp};
    end
    if isempty(yseed)
        yseedinput = manualseed;
    else
        tmp = yseed;
        tmp(:,3) = tmp(:,3) - shft;
        yseedinput = {'seed',tmp};
    end
    if isempty(zseed)
        zseedinput = manualseed;
    else
        tmp = zseed;
        tmp(:,3) = tmp(:,3) - shft;
        zseedinput = {'seed',tmp};
    end

    % unwrap X data
    if xyzvalid(1)
        Xwrap = api.Xpha;
        Xunwrap = zeros([Isz,Nfr]);
        [Xunwrap(:,:,tfframes),xseed] = unwrap2mov(...
            Xwrap(:,:,tfframes),...
            'mask',      mask(:,:,tfframes),...
            'PixelSize', api.PixelSpacing(1:2),...
            'Name',      'X-phase:',...
            'Connectivity',api.UnwrapConnectivity,...
            xseedinput{:});
        xseed(:,3) = xseed(:,3)+shft;
    else
        xseed = [];
        Xwrap = zeros([Isz,Nfr]);
        Xwrap(~mask) = NaN;
        Xunwrap = Xwrap;
    end

    % unwrap Y data
    if xyzvalid(2)
        Ywrap = api.Ypha;
        Yunwrap = zeros([Isz,Nfr]);
        [Yunwrap(:,:,tfframes),yseed] = unwrap2mov(...
            Ywrap(:,:,tfframes),...
            'mask',      mask(:,:,tfframes),...
            'PixelSize', api.PixelSpacing(1:2),...
            'Name',      'Y-phase:',...
            'Connectivity',api.UnwrapConnectivity,...
            yseedinput{:});
        yseed(:,3) = yseed(:,3)+shft;
    else
        yseed = [];
        Ywrap = zeros([Isz,Nfr]);
        Ywrap(~mask) = NaN;
        Yunwrap = Ywrap;
    end

    % unwrap Z data
    if xyzvalid(3)
        Zwrap = api.Zpha;
        Zunwrap = zeros([Isz,Nfr]);
        [Zunwrap(:,:,tfframes),zseed] = unwrap2mov(...
            Zwrap(:,:,tfframes),...
            'mask',      mask(:,:,tfframes),...
            'PixelSize', api.PixelSpacing(1:2),...
            'Name',      'Z-phase:',...
            'Connectivity',api.UnwrapConnectivity,...
            zseedinput{:});
        zseed(:,3) = zseed(:,3)+shft;
    else
        zseed = [];
        Zwrap = zeros([Isz,Nfr]);
        Zwrap(~mask) = NaN;
        Zunwrap = Zwrap;
    end

    % deformation fields
    dX = Xunwrap*xfac;
    dY = Yunwrap*yfac;
    dZ = Zunwrap*zfac;



    %% SPATIAL RESAMPLING
    % we resample the displacement field of each frame on a uniform
    % rectangular grid, encompassing the origin configuration of
    % the entire region of interest.

    % determine rectangular region of interest
    mn = NaN(Nfr,2);
    mx = NaN(Nfr,2);
    brdr = 2;

    for fr = 1:Nfr

        % skip non-frames of interest
        if ~tfframes(fr), continue; end

        % current displacement fields
        dXfr = dX(:,:,fr);
        dYfr = dY(:,:,fr);

        % tissue vector origins
        pts0 = [X(:)-dXfr(:),Y(:)-dYfr(:)];

        % resampling range
        mn(fr,:) = floor(min(pts0,[],1)) - brdr;
        mx(fr,:) =  ceil(max(pts0,[],1)) + brdr;

    end

    % final resampling range, limited to the image extents
    mn = max(min(mn,[],1),[1 1]);
    mx = min(max(mx,[],1),Isz([2 1]));

    xrng = [mn(1),mx(1)];
    yrng = [mn(2),mx(2)];


    % resampling values
    Nx = ceil(diff(xrng)/dresamp) + 1;
    xi = linspace(xrng(1),xrng(2),Nx);

    Ny = ceil(diff(yrng)/dresamp) + 1;
    yi = linspace(yrng(1),yrng(2),Ny);

    [Xi,Yi] = meshgrid(xi,yi);
    ptsi = [Xi(:),Yi(:)]';
    xisz = size(Xi);

    dxi = zeros([xisz Nfr+1]);
    dyi = zeros([xisz Nfr+1]);
    dzi = zeros([xisz Nfr+1]);
    ps = NaN(Nfr,1);

    % resample on rectangular grid
    for fr = 1:Nfr

        % skip non-frames of interest
        if ~tfframes(fr), continue; end

        % current displacement fields
        dXfr = dX(:,:,fr);
        dYfr = dY(:,:,fr);
        dZfr = dZ(:,:,fr);

        % tissue vector origins
        pts0 = [X(:)-dXfr(:),Y(:)-dYfr(:),zeros(numel(X),1)]';

        % current tissue locations
        % pts = [X(:),Y(:),dZfr(:)]';

        % point differences
        dpts = [dXfr(:),dYfr(:),dZfr(:)]';

        % valid displacements
        tf = ~isnan(dXfr) & ~isnan(dYfr) & ~isnan(dZfr);


        % THIN PLATE SPLINE
        if isequal(method,'tpaps')

            sm = 1-pspace;
            [stfr,ps(fr)] = tpaps_v3(pts0([1 2],tf),dpts(:,tf),sm);
            tmp = fnvalmod(stfr,ptsi);
            dxi(:,:,fr+1) = reshape(tmp(1,:),xisz);
            dyi(:,:,fr+1) = reshape(tmp(2,:),xisz);
            dzi(:,:,fr+1) = reshape(tmp(3,:),xisz);

        % GRIDFIT RESAMPLING
        else

            sm = (pspace)/(1-pspace);
            dxi(:,:,fr+1) = gridfit(pts0(1,tf),pts0(2,tf),dXfr(tf),xi,yi,...
                'smoothness',sm);
            dyi(:,:,fr+1) = gridfit(pts0(1,tf),pts0(2,tf),dYfr(tf),xi,yi,...
                'smoothness',sm);
            dzi(:,:,fr+1) = gridfit(pts0(1,tf),pts0(2,tf),dZfr(tf),xi,yi,...
                'smoothness',sm);

        end
        drawnow
    end



    %% TEMPORAL FITTING
    % we use the custom function POLYFIT2 to determine polynomial
    % fitted coefficents at all spatial locations within
    % the rectangular region of interest

    % temporal resampling range
    time = 0:Nfr;
    tmp = [true tfframes];


    % polynomial fit
    if Npoly<0
        spldx = DENSEsplinefit(yi,xi,time(tmp),dxi(:,:,tmp));
        spldy = DENSEsplinefit(yi,xi,time(tmp),dyi(:,:,tmp));
        spldz = DENSEsplinefit(yi,xi,time(tmp),dzi(:,:,tmp));
%         spldx = spapi({4,4,2},{yi,xi,time(tmp)},dxi(:,:,tmp));
%         spldy = spapi({4,4,2},{yi,xi,time(tmp)},dyi(:,:,tmp));
%         spldz = spapi({4,4,2},{yi,xi,time(tmp)},dzi(:,:,tmp));
    else
        spldx = DENSEpolyfit(yi,xi,time(tmp),dxi(:,:,tmp),Npoly,[0 Nfr]);
        spldy = DENSEpolyfit(yi,xi,time(tmp),dyi(:,:,tmp),Npoly,[0 Nfr]);
        spldz = DENSEpolyfit(yi,xi,time(tmp),dzi(:,:,tmp),Npoly,[0 Nfr]);
    end


    %% RETRIEVE INITIAL CONTOURS FROM SEEDFRAME

    if ~isempty(api.Mask)
        maskfcn = [];
        C = [];
        C0 = [];

    else

        % time point
        fr = seedframe;

        % sample rectangular displacement field at this time point
        dxfr = fnvalmod(spldx,{yi,xi,fr});
        dyfr = fnvalmod(spldy,{yi,xi,fr});

        % current point locations & current-to-origin deformation
        pts  = [Xi(:)+dxfr(:), Yi(:)+dyfr(:)];
        dpts = [-dxfr(:),-dyfr(:)];

        % THIN PLATE SPLINE
        if isequal(method,'tpaps')

            % spline current tissue configuration to
            % current-to-origin deformation
            st = tpaps_v3(pts',dpts',1);

            % project contours back to origin
            C0 = C(fr,:);
            for k = 1:numel(C0)
                dxy = fnval(st,C0{k}');
                C0{k} = C0{k} + dxy';
            end

        % GRIDFIT
        else

            % resample current-to-origin deformation on
            % uniform grid of current positions
            sm = 0.1;
            dxfr = gridfit(pts(:,1),pts(:,2),dpts(:,1),xi,yi,...
                'extend','always','smoothness',sm);
            dyfr = gridfit(pts(:,1),pts(:,2),dpts(:,2),xi,yi,...
                'extend','always','smoothness',sm);

            % spline current tissue configuration to
            % current-to-origin deformation
            ppx = spapi({2,2},{yi,xi},dxfr);
            ppy = spapi({2,2},{yi,xi},dyfr);

            % project contours back to origin
            C0 = C(fr,:);
            for k = 1:numel(C0)
                dxk = fnval(ppx,C0{k}(:,[2 1])');
                dyk = fnval(ppy,C0{k}(:,[2 1])');
                C0{k} = C0{k} + [dxk(:),dyk(:)];
            end

        end

    end



    %% OUTPUT DATA

    % final output structure
    metadata = struct(...
        'XYZValid',         xyzvalid,...
        'mmperpixel',       pxsz,...
        'Xwrap',            Xwrap,...
        'Ywrap',            Ywrap,...
        'Zwrap',            Zwrap,...
        'Xunwrap',          Xunwrap,...
        'Yunwrap',          Yunwrap,...
        'Zunwrap',          Zunwrap,...
        'Multipliers',      [xfac,yfac,zfac],...
        'spldx',            spldx,...
        'spldy',            spldy,...
        'spldz',            spldz,...
        'irng',             yrng,...
        'jrng',             xrng,...
        'frrng',            frrng,...
        'ResampleMethod',   method,...
        'ResampleDistance', dresamp,...
        'SpatialSmoothing', pspace,...
        'TemporalOrder',    Npoly,...
        'Xseed',            xseed,...
        'Yseed',            yseed,...
        'Zseed',            zseed,...
        'Contour',          {C},...
        'RestingContour',   {C0},...
        'MaskFcn',          maskfcn);


end



%% END OF FILE=============================================================
