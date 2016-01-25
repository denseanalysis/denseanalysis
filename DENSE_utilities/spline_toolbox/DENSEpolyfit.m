function [spl,A] = DENSEpolyfit(i,j,k,vals,N,kfactor)
% function [spl,A] = DENSEpolyfit(i,j,k,vals,N,kfactor)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

% sizes
kN = numel(k);
sz = [numel(i),numel(j)];

% kfactor
if nargin < 6 || isempty(kfactor)
    kfactor = [min(k),max(k)];
end


% Construct Vandermonde matrix (t^0, t^1, ... t^N)
k = (k-kfactor(1)) / diff(kfactor);
K = bsxfun(@power,k(:),0:N);
% K = cell2mat(arrayfun(@(n)k(:).^n,0:N,'uniformoutput',0));

% construct VALS matrix
VALS = reshape(vals,[prod(sz),kN])';

% coefficent "images"
if any(k==0)
    tf = (k==0);
    A = lsequal(K(~tf,:),VALS(~tf,:),K(tf,:),VALS(tf,:));
else
    A = K\VALS;
end
A = reshape(A',[sz,N+1]);


data = repmat(struct,[N+1,1]);
for pk = 1:N+1
    tmp = csape({i,j},A(:,:,pk));
%     tmp = spapi({2,2},{i,j},A(:,:,pk));
    tags = fieldnames(tmp);
    for ti = 1:numel(tags)
        data(pk).(tags{ti}) = tmp.(tags{ti});
    end
end

spl = struct(...
    'form',     'polyfit2',...
    'breaks',   {{i,j,k}},...
    'degree',   N,...
    'kfactor',  kfactor,...
    'data',     data);


return
%
%
% % time matricies
% n      = 1:Nharm;
% Ncoefs = 1+2*Nharm;
%
% tmatrix  = [0.5*ones(numel( t),1), cos(2*pi* t(:)*n), sin(2*pi* t(:)*n)];
% tmatrix0 = [0.5*ones(numel(t0),1), cos(2*pi*t0(:)*n), sin(2*pi*t0(:)*n)];
%
%
% dX  = reshape( dX(:),[prod(Vsz),numel( t)]);
% dX0 = reshape(dX0(:),[prod(Vsz),numel(t0)]);
%
% A = lsequal(tmatrix,dX',tmatrix0,dX0');
%
% A = reshape(A',[Vsz Ncoefs]);
% spl = repmat(struct,[Ncoefs 1]);
%
% for k = 1:Ncoefs
%
%     tmp = csape({y,x,z},A(:,:,:,k));
%     tags = fieldnames(tmp);
%     for ti = 1:numel(tags)
%         spl(k).(tags{ti}) = tmp.(tags{ti});
%     end
% end



end
