classdef filehandle < handle

    properties
        fid = 100
    end

    methods
        function fprintf(varargin)
        end

        function fwrite(varargin)
        end

        function fread(varargin)
        end

        function fgetl(varargin)
        end

        function fclose(varargin)
        end
    end
end
