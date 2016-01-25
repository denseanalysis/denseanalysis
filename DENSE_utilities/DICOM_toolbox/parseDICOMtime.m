function str = parseDICOMtime(val,format)

%PARSEDICOMTIME represent DICOM time fields as formated string
%
%INPUTS
%   val......time value
%   format...output format (e.g. 'HH:MM:SS' or 'HH.MM.SS.FFF');
%
%OUTPUTS
%   str....formatted string
%
%USAGE
%   STR = PARSEDICOMTIME(SD,FORMAT) output a DICOM time field as
%   formatted time string (see DATESTR for formatting)
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
    if nargin < 2, format = 'HH:MM:SS'; end

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
        if ~ischar(val)
            ERR = true;
        else
            if numel(val)==2
                str = datestr(datenum(val,'HH'),format);
            elseif numel(val) == 4
                str = datestr(datenum(val,'HHMM'),format);
            elseif numel(val) == 6
                str = datestr(datenum(val,'HHMMSS'),format);
            elseif numel(val)>6 && strwcmpi(val,'*.*')
                str = datestr(datenum(val,'HHMMSS.FFF'),format);
            else
                ERR = true;
            end
        end
    catch ERR
    end

    % unrecognized date
    if ~isempty(ERR)
        warning(sprintf('%s:unrecongizedDICOMtime',mfilename),...
            'Unrecognized DICOM time.');
        str = '';
    end

end
