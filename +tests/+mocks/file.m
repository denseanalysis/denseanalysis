classdef file < handle
    % file - Mock for a file object that responds to matlab commands
    properties
        Filename
    end

    methods

        function self = file(filename)
            if ~exist('filename', 'var'); filename = ''; end
            self.Filename = filename;
        end

        function res = exist(varargin)
            if numel(varargin) == 2 && ~strcmpi(varargin{2}, 'file')
                res = 0;
            else
                res = 2;
            end
        end

        function bool = ischar(varargin)
            bool = true;
        end

        function fid = fopen(varargin)
            fid = filehandle();
        end
    end
end
