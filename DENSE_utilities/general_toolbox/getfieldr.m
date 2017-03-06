function value = getfieldr(S, fields, varargin)
    % getfieldr - Recursively get fields from a struct
    %
    %   This function allows you to specify the fieldname to retrieve and
    %   include dots to get values out of nested structs. Also, it accepts
    %   an optional default value which will be returned in the case that
    %   the provided field was unable to be accessed.
    %
    % USAGE:
    %   value = getfieldr(S, fields, default)
    %
    % INPUTS:
    %   S:          Struct, Structure which you would like to access. At
    %               this point, this must be a scalar struct.
    %
    %   fields:     String, Name of the field to be returned as a string.
    %               Can either be a single field ('field') or a nested
    %               field ('parent.child').
    %
    %   default:    Any, Value to return in case the field cannot be
    %               located.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    if ~ischar(fields) && ~iscell(fields)
        error(sprintf('%s:InvalidFieldname', mfilename), ...
            'The fieldname must be a string.')
    end

    if ~isstruct(S)
        error(sprintf('%s:InvalidStruct', mfilename), ...
            'The first input must be a struct.')
    end

    % Split the field at the dots
    if ischar(fields)
        fields = regexp(fields, '\.', 'split');
    end

    try
        value = S.(fields{1});
    catch ME
        if numel(varargin)
            value = varargin{1};
            return;
        else
            rethrow(ME);
        end
    end

    if numel(fields) > 1
        value = getfieldr(value, fields(2:end), varargin{:});
    end
end
