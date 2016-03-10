classdef Configuration < structobj
    % Configuration - An object for saving/loading settings from JSON
    %
    % USAGE:
    %   conf = Configuration(jsonfile)
    %
    % INPUTS:
    %   jsonfile:   String, Path to the configuraiton file that will be
    %               written to. If this file already exists, the data
    %               contained in the file will be loaded.
    %
    % OUTPUTS:
    %   conf:       Object, Configuration object that behaves just like a
    %               structure with a few key features added. See individual
    %               methods for additional help.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties (Access = 'private')
        filename    % Path to the file to store the configuration in
        listener    % Listener to write settings to disk
    end

    methods
        function self = Configuration(filename)
            % Configuration - Configuration constructor
            %
            % USAGE:
            %   conf = Configuration(jsonfile)
            %
            % INPUTS:
            %   jsonfile:   String, Path to the configuraiton file that
            %               will be written to. If this file already
            %               exists, the data contained in the file will be
            %               loaded.
            %
            % OUTPUTS:
            %   conf:       Object, Configuration object that behaves just
            %               like a structure with a few key features added.
            %               See individual methods for additional help.

            self.filename = filename;

            if ~exist(self.filename, 'file')
                fclose(fopen(self.filename, 'wb'));
            else
                self.load();
            end

            % Write any new settings to the file
            self.listener = addlistener(self, 'Updated', @(s,e)save(s));
        end

        function self = reset(self)
            % reset - Remove all fields from the configuration object
            %
            % USAGE:
            %   reset(conf);

            self = rmfield(self, fieldnames(self));
        end

        function res = get(self, field, varargin)
            % get - Retrieve a value from the configuration
            %
            %   This function allows users to retrieve a value from the
            %   configuration object by string. Also, a default value can
            %   be supplied so that if that field doesn't exist, the
            %   default value will be returned rather than an error being
            %   issued.
            %
            %   The field string can be either a fieldname of the
            %   configuration  ('field') or if the field contains a
            %   structure, you can use dot notation to access nested
            %   properties ('field.value'). This is the equivalent of
            %   "conf.field.value".
            %
            % USAGE:
            %   res = get(conf, field, default)
            %
            % INPUTS:
            %   field:      String, Field name ('field') or nested field
            %               name ('field.value') to retrieve.
            %
            %   default:    Any, Value to return in case the field was
            %               was not found.
            %
            % OUTPUTS:
            %   res:        Any, Value at the requested field or the
            %               specified default value

            if ~exist('field', 'var')
                res = self;
                return
            end

            try
                res = subsref(self, getSubStruct(field));
            catch ME
                if any(strcmp(ME.identifier, {'MATLAB:nonExistentField', ...
                        'MATLAB:cellRefFromNonCell'})) && numel(varargin)
                    res = varargin{1};
                else
                    rethrow(ME);
                end
            end
        end

        function set(self, field, value)
            % set - Simple wrapper for setfield
            %
            %   To be consistent with having a get method, we have a
            %   corresponding set function which is a synonymn for the
            %   setfield function. The only difference is that this
            %   function accepts nested values as the fieldname
            %   ('field.value').
            %
            % USAGE:
            %   set(conf, fieldname, value)
            %
            % INPUTS:
            %   fieldname:  String, fieldname to set. This can either be a
            %               "primary" fieldname ('field') or a nested
            %               fieldname ('field.subfield.subsubfield').
            %
            %   value:      Any, Any data that should be stored in the
            %               requested field

            subsasgn(self, getSubStruct(field), value);
        end

        function save(self)
            % save - Saves the current configuration to the file
            %
            %   Saves all data to the specified file in JSON format. This
            %   method is called anytime that the underlying data object is
            %   altered.
            %
            % USAGE:
            %   save(conf)

            savejson('', self.struct(), self.filename);
        end

        function data = tojson(self)
            % tojson - Retrieve the JSON representation of this object
            %
            % USAGE:
            %   json = tojson(conf);
            %
            % OUTPUTS:
            %   json:   String, JSON-encoded string representing the data
            %           contained within this configuration instance.

            data = savejson('', self.struct());
        end

        function load(self)
            % load - Loads configuration object from disk
            %
            %   This function loads the data for this configuration object
            %   from the JSON file specified in the constructor. This is
            %   essentially a way to "reload" any changes that may have
            %   been made to the file after object creation.
            %
            %   This function is called automatically during object
            %   creation (if the specified file exists).
            %
            % USAGE
            %   load(conf)

            filedata = cells2structs(loadjson(self.filename));

            % Ensure that we turn off file-writing so we don't lose data
            if ~isempty(self.listener)
                self.listener.Enabled = false;
                reset(self);
                update(self, filedata);
                self.listener.Enabled = true;
            else
                reset(self);
                update(self, filedata);
            end
        end
    end
end

function S = cells2structs(S)
    % cells2structs - Flatten cell arrays of structs into arrays of structs
    %
    %   This flattens them as much as possible. Similar to a `squeeze` for
    %   cell arrays of structures.
    %
    % USAGE:
    %   S = cell2structs(S)
    %
    % INPUTS:
    %   S:  struct, structure containing fields to convert
    %
    % OUTPUTS:
    %   S:  struct, structure with cell of struct fields converted to array
    %       of struct fields when possible.

    fields = fieldnames(S);

    for k = 1:numel(fields)
        value = S.(fields{k});

        if iscell(value) && numel(value)
            % Flatten this if possible into an array
            try
                while iscell(value)
                    value = [value{:}];
                end
            catch
            end
        end

        % Perform same processing on all nested structures
        if isstruct(value)

            for m = 1:numel(value)
                value(m) = cells2structs(value(m));
            end
        end

        S.(fields{k}) = value;
    end
end

function S = getSubStruct(fields)
    % Construct substruct for field.subfield.subsubfield notation
    pieces = regexp(fields, '\.', 'split');
    subs = cat(1, repmat({'.'}, size(pieces)), pieces);
    S = substruct(subs{:});
end
