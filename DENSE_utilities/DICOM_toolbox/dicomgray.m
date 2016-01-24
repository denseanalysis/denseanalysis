%% HELPER FUNCTION: GRAYSCALE DICOM IMAGE
function I = dicomgray(varargin)

%DICOMGRAY read grayscale DICOM image from a given file.
% This function accepts all the same inputs as DICOMREAD,
% converting the returned image data to grayscale.

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.01     Drew Gilliam
%     --creation

    [X,map] = dicomread(varargin{:});
    if isempty(map)
        if size(X,3) == 1
            I = X;
        else
            I = rgb2gray(X);
        end
    else
        I = ind2gray(X,map);
    end
end
