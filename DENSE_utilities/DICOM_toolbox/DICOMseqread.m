function images = DICOMseqread(seqdata,varargin)

%DENSESEQREAD read DENSE associated image sequences from file
%
%INPUTS
%   seqdata....[Nx1] array of structures derived from DICOM header data
%       see DICOMSEQ for more information
%
%INPUT PARAMETERS
%   'Verbose'.....controls the display of progress messages to
%       the command line.  [true | {false}]
%   'Waitbar'.....controls the use of a progress bar.  [{true} | false]
%   'CancelRead'..[Nx1] logical array, indicating sequences that the
%                 program should not read (true)
%
%OUTPUTS
%   images.....[Nx1] cell array of grayscale image sequences
%
%USAGE
%
%   IMAGES = DICOMSEQREAD(SEQDATA) after loading sequence information into
%   the array of structures SEQDATA using the DICOMSEQ function, one may
%   load the corresponding image data into the workspace.
%   If the read operation was unnecessary or unsuccessful for any sequence,
%   the corresponding element of IMAGES is empty. If all reads were
%   unsuccessful, the function returns the empty set (IMAGES==[]).
%
%   [...] = DICOMSEQREAD(...,'Verbose',TF,...) TF is a logical scalar
%   controling the display of progress messages to the command line.
%
%   [...] = DICOMSEQREAD(...,'Waitbar',TF,...) TF is a logical scalar
%   controling the use of a progress bar.
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

    % check seqdata
    if ~isstruct(seqdata)
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'SEQDATA must be a structure.');
    end

    % mandatory SEQDATA fields
    tags = {'Filename';};
    tf = isfield(seqdata,tags);
    if any(~tf)
        str = sprintf('%s,',tags{~tf});
        error(sprintf('%s:missingDICOMinformation',mfilename),'%s',...
            'The following mandatory fields did not exist in ',...
            'any DICOM sequence: [',str(1:end-1),'].');
    end


    % parse inputs
    args = struct(...
        'Verbose',      false,...
        'Waitbar',      true,...
        'CancelRead',   false(size(seqdata)));
    [args,other_args] = parseinputs(fieldnames(args),...
        struct2cell(args),varargin{:});
    if ~isempty(other_args)
        error(sprintf('%s:invalidParameters',mfilename), ...
            'Invalid input parameter pair.');
    end

    % parse arguments
    FLAG_verbose = isequal(1,args.Verbose);
    FLAG_waitbar = isequal(1,args.Waitbar);
    FLAG_cancel  = logical(args.CancelRead(:));

    % check for complete ignore
    if all(FLAG_cancel)
        images = cell(size(seqdata));
        warning(sprintf('%s:ignoreAll',mfilename), ...
            'All sequence reads were cancelled!');
        return
    end

    % create waitbar
    if FLAG_waitbar
        hwait = waitbar(0,'Loading DICOM images...',...
            'Name','DICOM sequence imagery',...
            'WindowStyle','modal');
        hwaitCleanupObj = onCleanup(@()hwaitCleanupFcn(hwait));
        drawnow, pause(0.1)

        % count number of files to load
        Nperseq = cellfun(@numel,{seqdata.Filename});
        Nperseq(FLAG_cancel) = 0;
        Nfiles  = sum(Nperseq);
    end

    % initial message
    if FLAG_verbose
        fprintf('Loading DICOM images...\n');
    end


    % load grayscale imagery
    images = cell(size(seqdata));
    for k = 1:numel(seqdata)

        % check for cancellation
        if abortFcn, return; end

        % check for ignore
        if FLAG_cancel(k), continue; end

        % update waitbar
        if FLAG_waitbar && ishandle(hwait)
            cnt = sum(Nperseq(1:k-1));
            waitbar(cnt/Nfiles,hwait);
        end

        % check for Filename existance
        if isempty(seqdata(k).Filename), continue; end

        % load filenames
        files = seqdata(k).Filename;
        if ~iscell(files), files = {files}; end

        % check for cell string
        if ~iscellstr(files), continue; end

        % check for the existance of all files
        tf = cellfun(@(f)exist(f,'file')==2,files);
        if any(~tf), continue; end

        % load images (move to next sequence if any image load fails)
        I = cell([1 1 numel(files)]);
        ERR = [];
        for fi = 1:numel(files)
            try
                I{fi} = dicomgray(files{fi},'frames',1);
            catch ERR
                break;
            end

            if abortFcn, return; end
            if FLAG_waitbar && ishandle(hwait)
                cnt = cnt+1;
                waitbar(cnt/Nfiles,hwait);
            end

        end
        if ~isempty(ERR), continue; end

        % convert to 3D array if possible
        try
            I = cell2mat(I);
        catch ERR
            continue;
        end

        % save images
        images{k} = I;

        % verbose output
        if FLAG_verbose
            fprintf('Sequence %3d: %3d files loaded\n',k,numel(files));
        end
    end


    % check for existance of some DENSE data
    if all(cellfun(@isempty,images))
        warning(sprintf('%s:missingDICOMdata',mfilename),'%s',...
            'No valid DICOM sequences could be loaded.');
        images = [];
    end

    % end function
    if FLAG_verbose
        fprintf('DICOM imagery loaded.\n');
    end
    if FLAG_waitbar && ishandle(hwait)
        waitbar(1,hwait,'DICOM imagery loaded');
        pause(0.5);
    end



    %% HELPER FUNCTION: ABORT
    % If the user has displaye a waitbar, we are able to abort the load
    % operation by deleting said waitbar.
    function tf = abortFcn()
        if FLAG_waitbar && ~ishandle(hwait)
            if FLAG_verbose, disp('ABORT'); end
            images = [];
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
% delete the waitbar, if it exists
    if ishandle(hwait)
        delete(hwait);
        drawnow;
    end

end



%% END OF FILE=============================================================
