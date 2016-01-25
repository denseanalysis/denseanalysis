function varargout = guiROIselection(varargin)
% varargout = guiROIselection(varargin)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
    [varargout{1:nargout}] = guiROIselection_GUIDE(...
        'ExternalInitialization',varargin{:});

end


