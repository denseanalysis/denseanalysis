function groups = autoDENSEgroups(seqdata,varargin)

%AUTODENSEGROUPS automatically define DENSE groups within DICOM sequences
%
%INPUTS
%   seqdata....[Nx1] array of structures derived from DICOM header data
%       see DICOMSEQINFO for more information
%
%INPUT PARAMETERS
%   'Verbose'.....controls the display of progress messages to
%       the command line.  [true | {false}]
%   'Types'.......requested group types ['x'|'y'|'z'|'xy'|'xyz'|{'all'}]
%
%OUTPUTS
%   groups.....[Ngroupx1] array of structures with the following fields:
%       Name...........object name (blank)
%       UID............unique identification string
%       Type...........group type: 'x','y','z','xy', or 'xyz'
%       MagIndex.......indices into SEQDATA of magnitude information
%       PhaIndex.......indices into SEQDATA of phase information
%       Number.........number of phases
%       PixelSpacing...pixel spacing [i j]
%       Scale..........DENSE scale [x y z]
%       EncFreq........DENSE encoding frequency [x y z]
%       SwapFlag.......swap flag
%       NegFlag........negation flag [x y z]
%
%USAGE
%
%   GROUPS = AUTODENSEGROUPS(SEQDATA) this function searches the array of
%   structures SEQDATA, containing DICOM header information given by
%   DICOMSEQ, searching for valid DENSE sequences and grouping these
%   sequences into magnitude/phase data. The output GROUPS contains the
%   resulting groups in an array of structures. Each element of GROUPS
%   identifies the DENSE encoding type ('x','y','z','xy','xyz'), as well
%   as the sequence indices of the magnitude & phase data.
%
%   GROUPS = AUTODENSEGROUPS(...,'Verbose',TF) controls the display of
%   progess messages to the command line via the logical flag TF.  If
%   (TF==true),progess messages are outputted.
%
%   GROUPS = AUTODENSEGROUPS(...,'Types',C) controls the types of groups
%   the function will output.  C may be any of the following character
%   strings (defaulting to 'all') : ['x'|'y'|'z'|'xy'|'xyz'|'all']. C may
%   alternatively be a CELLSTR, indicating more than one type
%   (e.g. {'x','y'})
%
%NOTE ON GROUP INDICES
%
%   The 'MagIndex' and 'PhaIndex' fields in each element of GROUPS
%   are determined by the 'type' field:
%
%       'x'     MagIndex = [xmag  NaN  NaN]   PhaIndex = [xmag  NaN  NaN]
%       'y'     MagIndex = [ NaN ymag  NaN]   PhaIndex = [ NaN ypha  NaN]
%       'z'     MagIndex = [ NaN  NaN zmag]   PhaIndex = [ NaN  NaN zpha]
%       'xy'    MagIndex = [xmag ymag  NaN]   PhaIndex = [xpha ypha  NaN]
%       'xyz'   MagIndex = [xmag ymag zmag]   PhaIndex = [xpha ypha zpha]
%
%   Where xmag,ymag,zmag represent the x/y/z magnitude indices into the
%   input structure SEQDATA, and xpha,ypha,zpha represent the x/y/z phase
%   indices into the input structure SEQDATA.
%
%NOTE ON PIXELSPACING
%
%   In the DICOM standard, the 'PixelSpacing' field is defined
%   [row / column] (i.e. [i,j]).  Therefore the 2nd value corresponds
%   to the horizontal/x pixel spacing and the 1st value corresponds to the
%   vertical/y pixel spacing.
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation

    FLAG_warning = false;


    %% INITIALIZATION
    % we need to parse additional inputs, as well as ensure certain
    % SEQDATA data fields exist and are valid

    % parse inputs
    args = struct('Verbose',false,'Types','all');
    [args,other_args] = parseinputs(args,[],varargin{:});
    if ~isempty(other_args)
        error(sprintf('%s:invalidParameters',mfilename), ...
            'Invalid input parameter pair.');
    end

    % parse 'Verbose;
    FLAG_verbose = isequal(1,args.Verbose);

    % parse 'Types'
    tags = {'x','y','z','xy','xyz','all'};
    if ischar(args.Types), args.Types = {args.Types}; end
    if ~iscellstr(args.Types) || ...
       ~all(cellfun(@(x)any(strcmpi(x,tags)),args.Types))

        str = sprintf('%s|',tags{:});
        error(sprintf('%s:invalidTypes',mfilename),'%s',...
            'Unrecognized ''Types'' input. Valid identifiers are: ',...
            '[',str(1:end-1),'].');
    elseif any(strcmpi(args.Types,'all'))
        args.Types = {'x','y','z','xy','xyz'};
    end
    returntypes = args.Types(:);


    % test for structure
    if ~isstruct(seqdata)
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'The function expected a structure as input.');
    end

    % test for field existance
    tags = {'StudyInstanceUID';'SeriesNumber';
        'Height'; 'Width'; 'PixelSpacing'; ...
        'ImagePositionPatient'; 'ImageOrientationPatient'; ...
        'ValidSequence'; 'DENSEdata'; 'DENSEid'; };

    tf = isfield(seqdata,tags);
    if any(~tf)
        str = sprintf('%s,',tags{~tf});
        error(sprintf('%s:missingDICOMinformation',mfilename),'%s',...
            'The following mandatory fields did not exist in ',...
            'any DICOM sequence: [',str(1:end-1),'].');
    end

    % locate candidate DENSE fields
    tfdense = true(size(seqdata));
    for k = 1:numel(seqdata)
        tfdense(k) = ~isemptystruct(seqdata(k),tags) && ...
            isequal(true, seqdata(k).ValidSequence) && ...
            ischar(seqdata(k).DENSEid) && ...
            (numel(seqdata(k).DENSEdata) == 1);
    end

    if ~any(tfdense)
        error(sprintf('%s:noDENSEsequences',mfilename),'%s',...
            'No valid candidate DENSE sequences could be located.');
    end



    %% MATCH MAGNITUDE/PHASE
    % Here, we attempt to match Magnitude & Phase DENSE data into plausible
    % single/double/triple DENSE encodings (i.e. ['x','y','z']/'xy'/'xyz').
    % Valid groups are defined according to the following criteria:
    %
    % 1) Can the magnitude type be matched with the phase type?
    %    'mag.overall' -> any phase type is acceptable
    %    'mag.x','mag.y','mag.z' -> phase must match mag type
    %
    % 2) Can an exisiting group type accept the phase type?
    %    'x' type  -> the phase must be 'pha.y'
    %    'xy' type -> the phase must be 'pha.z'
    %    otherwise -> nope.
    %
    % 3) Does the phase data match the group magnitude?
    %    Validate phase data against magnitude data using a number of
    %    DICOM and DENSEdata fields
    %
    % 4) Does the phase data match other phases within the group?
    %    Validate phase data against magnitude data using a number of
    %    DICOM and DENSEdata fields
    %
    % 5) Do the SeriesNumbers line up?
    %    (pidx = current phase index, midx = group magnitude index)
    %    'pha.x' -> pidx can equal (midx) or (midx+1)
    %    'pha.y' -> pidx can equal (midx), (midx+1), or (midx+2)
    %    'pha.z' -> pidx can equal (midx), (midx+1), or (midx+3)

    % report
    if FLAG_verbose
        fprintf('Locating DENSE groups...\n');
    end

    % required SEQDATA matching fields
    tags_seq = {'StudyInstanceUID';...
        'Height'; 'Width'; 'PixelSpacing'; ...
        'ImagePositionPatient'; 'ImageOrientationPatient'};

    % required DENSEdata matching fields
    tags_dnsmag = {'Number','SwapFlag','NegFlag'};
    tags_dnspha = {'Number','Scale','EncFreq','SwapFlag','NegFlag'};
%     tags_dnspha = {'Number','SwapFlag','NegFlag'};

    % initialize groups structure
    groups = struct(...
        'Name','',...
        'UID', [],...
        'Type',[],...
        'MagIndex',num2cell(1:numel(seqdata))',...
        'PhaIndex',[]);


    % search loop
    midx = [];
    midx_maintain = false;
    for sk = 1:numel(seqdata)

        % clear current magnitude index if not "maintaining"
        if ~midx_maintain, midx = []; end
        midx_maintain = false;

        % check for valid dense data
        if ~tfdense(sk), continue; end

        % check for candidate magnitude or phase data
        % candidate magnitude -> record index & move to next sequence
        % candidate phase requires candidate magnitude
        id = seqdata(sk).DENSEid;
        if ~ischar(id)
            continue;
        elseif strwcmpi(id,'mag*') && ...
           ~isemptystruct(seqdata(sk).DENSEdata,tags_dnsmag)
            midx = sk;
            midx_maintain = true;
            continue;
        elseif ~isempty(midx) && strwcmpi(id,'pha*') && ...
           ~isemptystruct(seqdata(sk).DENSEdata,tags_dnspha)
            pidx = sk;
        else
            continue;
        end


        % for the remainder of this loop, we assume the sequence fields are
        % as we need them to be.  We wrap this code in a try/catch loop
        % just in case.
        try

            % current sequence data
            pseq  = seqdata(pidx);
            pdns  = pseq.DENSEdata;
            ptype = pseq.DENSEid(5:end);

            mseq  = seqdata(midx);
            mdns  = mseq.DENSEdata;
            mtype = mseq.DENSEid(5:end);

            gtype = groups(midx).Type;
            gidx  = groups(midx).PhaIndex;

            % plausible phase type (validate against magnitude & group)
            if ~strcmpi(mtype,'overall') && ~isequal(mtype,ptype)
                continue
            elseif ~isempty(gtype)
                allow = (strcmpi(gtype,'x') && strcmpi(ptype,'y')) || ...
                    (strcmpi(gtype,'xy') && strcmpi(ptype,'z'));
                if ~allow, continue; end
            end

            % plausible phase data (equality with group magnitude)
            magmatch = isequalstruct(pseq,mseq,tags_seq) && ...
               isequalstruct(pdns,mdns,tags_dnsmag);

            % plausible phase data (equality with group phases)
            phamatch = true(size(gidx));
            for k = 1:numel(gidx)
                phamatch(k) = isequalstruct(pdns,...
                    seqdata(gidx(k)).DENSEdata,tags_dnspha);
            end

            % validate equality
            if ~magmatch || any(~phamatch), continue; end


            % difference between SeriesNumbers
            dsn = pseq.SeriesNumber - mseq.SeriesNumber;

            % allowable SeriesNumbers
            if ~strcmpi(mtype,'overall');
                snmatch = any(dsn==[0 1]);
            else
                switch lower(ptype)
                    case 'x',  snmatch = any(dsn == [0 1]);
                    case 'y',  snmatch = any(dsn == [0 1 2]);
                    case 'z',  snmatch = any(dsn == [0 1 3]);
                    otherwise, snmatch = false;
                end
            end
            if ~snmatch, continue; end


            % Definative single encoding:
            % 1) 'mag.x','mag.y','mag.z'
            % 2) magnitude/phase in same series (pidx==midx)
            % 3) y/z phase where pidx == midx+1
            if ~strcmpi(mtype,'overall') || dsn==0 || ...
               (any(strcmpi(ptype,{'y','z'})) && dsn == 1)

                groups(midx).PhaIndex = pidx;
                groups(midx).Type = ptype;

            % multiple encodings
            % Note we've already assured that the pha/mag SeriesNumber are
            % valid & the current group is able to accept a multiple encoding
            % 1) if ('x' && pidx==midx+1) -> save single 'x' encoding and
            %    continue search for corresponding 'y' & 'z' encodings
            % 2) if ('y' && pidx==midx+2) -> save double 'xy' encoding and
            %    continue search for corresponding 'z' encoding
            % 3) if ('z' && pidx==midx+3) -> save triple 'xyz' encoding and
            %    end search
            else
                switch lower(ptype)
                    case 'x'
                        groups(midx).PhaIndex = pidx;
                        groups(midx).Type = 'x';
                        midx_maintain = true;
                    case 'y'
                        groups(midx).PhaIndex = [groups(midx).PhaIndex, pidx];
                        groups(midx).Type = 'xy';
                        midx_maintain = true;
                    case 'z'
                        groups(midx).PhaIndex = [groups(midx).PhaIndex, pidx];
                        groups(midx).Type = 'xyz';
                end
            end

        % catch error
        catch ERR
            if FLAG_verbose
                fprintf('There was an error parsing sequence %d\n',sk)
            end
            midx_maintain = false;
        end

    end % sequence loop


    % eliminate empty groups
    tf = cellfun(@(x)~isempty(x),{groups.Type}');
    groups = groups(tf);

    % expand single magnitude indices to match number of phase indices
    for k = 1:numel(groups)
        sz = size(groups(k).PhaIndex);
        groups(k).MagIndex = groups(k).MagIndex * ones(sz);
    end


    % report to user
    if numel(groups) == 0
        if FLAG_warning
            warning(sprintf('%s:noDENSEgroups',mfilename),'%s',...
                'No DENSE groups were located.');
        end
        groups = repmat(struct,[0 1]);
        return;
    elseif FLAG_verbose
        N = cellfun(@numel,{groups.PhaIndex}');
        fprintf('%d DENSE groups on 1st pass (1:%d, 2:%d, 3:%d)\n',...
            numel(groups),sum(N==1),sum(N==2),sum(N==3));
    end



    %% MATCH SINGLE ENCODINGS
    % here, we additionally match any single encodings to other single
    % encodings (i.e. x+y = xy, x+y+z = xyz)

    % number of groups
    N = numel(groups);

    % locate single encodings
    type = {groups.Type}';
    tfx = cellfun(@(tp)strcmpi(tp,'x'),type);
    tfy = cellfun(@(tp)strcmpi(tp,'y'),type);
    tfz = cellfun(@(tp)strcmpi(tp,'z'),type);

    % match 'y'/'z' to 'x'
    xymatch = false(N);
    xzmatch = false(N);

    for j = 1:N
        if ~tfx(j), continue; end
        idxi = groups(j).MagIndex;

        for i = 1:N
            if ~tfy(i) && ~tfz(i), continue; end
            idxj = groups(i).MagIndex;

            match = ...
                isequalstruct(seqdata(idxi),seqdata(idxj),tags_seq) && ...
                isequalstruct(seqdata(idxi).DENSEdata,...
                              seqdata(idxj).DENSEdata,...
                              tags_dnspha);

            if tfy(i)
                xymatch(i,j) = match;
            else tfz(i)
                xzmatch(i,j) = match;
            end
        end
    end

    % default new groups
    emptystruct = struct('Name',[],'UID',[],'Type',[],...
        'MagIndex',[],'PhaIndex',[]);
    newgroups = repmat(emptystruct,[0 1]);

    % search for 'xy' and 'xyz' matches

    % loop over 'x' values
    for xi = 1:N

        % loop over 'y' values
        for yi = 1:N
            if xymatch(yi,xi)

                % record new 'xy' group
                tmp = emptystruct;
                tmp.Type = 'xy';
                tmp.MagIndex = [groups([xi,yi]).MagIndex];
                tmp.PhaIndex = [groups([xi,yi]).PhaIndex];
                newgroups = [newgroups(:); tmp];

                % if we found 'xy' groups, additionally check for 'xyz'
                for zi = 1:N
                    if xzmatch(zi,xi)
                        tmp = emptystruct;
                        tmp.Type = 'xyz';
                        tmp.MagIndex = [groups([xi,yi,zi]).MagIndex];
                        tmp.PhaIndex = [groups([xi,yi,zi]).PhaIndex];
                        newgroups = [newgroups(:); tmp];
                    end
                end

            end
        end
    end


    % save to output
    groups = [groups(:); newgroups(:)];

    % report to user
    if FLAG_verbose
        N = cellfun(@numel,{groups.PhaIndex}');
        fprintf('%d DENSE groups on 2nd pass (1:%d, 2:%d, 3:%d)\n',...
            numel(groups),sum(N==1),sum(N==2),sum(N==3));
    end



    %% ELIMINATE UNWANTED TYPES
    % After searching SEQDATA for groups of all known types, we pair down
    % the results to the user-requested types.

    tf = cellfun(@(x)any(strcmpi(x,returntypes)),{groups.Type});
    groups = groups(tf);

    % report to user
    if numel(groups) <= 0
        if FLAG_warning
            warning(sprintf('%s:noDENSEgroups',mfilename),'%s',...
                'No DENSE groups were located.');
        end
        groups = repmat(struct,[0 1]);
        return;
    elseif FLAG_verbose
        N = cellfun(@numel,{groups.PhaIndex}');
        fprintf('%d DENSE groups after elimination (1:%d, 2:%d, 3:%d)\n',...
            numel(groups),sum(N==1),sum(N==2),sum(N==3));
    end



    %% FINAL OUTPUT STRUCTURE
    % Up until now, the "MagIndex" and "PhaIndex" fields have contained
    % only valid indices (i.e. no NaNs).  However, its better for the
    % output fields to always contain 3 indices each, with invalid indices
    % as NaN.
    % Additionally, we need to gather the DENSEdata from the new groups.

    for k = 1:numel(groups)
        mi = groups(k).MagIndex;
        pi = groups(k).PhaIndex;

        mdata = [seqdata(mi).DENSEdata];
        pdata = [seqdata(pi).DENSEdata];

        number   = mdata(1).Number;
        swapflag = mdata(1).SwapFlag;
        negflag  = mdata(1).NegFlag;

        sc = [pdata.Scale];
        ef = [pdata.EncFreq];

        midx = NaN(1,3);
        pidx = NaN(1,3);
        scale   = NaN(1,3);
        encfreq = NaN(1,3);

        switch lower(groups(k).Type)
            case 'x'
                midx(1)    = mi(1);
                pidx(1)    = pi(1);
                scale(1)   = sc(1);
                encfreq(1) = ef(1);
            case 'y'
                midx(2)    = mi(1);
                pidx(2)    = pi(1);
                scale(2)   = sc(1);
                encfreq(2) = ef(1);
            case 'z'
                midx(3)    = mi(1);
                pidx(3)    = pi(1);
                scale(3)   = sc(1);
                encfreq(3) = ef(1);
            case 'xy'
                midx(1:2)    = mi(1:2);
                pidx(1:2)    = pi(1:2);
                scale(1:2)   = sc(1:2);
                encfreq(1:2) = ef(1:2);
            case 'xyz'
                midx(1:3)    = mi(1:3);
                pidx(1:3)    = pi(1:3);
                scale(1:3)   = sc(1:3);
                encfreq(1:3) = ef(1:3);
        end

        pxsp = seqdata(mi(1)).PixelSpacing(:)';

        groups(k).Name = sprintf('auto.%d',k);
        groups(k).UID  = dicomuid;
        groups(k).MagIndex      = midx;
        groups(k).PhaIndex      = pidx;
        groups(k).Number        = number;
        groups(k).PixelSpacing  = pxsp;
        groups(k).Scale         = scale;
        groups(k).EncFreq       = encfreq;
        groups(k).SwapFlag      = swapflag;
        groups(k).NegFlag       = negflag;

    end



end


%% END OF FILE=============================================================
