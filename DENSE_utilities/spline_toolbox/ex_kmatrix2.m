% Example kmatrix

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

clear all, close all, pause(0)

Na = 100;
Nb = 100;

a = rand(2,Na);
% b = rand(2,Nb);
b = a;

tic
K1 = kmatrix2(a.',b.');
toc

tic
d1  = b(1*ones(Nb,1),:) - a(1*ones(Na,1),:).';
d2  = b(2*ones(Nb,1),:) - a(2*ones(Na,1),:).';
dsq = d1.*d1 + d2.*d2;
dsq(dsq<=0) = 1;
K2  = dsq .* log(dsq);
toc

tic
K3 = stcol(a,b,'tr');
toc

max(abs(K1(:)-K2(:)))

max(abs(K1(:)-K3(:)))

max(abs(K2(:)-K3(:)))
