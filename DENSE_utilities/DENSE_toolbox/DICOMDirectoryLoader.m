function [out, uipath, uifile] = DICOMDirectoryLoader(obj, startpath)
    % DICOMDirectoryLoader - Loading function for DICOM files from folders
    %
    %   This is a loader that is used by DENSEdata.load to populate a
    %   DENSEdata object from a directory containing DICOM files.
    %
    % USAGE:
    %   [out, uipath, uifile] = DICOMDirectoryLoader(obj, startpath)
    %
    % INPUTS:
    %   obj:        DENSEdata Object, Handle to the DENSEdata object that
    %               initiated the call this function.
    %
    %   startpath:  String, Directory in which to initially look for DICOM
    %               files. A file selection dialog will be launched and
    %               this will be the initial directory.
    %
    % OUTPUTS:
    %   out:        Struct, DENSEdata structure that will be used to
    %               populate the DENSEdata object.
    %
    %   uipath:     String, Path that was ultimately selected for loading
    %               all of the images in.
    %
    %   uifile:     String, Empty value indicating that no actual files
    %               were selected for loading by this loader.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    % empty workspace file output
    uifile = [];
    out = [];

    % test startpath
    if ~ischar(startpath)
        error(sprintf('%s:invalidInput',mfilename),...
            '"startpath" must be a valid directory string.');
    elseif exist(startpath, 'dir') ~= 7
        warning(sprintf('%s:invalidInput',mfilename),'%s',...
            'The directory <', startpath, '> could not be located.')
        startpath = pwd;
    end

    % load DICOM data
    [seq, uipath] = DICOMseqinfo(startpath, 'OptionsPanel', true);
    if isempty(seq)
        uipath = [];
        return;
    end

    % try to locate groups
    dns = autoDENSEgroups(seq,'Types',obj.autodensetypes,'verbose',false);

    % load slice information & add to seq
    slcdata = DICOMslice(seq,{seq.NumberInSequence});
    tags = fieldnames(slcdata);
    for k = 1:numel(seq)
        for ti = 1:numel(tags)
            seq(k).(tags{ti}) = slcdata(k).(tags{ti});
        end
    end

    % generate sequence name & program UID
    for k = 1:numel(seq)
        sd = seq(k).SeriesDescription;
        if isempty(sd) || ~ischar(sd)
            sd = 'unknown';
        end
        seq(k).DENSEanalysisName = sd;
        seq(k).DENSEanalysisUID  = dicomuid;
        seq(k).TranslationRC = [0 0];
    end

    % shift new fields to top of structure
    Nfield = numel(fieldnames(seq));
    Nnew   = 2;
    seq = orderfields(seq,[Nfield+(1-Nnew:0),1:Nfield-Nnew]);

    % load imagery
    cancel = ~[seq.ValidSequence];
    img = DICOMseqread(seq,'CancelRead',cancel);

    if isempty(img);
        uipath = [];
        return;
    end

    % empty roi
    roi = repmat(struct,[0 1]);

    out.dns = dns;
    out.roi = roi;
    out.seq = seq;
    out.img = img;
end
