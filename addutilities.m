function varargout = addutilities(uipath)
% varargout = addutilities(uipath)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
    % default utilities folder
    if nargin < 1 || isempty(uipath), uipath = 'matlab_utilities'; end

    % check number of outputs
    error(nargoutchk(0,2,nargout));

    % check for folder existance
    if ~isdir(uipath)
        error(sprintf('%s:invalidPath',mfilename),...
            'Utility folder <%s> cannot be located.',uipath);
    end

    % absolute folder path
    [stat,info] = fileattrib(uipath);
    uipath = info.Name;

    % locate utility directories
    % (one folder down from the path)
    d = dir(uipath);
    d = d(3:end);
    d = d([d.isdir]);
    folders = cellfun(@(x)fullfile(uipath,x),{d.name},'uniformoutput',0);

    % add utility directories
    addpath(folders{:});

    % output
    if nargout>0, varargout{1} = uipath; end
    if nargout>1, varargout{2} = folders; end


end
