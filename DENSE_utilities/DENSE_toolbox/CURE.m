function val = CURE(strain)
% val = CURE(strain)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  

    if size(strain,2)<3
        val = NaN(size(strain,1),1);
        return
    end

    % size of strain values
    Nphase  = size(strain,1);
    Nsector = size(strain,2);

    % subtract phase 1 strain, according to Ken's request
    strain = strain - strain(ones(Nphase,1),:);

    % fourier transform
    fdata = fftshift(fft(strain,[],2),2);
    fsq  = fdata.*conj(fdata);

    % 0/1 energy
    idx = 1 + ceil(Nsector/2);
    e0 = fsq(:,idx);
    e1 = sum(fsq(:,idx+[-1 1]),2);

    % CURE value
    val = 1./sqrt(1 + (e1./(e0+eps)));

    % original code
%     val = NaN(Nslice,Nphase);
%     for i = 1:Nslice
%         for k = 1:Nphase
%             fData = fftshift(fft(strain(i,:,k),[],2),2);
%             F0idx = 1 + ceil(Nseg/2);
%             eData = fData.*conj(fData);
%             eZero = squeeze(sum(eData(:,F0idx,:),1));
%             eOne  = squeeze(sum(sum(eData(:,F0idx+[-1 1],:),2),1));
%             val(i,k) = 1/sqrt(1 + sum(eOne)/sum(eZero));
%         end
%     end

end
