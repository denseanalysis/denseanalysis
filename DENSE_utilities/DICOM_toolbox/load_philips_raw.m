function [files, filedata] = load_philips_raw(files, headerFilterFcn, continueFcn)
  nFiles   = numel(files);
  valid    = false(nFiles, 1);
  filedata = repmat(struct, 0, 0);

  pdata = repmat(struct, 0, 0);

  % To process the raw images we must load all of them in first
  for k = 1:numel(files)
    % TODO: Fix this so we aren't growing this every iteration #perf
    dcmdata(k) = dicominfo(files{k});

    % Check if the user cancelled the load, and bail if needed
    if continueFcn(k) == false
      return
    end
  end

  % Get the unique series
  seriesNumbers = [dcmdata.SeriesNumber];

  for series = unique(seriesNumbers)
    infos = process_series(dcmdata(seriesNumbers == series));
    pdata = cat(1, pdata, infos(:));
  end


  for k = 1:numel(pdata)
    % This gets the fields that we want to keep
    fields = headerFilterFcn(pdata(k));
    for m = 1:numel(fields)
      tag = fields{m};
      filedata(k).(tag) = pdata(k).(tag);
    end

    valid(k)    = true;
  end

  % Only return the valid ones
  files    = files(valid);
  filedata = filedata(valid);

  function output = process_series(infos)
    % Make sure we sort by InstanceNumber
    [~, sortOrder] = sort([infos.InstanceNumber]);
    infos = infos(sortOrder);

    % Separate out real and imaginary images
    imageTypes = {infos.ImageType};
    isReal     = cellfun(@isempty, regexp(imageTypes, '\\R_FFE\\'));
    isImag     = cellfun(@isempty, regexp(imageTypes, '\\I_FFE\\'));

    realImages = infos(isReal);
    imagImages = infos(isImag);

    % Group by cardiac phase
    triggerTimes       = [realImages.TriggerTime];
    uniqueTriggerTimes = unique(triggerTimes);
    nPhases            = numel(uniqueTriggerTimes);

    % Reshape our image data in a logical way (nEncodings x nPhases)
    realImages = reshape(realImages, [], nPhases);
    imagImages = reshape(imagImages, [], nPhases);

    % For each real/imaginary pair, load the images in as a complex image so we
    % can then compute all the displacement images
    loadFcn = @(R,I)loadComplexImage(R,I);
    complexImages = arrayfun(loadFcn, realImages, imagImages, 'Uni', false);

    instanceNumber = 1;

    for k = 1:nPhases
      [dx, dy, dz] = simpleEncoding(complexImages{:, k});

      % X/Y/Z phase
      phaseX = phase12bit(angle(dx));
      phaseY = phase12bit(angle(dy));
      phaseZ = phase12bit(angle(dz));

      % Magnitude image averaged across all acquisitions
      aveMag = mean(abs(cat(3, complexImages{:, k})), 3);

      % Now prepare the "DICOMs"
      minfo = createSeq(aveMag, k, nPhases, 'overall','mag', realImages(1,k), instanceNumber);
      xinfo = createSeq(phaseX, k, nPhases, 'x-enc', 'pha', imagImages(2,k), instanceNumber);
      % Series numbers need to be unique for each encoding direction. Since
      % philips uses offsets of 100 for series, we can use offsets of 1
      xinfo.SeriesNumber = xinfo.SeriesNumber + 1;

      yinfo = createSeq(phaseY, k, nPhases, 'y-enc', 'pha', imagImages(3,k), instanceNumber);
      yinfo.SeriesNumber = yinfo.SeriesNumber + 2;

      zinfo = createSeq(phaseZ, k, nPhases, 'z-enc', 'pha', imagImages(4,k), instanceNumber);
      zinfo.SeriesNumber = zinfo.SeriesNumber + 3;

      % TODO: Figure out what the concatenation issue with an empty struct is
      if exist('output', 'var')
        output = cat(1, output(:), minfo, xinfo, yinfo, zinfo);
      else
        output = cat(1, minfo, xinfo, yinfo, zinfo);
      end

      % Increment the monotonically increasing instance number
      instanceNumber = zinfo.InstanceNumber + 1;
    end
  end

  function info = createSeq(img, phase, nPhases, direction, type, template, instanceNumber)
    info = template;
    denc = encodingFrequency(info);

    % Use the ImageComment field to provide this metadata
    fmt = 'DENSE %s %s Scale:1 EncFreq:%0.4f Rep:0/1 Slc:0/1 Par:0/1 Phs:%d/%d RCswap:0 RCSflip:0/0/0';
    comment = sprintf(fmt, direction, type, denc, phase - 1, nPhases);
    info.ImageComments = comment;
    info.InstanceNumber = instanceNumber;

    % Simulate the load but just return the image we already have
    info.LoadFcn = @()img;
  end

  function ph = phase12bit(ph)
    % Convert the (-pi, pi] to [0, 4096]
    ph = uint16((ph / pi) .* 2048 + 2047);
  end

  function f = encodingFrequency(info)
    details = info.Private_2005_140f.Item_1;
    f = 1.0 / details.TagSpacingFirstDimension;
  end

  function img = loadComplexImage(realInfo, imagInfo)
    % Loads complex image data from a real and imaginary component
    realImg = loadWithRescale(realInfo);
    imagImg = loadWithRescale(imagInfo);

    img = realImg + (j * imagImg);
  end

  function img = loadWithRescale(info)
    intercept  = info.RescaleIntercept;
    slope      = info.RescaleSlope;
    scaleSlope = info.Private_2005_100e;

    img = single(dicomread(info));

    img = (img * slope + intercept) / (slope * scaleSlope);
  end

  function [dx, dy, dz] = simpleEncoding(varargin)
    % Simple Encoding weights from
    % https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2772058/
    weights = [-1, 1, 0, 0;
               -1, 0, 1, 0;
               -1, 0, 0, 1;
                1, 0, 0, 0];

    [dx, dy, dz] = decodeDisplacements(varargin, weights);
  end

  function [dx, dy, dz] = balancedEncoding(varargin)
    % Balanced Encoding weights from
    % https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2772058/
    sq3 = sqrt(3);
    weights = [-sq3, sq3, sq3,-sq3;
               -sq3, sq3,-sq3, sq3;
               -sq3,-sq3, sq3, sq3;
                  1,   1,   1,   1] ./ 4;

    [dx, dy, dz] = decodeDisplacements(varargin, weights);
  end

  function [dx, dy, dz] = decodeDisplacements(phaseImages, W)
    sz = size(phaseImages{1});

    flattened = cellfun(@(x)x(:).', phaseImages, 'uniform', false);
    phaseData = cat(1, flattened{:});

    displacements = W * phaseData;

    dx = reshape(displacements(1,:), sz);
    dy = reshape(displacements(2,:), sz);
    dz = reshape(displacements(3,:), sz);
  end
end
