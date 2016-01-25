function shft = registerDENSE(Xmag,Ymag,Zmag,varargin)

%REGISTERDENSE register the DENSE magnitude information, determining the
%   2D translation that best aligns the information
%
%
%
%
%
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
    corrfac = 0.5;
    maxdisp = 10;

    % determine available correlation function
    if exist('normxcorr2_mex','file')
        normxcorr2Fcn = @(T,A)normxcorr2_mex(T,A,'valid');
    else
        normxcorr2Fcn = @(T,A)normxcorr2_valid(T,A);
    end

    % general input error ID
    errid = sprintf('%s:invalidInput',mfilename);


    % initialize output
    shft = NaN(2,3);

    % check if registration is necessary
    tfreg = ~[isempty(Xmag),isempty(Ymag),isempty(Zmag)];

    if sum(tfreg) == 0
        return;
    elseif sum(tfreg) == 1
        shft(:,tfreg) = 0;
        return;
    end

    % check imagery
    checkfcn = @(m)isempty(m) || (isnumeric(m) && any(ndims(m)==[2 3]));

    if ~checkfcn(Xmag) || ~checkfcn(Ymag) || ~checkfcn(Zmag)
        error(errid,'%s','Invalid imagery; function expects 3D X/Y/Z ',...
            'magnitude information of the same size.');
    end

    % base imagery (imagery to be registered against)
    baseidx = find(tfreg,1,'first');
    Isz = magfun(@(m)size(m(:,:,1)),baseidx);
    Nfr = magfun(@(m)size(m,3),baseidx);

    % check other imagery against base imagery
    checkfcn = @(m)isempty(m) || ...
        (all(size(m(:,:,1)) == Isz) && size(m,3)==Nfr);

    if ~checkfcn(Xmag) || ~checkfcn(Ymag) || ~checkfcn(Zmag)
        error(errid,'%s','Invalid imagery; function expects 3D X/Y/Z ',...
            'magnitude information of the same size.');
    end



    % set base imagery shift information
    % remove base imagery from necessary registration
    shft(:,baseidx) = 0;
    tfreg(baseidx) = 0;



    % determine extents for registration
    % we only want to use the center of the image for registration, as many
    % Sprial MRI image sequences contain black regions that would inhibit
    % successful correlation.  Therefore, we will use a square region in
    % the center of the image.
    origin = (Isz+1)/2;
    radius = corrfac * ((Isz-1)/2);

    rA = [max(1,ceil(origin(1)-radius(1))), ...
          min(Isz(1),floor(origin(1)+radius(1)))];

    cA = [max(1,ceil(origin(2)-radius(2))), ...
          min(Isz(2),floor(origin(2)+radius(2)))];

    Asz = [diff(rA), diff(cA)] + 1;

    if any(Asz < 0)
        error(errid,'%s','The input imagery and selected ',...
            'SizeFactor of ',num2str(corrfac),...
            ' has resulted in an invalid correlation region. ');
    end

    % determine template extents
    % the template extents are equal to the registration image extents,
    % reduced by the maximum displacement.
    rT = rA + [maxdisp,-maxdisp];
    cT = cA + [maxdisp,-maxdisp];

    Tsz = [diff(rT),diff(cT)] + 1;

    if any(Tsz < 0)
        error(errid,'%s','MaxDisplacement of ', num2str(maxdisp),...
            ' has led to an invalid correlation template.');
    end

    % small region/template warning
    if all(Asz < 5)
        warning(sprintf('%s:smallCorrelation',mfilename),...
            'The correlation region is smaller than [5x5].');
    elseif all(Tsz < 5)
        warning(sprintf('%s:smallCorrelation',mfilename),...
            'The correlation template is smaller than [5x5].');
    end


    % expected correlation size
    Csz  = Asz-Tsz+1;


    % register with respect to base imagery
    for idx = 1:3
        if ~tfreg(idx), continue; end

        % we will record the position of the current frame
        % relative to the base frame (in base-1 coordinates)
        pos = zeros(2,Nfr);

        for fr = 1:Nfr

            % base image
            A = magfun(@(m)double(m(rA(1):rA(2),cA(1):cA(2),fr)),baseidx);

            % template image
            T = magfun(@(m)double(m(rT(1):rT(2),cT(1):cT(2),fr)),idx);

            % correlation map
            C = normxcorr2Fcn(T,A);

            % maximum correlation
            [val,ind] = max(C(:));
            rmax = rem(ind-1,Csz(1))+1;
            cmax = floor((ind-1)/Csz(1))+1;

            % record current position
            pos(:,fr) = round(Csz/2) - [rmax cmax] + 1;

        end

        % average IDX position
        avepos = round(mean(pos,2));

        % record i/j translation necessary to align current
        % image sequence with the base image sequence
        shft(:,idx) = 1-avepos(:);

    end


    function varargout = magfun(function_handle,index)
        switch index
            case 1
                [varargout{1:nargout}] = function_handle(Xmag);
            case 2
                [varargout{1:nargout}] = function_handle(Ymag);
            case 3
                [varargout{1:nargout}] = function_handle(Zmag);
        end
    end


    function C = normxcorr2_valid(T,A)

        % input sizes
        Tsz = size(T(:,:,1));
        Asz = size(A(:,:,1));

        % full/crop size
        fullsz = Asz + Tsz - 1;

        % crop size
        cropsz = Asz - Tsz + 1;
        %switch lower(shape)
        %    case 'same',  cropsz = Asz;
        %    case 'valid', cropsz = Asz - Tsz + 1;
        %    otherwise,    cropsz = fullsz;
        %end

        % crop range
        cropoffset = round((fullsz - cropsz) / 2);
        cropi = cropoffset(1) + (1:cropsz(1));
        cropj = cropoffset(2) + (1:cropsz(2));

        % correlate & crop
        C0 = normxcorr2(T,A);
        C  = C0(cropi,cropj);

    end

end
