function str = parsePatientName(pn)

%PARSEPATIENTNAME convert the PatientName DICOM field to a string
%
%INPUTS
%   pn....PatientName structure, with the following recognized fields:
%       'FamilyName', 'GivenName'
%
%OUTPUTS
%   str...PatientName as string (FamilyName_GivenName)
%
%USAGE
%   STR = PARSEPATIENTNAME(PN) convert the PatientName DICOM structure to
%   a string for easier display.

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

    % return empty string
    if isempty(pn)
        str = '';

    % return input string
    elseif ischar(pn)
        str = pn;

    % assemble strung
    elseif isstruct(pn)

        str = '';
        if isfield(pn,'FamilyName')
            str = char(pn.FamilyName);
        end
        if isfield(pn,'GivenName')  && ischar(pn.GivenName)
            str = sprintf('%s_%s',str,char(pn.GivenName));
        end

        % trim
        if strcmp(str(1),'_'),   str = str(2:end); end
        if strcmp(str(end),'_'), str = str(1:end-1); end

    end

end
