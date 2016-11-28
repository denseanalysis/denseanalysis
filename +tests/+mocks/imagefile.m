classdef imagefile < tests.mocks.file

    properties
        Alpha
        Colormap
        Dimensions
        ImageData
    end

    methods
        function self = imagefile(filename, imagedata, colormap, alpha)
            self.Filename = filename;
            self.Dimensions = size(imagedata);
            self.ImageData = imagedata;

            if ~exist('colormap', 'var')
                colormap = rand(ceil(max(imagedata(:))), 3);
            end

            self.Colormap = colormap;

            if exist('alpha', 'var')
                self.Alpha = alpha;
            end
        end

        function [im, map, alpha] = imread(self, varargin)
            im = self.ImageData;
            map = self.Colormap;
            alpha = self.Alpha;
        end
    end
end
