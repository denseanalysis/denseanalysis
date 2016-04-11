classdef structobj < handle
    % structobj - Mimics a structure but can be passed by reference
    %
    %   This class was developed to completely wrap the behavior of struct
    %   in a class. It has the added benefit that it can be passed around
    %   as a handle (by reference) so if a function or the user modifies
    %   the information contained within, all other copies of the
    %   information will see the change (and can react to it using the
    %   Updated event).
    %
    %   The resulting handle to the structobj object can be modified and
    %   used just like a structure would ordinarily be used.
    %
    % USAGE:
    %   self = structobj(S)
    %
    % INPUTS:
    %   S:      struct, Structure containing all of the data to be stored.
    %
    % OUTPUTS:
    %   self:   Handle, Handle to the structobj object which can be used
    %           just like a struct to modify the contents.

    % Copyright (c) <2016> Jonathan Suever (suever@gmail.com
    % All rights reserved
    %
    % This software is licensed using the 3-clause BSD license.

    properties (Access = 'private')
        Data = repmat(struct(), [0 1]); % Structure holding all the data
    end

    events
        Updated     % Event that is fired any time the data is modified
    end

    methods
        function self = structobj(varargin)
            % structobj - Constructor for the structobj object
            %
            % USAGE:
            %   self = structobj(S)
            %   self = structobj(varargin);
            %
            % INPUTS:
            %   S:          struct, Structure containing all of the data to
            %               be stored.
            %
            %   varargin:   Mixed, Inputs typically passed to the struct
            %               constructor.
            %
            % OUTPUTS:
            %   self:   Handle, Handle to the structobj object which can
            %           be used just like a struct to modify the contents.

            if nargin == 0
                S = struct();
            elseif ~isstruct(varargin{1})
                S = struct(varargin{:});
            else
                S = varargin{1};
            end

            % If a multi-dimensional struct is used, then create a
            % multidimensional structobj object
            if numel(S) == 1
                self.Data = S(1);
            else
                self = structobj.empty();

                for k = 1:numel(S)
                    self = cat(1, self, structobj(S(k)));
                end

                self = reshape(self, size(S));
            end
        end

        function res = copy(self)
            % copy - Makes a complete (shallow) copy of the object
            %
            %   This makes a shallow copy in that if you have any handle
            %   object instances saved in the object, these are copied by
            %   reference. The main structobj object, however, is copied
            %   and the result is unlinked with the original instance.
            %
            % USAGE;
            %   obj = self.copy()
            %
            % OUTPUTS:
            %   obj:    Handle, Handle to a duplicate structobj object

            res = structobj.loadobj(self.saveobj());
        end

        function disp(self)
            % disp - Overloaded display function
            %
            %   The DISP method was overloaded to display the underlying
            %   data just like it would be if it were a structure. This is
            %   further improve the seamless usage of structobj as
            %   opposed to a standard struct.
            %
            % USAGE:
            %   self.disp()

            disp(struct(self));
        end

        function self = horzcat(self, varargin)
            % horzcat - Concatenate objects in the 2nd dimension
            %
            %   This overloaded function first ensures that all members
            %   contain the same fields and can be concatenated (similar to
            %   the behavior for structs).
            %
            % USAGE:
            %   obj = self.horzcat(obj2)
            %
            % INPUTS:
            %   obj2:   Handle, structobj object to be concatenated with
            %           the current object.
            %
            % OUTPUTS:
            %   obj:    Handle, Array of the concatenation of the two
            %           structobj objects.

            self.checkfields(varargin{:})
            self = builtin('horzcat', self, varargin{:});
        end

        function props = properties(self)
            % properties - Get stored properties and fields
            %
            %   This returns a list of all the properties that are stored
            %   within the object. In older versions of MATLAB (< 2014a),
            %   overloading this function would allow for tab completion.
            %
            % USAGE:
            %   names = self.fieldnames()
            %
            % OUTPUTS:
            %   names:  Cell Array, Cell array of strings where each
            %           element corresponds to one of the fields stored in
            %           the data structure

            props = fieldnames(self);
        end

        function out = saveobj(self)
            % saveobj - Saves the necessary data to create an object
            %
            % USAGE:
            %   res = self.saveobj()
            %
            % OUTPUTS;
            %   res:    Struct, Structure containing the properties
            %           necessary to re-create an identical object.

            out = struct(self);
        end

        function self = subsasgn(self, s, varargin)
            % subsasgn - Overloaded subscript assignment function
            %
            %   This method was overloaded to allow the user to add/modify
            %   properties of the object just like they would with a
            %   structure (dot notation, etc.). This results in nearly
            %   identical behavior except for some limitations thanks to
            %   MATLAB bugs.

            if ~isempty(s) && isequal(s(1).type, '()')
                obj = builtin('subsref', self, s(1));
                s = s(2:end);
            else
                obj = self;
            end

            dat = [obj.Data];
            dat = reshape(dat, size(obj));

            if isempty(s)
                self = obj;
                return
            end

            try
                out = builtin('subsasgn', dat, s, varargin{:});
            catch ME
                if strcmpi(ME.identifier, 'MATLAB:noPublicFieldForClass')
                    item = subsref(dat, s(1));
                    ignore = subsasgn(item, s(2:end), varargin{:}); %#ok
                    out = dat;
                else
                    rethrow(ME);
                end
            end

            out = num2cell(out);
            [obj.Data] = deal(out{:});
        end

        function varargout = subsref(self, s)
            % subsref - Overloaded subscript referencing function
            %
            %   This method was overloaded to allow the user to view the
            %   properties of the object just like they would with a
            %   structure (dot notation, etc.). This results in nearly
            %   identical behavior except for some limitations thanks to
            %   MATLAB bugs.

            if numel(s) == 1 && isequal(s(1).type, '()')
                obj = builtin('subsref', self, s(1));
                varargout = {obj};
                return
            end

            [varargout{1:nargout}] = builtin('subsref', struct(self), s(1));

            if numel(s) > 1
                if isa(varargout, class(self))
                    [varargout{:}] = varargout{1}.subsref(s(2:end));
                else
                    [varargout{:}] = subsref(varargout{:}, s(2:end));
                end
            end
        end

        function update(self, obj)
            % update - Updates the current object with data from a struct
            %
            %   This function allows the user to quickly merge an existing
            %   structure with the current object.
            %
            % USAGE:
            %   self.update(S)
            %
            % INPUTS:
            %   S:  struct, Structure or structure-like object whose values
            %       should be incorporated into the current object

            % Test to see if the alternate object is easily converted
            if ~isequal(size(self), size(obj))
                error(sprintf('%s:MismatchSize', mfilename), ...
                    'Sizes must match');
            end

            if numel(self) > 1
                arrayfun(@update, self, obj);
                return;
            end

            try
                obj = struct(obj);
            catch
                error(sprintf('%s:InvalidStruct', mfilename), ...
                    'Requires a structure-like input');
            end

            fields = fieldnames(obj);

            for k = 1:numel(fields)
                [self.Data.(fields{k})] = deal(obj.(fields{k}));
            end
        end

        function self = vertcat(self, varargin)
            % vertcat - Concatenate objects in the 1st dimension
            %
            %   This overloaded function first ensures that all members
            %   contain the same fields and can be concatenated (similar to
            %   the behavior for structs).
            %
            % USAGE:
            %   obj = self.vertcat(obj2)
            %
            % INPUTS:
            %   obj2:   Handle, structobj object to be concatenated with
            %           the current object.
            %
            % OUTPUTS:
            %   obj:    Handle, Array of the concatenation of the two
            %           structobj objects.

            self.checkfields(varargin{:})
            self = builtin('vertcat', self, varargin{:});
        end
    end

    %--- Overloaded struct functions ---%
    methods
        function res = struct(self)
            % struct - Converts structobj to a structure array
            %
            %   Converts the structobj back into a struct which can no
            %   longer be passed around by reference.
            %
            % USAGE:
            %   S = self.struct()
            %
            % OUTPUTS;
            %   S:  Struct, Structure containing all of the same data as
            %       the structobj object except it can no longer be
            %       passed around as a handle.

            if isempty(self)
                res = repmat(struct(), size(self));
            else
                res = reshape([self.Data], size(self));
            end
        end

        function res = fieldnames(self)
            % fieldnames - Get stored properties and fields
            %
            %   This returns a list of all the properties that are stored
            %   within the object. In older versions of MATLAB (< 2014a),
            %   overloading this function would allow for tab completion.
            %
            % USAGE:
            %   names = self.fieldnames()
            %
            % OUTPUTS:
            %   names:  Cell Array, Cell array of strings where each
            %           element corresponds to one of the fields stored in
            %           the data structure

            res = fieldnames(struct(self));
        end

        function res = getfield(self, field, default)
            % getfield - Get the value of a specific field
            %
            %   Overloaded version of the getfield method for structures.
            %   This implementation varies in one way in that it can accept
            %   an additional input which specifies a default value to
            %   return if the requested field does not exist.
            %
            % USAGE:
            %   val = self.getfield(fieldname, default)
            %
            % INPUTS:
            %   fieldname:  String, Name of the property to return
            %
            %   default:    The default value to return if the requested
            %               property does not exist.
            %
            % OUTPUTS:
            %   val:        The value of the requested field

            if ~isfield(self, field) && exist('default', 'var')
                if numel(self) > 1
                    res = repmat({default}, size(self));
                else
                    res = default;
                end
            else
                res = getfield(struct(self), field);
            end
        end

        function res = isfield(self, varargin)
            % isfield - Determines whether the object has a specific field
            %
            % USAGE:
            %   bool = self.isfield(fieldname)
            %
            % INPUTS:
            %   fieldname:  String, Name of the property to return
            %
            % OUTPUTS:
            %   bool:       Logical, TRUE if the field exists and FALSE
            %               otherwise

            res = isfield(struct(self), varargin{:});
        end

        function res = isstruct(varargin)
            % isstruct - Overloaded function to trick built-in functions
            %
            %   Many built-in functions expect a structure as an input and
            %   this method allows structobj objects to be passed in
            %   lieu of structures by falsely reporting that they are
            %   structures. This works because we have also overloaded all
            %   struct functionality.
            %
            % USAGE:
            %   bool = self.isstruct()
            %
            % OUTPUTS:
            %   bool:   Logical, This value is ALWAYS TRUE

            res = true;
        end

        function [self, perm] = orderfields(self, varargin)
            % orderfields - Order the fields of the object
            %
            %   The typical usage of this functions is to enforce a
            %   specific ordering of the object properties. See the help
            %   for the built-in ORDERFIELDS function for more information.
            %
            % USAGE:
            %   [self, perm] = self.orderfields()
            %
            % OUTPUTS:
            %   self:   Handle, structobj object (with the same handle)
            %           with the fields ordered as requested.
            %
            %   perm:   Vector, A permutation vector representing the
            %           change in order performed on the fields of the
            %           object that resulted in the output object.

            for k = 1:numel(self)
                [self(k).Data, perm] = orderfields(self(k).Data, varargin{:});
            end
        end

        function self = rmfield(self, varargin)
            % rmfield - Removes the specified fields from the object
            %
            % USAGE:
            %   self = self.rmfield(fields)
            %
            % INPUTS:
            %   fields: String or Cell Array, Names of the fields to remove
            %
            % OUTPUTS:
            %   self:   Handle, structobj object with the specified fields
            %           removed.

            for k = 1:numel(self)
                self(k).Data = rmfield(self(k).Data, varargin{:});
            end
        end
    end

    %--- Get / Set Functions ---%
    methods
        function set.Data(self, val)
            self.Data = val;
            notify(self, 'Updated');
        end
    end

    methods (Access = 'private')
        function checkfields(varargin)
            % checkfields - Ensures that all members have the same fields
            %
            %   In order to behave like a structure, it is necessary that
            %   all members of a multi-dimensional structobj object have
            %   the same properties.
            %
            %   An error is thrown if the fields do not match for all input
            %   objects.
            %
            % USAGE:
            %   self.checkfields()

            fields = cellfun(@(x)sort(fieldnames(x)), varargin, 'uni', 0);

            equal = cellfun(@(x)isequal(x, fields{1}), fields(2:end));

            if ~all(equal)
                error(sprintf('%s:MismatchedFields', mfilename), ...
                    'Unmatched structure fields. Cannot concatenate');
            end
        end
    end

    methods (Static)
        function res = loadobj(S)
            % loadobj - Instantiate an object from a structure
            %
            %   This function is called when loading an object from a .mat
            %   file. Alternately, this can be used if you just want to
            %   quickly construct an object from a structure.
            %
            % USAGE:
            %   self = loadobj(S)
            %
            % INPUTS:
            %   S:      Struct, Structure containing all the information
            %           required to properly construct the object
            %
            % OUTPUTS:
            %   self:   Object, Instance of structobj that is the same
            %           dimensionality as the input structure.

            res = structobj(S);
        end

        function results = test(varargin)
            % structobj.test - Runs all unittests
            %
            % USAGE:
            %   results = structobj.test(name);
            %
            % INPUTS:
            %   name:   String, Name of a specific test to run (optional)
            %
            % OUTPUTS:
            %   results:    TestResult, matlab.unittest.TestResult object
            %               that provides detailed information about which
            %               tests passed or failed.

            tests = test_structobj();
            results = tests.run(varargin{:});
        end
    end
end
