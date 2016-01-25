function buf = DICOMcellstr(metadata)

%DICOMCELLSTR convert DICOM header info into a formatted cellstr
%
%INPUTS
%   metadata.....DICOM header structure (see DICOMINFO or DICOMSEQINFO)
%
%OUTPUTS
%   buf..........CELLSTR of header information
%
%USAGE
%
%   BUF = DICOMCELLSTR(METADATA) converts the METADATA structure derived
%   from DICOMINFO or DICOMSEQINFO into a cell array of strings, suitable
%   for display in a UICONTROL listbox.  BUF will display all non-empty
%   fields of METADATA. Additionally, some Study/Patient/Series/Slice
%   identifiers are moved to the top of the display for easier access.
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

    % check for input structure
    if ~isstruct(metadata) || numel(metadata)~=1
        error(sprintf('%s:invalidInput',mfilename),...
            'Input must be [1x1] structure.');
    end


    % top tags
    % (note the empty tag '' provides an empty line on the display)
    toptags = {...
        'StudyDescription';'StudyDate';'StudyTime';...
        'ProtocolName';'StudyInstanceUID';'';...
        'PatientName';'PatientID';'PatientBirthDate';'PatientSex';...
        'PatientAge';'PatientWeight';'';...
        'SeriesNumber';'SeriesDescription';'SeriesDate';'SeriesTime';...
        'SeriesInstanceUID';'NumberInSequence';'';...
        'Height';'Width';'PixelSpacing';'DENSEid';'DENSEdata';...
        'ImagePositionPatient';'ImageOrientationPatient';'';};

    % all SEQDATA tags
    fields = fieldnames(metadata);
    tf = ismember(fields,toptags);
    tags = [toptags(:); fields(~tf)];

    % gather tag string names
    % using "char" ensures all tags are initially the same length
    buf = char(tags);

    % convert to cellstr (without trimming)
    buf = mat2cell(buf,ones(size(buf,1),1),size(buf,2));

    % replace whitespace with '.'
    buf = strcat(regexprep(buf,'\s','\.'),'....');

    % parse tag values
    tf = true(size(buf));
    for ti = 1:numel(tags)

        % gather tag & value
        tag = tags{ti};
        if isempty(tag)
            buf{ti} = '';
            continue;
        end
        val = [];
        if isfield(metadata,tag), val = metadata.(tag);  end


        % empty field
        if isempty(val)
            if ismember(tag,toptags)
                str = '[]';
            else
                tf(ti) = false;
                continue;
            end

        % Date & Time
        elseif any(strcmpi(tag,{'PatientBirthDate','StudyDate','SeriesDate'}))
            str = parseDICOMdate(val,'yyyy.mm.dd');
        elseif any(strcmpi(tag,{'StudyTime','SeriesTime'}))
            str = parseDICOMtime(val,'HH:MM:SS.FFF');

        % Names
        elseif isequal(tag,'PatientName')
            str = parsePatientName(val);

        % DENSE data
        elseif isequal(tag,'DENSEdata')
            str = sprintf('%.2f/%.2f/%d/[%d%d%d] (sc/en/sw/ng)',...
                val.Scale,val.EncFreq,val.SwapFlag,val.NegFlag);

        % general string
        elseif ischar(val)
            str = val;

        % numbers & logicals
        elseif isinteger(val)
            str = num2str(val(:)','%d ');
        elseif isnumeric(val) && all(mod(val(:),1) == 0)
            str = num2str(val(:)','%d ');
        elseif isnumeric(val)
            str = num2str(val(:)','%f ');
        elseif islogical(val)
            tmp = {'false','true'};
            str = sprintf('%s ',tmp{val(:)+1});

        % otherwise - note the size & class
        else
            str = sprintf('%dx',size(val));
            str = sprintf('[%s] %s',str(1:end-1),class(val));
        end

        % update cellstr
        buf{ti} = sprintf('%s %s',buf{ti},str);
    end

    % remove invalid fields
    buf = buf(tf);

end

