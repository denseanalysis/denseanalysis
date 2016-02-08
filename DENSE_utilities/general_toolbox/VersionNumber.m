classdef VersionNumber
    % VersionNumber - Class for parsing and comparing version numbers
    %
    %   The purpose of this class is to streamline the parsing and
    %   comparing of version numbers. It handles a variety of version
    %   string formats as well as pre-release information (alpha, beta, and
    %   release candidates).
    %
    %   See VersionNumber.test() method to see the different formats
    %   supported by the class.
    %
    % USAGE:
    %   v = VersionNumber(x,y,z,...)
    %   v = VersionNumber(string)
    %
    % INPUTS:
    %   x,y,z...:   Integers, Version numbers with most significant version
    %               number appearing first. (i.e. VersionNumber(1,2,3) ==
    %               '1.2.3')
    %
    %   string:     String, String representation of the version number.
    %
    % OUTPUTS:
    %   v:          Object, VersionNumber object that can be used to
    %               compare to other VersionNumber objects

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties (Hidden)
        string = '' % String representation of the version
        parts       % Struct containing the various parts of the version
    end

    properties (Hidden, Dependent)
        nPieces     % Number of parts to the version number (x.y.z == 3)
        release     % Release name
    end

    % Get/Set Methods
    methods
        function res = get.nPieces(self)
            res = numel(self.parts.pieces);
        end

        function res = get.release(self)
            if isempty(self.parts.suffix)
                res = 'stable';
            else
                res = self.parts.suffix;
            end
        end
    end

    methods
        function self = VersionNumber(varargin)
            % VersionNumber - Constructor for a version number
            %
            % USAGE:
            %   v = VersionNumber(x,y,z,...)
            %   v = VersionNumber(string)
            %   v = VersionNumber(array)
            %
            % INPUTS:
            %   x,y,z...:   Integers, Version numbers with most significant
            %               version number appearing first. (i.e.
            %               VersionNumber(1,2,3) == '1.2.3')
            %
            %   string:     String, String representation of the version.
            %
            %   array:      [1 X M] Array, An array of integers similar to
            %               x,y,z above where each element represents a
            %               version number with the most significant
            %               appearing first. (i.e. [1, 2, 3] == '1.2.3')
            %
            % OUTPUTS:
            %   v:          Object, VersionNumber object that can be used
            %               to compare to other VersionNumber objects

            if nargin == 0
                error(sprintf('%s:InvalidInput', mfilename), ...
                    'You must specify a version number');
            end

            if numel(varargin) == 1
                str = varargin{1};
            else
                str = varargin;
            end

            if ~ischar(str)
                % Convert this number to a string
                if isa(str, class(self))
                    self = str;
                    return
                end

                if isnumeric(str)
                    str = num2cell(str);
                end

                if iscell(str)
                    str = sprintf('%d.', str{:});
                    str(end) = [];
                else
                    error(sprintf('%s:InvalidVersion', mfilename), ...
                        'Version input should be char, numeric, or cells')
                end
            end

            self.string = str;
            self.parts = self.parse(str);
        end

        function [vals, ind] = sort(self, order)
            % Sort from lowest (oldest) to highest (newest)
            numels = max([self.nPieces]);

            % Now pad them to be the same size
            padmat = zeros(numel(self), numels);

            for k = 1:numel(self)
                padmat(k, 1:self(k).nPieces) = self(k).parts.pieces;
            end

            func = @(x)strcat(upper(x.parts.suffix), 'Z');
            suffixes = arrayfun(func, self, 'uni', 0);
            [~, ind] = sort(suffixes);

            padmat(:,end) = ind;
            [~, ind] = sortrows(padmat);

            if exist('order', 'var') && strncmpi(order, 'desc', 4)
                ind = flipud(ind);
            end

            vals = self(ind);
        end

        function disp(self)
            % disp - Overloads the built-in display to show version string

            if numel(self) == 1
                fprintf(1, '\t%s\n', self.char());
            else
                builtin('disp', self)
            end
        end

        function out = char(self)
            % char - Converts version to a human-readable form
            if numel(self) == 1
                out = sprintf('%s (%s)', self.parts.number, self.release);
            else
                out = builtin('char', self);
            end
        end

        function bool = isPreRelease(self)
            % isPreRelease - Helper function for determining stability
            %
            %   This can be used to quickly determine whether a "new"
            %   version is a pre-release or not. If you are running stable
            %   software, typically you will want to ignore pre-releases.

            bool = ~strcmpi(self.release, 'stable');
        end

        function bool = lt(obj1, obj2)
            % < Less than.
            %
            %   A < B Performs a comparison between A and B. If B is not a
            %   VersionNumber it will be implicitly converted prior to
            %   comparison.

            [~, ind] = sort([obj1, VersionNumber(obj2)]);
            bool = isequal(ind, [1;2]) && ~eq(obj1, obj2);
        end

        function bool = le(obj1, obj2)
            % <= Less than or equal.
            %
            %   A <= B Performs a comparison between A and B. If B is not a
            %   VersionNumber it will be implicitly converted prior to
            %   comparison.

            bool = obj1 == obj2 || obj1 < obj2;
        end

        function bool = ge(obj1, obj2)
            % >= Greater than or equal.
            %
            %   A >= B Performs a comparison between A and B. If B is not a
            %   VersionNumber it will be implicitly converted prior to
            %   comparison.

            bool = obj1 == obj2 || obj1 > obj2;
        end

        function bool = eq(obj1, obj2)
            % == Equal
            %
            %   A == B Performs a comparison between A and B. If B is not a
            %   VersionNumber it will be implicitly converted prior to
            %   comparison.

            if ~isa(obj2, class(obj1))
                obj2 = VersionNumber(obj2);
            end

            bool = isequal(obj1.parts.pieces, obj2.parts.pieces) && ...
                   isequal(obj1.parts.suffix, obj2.parts.suffix);
        end

        function bool = ne(obj1, obj2)
            % ~= Not Equal
            %
            %   A ~= B Performs a comparison between A and B. If B is not a
            %   VersionNumber it will be implicitly converted prior to
            %   comparison.

            bool = ~eq(obj1, obj2);
        end

        function bool = gt(obj1, obj2)
            % > Greater Than
            %
            %   A > B Performs a comparison between A and B. If B is not a
            %   VersionNumber it will be implicitly converted prior to
            %   comparison.

            bool = lt(VersionNumber(obj2), obj1);
        end
    end

    methods (Access = 'private')
        function mat = sortmat(obj1, obj2)
            % sortmat - Helper function to create sortable versions
            %
            %   The purpose of this function is to convert a version string
            %   into a numeric matrix representation where they can be
            %   compared by simply sorting the rows. The last column takes
            %   into account the release type to ensure that stable
            %   releases are favored over pre-releases.

            if ~isa(obj2, 'VersionNumber')
                obj2 = VersionNumber(obj2);
            end

            % Pad them all to be the same size and have trailing zeros
            nPieces = max(obj1.nPieces, obj2.nPieces);
            mat = zeros(2, nPieces);
            mat(1,1:obj1.nPieces) = obj1.parts.pieces;
            mat(2,1:obj2.nPieces) = obj2.parts.pieces;

            % Now make the last column pertain to the suffix
            suffix1 = obj1.parts.suffix;
            suffix2 = obj2.parts.suffix;

            if isequal(suffix1, suffix2); return; end

            % Append a Z so that an empty string bets sorted than alpha,
            % beta, rc, stable, etc.
            suffixes = {[upper(suffix1), 'Z'], [upper(suffix2), 'Z']};

            [~, ind] = sort(suffixes);
            mat(:,end+1) = ind;
        end
    end

    methods (Static)
        function data = parse(string)
            % parse - Parses a version string into it's constituents
            %
            % USAGE:
            %   data = parse(string)
            %
            % INPUTS:
            %   string: String, String representing the version number
            %           (i.e. '1.2.3')
            %
            % OUTPUTS:
            %   data:   Struct, Structure containing several pieces of
            %           information pertaining to the input string:
            %
            %               number: String representation of just the
            %                       numeric part of the version
            %
            %               suffix: String representing the the release
            %                       type (alpha, beta, rc1, etc.) and an
            %                       empty string implies stable.
            %
            %               pieces: [1 x N] Array, Numeric array of the
            %                       numeric representation of NUMBER.

            pattern = '^(\s*)v?(?<number>(\d+[-_\.])*\d+)[-_\.]*(?<suffix>.*)';
            data = regexp(string, pattern, 'names');

            % Now break the number into pieces
            pieces = regexp(data.number, '[-_\.]', 'split');
            data.pieces = str2double(pieces);

            % Trim whitespace around the suffix if necessary
            data.suffix = strtrim(data.suffix);

            % Remove any leading or trailing parenthesis on suffix
            data.suffix = regexprep(data.suffix ,'(^\()|(\)$)', '');
        end

        function test()
            % Some really basic tests to demonstrate functionality and test
            % logic and comparators
            %
            % USAGE:
            %   VersionNumber.test()

            % Test Constructors of all different types
            assert(VersionNumber('1.2.3') == VersionNumber('1.2.3'))
            assert(VersionNumber('1.2.3') == VersionNumber('v1.2.3'))
            assert(VersionNumber('1.2.3') == VersionNumber(1,2,3))
            assert(VersionNumber('1.2.3') == VersionNumber([1,2,3]))
            assert(VersionNumber('1.2.3') == VersionNumber('1_2_3'))
            assert(VersionNumber('1.2.3') == VersionNumber('1-2-3'))

            function testComparators(low, high)
                % Quick utility function to test all comparisons
                low = VersionNumber(low);
                high = VersionNumber(high);
                assert(low < high);
                assert(low <= high);
                assert(high > low);
                assert(high >= low);
                assert(low ~= high);
            end

            % Basic comparisons
            testComparators('0.9', '1.0')
            testComparators('1.1', '1.2')
            testComparators('1.0', '2.0')

            % Test minor version expansions
            testComparators('1.1.1', '1.2')
            testComparators('1.2', '1.2.1')

            % Test pre-release versions
            testComparators('1.0alpha', '1.0beta')
            testComparators('1.0beta', '1.0rc1')
            testComparators('1.0rc1', '1.0rc2')
            testComparators('1.0rc2', '1.0')
        end
    end
end
