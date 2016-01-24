%createcolormap4strain

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

function map = straincmap(N)

if nargin < 1 || isempty(N), N = 256; end



% clrval = [0 0 1; 1 0 0];
% hsvval = rgb2hsv(clrval);
%
% hue = linspace(hsvval(1,1),hsvval(2,1),N)';
% map = hsv2rgb([hue ones(N,2)]);
%
% % rgbval = jet(N);
% % hsvval = rgb2hsv(rgbval);
% %
% % hue = hsvval(:,1);
% % theta = linspace(0,2*pi,N);
% % sat = 0.5*(1 + cos(theta));
% %
% % fac = 0.40;
% % sat = fac*sat + (1-fac);
% %
% %
% % map = hsv2rgb([hue(:) sat(:) ones(N,1)]);
%
% return

nbr = floor(N/3);
tmp = linspace(0,1,(N-2*nbr)+2);

vals = [zeros(1,nbr-1),tmp,ones(1,nbr-1)]';

map = [zeros(1,nbr-1),tmp,ones(1,nbr-1);
       tmp ones(1,N-2*numel(tmp)) fliplr(tmp);
       ones(1,nbr-1),fliplr(tmp),zeros(1,nbr-1)]';


return




N = 127;

binsize1 = 2;
binsize2 = 41;
increment = 1/binsize2;

map = zeros(N,3);

array1 = [1-increment*(binsize1-1):increment:1];        %small count up
array2 = [1-increment*(binsize2-1):increment:1];        %large count up
array3 = fliplr(array2);                                %large count dn
array4 = fliplr(array1);                                %small count dn
array5 = ones(binsize2,1);                              %array of ones, size of binsize2

column3 = zeros(N,1);
column3(1:binsize1) = array1;
column3(binsize1+1:binsize1+binsize2) = array5;
column3(binsize1+binsize2+1:binsize1+2*binsize2) = array3;

column2 = zeros(N,1);
column2(binsize1+1:binsize1+binsize2) = array2;
column2(binsize1+binsize2+1:binsize1+2*binsize2) = array5;
column2(binsize1+2*binsize2+1:binsize1+3*binsize2) = array3;

column1 = zeros(N,1);
column1(binsize1+binsize2+1:binsize1+2*binsize2) = array2;
column1(binsize1+2*binsize2+1:binsize1+3*binsize2) = array5;
column1(binsize1+3*binsize2+1:N) = array4;

map(:,1) = column1;
map(:,2) = column2;
map(:,3) = column3;
