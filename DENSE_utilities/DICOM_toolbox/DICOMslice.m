function slicedata = DICOMslice(metadata,varargin)

%DICOMSLICE determine slice plane matches among DICOM information
%
%INPUTS
%   metadata....[Nx1] array of structures containing the following fields:
%       StudyInstanceUID..........subject identifier    string
%       Height....................image height          scalar integer
%       Width.....................image width           scalar integer
%       PixelSpacing..............pixel spacing         [1x2]
%       ImagePositionPatient......slice position        [3x1]
%       ImageOrientationPatient...slice orientation     [6x1]
%
%OUTPUTS
%   slicedata...[Nx1] slice information structure
%       sliceid......exact slice identification value
%       planeid......slice plane identification value
%       parallelid...parallel slice identification value
%       extents2D....2D image corner coordinates [4x2]
%       extents3D....3D slice corner coordinates [4x3]
%       tform........[image pixel]-to-[real world]
%                    coordinate transformation structure
%
%USAGE
%
%   SLICEDATA = DICOMSLICE(METADATA) determines slice information from the
%   DICOM header array of structures METADATA.
%
%       SLICEID: This field is an identifying integer value representing
%       METADATA elements with exactly the same Height, Width,
%       PixelSpacing, ImagePositionPatient, and ImageOrientationPatient.
%       Note some elements may be NaNs, indicating the corresponding
%       element of METADATA did not contain valid slice information.
%
%       PLANEID: This field is an identifying integer value representing
%       METADATA elements that are from the same infinite slice planes.
%       An image of finite extents is said to belong to a slice plane
%       group if that image is parallel to the slice plane and separated
%       by a negligable distance to the slice plane.
%       Note some elements may be NaNs, indicating the corresponding
%       elementof METADATA did not contain valid slice information.
%
%       PARALLELID: This field is an identifying integer value representing
%       METADATA elements that are parallel.
%       Note some elements may be NaNs, indicating the corresponding
%       elementof METADATA did not contain valid slice information.
%
%       EXTENTS2D: 2D image coordinates ([4x2] matrix, each row
%       representing a 2D image corner in pixel coordinates).
%
%       EXTENTS3D: 3D image coodinates ([4x3] matrix, each row
%       representing a 3D slice corner in real-world coordinates).
%
%       TFORM: [image pixel]-to-[real world] coordinate transformation
%       structure (see MAKETFORM).
%
%
%   SLICEDATA = DICOMSLICE(METADATA,OTHERPARAM_1,OTHERPARAM_2,...)
%   the user may additionally enter other identifying information as
%   desired. Each OTHERPARAM field is an [Nx1] cell array containing
%   other identifying information, and the user may define as many
%   OTHERPARAM inputs as desired.  Note, any additional fields
%   will only affect the output SLICEID.
%
%
%NOTE ON SLICE VERSUS PLANE
%   In the context of this function, "slice" will define a finite image
%   with a specific position and orientation, while the "plane" or
%   "slice plane" defines an infinite plane on which a finite slice lies.
%
%
%NOTE ON COORDINATE TRANSFORMATION
%
%   Each element of the SLICEDATA structure contains a transformation
%   structure TFORM, created via the matlab function MAKETFORM using the
%   'affine' transformtype.  This transform incorporates the
%   'PixelSpacing', 'ImageOrientationPatient', and 'ImagePositionPatient'
%   fields, defining the transformation from [image pixel] coordinates to
%   [real-world] coordinates. To transform an arbitray 2D image location
%   into 3D space, use the following script:
%
%       % let x/y be vectors of image coordinates in base-1
%       % coordinates (i.e. the image origin is at [1,1])
%       % let slicedata(n) be the nth slice data structure
%       X2d = [x(:),y(:)];
%       coords = [X2d-1, zeros(size(x(:)))];
%       X3d = tformfwd(slicedata(n).tform,coords);
%
%   To transform 3D coordinates to the image space:
%
%       coords = tforminv(slicedata(n).tform,X3d);
%       X2d = coords(:,1:2)+1;
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


    %% SETUP

    % tolerances defining matching slice planes
    dsttol = 1e-3;  % distance tolerance (less than 1 nm separation)
    dottol = 1e-10; % dot product tolerance (to handle floating-point errors)

    % check for input structure array
    if ~isstruct(metadata) || numel(metadata)<1
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'This function expects an array of structures as input.');
    end

    % ensure mandatory fields exist within metadata
    tags = {'StudyInstanceUID';'Height'; 'Width'; 'PixelSpacing'; ...
        'ImagePositionPatient'; 'ImageOrientationPatient';};

    tf = isfield(metadata,tags);
    if any(~tf)
        str = sprintf('%s,',tags{~tf});
        error(sprintf('%s:missingDICOMinformation',mfilename),'%s',...
            'The following mandatory fields did not exist in',...
            'any DICOM sequence: ',str(1:end-1),'.');
    end


    % metadata indices with expected type
    tf = true(size(metadata));
    for k = 1:numel(metadata)

        uid = metadata(k).StudyInstanceUID;
        h   = metadata(k).Height;
        w   = metadata(k).Width;
        px  = metadata(k).PixelSpacing;
        ipp = metadata(k).ImagePositionPatient;
        iop = metadata(k).ImageOrientationPatient;

        tf(k) = ~isempty(uid) && ischar(uid)    && ...
                ~isempty(h)   && isnumeric(h)   && numel(h)  ==1 && ...
                ~isempty(w)   && isnumeric(w)   && numel(w)  ==1 && ...
                ~isempty(px)  && isnumeric(px)  && numel(px) ==2 && ...
                ~isempty(ipp) && isnumeric(ipp) && numel(ipp)==3 && ...
                ~isempty(iop) && isnumeric(iop) && numel(iop)==6;
    end

    % check for error
    if ~any(tf)
        error(sprintf('%s:invalidDICOMinformation',mfilename),'%s',...
            'No elements of the input array of structures contained ',...
            'the expected form of the mandatory fields.');
    end

    % check for additional identifying information
    otherdata = repmat(struct,size(metadata));
    if nargin > 1

        for vk = 1:nargin-1
            newtag = sprintf('OtherParameter_%d',vk);
            data = varargin{vk};
            if ~iscell(data) || numel(data) ~= numel(metadata)
                error(sprintf('%s:invalidAdditionalData',mfilename),...
                    'Invalid additional indentifying information.');
            else
                for k = 1:numel(otherdata)
                    otherdata(k).(newtag) = data{k};
                end
            end
        end

    end



    %% planar SLICES
    % first, we determine the exact slice id based on the structure
    % fieldnames 'tags' above.  We then group the images into slice plane
    % groups (parallel to each other and separated by a negligable
    % distance)

    % initialize sliceid matrix
    sliceid = NaN(size(metadata));

    % find exact matches
    if isempty(fieldnames(otherdata))
        [b,ndx,sliceid(tf)] = unique_struct(metadata(tf),tags);
    else
        for k = 1:numel(otherdata)
            if ~tf(k), continue; end
            for ti = 1:numel(tags)
                otherdata(k).(tags{ti}) = metadata(k).(tags{ti});
            end
        end
        [b,ndx,sliceid(tf)] = unique_struct(otherdata(tf));
    end


    % transformation matrices (T)
    % 3D extents of slice planes (X)
    N = numel(b);
    X2 = zeros([4 2 N]);
    X3 = zeros([4 3 N]);
    tform = repmat(struct,[1 1 N]);

    for k = 1:N
        Isz  = double([b(k).Height, b(k).Width]);
        pxsz = double(b(k).PixelSpacing(:)');
        ipp  = double(b(k).ImagePositionPatient(:));
        iop  = double(b(k).ImageOrientationPatient(:));

        R = [iop(1:3)*pxsz(2), ...
             iop(4:6)*pxsz(1), ...
             cross(iop(1:3)*pxsz(2), iop(4:6)*pxsz(1))];
        T = [R, ipp; 0 0 0 1];

        tmp = maketform('affine',T');
        tags = fieldnames(tmp);
        for ti = 1:numel(tags)
            tform(k).(tags{ti}) = tmp.(tags{ti});
        end

        sz = (Isz-1);
        x = [0 0 Isz(2) sz(2)];
        y = [0 sz(1) sz(1) 0];
        z = zeros(1,4);

        X2(:,:,k) = [x(:),y(:)];
        X3(:,:,k) = tformfwd(tform(k),[x(:),y(:),z(:)]);

    end

    % coplanar check:
    % if parallel (i.e. abs(dot(ni,nj)) == 1) and negligable
    % distance between planes, they are the same plane!
    parallel = logical(eye(N));
    planar   = logical(eye(N));

    for i = 1:N
        for j = i+1:N

            % check for subject equality first
            if ~isequalstruct(b(i),b(j),{'StudyInstanceUID'})
                continue;
            end

            % unit vectors
            ni = tform(i).tdata.T(3,1:3);
            nj = tform(j).tdata.T(3,1:3);
            ni = ni / sqrt(sum(ni.^2));
            nj = nj / sqrt(sum(nj.^2));

            % test for parallel (dot(ni,nj) == ||ni||*||nj|| == 1)
            parallel(i,j) = abs(1 - abs(dot(ni,nj))) < dottol;

            % test for coplanar
            if parallel(i,j)
                % distance between parallel planes
                vec = X3(1,:,j) - X3(1,:,i);
                d = abs(dot(ni,vec));
                if d < dsttol, planar(i,j) = 1; end
            end

        end
    end
    planar = planar | planar';
    parallel = parallel | parallel';

    % group slice planes
    if ~any(planar(:))
        planeid = sliceid;
    else
        map = sliceid;
        for k = 1:N
            mink = find(planar(k,:),1,'first');
            map(map==k) = mink;
        end
        [tmp,m,planeid] = unique(map);
        planeid(~tf) = NaN;
    end

    % group parallel slices
    if ~any(parallel)
        parallelid = sliceid;
    else
        map = sliceid;
        for k = 1:N
            mink = find(parallel(k,:),1,'first');
            map(map==k) = mink;
        end
        [tmp,m,parallelid] = unique(map);
        parallelid(~tf) = NaN;
    end

    % output
    slicedata = struct(...
        'sliceid',num2cell(NaN(size(metadata))),...
        'planeid',num2cell(NaN(size(metadata))),...
        'parallelid',num2cell(NaN(size(metadata))),...
        'extents2D',[],'extents3D',[],'tform',[]);
    for k = 1:numel(metadata)
        if ~tf(k), continue; end
        slicedata(k).sliceid = sliceid(k);
        slicedata(k).planeid = planeid(k);
        slicedata(k).parallelid = parallelid(k);

        idx = sliceid(k);
        slicedata(k).extents2D = X2(:,:,idx);
        slicedata(k).extents3D = X3(:,:,idx);
        slicedata(k).tform     = tform(idx);
    end


end


%% END OF FILE=============================================================
