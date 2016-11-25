function [out, uipath, uifile] = DNSFileLoader(startpath)
    % DNSFileLoader - Loading function for previously saved .dns files
    %
    %   This is a loader that is used by DENSEdata.load to populate a
    %   DENSEdata object from a directory containing DICOM files.
    %
    % USAGE:
    %   [out, uipath, uifile] = DNSFileLoader(startpath)
    %
    % INPUTS:
    %   startpath:  String, Directory in which to initially look for DNS
    %               files. A file selection dialog will be launched and
    %               this will be the initial directory. Alternately, if a
    %               complete file path to a .dns file is provided, that
    %               file will be loaded directly WITHOUT launching a file
    %               load dialog.
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

    % If no filename was provided explicitly, then prompt the user
    out = [];

    if ~exist('startpath', 'var')
        startpath = pwd;
    end

    % test startpath
    if ~ischar(startpath)
        error(sprintf('%s:invalidInput',mfilename),...
            '"startpath" must be a valid directory string.');
    elseif exist(startpath, 'file') == 2
        filename = which(startpath);
        startpath = fileparts(filename);
    elseif ~exist(startpath, 'dir')
        warning(sprintf('%s:invalidInput',mfilename),'%s',...
            'The directory <', startpath, '> could not be located.')
        startpath = pwd;
    end

    if ~exist('filename', 'var')
        % locate a file to load
        [uifile,uipath] = uigetfile(...
            {'*.dns','DENSE workspace (*.dns)'},...
            'Select DNS file',startpath);
        if isequal(uipath,0)
            uipath = [];
            return;
        end

        filename = fullfile(uipath, uifile);
    else
        [uipath, uifile] = fileparts(filename);
    end

    % create load waitbar
    hwait = waitbartimer;
    cleanupObj = onCleanup(@()delete(hwait(isvalid(hwait))));
    hwait.WindowStyle = 'modal';
    hwait.String      = 'Loading workspace...';
    hwait.start;
    drawnow

    % load file
    S = load(filename,'-mat');
    if ~all(isfield(S,{'seq','img','dns','roi'}))
        error(sprintf('%s:invalidFile',mfilename),...
            '".dns" file does not contain appropriate data.');
    end

    seq = S.seq(:);
    img = S.img(:);
    dns = S.dns(:);
    roi = S.roi(:);
    clear S

    % run a quick hack error check:
    % if "autoDENSEgroups" returns without error, we probably have
    % good valid seq with some sort of DENSE data in it.
    autoDENSEgroups(seq);

    % re-parse the "ImageComments" field of the first image in
    % all DENSE sequences to find the Partition information.
    % this needs to be done for backward compatability.
    for k = 1:numel(seq)
        if ~isempty(seq(k).DENSEid)
            if iscell(seq(k).ImageComments)
                str = seq(k).ImageComments{1};
            else
                str = seq(k).ImageComments;
            end
            [~,data] = parseImageCommentsDENSE(str);
            seq(k).DENSEdata.Partition = data.Partition;
        end
    end

    % re-parse the slice identifiers
    slcdata = DICOMslice(seq,{seq.NumberInSequence});
    tags = fieldnames(slcdata);
    for k = 1:numel(seq)
        for ti = 1:numel(tags)
            seq(k).(tags{ti}) = slcdata(k).(tags{ti});
        end
    end

    out.seq = seq;
    out.img = img;
    out.dns = dns;
    out.roi = roi;
end
