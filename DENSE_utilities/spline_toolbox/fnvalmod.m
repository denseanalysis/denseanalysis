function vals = fnvalmod(f,varargin)
% Overloaded FNVAL function to deal with the POLYFIT2 form

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

% types of splines this function covers
types = {'polyfit2','splinefit2'};

% correct function/value order
if ~isstruct(f)
   	if isstruct(varargin{1})
        temp = f; f = varargin{1}; varargin{1} = temp;
    else
       vals = fnval(f,varargin{:});
       return
    end
end

% test for spline forms this function covers
if ~isfield(f,'form') || ~any(cellfun(@(t)isequal(f.form,t),types))
    vals = fnval(f,varargin{:});
    return
end

% sampling locations
pts = varargin{1};
if iscell(pts)
    [i,j,k] = ndgrid(pts{:});
    pts  = [i(:),j(:),k(:)]';
    vals = NaN(size(i));
else
    vals = NaN(1,size(pts,2));
end
Npts = size(pts,2);



switch lower(f.form)

    case 'polyfit2'

        % apply k-factor scaling
        pts(3,:) = (pts(3,:)-f.kfactor(1)) / diff(f.kfactor);

        % number of polynomials
        N = f.degree;

        % recover coefficents
        A = zeros([N+1,Npts]);
        for k = 1:N+1
            A(k,:) = fnval(f.data(k),pts(1:2,:));
        end

        % Construct Vandermonde matrix (t^0, t^1, ... t^N)
        k = pts(3,:);
        K = bsxfun(@power,k(:),0:N);
%         K = cell2mat(arrayfun(@(n)k(:).^n,0:N,'uniformoutput',0));

        % recover values
        vals(:) = sum(A.*K');

    case 'splinefit2'

        % points inside all "breaks"
        tfin = f.breaks{1}(1)<=pts(1,:) & pts(1,:)<=f.breaks{1}(end) ...
             & f.breaks{2}(1)<=pts(2,:) & pts(2,:)<=f.breaks{2}(end) ...
             & f.breaks{3}(1)<=pts(3,:) & pts(3,:)<=f.breaks{3}(end);
        if ~any(tfin), return; end


        % distance from each valid point to each data element
        dist = bsxfun(@minus,f.breaks{3}(:),pts(3,:));

        % data element indices surrounding each valid point
        tmp = dist;
        tmp(dist>0) = -Inf;
        [distA,idxA] = max(tmp,[],1);

        tmp = dist;
        tmp(dist<0) = Inf;
        [distB,idxB] = min(tmp,[],1);

        idx = [idxA;idxB];
        idx(:,~tfin) = NaN;

        w = bsxfun(@rdivide,abs([distB;distA]),distB-distA);
        w(:,idxA==idxB) = 0.5;
        w(:,~tfin) = NaN;


        % sample each data element as required
        v = NaN(2,Npts);
        for k = 1:numel(f.breaks{3})
            tfk = (idx==k);
            for n = 1:2
                if any(tfk(n,:))
                    v(n,tfk(n,:)) = fnval(f.data(k),pts(1:2,tfk(n,:)));
                end
            end
        end

        % save values
        vals = sum(v.*w,1);
%
%
%
%
%         d = v;
%         for k = 1:numel(f.breaks{3})
%             vtmp = fnval(
%         end




%         % data elements surrounding each point
%         idx = NaN(2,size(pts,2));
%         idx(tf) =
%

%
%
%
%
%         % number of data frames
%         N = f.degree;
%
%         % recover closest
%         for k = 1:

    otherwise
        error(sprintf('%s:unknownError',mfilename),...
            'There was an unknown error.');

end
