function str = parseDICOMdate(val,format)

%PARSEDICOMDATE represent DICOM date fields as formated string
%
%INPUTS
%   val......Date string (as 'yyymmdd')
%   format...output format (e.g. 'mm.dd.yyyy' or 'mmm.dd.yyyy');
%
%OUTPUTS
%   str....formatted string
%
%USAGE
%   STR = PARSEDICOMDATE(SD,FORMAT) output a DICOM date field as
%   formatted date string (see DATESTR for formatting)
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation


    % default format
    if nargin < 2, format = 'yyyy.mm.dd'; end

    % test the format string
    try
        str = datestr(0,format);
    catch ERR
        warning(sprintf('%s:unrecongizedFormatString',mfilename),...
            'Unrecognized format string.');
        str = '';
        return;
    end

    % parse to user-specified date format
    ERR = [];
    try
        if ischar(val) && numel(val,8)
            str = datestr(datenum(val,'yyyymmdd'),format);
        elseif ischar(val) && numel(val,10)
            str = datestr(datenum(val,'yyyy.mm.dd'),format);
        else
            ERR = true;
        end
    catch ERR
    end

    % unrecognized date
    if ~isempty(ERR)
        warning(sprintf('%s:unrecongizedDICOMdate',mfilename),...
            'Unrecognized DICOM Date.');
        str = '';
    end

end
