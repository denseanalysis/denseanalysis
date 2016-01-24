% Example tpaps

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

clear all, close all; drawnow

Isz = [128,128];

x = 1:128;
[X,Y] = meshgrid(x);


dX = .75*ones(size(X));
dY = .75*ones(size(Y));

X0 = X-dX;
Y0 = Y-dY;

% RHO = RHO./max(RHO(:));
%
% x = [X(:),Y(:)]';
% y = RHO(:)';
%
%
% [X0,Y0] = pol2cart(THETA,RHO);
% X0 = X0+mean(X(:));
% Y0 = Y0+mean(Y(:));
%
% dX = X0-X;
% dY = Y0-Y;

a = 25;


dXN = dX + 0.1*randn(size(dX));
dYN = dY + 0.1*randn(size(dY));

p = 1e-4;

maxdist = 5;

% divide the image region into blocks

N = ceil(Isz/20);
irng = round(linspace(1,Isz(1),N(1)));
jrng = round(linspace(1,Isz(2),N(2)));

% irng = [max(1,irng(1:end-1)-maxdist),min(Isz(1),irng(2:end)+maxdist)];
%
% jrng = [max(1,jrng(1:end-1)-maxdist),min(Isz(2),jrng(2:end)+maxdist)];

irng = [1 irng(2:end-1)+1;irng(2:end)]';
jrng = [1 jrng(2:end-1)+1;jrng(2:end)]';

[bi,bj] = ndgrid(1:size(irng,1),1:size(jrng,1));

tic
pts = [X0(:),Y0(:)]';
for k = 1:numel(X)
    dsq = (pts(1,:)-pts(1,k)).^2 + (pts(2,:)-pts(2,k)).^2;
    tf  = dsq <= 5^2;
    tmp = tpaps(pts(:,tf),dXN(tf),p);
end
toc
return

tic

xspl = tpaps(pts,dXN(:)',p);
yspl = tpaps(pts,dYN(:)',p);
toc

return

dXi = reshape(fnval(xspl,pts),size(X));
dYi = reshape(fnval(yspl,pts),size(Y));



figure
imshow(ones(Isz),[],'init','fit');
hold on
quiver(X0,Y0,dX,dY,0,'-g');
quiver(X0,Y0,dXi,dYi,0,'-r');
hold off

hold on
for k = 1:numel(bi)
    x = jrng(bj(k),:) + [-.5 .5];
    y = irng(bi(k),:) + [-.5 .5];
    plot(x([1 1 2 2 1]),y([1 2 2 1 1]),'-r');
end
hold off
