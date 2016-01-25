function f = multimediaformats()
% f = multimediaformats()

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
    % initialize structure
    idx = 0;
    f = repmat(struct,[0 1]);

    % BITMAP
    idx = idx+1;
    f(idx).Name             = 'BMP';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.bmp'};
    f(idx).Description      = 'Bitmap image (*.bmp)';
    f(idx).Filter           = '*.bmp';
    f(idx).HGExportFormat   = 'bmp';

    % EMF
    idx = idx+1;
    f(idx).Name             = 'EMF';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.emf'};
    f(idx).Description      = 'Enhanced Metafile (*.emf)';
    f(idx).Filter           = '*.emf';
    f(idx).HGExportFormat   = 'meta';

    % EPS
    idx = idx+1;
    f(idx).Name             = 'EPS';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.eps'};
    f(idx).Description      = 'EPS file (*.eps)';
    f(idx).Filter           = '*.eps';
    f(idx).HGExportFormat   = 'eps';

    % JPEG
    idx = idx+1;
    f(idx).Name             = 'JPEG';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.jpg','.jpeg'};
    f(idx).Description      = 'JPEG image (*.jpg)';
    f(idx).Filter           = '*.jpg;*.jpeg';
    f(idx).HGExportFormat   = 'jpeg75';

    % PDF
    idx = idx+1;
    f(idx).Name             = 'PDF';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.pdf'};
    f(idx).Description      = 'Portable Document Format (*.pdf)';
    f(idx).Filter           = '*.pdf';
    f(idx).HGExportFormat   = 'pdf';

    % PNG
    idx = idx+1;
    f(idx).Name             = 'PNG';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.png'};
    f(idx).Description      = 'Portable Network Graphics image (*.png)';
    f(idx).Filter           = '*.png';
    f(idx).HGExportFormat   = 'png';

    % TIFF
    idx = idx+1;
    f(idx).Name             = 'TIFF';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.tiff','.tif'};
    f(idx).Description      = 'TIFF image (*.tiff)';
    f(idx).Filter           = '*.tif;*.tiff';
    f(idx).HGExportFormat   = 'tiff';

    % TIFF (no compression)
    idx = idx+1;
    f(idx).Name             = 'TIFFN';
    f(idx).Type             = 'Image';
    f(idx).Extension        = {'.tiff','.tif'};
    f(idx).Description      = 'Uncompressed TIFF image (*.tiff)';
    f(idx).Filter           = '*.tif;*.tiff';
    f(idx).HGExportFormat   = 'tiffn';

    % AVI
    idx = idx+1;
    f(idx).Name             = 'AVI';
    f(idx).Type             = 'Video';
    f(idx).Extension        = {'.avi'};
    f(idx).Description      = 'AVI file (*.avi)';
    f(idx).Filter           = '*.avi';
    f(idx).HGExportFormat   = 'tiffn';

    % GIF
    idx = idx+1;
    f(idx).Name             = 'GIF';
    f(idx).Type             = 'Video';
    f(idx).Extension        = {'.gif'};
    f(idx).Description      = 'Animated GIF file (*.gif)';
    f(idx).Filter           = '*.gif';
    f(idx).HGExportFormat   = 'tiffn';

end
