%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

clear all, close all, pause(0)


Vsz = [50 50 21];

% random matrix
% rand('state',7);
matrix = 100*rand(Vsz);


% logical mask
Ntrue = 4;
tmp = randperm(numel(matrix));
mask = false(Vsz);
mask(tmp(1:Ntrue)) = 1;



niter = 1000;


% regular "max"
tic
for iter = 1:niter
    matrix_tmp = matrix;
    matrix_tmp(~mask) = -Inf;
    [val1,ind1] = max(matrix_tmp(:));
end
t1 = toc;

% "quickmax_mex" test
tic
for iter = 1:niter
    [val2,ind2] = quickmax_mex(matrix,mask);
end
t2 = toc;

% "quickfind_mex" test
tic
[matrix_sort,matrix_idx] = sort(matrix(:),'descend');
matrix_idx = uint32(matrix_idx);
for iter = 1:niter
    ind3 = quickfind_mex(mask,matrix_idx);
end
if ind3 < 1
    val3 = -Inf;
else
    val3 = matrix(ind3);
end
t3 = toc;

% "quickmax" test
tic
for iter = 1:niter
    [val4,ind4] = quickmax(matrix,mask);
end
t4 = toc;

% "quickfind" test
tic
[matrix_sort,matrix_idx] = sort(matrix(:),'descend');
matrix_idx = uint32(matrix_idx);
for iter = 1:niter
    ind5 = quickfind(mask,matrix_idx);
end
if ind5 < 1
    val5 = -Inf;
else
    val5 = matrix(ind5);
end
t5 = toc;


% results
fprintf(1,'         method\t   value\t   index\t     sec\n')
fprintf(1,'%15s\t%8.3f\t%8d\t%8.5f\n','max',            val1,ind1,t1);
fprintf(1,'%15s\t%8.3f\t%8d\t%8.5f\n','quickmax_mex',   val2,ind2,t2);
fprintf(1,'%15s\t%8.3f\t%8d\t%8.5f\n','quickfind_mex',  val3,ind3,t3);
fprintf(1,'%15s\t%8.3f\t%8d\t%8.5f\n','quickmax',       val4,ind4,t4);
fprintf(1,'%15s\t%8.3f\t%8d\t%8.5f\n','quickfind',      val5,ind5,t5);



