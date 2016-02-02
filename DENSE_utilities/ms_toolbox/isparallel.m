function [tf,pos,order] = isparallel(ipp,iop,flag_checkalignment)
% [tf,pos,order] = isparallel(ipp,iop,flag_checkalignment)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

    % expected values
    if ~isnumeric(ipp) || ~ismatrix(ipp) || size(ipp,2)~=3 || ...
       ~isnumeric(iop) || ~ismatrix(iop) || size(iop,2)~=6 || ...
       ~any(size(iop,1)==[1,size(ipp,1)])

        error(sprintf('%s:invalidInput',mfilename),'%s',...
            '"ImagePositionPatient" and "ImageOrientationPatient" ',...
            'must be [Nx3] and [Nx6] matrices, respectively.');
    end

    % validate alignment check
    if nargin < 3 || isempty(flag_checkalignment)
        flag_checkalignment = false;
    else
        flag_checkalignment = isequal(true,flag_checkalignment);
    end

    % default outputs
    tf    = false;
    pos   = [];
    order = [];

    % ensure all positions are unique
    tmp = unique(ipp,'rows');
    if size(tmp,1)~=size(ipp,1), return; end

    % ensure all orientations are equal
    if size(iop,1) > 1
        tf = bsxfun(@eq,iop(1,:),iop);
        if ~all(tf(:)), return; end
    end

    % orientation vector
    orient = cross(iop(1,1:3),iop(1,4:6));

    % check alignment (i.e. all IPP must lie on a single line)
    if flag_checkalignment

        % Orthogonal Distance Regression Line
        % (line of best fit to 3D positions)
        % X = A*z + X0
        [coeff,score] = princomp(ipp);
        X0 = mean(ipp,1);
        A = coeff(:,1);
        z = score(:,1);

        % ensure all points lie on the line
        ippfit = bsxfun(@plus,X0,z*A');
        dsq = sum((ipp-ippfit).^2,2);
        tol = 1e-4;
        if any(dsq > tol^2), return; end

        % check for A vector parallel to image orientation vector
        % dot(orient,A) == ||orient||*||A|| == 1
        tol = 1e-4;
        if any(abs(1-abs(dot(orient,A))) > tol), return; end

    end

    % valid alignment
    tf = true;

    % distance between planes
    if nargout > 1

        % arbitrary origin (1st point)
        pt0 = ipp(1,:);

        % distance from origin
        vec = bsxfun(@minus,ipp,pt0);
        x = sum(bsxfun(@times,vec,iop(1,1:3)),2);
        y = sum(bsxfun(@times,vec,iop(1,4:6)),2);
        z = sum(bsxfun(@times,vec,orient),2);
        pos = [x(:),y(:),z(:)];

        % sort order
        if nargout > 2
            [zsort,order] = sort(z,'ascend');
        end

    end


end
