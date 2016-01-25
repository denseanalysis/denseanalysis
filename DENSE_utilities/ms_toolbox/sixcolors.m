function map = sixcolors(m)
%SIXCOLORS repeats [red; yellow; blue; orange; green; violet]

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
if nargin + nargout == 0
   h = get(gca,'child');
   m = length(h);
elseif nargin == 0
   m = size(get(gcf,'colormap'),1);
end

R = [1 0 0; 1 1 0; 0 0 1; 1 1/2 0; 0 1 0; 2/3 0 1];

% Generate m/6 vertically stacked copies of r with Kronecker product.
e = ones(ceil(m/6),1);
R = kron(e,R);
R = R(1:m,:);

if nargin + nargout == 0
   % Apply to lines in current axes.
   for k = 1:m
      if strcmp(get(h(k),'type'),'line')
         set(h(k),'color',R(k,:))
      end
   end
else
   map = R;
end
