function [seqdata,uipath] = DICOMseqinfo(startpath,varargin)
%DICOMSEQINFO parse DICOM file header information
%   into unique image sequences
%
%INPUTS
%   startpath.....starting directory for UIGETDIR dialog
%
%INPUT PARAMETERS
%   'SkipDialog'.....allows the user to bypass the directory dialog box,
%       setting UIPATH = STARTPATH.  [true | {false}]
%   'Verbose'........controls the display of progress messages to
%       the command line.  [true | {false}]
%   'Waitbar'........controls the use of a progress bar.  [{true} | false]
%   'OptionsPanel'...display options panel for sequence selection when
%       "true". Defaults to "false".
%
%OUTPUTS
%   seqdata.....structure array of DICOM sequence header information
%   uipath......directory searched
%
%USAGE
%
%   SEQDATA = DICOMSEQINFO(STARTPATH) parses all valid DICOM files within a
%   user-selected folder heirachy into unique image sequences, returning
%   DICOM sequence header information in SEQDATA.  The directory dialog box
%   (using the builtin function UIGETDIR) is initialized at the directory
%   STARTPATH.
%
%   [...,UIPATH] = DICOMSEQINFO(...) returns the actual directory UIPATH
%   searched by the algorithm.
%
%   [...] = DICOMSEQINFO() and [...] = DICOMSEQINFO([])
%   is the same as [...] = DICOMSEQINFO(PWD)
%
%   [...] = DICOMSEQINFO(...,'SkipDialog',TF,...) TF is a logical scalar
%   allowing the user to bypass the directory dialog box, setting
%   UIPATH = STARTPATH.
%
%   [...] = DICOMSEQINFO(...,'Verbose',TF,...) TF is a logical scalar
%   controling the display of progress messages to the command line.
%
%   [...] = DICOMSEQINFO(...,'Waitbar',TF,...) TF is a logical scalar
%   controling the use of a progress bar.
%
%NOTES ON SEQDATA
%
%   The SEQDATA array of structures contains a vast amount of DICOM header
%   information, with fields defined by the builtin MATLAB function
%   DICOMINFO and the builtin DICOM dictionary. Each element of SEQDATA
%   represents a single unique image sequence containing one or more files.
%
%   The fields within SEQDATA are the union of all fields within the files of
%   interest. No header field is guaranteed to exist.  Note that if
%   some sequences do not contain a given header field, that field of
%   SEQDATA may still exist but will be empty.
%
%   This function makes the following modifications to the header
%   information gleaned from DICOM files.
%
%     • We ignore header fields beginning with 'Private' (i.e. fields
%       unrecognized by the MATLAB DICOM dictionary) as well as fields
%       beginning with 'Icon' (to save space).
%
%     • If a header field is consistent across all files of a given image
%       sequence (e.g. 'PatientName','ProtocolName',etc.), we collapse that
%       field into a single value.
%
%     • Fieldnames that were not consistent across all files of a given image
%       sequence and could not be collapsed (e.g. 'InstanceNumber',
%       'ImageComments',etc) are recorded in the new field
%       'MultipleValueFields'
%
%     • We record the number of files in a given sequence in the field
%       'NumberInSequence'
%
%     • DENSE information (see NOTE ON IMAGECOMMENTS below) adds three
%       fields to SEQDATA: 'DENSEid','DENSEindex','DENSEdata'
%
%     • We attempt to discover and mark incomplete or invalid sequences
%       using a number of different tests. Valid sequences are marked
%       within the 'ValidSequence' tag.  Valid sequences have...
%       --Non-empty mandatory tags
%       --Expected 'InstanceNumber'
%       --An empty or valid 'DENSEid' (not 'unknown')
%       --Expected 'DENSEindex' values if DENSE
%
%
%NOTE ON UNIQUE IMAGE SEQUENCES
%
%   In order to identify a "unique image sequence" from a large set of
%   DICOM files, certain header information should exist and contain
%   appropriate identifying information.
%
%   GENERAL IDENTIFICATION: We rely on the following information to
%   identify unique image sequences:
%
%     • Subject: who/what is the subject of the DICOM file?
%       'StudyInstanceUID'
%
%     • Series: to what series does the file belong?
%       'SeriesInstanceUID'
%
%     • Slice: where in the subject was the file acquired?
%       'ImageOrientationPatient, 'ImagePoisitionPatient'
%       'Height', 'Width', 'PixelSpacing'
%
%     • Order: where in the sequence was the file acquired?
%       'InstanceNumber'
%
%   PER-PROTOCOL IDENFICIATION: We additionally examine protocol-specific
%   information to further identify unique image sequences. Note that these
%   header fields are not mandatory.
%
%     • DENSE data: what is the DENSE encoding of the the file?
%       'ImageComments'
%
%
%NOTE ON IMAGECOMMENTS
%
%   The ImageComments field of a DICOM can contain useful information,
%   e.g. DENSE encoding parameters. Currently, this function will
%   successfully parse the following ImageComments:
%
%     • DENSE data (via parseImageCommentsDENSE)
%       e.g. "DENSE y-enc pha - Scale:1.000000 EncFreq:1.10 Rep:0/1
%             Slc:0/1 Par:19/20 Phs:0/20 RCswap:0 RCSflip:1/0/0"
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.01     Drew Gilliam
%     --creation
%   2009.02     Drew Gilliam
%     --dialog box directory selection
%     --maxfiles warning
%   2009.06     Drew Gilliam
%     --upgraded options panel


    % unnecessary tag identifiers
    excludetags = {'Private*','Icon*'};

    % file limit
    maxfiles = 4000;

    % DICOM file filters
    filefilters = {'*.ima','*.dcm','*'};

    % use the "quick" ISDICOM check prior to DICOMINFO
    % This isn't necessary & may slow down the function, but we didn't
    % remove it from the code entirely for some reason.
    FLAG_isdicom = true;



    %% PARSE INPUTS, CHOOSE DIRECTORY
    % This section uses the UIGETDIR matlab tool to interactively choose a
    % directory to investigate.

    % default inputs
    if nargin < 1 || isempty(startpath),  startpath = pwd;    end

    % check 'startpath' input
    if ~ischar(startpath) || exist(startpath,'dir')~=7
        error(sprintf('%s:noPath',mfilename),...
            'The first input must be a valid directory string.');
    end

    % parse additional inputs
    args = struct(...
        'SkipDialog',   false,...
        'Verbose',      false,...
        'Waitbar',      true,...
        'OptionsPanel', false);
    [args,other_args] = parseinputs(fieldnames(args),...
        struct2cell(args),varargin{:});
    if ~isempty(other_args)
        error(sprintf('%s:invalidParameters',mfilename), ...
            'Invalid input parameter pair.');
    end

    % parse arguments
    FLAG_skipdialog = isequal(1,args.SkipDialog);
    FLAG_verbose    = isequal(1,args.Verbose);
    FLAG_waitbar    = isequal(1,args.Waitbar);
    FLAG_options    = isequal(1,args.OptionsPanel);

    % choose new directory
    if FLAG_skipdialog
        uipaths = {startpath};
    else
        uipaths = uigetdirs(startpath, 'Choose DICOM directory');
        if isempty(uipaths)
            seqdata = []; uipath = [];
            return;
        end
    end

    % Store the parent directory if multiple dirs were selected
    if numel(uipaths) > 1
        uipath = fileparts(uipaths{1});
    else
        uipath = uipaths{1};
    end

    % ensure directory exists
    for k = 1:numel(uipaths)
        if exist(uipaths{k}, 'dir') ~= 7
            error(sprintf('%s:noPath', mfilename), '%s\n%s', ...
                'The specified directory does not exist:', ...
                ['<', char(uipath{k}), '>']);
        end
    end

    % initialize waitbar
    if FLAG_waitbar
        hwait = waitbar(0,'...',...
            'Name','DICOM sequence information',...
            'WindowStyle','modal');
        hwaitCleanupObj = onCleanup(@()hwaitCleanupFcn(hwait));
        drawnow, pause(0.1)
    end

    %% LOCATE CANDIDATE DICOM FILES
    % Here, we search the chosen directory hierarchy for candidate DICOM
    % files.  If the "FLAG_isdicom" is true (internal flag specified
    % above), we attempt to pare down the candidate DICOM files via the
    % "isdicom" function.

    % report progress
    reportFcn({'Locating DICOM files...\n'},...
        'Locating DICOM files...',0);

    % all files from hierarchy
    files = cellfun(@(pth)getfiles(pth, filefilters, 1), uipaths, 'uni', 0);
    files = cat(1, files{:});
    Nfiles = numel(files);

    % check for cancellation
    if abortFcn, return; end
    if FLAG_waitbar, pause(0.1); end

    % pare down DICOM files
    if FLAG_isdicom && Nfiles > 0

        % report
        reportFcn({'Validating DICOM files...\n'},...
            'Validating DICOM files...',0);

        % use ISDICOM to locate DICOM files
        valid = false(size(files));

        tic
        for fi = 1:Nfiles
            valid(fi) = isdicom(files{fi});

            % check for cancellation
            if abortFcn, return; end

            % report
            if FLAG_verbose || FLAG_waitbar
                if fi==Nfiles || mod(fi,round(Nfiles/100))==0
                    reportFcn({},[],fi/Nfiles);
                end
                if fi==Nfiles || mod(fi,100)==0
                    reportFcn(...
                        {'%5d of %5d (%6.1f sec)\n',fi,Nfiles,toc},...
                        [],[]);
                end
            end

        end

        % remove candidate files
        files = files(valid);
        Nfiles = numel(files);

    end

    % check for no files
    if Nfiles <= 0
        error(sprintf('%s:noDICOM',mfilename),'%s\n%s',...
            'No DICOM files were found in the specified folder:',...
            ['<',uipath,'>']);
    end

    % report
    reportFcn({'%d candidate DICOM files.\n',Nfiles},[],[]);

    % check file limit
    if Nfiles >= maxfiles
        set(hwait,'Visible','off');

        str = sprintf('%s','The specified directory has a large ',...
            'number of DICOM files (', num2str(Nfiles,'%d'), ' files). ',...
            'We suggest you instead select a subset of the ',...
            'files for analysis. Do you want to continue?');
        button = questdlg(str,'Too many files...','Continue','Cancel','Cancel');
        if ~strcmpi(button,'continue')
            seqdata = []; uipath = [];
            return;
        else
            set(hwait,'Visible','on');
        end
    end



    %% GATHER DICOM HEADER DATA
    % Identify all the candidate DICOM files in the UIPATH hierarchy via
    % ISDICOM, then read all header informtion via DICOMINFO.
    %
    % Note we ignore some unecessary DICOM header information to save
    % memory (i.e. fields that start with 'Private' or 'Icon')

    % gather requested DICOM data
    filedata = repmat(struct,[Nfiles,1]);
    valid = false(Nfiles,1);

    % report
    reportFcn({'Loading DICOM information...\n'},...
        'Loading DICOM information...',0);

    tic
    for fi = 1:Nfiles

        % attempt to load dicom header
        try
            dcmdata = dicominfo(files{fi});
        catch
            dcmdata = [];
        end

        % If this is Philips, attempt to grab the TagSpacing
        if isstruct(dcmdata) && strwcmpi(getfieldr(dcmdata, 'Manufacturer', ''), '*philips*')

            % Make sure that this is a protocol that we expect
            if regexp(dcmdata.ProtocolName, '\<3DDE\>')
                % Add some custom fields for Philips data
                stacks = struct2array(dcmdata.Private_2001_105f);

                % There is a stack for each encoding direction
                dimensions = numel(stacks);
                nSlices = double(stacks(1).Private_2001_102d);
                nPhases = double(dcmdata.Private_2001_1017);

                details = getfieldr(dcmdata, 'Private_2005_140f.Item_1', struct());

                % Get the tag spacing
                encodingFrequency = 1.0 / details.TagSpacingFirstDimension;

                % Determine if this is a magnitude or phase image
                if regexp(dcmdata.ImageType, '\\M\\')
                    imtype = 'mag';
                else
                    imtype = 'pha';
                end

                % Try to fill in the ImageComments as needed so that
                % the DENSE images are processed appropriately
                instance = dcmdata.InstanceNumber - 1;
                currentPhase = mod(instance, nPhases);
                currentSlice = floor(mod(instance / nPhases, nSlices));

                type_index = mod(floor(instance / (nSlices * nPhases)), dimensions) + 1;
                directions = 'xyz';

                encoding_direction = directions(type_index);

                fmt = 'DENSE %s-enc %s Scale:1 EncFreq:%0.4f Rep:0/1 Slc:1/0 Par:%d/%d Phs:%d/%d RCswap:0 RCSflip:0/1/0';
                comments = sprintf(fmt, encoding_direction, imtype, ...
                    encodingFrequency, currentSlice, nSlices, ...
                    currentPhase, nPhases);

                dcmdata.ImageComments = comments;

                % Take care of any strange rounding issues
                dcmdata.ImageOrientationPatient = round(dcmdata.ImageOrientationPatient .* 1000) ./ 1000;
                dcmdata.ImagePositionPatient = round(dcmdata.ImagePositionPatient .* 1000) ./ 1000;
                dcmdata.SliceLocation = round(dcmdata.SliceLocation .* 1000) ./ 1000;

                % Modify the series description to provide the user
                % more information when manually assigning DENSE groups
                dcmdata.SeriesDescription = sprintf('%s: %s-enc %s Slice:%d', ...
                    dcmdata.SeriesDescription, encoding_direction, ...
                    imtype, currentSlice);

                % Update the InstanceNumber to allow the rest of the
                % load function to operate appropriately.
                %
                % TODO: Fix the rest of this function to be more robust
                % and not as strict with InstanceNumber values
                dcmdata.InstanceNumber = currentPhase + 1;
            end
        end

        % save header fields
        if ~isempty(dcmdata)
            tags = fieldnames(dcmdata);
            tf = false(size(tags));
            for ti = 1:numel(excludetags)
                tf = tf | strwcmpi(tags,excludetags{ti});
            end
            tags = tags(~tf);

            % gather header data
            for ti = 1:numel(tags)
                tag = tags{ti};
                filedata(fi).(tag) = dcmdata.(tag);
            end

            valid(fi) = true;
        end

        % report (with cancellation)
        if FLAG_verbose || FLAG_waitbar
            if abortFcn, return; end
            if fi==Nfiles || mod(fi,round(Nfiles/100))==0
                reportFcn({},[],fi/Nfiles);
            end
            if fi==Nfiles || mod(fi,100)==0
                reportFcn(...
                    {'%5d of %5d (%6.1f sec)\n',fi,Nfiles,toc},...
                    [],[]);
            end
        end
    end

    % eliminate invalid DICOM files
    files    = files(valid);
    filedata = filedata(valid);
    Nfiles   = numel(filedata);

    % check for files
    if Nfiles <= 0
        error(sprintf('%s:noDICOM',mfilename),'%s\n%s',...
            'No DICOM files were found in the specified folder:',...
            ['<',uipath,'>']);
    end

    % report
    reportFcn({'%d valid DICOM files\n',Nfiles},[],[]);



    %% CHECK FOR MANDATORY HEADER FIELDS
    % certain header fields are mandatory to properly sort the files.
    % Note that UIDs (globally unique identifiers) are chronolgoical, and
    % mandatory within a DICOM file. Slice parameters are not mandated by
    % the DICOM standard, but are necessary for our purposes.
    % • Subject: 'StudyInstanceUID'
    % • Series:  'SeriesInstanceUID','SeriesNumber'
    % • Slice:   'Height','Width','PixelSpacing',
    %            'ImagePositionPatient','ImageOrientationPatient'
    % • Time:    'InstanceNumber'

    % mandatory tags
    tags = {'StudyInstanceUID','SeriesInstanceUID','SeriesNumber',...
            'Height','Width','PixelSpacing',...
            'ImagePositionPatient','ImageOrientationPatient',...
            'InstanceNumber'};
    type = {'char','char','numeric',...
            'numeric','numeric','numeric',...
            'numeric','numeric','numeric'};
    len  = {[],[],1,1,1,2,3,6,1};

    % ensure all tags exist within filedata
    tf = isfield(filedata,tags);
    if any(~tf)
        str = sprintf('%s,',tags{~tf});
        error(sprintf('%s:missingDICOMinformation',mfilename),'%s',...
            'The following mandatory fields did not exist in ',...
            'any DICOM file: [',str(1:end-1),'].');
    end

    % ensure madatory fields are not empty and of the
    % expected form in every file
    valid = true(Nfiles,1);
    for k = 1:Nfiles
        for ti = 1:numel(tags)
            val = filedata(k).(tags{ti});

            if isempty(val) || ~isa(val,type{ti}) || ...
               (~isempty(len{ti}) && numel(val) ~= len{ti})
                valid(k) = false;
                break
            end

        end
    end

    % report to user
    if all(~valid)
        error(sprintf('%s:invalidDICOMinformation',mfilename),'%s',...
            'No file contained the mandatory header information of the ',...
            'expected type & number of elements.');
    else
        if any(~valid)
            warning(sprintf('%s:invalidDICOMinformation',mfilename),'%s',...
                'Some files did not contain the expected mandatory ',...
                'header information.');
        else
            reportFcn({'All files contain valid mandatory tags.\n'},[],[]);
        end
    end

    % check for cancellation
    if abortFcn, return; end

    % eliminate invalid DICOM files
    files    = files(valid);
    filedata = filedata(valid);
    Nfiles   = numel(filedata);



    %% PARSE IMAGECOMMENTS
    % Currently, we parse the following types of ImageComments:
    % • DENSE data: If the file contains DENSE data, we fill in the
    %       DENSEid, DENSEindex, and DENSEdata fields.

    % allocate empty fields
    [filedata.DENSEid]    = deal('');
    [filedata.DENSEindex] = deal([]);
    [filedata.DENSEdata]  = deal([]);
    % [filedata.***] = deal([]);

    % if ImageComments exists, parse all files
    if isfield(filedata,'ImageComments');
        for k = 1:numel(filedata)

            str = filedata(k).ImageComments;

            % check for non-empty string IC field
            if isempty(str) || ~ischar(str)
                continue;
            end

            %-----DENSE DATA-----
            if strwcmpi(str,'dense*')
                [id,data] = parseImageCommentsDENSE(str, filedata(k));
                filedata(k).DENSEid = id;
                if ~isempty(id) && ~strcmpi(id,'unknown')
                    filedata(k).DENSEindex = data.Index;
                    filedata(k).DENSEdata = ...
                        rmfield(data,{'Type','Index'});
                end

            %-----OTHER FILE TYPES-----
            % elseif

            end

        end
    end

    %% SORT FILES
    % After gathering all header information, we order the files by
    % Subject, Series, DENSE ID, and Instance. This is accomplished using
    % the SORTROWS function, sorting a large cell array of strings and
    % values derived from the filedata structure array.
    %
    % Note these ids are not necessarily unique identifiers, but proper
    % ordering will save us work in the long run.
    %
    % Additionally note, in the case of single-series DENSE data (i.e.
    % magnitude and phase data have the same SeriesNumber), magnitude
    % information (specified by a 'mag.*' DENSEid field) will always
    % preceed phase data (specified by a 'pha.*' DENSEid field).

    % sort tags
    tags = {'StudyInstanceUID',...
            'SeriesNumber',...
            'DENSEid',...
            'InstanceNumber'};

    % initialize sort array with default values of expected type
    defvals = {'',0,'',0};
    array = repmat(defvals,[Nfiles,1]);

    % fill sort array
    for k = 1:Nfiles
        for ti = 1:numel(tags)
            tag = tags{ti};

            % test for empty tag
            if isempty(filedata(k).(tag))
                continue;
            end
            val = filedata(k).(tag);

            % ensure value of correct type
            if isnumeric(defvals{ti})
                val = double(val);
            else
                val = char(val);
            end

            % save to array
            array{k,ti} = val;

        end
    end

    % sort cell array to determine order
    [array,order] = sortrows(array);
    filedata = filedata(order);
    files    = files(order);



    %% UNIQUE SEQUENCES
    % A unique sequence is identified by a number of DICOM header fields,
    % including Patient, Series, Slice, and DENSE information.
    %
    % We first identify all sequences via Patient/Study, Series, and
    % DENSE information. Note that the DENSE identifier separates a
    % single series containing magnitude and phase information into
    % multiple series.
    %
    % We then ensure that each sequence is derived from a single slice of
    % the subject (otherwise we break the entire sequence into
    % single-image sub-sequences).

    reportFcn({'Identifying unique sequences...\n'},[],[]);

    % sequence tags
    tags = {'StudyInstanceUID';...
            'SeriesInstanceUID';...
            'DENSEid'};

    % unique series
    [unqdata,m,idx] = unique_struct(filedata,tags);


    % unique string identifiers
    uid = cellfun(@(n)sprintf('%d',n),num2cell(1:numel(unqdata)),...
        'uniformoutput',0);

    % file string identifier
    id = cellfun(@(n)sprintf('%d',n),num2cell(idx(:)),...
        'uniformoutput',0);


    % divide series without matching slice information into
    % single-image sequences
    tags = {'Height'; 'Width'; 'PixelSpacing'; ...
        'ImagePositionPatient'; 'ImageOrientationPatient';};

    for k = 1:numel(uid)
        tf = (idx==k);
        [tmp,ndx,pos] = unique_struct(filedata(tf),tags);
        if numel(tmp) > 1
            id(tf) = cellfun(@(s,n)sprintf('%s.%d',s,round(n)),...
                id(tf),num2cell(pos(:)),...
                'uniformoutput',0);
        end
    end

    % new unique identifiers
    [uid,m,idx] = unique_nat(id);

    % display
    reportFcn({'%d unique sequences found.\n',numel(uid)},[],[]);



    %% GATHER SEQUENCE DATA
    % Finally, we gather sequence data into a new data structure.
    % --We add the field 'NumberInSequence' indicating the number of files
    %   in the image sequence.
    % --We collapse fields that have the same value across the given
    %   sequence into a single value
    % --We add the field 'MultipleFields' indicating the field names that
    %   were not collapsed for a given sequence.

    seqdata = repmat(struct,[numel(uid),1]);
    tags = fieldnames(filedata);

    reportFcn({},'Gathering DICOM sequences...',0);

    for k = 1:numel(uid)
        tf = (idx == k);

        tagnomatch = false(size(tags));
        for ti = 1:numel(tags)
            tag = tags{ti};
            vals = {filedata(tf).(tag)};
            match = cellfun(@(v)isequal(vals{1},v),vals);
            if all(match)
                seqdata(k).(tag) = vals{1};
            else
                seqdata(k).(tag) = vals(:);
                tagnomatch(ti) = true;
            end

        end

        seqdata(k).NumberInSequence    = sum(tf);
        seqdata(k).MultipleValueFields = tags(tagnomatch);

        % report (with cancellation)
        if FLAG_waitbar
            if abortFcn, return; end
            reportFcn({},[],k/numel(uid));
        end

    end

    % ensure some tags are always contained within a cell array
    tags = {'Filename','DENSEindex'};

    for ti = 1:numel(tags)
        if ~isfield(seqdata,tags),continue; end
        for k = 1:numel(seqdata)
            val = seqdata(k).(tags{ti});
            if isempty(val)
                val = {};
            elseif ~iscell(val)
                val = {val};
            end
            seqdata(k).(tags{ti}) = val;
        end
    end



    %% TEST FOR SINGLE PATIENT
    % Though this function is able to work with several distinct patients,
    % we've included code to choose a single patient from the available
    % information via a LISTDLG

    % determine patient UIDs
    [uid,ndx,idx] = unique({seqdata.StudyInstanceUID}');

    if FLAG_options

        if FLAG_waitbar
            set(hwait,'visible','off');
        end

        tf = seqinfogui(seqdata);
        if isempty(tf)
            seqdata = []; uipath = [];
            return;
        end
        seqdata = seqdata(tf);

        if FLAG_waitbar
            set(hwait,'visible','on');
        end
%
%         % measure number of sequences per patient
%         N = arrayfun(@(k)sum(idx==k),(1:numel(uid))');
%
%         % string display format
%         fmt = ['<HTML><FONT color=#000099>[%03d]</FONT> '...
%                '<FONT color=#cc6600>%s</FONT> '...
%                '<FONT color=#000099>%s</FONT> '...
%                '<FONT color=#cc6600>%s</FONT></HTML>'];
%
%         % gather patient identification strings
%         strs = cellfun(...
%             @(n,dt,sd,pn)sprintf(fmt,n,parseDICOMdate(dt),...
%                 sd,parsePatientName(pn)),...
%             num2cell(N),...
%             {seqdata(ndx).StudyDate}',...
%             {seqdata(ndx).StudyDescription}',...
%             {seqdata(ndx).PatientName}',...
%             'uniformoutput',0);
%
%         % listbox prompt
%         prompt = {'Multiple subjects found.';...
%                   ['listed below as: ',...
%                   '[# of sequences] Date / Study / Patient'];...
%                   'Please select subject for analysis.';};
%
%         % display listbox, wait for user selection
%         [sel,ok] = listdlg(...
%             'Name',             'Select Patient',...
%             'PromptString',     prompt,...
%             'ListString',       strs,...
%             'SelectionMode',    'single',...
%             'ListSize',         [500 200]);
%
%         % return in error
%         if ~ok
%             seqdata = []; uipath = [];
%             return;
%         end
%
%         % remove all but selected datasets
%         tf = (idx==sel);
%         seqdata = seqdata(tf);

    end



    %% SEQUENCE VALIDATION
    % Here, we check some sequence fields for expected data. We do
    % not eliminate any sequences from the output, but we mark the
    % sequence as possibly incomplete via the 'ValidSequence' field.

    % default value
    [seqdata.ValidSequence] = deal(true);


    % ensure fields were successfully collapsed
    tags = {'StudyInstanceUID','SeriesInstanceUID','SeriesNumber',...
            'Height','Width','PixelSpacing',...
            'ImagePositionPatient','ImageOrientationPatient',...
            'DENSEid','DENSEdata'};

    for k = 1:numel(seqdata)
        if ~seqdata(k).ValidSequence, continue; end
        for ti = 1:numel(tags)
            if iscell(seqdata(k).(tags{ti}))
                seqdata(k).ValidSequence = false;
                break;
            end
        end
    end


    % We can compare the 'InstanceNumber' to the expected instance
    % numbers (i.e. 1:NumberInSequence) to see if any files are missing
    % from a given sequence. Note that single element sequences are
    % valid.

    for k = 1:numel(seqdata)
        if ~seqdata(k).ValidSequence, continue; end

        try
            N = seqdata(k).NumberInSequence;
            if N==1
                tf = true;
            else
                idx = [seqdata(k).InstanceNumber{:}];
                tf = isequal(idx(:),(1:N)') | ...
                     isequal(idx(:),(0:N-1)');
            end

        catch ERR
            tf = false;
        end

        % save value
        seqdata(k).ValidSequence = tf;

    end



    % We can compare the recovered DENSE information to what it should be.
    % The 'DENSEid' should not be 'unknown', and the 'InstanceNumber',
    % 'DENSEindex', and 'DENSEdata.Number' fields should be consistent.
    for k = 1:numel(seqdata)
        if ~seqdata(k).ValidSequence || ...
           isempty(seqdata(k).DENSEid)
            continue;
        end

        if isequal(seqdata(k).DENSEid,'unknown')
            seqdata(k).ValidSequence = false;
            continue;
        end

        % gather expected indices & test
        try
            N1 = seqdata(k).NumberInSequence;
            N2 = seqdata(k).DENSEdata.Number;
            if ~isequal(N1,N2)
                tf = false;
            elseif N1==1 && numel(seqdata(k).DENSEindex)~=1
                tf = false;
            else
                idx_exp  = 1:seqdata(k).NumberInSequence;
                idx_dns = [seqdata(k).DENSEindex{:}];
                tf = isequal(idx_exp(:),idx_dns(:));
            end
        catch ERR
            tf = false;
        end

        % save value
        seqdata(k).ValidSequence = tf;

    end

    % report to user
    if any(~[seqdata.ValidSequence])
        warning(sprintf('%s:invalidDICOMinformation',mfilename),'%s',...
            'Some sequences could not be validated. ');
    else
        reportFcn({'All unique sequences are valid.\n'},[],[]);
    end

    % set final completion flag
    % (This ensures that the cleanup function does not overwrite the
    %  output with an empty structure)
    str = sprintf('%d DICOM sequences found.',numel(seqdata));
    reportFcn({[str '\n']},str,1);
    if FLAG_waitbar, pause(1); end



    %% HELPER FUNCTION: REPORT & ABORT
    % Report: this function will generate reports to the command line and
    %         update the waitbar. (Note VERBOSE_MSG must be a cell array
    %         of FPRINTF-style inputs)
    % Abort:  this function checks if the user has closed the waitbar,
    %         indicating function cancellation

    function reportFcn(verbose_msg,waitbar_msg,waitbar_x)

        % command line report
        if FLAG_verbose && ~isempty(verbose_msg)
            fprintf(verbose_msg{:});
        end

        % waitbar update
        if FLAG_waitbar && ishandle(hwait)
            if ~isempty(waitbar_x) && ~isempty(waitbar_msg)
                waitbar(waitbar_x,hwait,waitbar_msg);
            elseif ~isempty(waitbar_x)
                waitbar(waitbar_x,hwait);
            end
        end

        % allow functions to executre
        if FLAG_verbose || FLAG_waitbar
            drawnow
        end

    end


    function tf = abortFcn()
        if FLAG_waitbar && ~ishandle(hwait)
            if FLAG_verbose, disp('ABORT'); end
            seqdata = [];
            uipath = [];
            tf = true;
        else
            tf = false;
        end
    end


end

%% CLEANUP FUNCTIONS
% we associate "onCleanup" objects with the waitbar, ensuring it is closed
% if we exit in error...

function hwaitCleanupFcn(hwait)
    if ishandle(hwait)
        delete(hwait);
        drawnow;
    end
end



%% END OF FILE=============================================================
