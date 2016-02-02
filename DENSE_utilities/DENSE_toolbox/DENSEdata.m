%% DENSE DATA CLASS DEFINITION
% This class holds and manages the necessary data for the DENSEanalysis
% GUI, ensuring that we never make multiple copies of these large
% arrays of structures and cells and that the user does not acidentally
% change any data structures.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

classdef DENSEdata < handle

    % get-only ptoperties
    properties (SetAccess='private')

        % sequence/image information
        seq = repmat(struct,[0 1]);
        img = cell(0,1);

        % DENSE group information
        dns = repmat(struct,[0 1]);

        % ROI information
        roi = repmat(struct,[0 1]);

        % SPLINE information
        spl = repmat(struct,[0 1]);

    end

    % private properties
    properties (SetAccess='private',GetAccess='private')

        % loading flags
        autodensetypes   = {'xy','xyz'};
        manualdensetypes = {'x','y','z','xy','xyz'};

    end


    %
    events
        NewState
    end


    methods

        % constructor
        function obj = DENSEdata(varargin)
           % do nothing
        end

        % load data from file
        function [uipath,uifile] = load(obj,varargin)
            [uipath,uifile] = loadFcn(obj,varargin{:});
        end

        % save data to file
        function uifile = save(obj,varargin)
            uifile = saveFcn(obj,varargin{:});
        end


        % rename objects
        function renameSequence(obj,idx,varargin)
            renameFcn(obj,'seq',idx,varargin{:});
        end
        function renameDENSE(obj,idx,varargin)
            renameFcn(obj,'dns',idx,varargin{:});
        end
        function renameROI(obj,idx,varargin)
            renameFcn(obj,'roi',idx,varargin{:});
        end


        % locate unique identifiers
        function idx = UIDtoIndexROI(obj,uid)
            idx = UIDtoIndexFcn(obj,'roi',uid);
        end

        function idx = UIDtoIndexDENSE(obj,uid)
            idx = UIDtoIndexFcn(obj,'dns',uid);
        end



        % ROI functions
        function roiidx = createROI(obj,seqidx)
            roiidx = createROIFcn(obj,seqidx);
        end

        function deleteROI(obj,idx)
            deleteElementFcn(obj,'roi',idx);
        end

        function updateROI(obj,idx,frame,data)
            updateROIFcn(obj,idx,frame,data);
        end

        function roiidx = findROI(obj,seqidx)
            roiidx = findROIFcn(obj,seqidx);
        end

        % DENSE function
        function editDENSE(obj)
            editDENSEFcn(obj);
        end

        function regDENSE(obj,didx)
            regDENSEFcn(obj,didx);
        end


        function data = getDisplayData(obj)
            data = getDisplayDataFcn(obj);
        end

        function spdata = analysis(obj,varargin)
            spdata = analysisFcn(obj,varargin{:});
        end

        function tf = isAllowAnalysis(obj,varargin)
            tf = isAllowAnalysisFcn(obj,varargin{:});
        end

        function tf = isAllowExportROI(obj,varargin)
            tf = isAllowExportROIFcn(obj,varargin{:});
        end

        function data = exportROI(obj,varargin)
            data = exportROIFcn(obj,varargin{:});
        end

        function imdata = imagedata(varargin)
            imdata = ImageData(varargin{:});
        end

        function condata = contourdata(varargin)
            condata = contourData(varargin{:});
        end
    end


    methods (Hidden=true)

        function tf = isempty(obj)
            tf = isempty(obj.seq);

        end

    end



end




%% LOAD DENSE DATA
% This function allows the user to load two types of data from file:
% 1) DICOM data, 2) MAT-file data (using the ".dns" extension)
%
%

function [uipath,uifile] = loadFcn(obj,type,startpath)

    % default inputs
    if nargin < 2 || isempty(type),      type = 'dicom';  end
    if nargin < 3 || isempty(startpath), startpath = pwd; end

    % If the startpath was a full filepath, load that without prompt
    if exist(startpath, 'file') == 2
        filename = startpath;
        startpath = pwd;
    end

    % test type input
    if ~ischar(type) || ~any(strcmpi(type,{'dicom','mat'}))
        error(sprintf('%s:invalidInput',mfilename),...
            'Valid ''type'' string options are be [dicom|mat].');
    end

    % test startpath
    if ~ischar(startpath)
        error(sprintf('%s:invalidInput',mfilename),...
            '"startpath" must be a valid directory string.');
    elseif exist(startpath,'dir')~=7
        warning(sprintf('%s:invalidInput',mfilename),'%s',...
            'The directory <', startpath, '> could not be located.')
        startpath = pwd;
    end


    % DIRECTORY LOAD-------------------------------------------------------
    if strcmpi(type,'dicom')

        % empty workspace file output
        uifile = [];

        % load DICOM data
        [seq,uipath] = DICOMseqinfo(startpath,...
            'OptionsPanel',true);
        if isempty(seq)
            uipath = [];
            return;
        end

        % try to locate groups
        dns = autoDENSEgroups(seq,'Types',obj.autodensetypes,...
            'verbose',false);

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

    % MAT FILE LOAD--------------------------------------------------------
    else
        % If no filename was provided explicitly, then prompt the user
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
            [uipath,uifile] = fileparts(filename);
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
                [id,data] = parseImageCommentsDENSE(str);
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

    end


    % CLEANUP--------------------------------------------------------------
    % some silly tests
    if ~isstruct(seq) || isempty(seq) || ~iscell(img) || ...
       ~isstruct(dns) || ~isstruct(roi)
       error(sprintf('%s:invalidData',mfilename),....
            'Some loaded variables were not as expected.');
    end

    % backwards-compatability: add TranslationRC field
    if ~isfield(seq,'TranslationRC')
        [seq.TranslationRC] = deal([0 0]);
    end


    % empty any remaining "invalid" sequences
    for k = 1:numel(img)
        if isequal(seq(k).ValidSequence,false)
            img{k} = [];
        end
    end

    % test for some valid data
    tf = cellfun(@isempty,img);
    if all(tf)
        error(sprintf('%s:invalidData',mfilename),....
            'We were unable to locate valid DICOM data!');
    elseif any(tf)
        errstr = sprintf('%s','Some DICOM sequences seem ',...
            'to be missing files, and will thus not be displayed. ',...
            'You may want to locate any missing files and create ',...
            'a new workspace before continuing.');
        h = warndlg(errstr,'Invalid sequences...','modal');
        waitfor(h);
    end

    % eliminate any unsupported dns groups (e.g. single encodings)
    tf = true(size(dns));
    for k = 1:numel(dns)
        tf(k) = any(strcmpi(dns(k).Type,obj.manualdensetypes));
    end
    dns = dns(tf);

    % throw a warning dialog if there are no groups
    if isempty(dns)
        errstr = sprintf('%s','The program is unable to automatically ',...
            'locate any DENSE groups in the DICOM data, though there ',...
            'is some valid DENSE data available.  You''ll need to ',...
            'create the groups yourself.');
        h = warndlg(errstr,'No DENSE groups...','modal');
        waitfor(h);
    end

    % save all data to object
    obj.seq = seq;
    obj.img = img;
    obj.dns = dns;
    obj.roi = roi;
    obj.spl = repmat(struct,[0 1]);

    % events
    notify(obj,'NewState',DENSEEventData('load',[]));

end


function file = saveFcn(obj,uipath,uifile,flag_fileselect)

    % default file name
    deffile = 'workspace.dns';

    % default path
    if nargin < 2 || isempty(uipath), uipath = pwd; end
    if nargin < 3 || isempty(uifile), uifile = deffile; end
    if nargin < 4 || isempty(flag_fileselect), flag_fileselect = true; end

    % check directory
    if ~isdir(uipath)
        uipath = pwd;
        flag_fileselect = true;
    end

    % check file
    file = fullfile(uipath,uifile);
    if ~isfile(file)
        file = fullfile(uipath,deffile);
        flag_fileselect = true;
    end

    % user-selected file
    if flag_fileselect

        % select file
        [uifile,uipath] = uiputfile(...
            {'*.dns','DENSE workspace Files (*.dns)'},...
            [],file);
        if isequal(uifile,0),
            file = [];
            return;
        end

        % gather filename
        if ~strwcmpi(uifile,'*.dns'), uifile = [uifile '.dns']; end
        file = fullfile(uipath,uifile);

    end

    % waitbar
    [~,f,e] = fileparts(file);
    str = [f e];
    hwait = waitbar(0,{'Saving';str},...
        'WindowStyle','modal',...
        'CloseRequestFcn',[]);
    try
        htext = findall(hwait,'type','text');
        set(htext,'interpreter','none');
    catch
    end

    drawnow, pause(0.1);

    try
        % save to file
        seq = obj.seq; %#ok
        img = obj.img; %#ok
        dns = obj.dns; %#ok
        roi = obj.roi; %#ok
    %     for k = 1:numel(roi), roi(k), end
        save(file,'seq','img','dns','roi');

        waitbar(1,hwait,{'Save Complete';str});
        pause(1);
        close(hwait,'force');

    catch ERR
        if ishandle(hwait), close(hwait,'force'); end
        rethrow(ERR);
    end
end




function roiidx = createROIFcn(obj,seqidx)

    % check for empty object
    if isempty(obj.seq)
        error(sprintf('%s:cannotCreateROI',mfilename),...
            'DENSEdata object is empty.')
    end

    % check sequence index
    rng = [1 numel(obj.seq)];
    if ~isnumeric(seqidx) || ~isscalar(seqidx) || ...
       seqidx < rng(1) || rng(2) < seqidx
        error(sprintf('%s:invalidSequenceIndex',mfilename),...
            'Invalid sequence index.')
    end

    % default name
    name = sprintf('ROI.%d',numel(obj.roi) + 1);

    roi = newroigui(obj,seqidx,'Name',name);
    if isempty(roi)
        roiidx = [];
        return;
    end

    % copy new ROI to the object
    roiidx = numel(obj.roi)+1;
    tags = fieldnames(roi);
    for ti = 1:numel(tags)
        obj.roi(roiidx).(tags{ti}) = roi.(tags{ti});
    end

    % notify event
    notify(obj,'NewState',DENSEEventData('new','roi'));
end



function roiidx = findROIFcn(obj,seqidx)

    % check sequence index
    if ~isnumeric(seqidx) || ...
       any(seqidx < 1) || any(numel(obj.seq) < seqidx)
        error(sprintf('%s:invalidIndex',mfilename),...
            'Invalid sequence index.')
    end

    % no rois in data
    if isempty(obj.roi)
        roiidx = [];
        return;
    end

    % locate any ROI with the same slice id as the
    % specified sequence index
    tf = cellfun(@(x)~isempty(intersect(seqidx,x)),{obj.roi.SeqIndex});
    roiidx = find(tf);
    roiidx = roiidx(:);

end


function idx = UIDtoIndexFcn(obj,tag,uid)

    if ~iscell(uid), uid = {uid}; end
    if ~iscellstr(uid)
        error(sprintf('%s:invalidUID',mfilename),...
            'UIDs must be valid single string or cellstr.');
    end

    % initialize output
    idx = NaN(size(uid));
    if isempty(obj.(tag)), return; end

    % gather ROI UIDs
    switch tag
        case {'roi','dns'}
            datauid = {obj.(tag).UID}';
        otherwise
            error(sprintf('%s:invalidField',mfilename),...
                'Unrecognized field.');
    end


    for k = 1:numel(uid)
        tf = strcmpi(uid{k},datauid);
        if any(tf)
            idx(k) = find(tf,1,'first');
        end
    end


end


function updateROIFcn(obj,roiidx,frame,data)

    % test for some valid ROI
    if isempty(obj.roi)
        error(sprintf('%s:emptyROI',mfilename),...
            'DENSEdata ROI data is currently empty.')
    end

    % check ROI index
    rng = [1 numel(obj.roi)];
    if ~isnumeric(roiidx) || ~isscalar(roiidx) || ...
       roiidx < rng(1) || rng(2) < roiidx
        error(sprintf('%s:invalidIndex',mfilename),...
            'Invalid ROI index.')
    end

    % check frame
    rng = [1 size(obj.roi(roiidx).Position,1)];
    if ~isnumeric(frame) || ~isscalar(frame) || ...
       frame < rng(1) || rng(2) < frame
        error(sprintf('%s:invalidIndex',mfilename),...
            'Invalid ROI frame.')
    end

    % test data
    tags = {'Position','IsClosed','IsCurved','IsCorner'};

    if ~isstruct(data) || ~all(isfield(data,tags))
        error(sprintf('%s:invalidROIData',mfilename),...
            'Invalid ROI data structure.')
    end

    for ti = 1:numel(tags)
        tag = tags{ti};
        sz = size(obj.roi(roiidx).(tag),2);

        if ~iscell(data.(tag)) || ...
           ~any(numel(data.(tag)) == [1 sz])
            error(sprintf('%s:invalidROIData',mfilename),'%s',...
                'Invalid ROI data field: ',tag,'.')
        end
    end

    % copy to ROI
    [obj.roi(roiidx).Position{frame,:}] = deal(data.Position{:});
    [obj.roi(roiidx).IsClosed{frame,:}] = deal(data.IsClosed{:});
    [obj.roi(roiidx).IsCurved{frame,:}] = deal(data.IsCurved{:});
    [obj.roi(roiidx).IsCorner{frame,:}] = deal(data.IsCorner{:});

end




function data = getDisplayDataFcn(obj)
    mxpha = 2^12-1;

    emptydata = struct(...
        'isValid',          false,...
        'ImageSize',        NaN(1,2),...
        'PixelSpacing',     NaN(1,2),...
        'NumberOfFrames',   NaN,...
        'ILim',             NaN(1,2),...
        'TranslationRC',    NaN(1,2));

    if isempty(obj)
        data = repmat(emptydata,[0 1]);
    else

        N = numel(obj.seq);
        data = repmat(emptydata,[N 1]);

        for k = 1:N
            if ~isempty(obj.img{k})
                if strwcmpi(obj.seq(k).DENSEid,'*pha*')
                    mx = mxpha * ones(size(obj.img{k},3),1);
                else
                    mx  = double(max(max(obj.img{k})));
                end
                Isz = size(obj.img{k}(:,:,1));
                px  = obj.seq(k).PixelSpacing;

                data(k).isValid        = true;
                data(k).ImageSize      = Isz;
                data(k).PixelSpacing   = px;
                data(k).NumberOfFrames = size(obj.img{k},3);
                data(k).ILim           = [zeros(size(mx(:))),mx(:)];
                data(k).TranslationRC  = obj.seq(k).TranslationRC;
            end
        end

    end

end



function renameFcn(obj,tag,idx,name)

    % check for empty object
    if isempty(obj.(tag))
        error(sprintf('%s:invalidRename',mfilename),...
            'Object field is empty, cannot rename.');
    end

    % check index
    rng = [1 numel(obj.(tag))];
    if ~isnumeric(idx) || ~isscalar(idx) || ...
       idx < rng(1) || rng(2) < idx
        error(sprintf('%s:invalidIndex',mfilename),...
            'Index to rename cannot be found.');
    end

    % enter new name
    if nargin < 4
        switch tag
            case 'seq'
                curname = obj.seq(idx).DENSEanalysisName;
                ttl = 'Edit Sequence Name';
            case 'dns'
                curname = obj.dns(idx).Name;
                ttl = 'Edit DENSE Name';
            case 'roi'
                curname = obj.roi(idx).Name;
                ttl = 'Edit ROI Name';
        end
        if isempty(curname), curname = ''; end

        answer = inputdlg({'Enter new name:'},ttl,1,{curname});
        if numel(answer)==0, return; end

        name = answer{1};
        if isequal(name,curname), return; end

    end

    % check name for string
    if isempty(name), name = ''; end
    if ~ischar(name)
        error(sprintf('%s:invalidIndex',mfilename),...
            'New name must be a valid string.');
    end

    % save new name
    switch tag
        case 'seq'
            obj.seq(idx).DENSEanalysisName = name;
        case 'dns'
            obj.dns(idx).Name = name;
        case 'roi'
            obj.roi(idx).Name = name;
    end

    % signal event
    notify(obj,'NewState',DENSEEventData('rename',tag));

end




function deleteElementFcn(obj,tag,idx)

    % check for empty object
    if isempty(obj.(tag))
        error(sprintf('%s:invalidDelete',mfilename),...
            'Object field is empty, cannot rename.');
    end

    % check index
    rng = [1 numel(obj.(tag))];
    if ~isnumeric(idx) || ~isscalar(idx) || ...
       idx < rng(1) || rng(2) < idx
        error(sprintf('%s:invalidIndex',mfilename),...
            'Index to rename cannot be found.');
    end

    % offer chance to cancel
    str = {'Delete cannot be undone.';'Continue?'};
    answer = questdlg(str,'Delete','OK','Cancel','Cancel');
    if ~isequal(answer,'OK'), return; end

    % remove element
    obj.(tag)(idx) = [];

    % notify event
    notify(obj,'NewState',DENSEEventData('delete',tag));

end


%% ANALYSIS FUNCTION


function spdata = analysisFcn(obj,didx,ridx,seedframe,varargin)

    % gather data
    imdata = imageData(obj,didx);
    cndata = contourData(obj,ridx);

    % ensure DENSE/ROI indices overlap
    sidx = [imdata.MagIndex; imdata.PhaIndex];

    if isempty(intersect(cndata.SeqIndex(:),sidx(:)))
        roibuf = sprintf('%d,',   cndata.SeqIndex);
        dnsbuf = sprintf('%d/%d,',sidx(~isnan(sidx)));
        error(sprintf('%s:indicesDoNotMatch',mfilename),'%s',...
            'The ROI sequence indices [',roibuf(1:end-1),...
            '] do not match the DENSE sequence indices [',...
            dnsbuf(1:end-1),']');
    end

    % check seedframe
    rng = cndata.ValidFrames;
    if ~isnumeric(seedframe) || ~isscalar(seedframe) || ...
       seedframe < rng(1) || rng(2) < seedframe
        error(sprintf('%s:invalidFrame',mfilename),...
            'Frame is invalid.');
    end

    % if the current resident analysis "spl" is of the same indices,
    % gather those parameters & pass to the DENSESPLINE function
    options = struct('FramesForAnalysis',cndata.ValidFrames);
    tagsA = {'ResampleMethod','SpatialSmoothing','TemporalOrder'};
    tagsB = {'Xseed','Yseed','Zseed'};
    if ~isempty(obj.spl)
        for ti = 1:numel(tagsA)
            options.(tagsA{ti}) = obj.spl.(tagsA{ti});
        end

        dlast = UIDtoIndexDENSE(obj,obj.spl.DENSEUID);
        rlast = UIDtoIndexROI(obj,obj.spl.ROIUID);
        if isequal(dlast,didx) && isequal(rlast,ridx)
            for ti = 1:numel(tagsB)
                options.(tagsB{ti}) = obj.spl.(tagsB{ti});
            end
            if cndata.ValidFrames(1)<=obj.spl.frrng(1) && ...
               obj.spl.frrng(2)<=cndata.ValidFrames(2) && ...
               obj.spl.frrng(1)<=seedframe && seedframe<=obj.spl.frrng(2)
                options.FramesForAnalysis = obj.spl.frrng;
            end
        end
    end

    % 'UnwrapConnectivity' option based on ROI type
    if any(strcmpi(cndata.ROIType,{'open','closed'}));
        options.UnwrapConnectivity = 8;
    end

    % initialize waitbar timer
    hwait = waitbartimer;
    cleanupObj = onCleanup(@()delete(hwait(isvalid(hwait))));
    hwait.String = 'Performing Analysis...';
    hwait.WindowStyle = 'modal';
    hwait.AllowClose  = false;
    hwait.start;


    % Perform analysis
    try
        spdata = DENSEspline(imdata,cndata,options,...
            'SeedFrame',seedframe,'OptionsPanel',true, varargin{:});
    catch ERR
        hwait.stop;
        delete(hwait);
        errstr = sprintf('%s','Analysis error - more information will be ',...
            'printed to the command line.');
        h = errordlg(errstr,'Analysis error!','modal');
        waitfor(h);
        rethrow(ERR);
    end

    % remove waitbar timer
    hwait.stop;
    delete(hwait)

    if ~isempty(spdata)
        spdata.DENSEUID = obj.dns(didx).UID;
        spdata.ROIUID   = obj.roi(ridx).UID;
        spdata.Mag      = imdata.Mag;
        spdata.DENSEType = imdata.DENSEType;
        spdata.ROIType   = cndata.ROIType;

        obj.spl = spdata;
        notify(obj,'NewState',DENSEEventData('new','spl'));
    end

end


function tf = isAllowAnalysisFcn(obj,didx,ridx,frame)

    % attempt to gather data, testing the indices
    try
        imdata = imageData(obj,didx,true);
        cndata = contourData(obj,ridx,frame,true);
    catch
        tf = false;
        return
    end

    % ensure DENSE/ROI indices overlap
    sidx = [imdata.MagIndex; imdata.PhaIndex];
    if isempty(intersect(cndata.SeqIndex(:),sidx(:)))
        tf = false;
        return
    end

    % return valid!
    tf = true;

end



%% MASK FUNCTIONS
function tf = maskSA(X,Y,C)
    [inep,onep] = inpolygon(X,Y,C{1}(:,1),C{1}(:,2));
    [inen,onen] = inpolygon(X,Y,C{2}(:,1),C{2}(:,2));
    tf = (inep & ~inen) | onep | onen;
end

function tf = maskLA(X,Y,C)
    C = cat(1,C{:});
    tf = inpolygon(X,Y,C(:,1),C(:,2));
end

function tf = maskLine(X,Y,C)
    tf = false(size(X));
    for n = 1:numel(C)
        tf = tf | pixelize(C{n},X,Y);
    end
end

function tf = maskGeneral(X,Y,C)
    tf = false(size(X));
    for n = 1:numel(C)
        tf = tf | inpolygon(X,Y,C{n}(:,1),C{n}(:,2));
    end
end


function imdata = ImageData(obj,didx,checkonlyflag)
    if nargin < 3 || isempty(checkonlyflag)
        checkonlyflag = false;
    end


    % check for empty object
    if isempty(obj.seq) || isempty(obj.dns)
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'One or more object fields are empty.');
    end

    % check DENSE index
    rng = [1 numel(obj.dns)];
    if ~isnumeric(didx) || ~isscalar(didx) || ...
       didx < rng(1) || rng(2) < didx
        error(sprintf('%s:invalidDENSEIndex',mfilename),...
            'DENSE Index is invalid.');
    end

    % current DENSE object
    dns = obj.dns(didx);

    % indices
    midx = dns.MagIndex;
    pidx = dns.PhaIndex;
    sidx = [midx; pidx];

    if checkonlyflag
        Mag = [];
        I = cell(2,3);

    else

        % gather imagery
        I = cell(2,3);
        tf = ~isnan(sidx);
        I(tf) = obj.img(sidx(tf));

        % register imagery
        for k = 1:6
            if ~isnan(sidx(k))
                shft = obj.seq(sidx(k)).TranslationRC;
                I{k} = imtranslate(I{k},shft);
            end
        end

        % ensure imagery is double floating point
        % normalize magnitude imagery per frame onto the range [0 1]
        % normalize phase imagery onto the range [-pi pi]
        mxpha = 2^12 - 1;

        for k = 1:3

            if ~isnan(midx(k))
                I{1,k} = double(I{1,k});
                for fr = 1:size(I{1,k},3)
                    mx = max(max(I{1,k}(:,:,fr)));
                    I{1,k}(:,:,fr) = I{1,k}(:,:,fr) / mx;
                end
            end

            if ~isnan(pidx(k))
                I{2,k} = 2*pi*(double(I{2,k})/mxpha) - pi;
            end

        end


        % determine multi-type, indicating we should apply swap x/y,
        % and negate phase information if necessary
%         if any(strcmpi(dns.Type,{'xy','xyz'}));

            % swap imagery & associated parameters
            if dns.SwapFlag
                I(:,[1 2]) = I(:,[2 1]);
                dns.Scale(:,[1 2])   = dns.Scale(:,[2 1]);
                dns.EncFreq(:,[1 2]) = dns.EncFreq(:,[2 1]);
            end

            % negate phase imagery
            for k = 1:3
                if dns.NegFlag(k)
                    I{2,k} = -I{2,k};
                end
            end

%         end

        % gather magnitude information
        % (average of normalized magnitude frames)
        Mag = 0;
        for k = 1:3
           if ~isempty(I{1,k})%~isnan(midx(k))
               Mag = Mag + I{1,k};
           end
        end
        Mag = Mag / sum(~isnan(midx));
    end

    % image data structure
    imdata = struct(...
        'DENSEType',    dns.Type,...
        'MagIndex',     midx,...
        'PhaIndex',     pidx,...
        'Mag',          Mag,...
        'Xpha',         I(2,1),...
        'Ypha',         I(2,2),...
        'Zpha',         I(2,3),...
        'PixelSpacing', dns.PixelSpacing,...
        'EncFreq',      dns.EncFreq,...
        'Scale',        dns.Scale);

end


function cndata = contourData(obj,ridx,frames,checkonlyflag)
    if nargin < 4 || isempty(checkonlyflag)
        checkonlyflag = false;
    end

    % check for empty object
    if isempty(obj.seq) || isempty(obj.roi)
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'One or more object fields are empty.');
    end

    % check indices
    rng = [1 numel(obj.roi)];
    if ~isnumeric(ridx) || ~isscalar(ridx) || ...
       ridx < rng(1) || rng(2) < ridx
        error(sprintf('%s:invalidROIIndex',mfilename),...
            'ROI Index is invalid.');
    end

    % gather object
    roi  = obj.roi(ridx);
    pos  = obj.roi(ridx).Position;
    Nfr  = size(pos,1);
    sidx = roi.SeqIndex;

    % empty ROI frames positions
    tf = cellfun(@isempty,pos);
    emptypos = any(tf,2);

    % check for ROI continuity
    idx = find(~emptypos);
    if any(emptypos(idx(1):idx(end)))
        error(sprintf('%s:invalidPosition',mfilename),...
            'The ROI is not defined on a continuous frame range.');
    end

    % default inputs
    if nargin < 3 || isempty(frames), frames = idx; end

    % check frames
    if ~isnumeric(frames) || any(mod(frames,1)~=0) || ...
       any(frames < 1) || any(Nfr < frames)
        error(sprintf('%s:invalidFrame',mfilename),...
            'Frame Index is invalid.');
    end

    % check for valid positions
    if any(emptypos(frames))
        error(sprintf('%s:invalidFrame',mfilename),...
            'The ROI has not been defined on one or more frames.');
    end


    if checkonlyflag
        maskfcn = [];
        C = [];
    else
        % mask function
        switch lower(roi.Type)
            case 'sa',
                maskfcn = @(X,Y,C)maskSA(X,Y,C);
            case 'la',
                maskfcn = @(X,Y,C)maskLA(X,Y,C);
            case {'closed','open'}
                maskfcn = @(X,Y,C)maskLine(X,Y,C);
            otherwise
                maskfcn = @(X,Y,C)maskGeneral(X,Y,C);
        end

        % contour retrieval
        C = repmat({zeros(0,2)},size(pos));
        for fr = frames(:)'
            for k = 1:size(C,2)
                seg = clinesegments(pos{fr,k},...
                    roi.IsClosed{fr,k},roi.IsCurved{fr,k},...
                    roi.IsCorner{fr,k},0.5);
                crv = cat(1,seg{:});
                tf = [true; all(crv(2:end,:)~=crv(1:end-1,:),2)];
                C{fr,k} = crv(tf,:);
            end
        end
    end

    % save contour data
    cndata = struct(...
        'ROIType',      roi.Type,...
        'SeqIndex',     roi.SeqIndex,...
        'Contour',      {C},...
        'MaskFcn',      maskfcn,...
        'ValidFrames',  frames([1 end]));

end



%% EDIT DENSE
function editDENSEFcn(obj)


    % edit the groups
    newdns = guiDENSEgroups(obj.seq,'Types',obj.manualdensetypes,...
        'InitialGroups',obj.dns);

    % clear DENSE
    if isempty(newdns)
        if isstruct(newdns) && ~isempty(obj.dns)
            obj.dns = repmat(struct,[0 1]);
            notify(obj,'NewState',DENSEEventData('new','dns'));
        end
        return
    end

    % check for difference
    if isempty(obj.dns)
        uidcur = {};
    else
        uidcur = {obj.dns.UID};
    end
    uidnew = {newdns.UID};

    if isempty(setxor(uidcur,uidnew))
        return
    end


%     % ensure ShiftIJ field
%     if ~isfield(newdns,'ShiftIJ')
%         newdns(1).ShiftIJ = [];
%     end
%
%     % IJ shift calculation if empty
%     for k = 1:numel(newdns)
%         if isempty(newdns(k).ShiftIJ)
%             midx = newdns(k).MagIndex;
%             tf = ~isnan(midx);
%             if numel(unique(midx(tf))) <= 1
%                 shft       = NaN(2,3);
%                 shft(tf,:) = 0;
%             else
%                 I     = cell(3,1);
%                 I(tf) = obj.img(midx(tf));
%                 shft  = registerDENSE(I{:});
%             end
%             newdns(k).ShiftIJ = shft;
%         end
%     end

    % notify anybody waiting
    obj.dns = newdns;
    notify(obj,'NewState',DENSEEventData('new','dns'));

end


%% REGISTER DENSE


function regDENSEFcn(obj,didx)

    % check for empty object
    if isempty(obj.seq) || isempty(obj.dns)
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'One or more object fields are empty.');
    end

    % check DENSE index
    rng = [1 numel(obj.dns)];
    if ~isnumeric(didx) || ~isscalar(didx) || ...
       didx < rng(1) || rng(2) < didx
        error(sprintf('%s:invalidDENSEIndex',mfilename),...
            'DENSE Index is invalid.');
    end

    % current DENSE object
    dns = obj.dns(didx);

    % indices
    midx = dns.MagIndex;
    pidx = dns.PhaIndex;

    % swap imagery
%     if any(strcmpi(dns.Type,{'xy','xyz'}));
        if dns.SwapFlag
            midx([1 2]) = midx([2 1]);
            pidx([1 2]) = pidx([2 1]);
        end
%     end

    % application data
    api = struct('shift',NaN(2,3));
    tags = {'Xmag','Ymag','Zmag'};

    for k = 1:3
        if isnan(midx(k))
            api.(tags{k}) = [];
        else
            api.(tags{k}) = obj.img{midx(k)};
            api.shift(:,k) = obj.seq(midx(k)).TranslationRC(:);
        end
    end

    % determine shift
    shft = DENSEtranslate(api);
    if isempty(shft), return; end

    % save shift
    for k = 1:3
        if ~isnan(midx(k))
            obj.seq(midx(k)).TranslationRC(:) = shft(:,k);
            obj.seq(pidx(k)).TranslationRC(:) = shft(:,k);
        end
    end

%     % notify anybody waiting
%     notify(obj,'NewState',DENSEEventData('new','dns'));

end




%% EXPORT ROI

function tf = isAllowExportROIFcn(obj,ridx)

    % attempt to gather contour data, testing the indices
    try
        cndata = contourData(obj,ridx,[],true);
    catch
        tf = false;
        return
    end

    % check for SA type
    if ~strcmpi(cndata.ROIType,'SA')
        tf = false;
    else
        tf = true;
    end

end


function exportdata = exportROIFcn(obj,ridx,varargin)

    % gather the contour to check if its available
    try
        cndata = contourData(obj,ridx);
    catch
        error(sprintf('%s:ROIExportDisabled',mfilename),...
            'Cannot export requested ROI.');
    end

    % sequence indices
    sidx = cndata.SeqIndex;
    sidx0 = min(sidx);

    % frame range
    frames = cndata.ValidFrames(1):cndata.ValidFrames(2);

    % default last name
    try
        lastname = obj.seq(sidx0).PatientName.FamilyName;
    catch ERR
        lastname = 'unknown';
    end

    % parse extra inputs
    defapi = struct(...
        'ExportPath',   pwd,...
        'LastName',     lastname,...
        'SeriesRange',  [1 1]);
    api = parseinputs(defapi,[],varargin{:});

    % other values for this specific ROI
    api.SeriesNumber   = obj.seq(sidx0).SeriesNumber;
    api.Partition      = obj.seq(sidx0).DENSEdata.Partition(1);
    api.Nphase         = obj.seq(sidx0).DENSEdata.Number;

    % open GUI
    exportdata = exportroigui(api);
    if isempty(exportdata), return; end

    % check if any of the files exist
    tf = cellfun(@(f)exist(f,'file')==2,exportdata.Filenames);
    if any(tf)
        str = {'One or more ROI file exists.';'Overwrite?'};
        button = questdlg(str,'Overwrite Files',...
            'Yes','No','Cancel','Cancel');
        if ~strcmpi(button,'Yes')
            exportdata = [];
            return;
        end
    end



    % output the contours
    if 1

        % directly output contours
        for fr = frames(:)'

            xOuterCon = cndata.Contour{fr,1};
            xOuterCon(end+1,:) = xOuterCon(1,:);

            xInnerCon = cndata.Contour{fr,2};
            xInnerCon(end+1,:) = xInnerCon(1,:);

            save(exportdata.Filenames{fr},'xInnerCon','xOuterCon');

        end

    else

        % for each frame, perform a linear resampling of both contours with 40
        % points (the 1st point must be the last) and save
        si = linspace(0,1,exportdata.Nsample-1);

        for fr = frames(:)'

            epi = cndata.Contour{fr,1};
            d = cumsum([0; sqrt(sum(diff(epi,[],1).^2,2))]);
            s = d./max(d);
            spepi = spapi(2,s',epi');

            xOuterCon = fnval(si,spepi)';
            xOuterCon(end+1,:) = xOuterCon(1,:);


            endo = cndata.Contour{fr,2};
            d = cumsum([0; sqrt(sum(diff(endo,[],1).^2,2))]);
            s = d./max(d);
            spendo = spapi(2,s',endo');

            xInnerCon = fnval(si,spendo)';
            xInnerCon(end+1,:) = xInnerCon(1,:);

            save(exportdata.Filenames{fr},'xInnerCon','xOuterCon');

        end
    end





end
