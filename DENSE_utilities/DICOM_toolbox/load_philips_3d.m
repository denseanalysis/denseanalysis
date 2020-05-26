function [files, filedata] = load_philips_3d(files, headerFilterFcn, continueFcn)
  nFiles   = numel(files);
  filedata = repmat(struct, [nFiles, 1]);
  valid    = false(nFiles, 1);

  for k = 1:numel(files)
    try
      dcmdata = dicominfo(files{k});
    catch
      continue
    end

    dcmdata = process_image(dcmdata);

    fields = headerFilterFcn(dcmdata);
    for m = 1:numel(fields)
      tag = fields{m};
      filedata(k).(tag) = dcmdata.(tag);
    end

    % Specify function to load corresponding pixel data
    filedata(k).LoadFcn = @()dicomgray(filename, 'frames', 1);

    valid(k) = true;

    % Check if the user cancelled the load, and bail if needed
    if continueFcn(k) == false
      return
    end
  end

  % Only return the valid ones
  files    = files(valid);
  filedata = filedata(valid);
end

function dcmdata = process_image(dcmdata)
     % Add some custom fields for Philips data
    stacks = struct2array(dcmdata.Private_2001_105f);

    % There is a stack for each encoding direction
    dimensions = numel(stacks);
    nSlices = double(stacks(1).Private_2001_102d);
    nPhases = double(dcmdata.Private_2001_1017);

    details = getfieldr(dcmdata, 'Private_2005_140f.Item_1', struct());

    % Get the tag spacing
    encodingFrequency = 1.0 / details.TagSpacingFirstDimension;

    % Determine if this is a magnitude or phase image
    if regexp(dcmdata.ImageType, '\\M\\')
        imtype = 'mag';
    else
        imtype = 'pha';
    end

    % Try to fill in the ImageComments as needed so that
    % the DENSE images are processed appropriately
    instance = dcmdata.InstanceNumber - 1;
    currentPhase = mod(instance, nPhases);
    currentSlice = floor(mod(instance / nPhases, nSlices));

    type_index = mod(floor(instance / (nSlices * nPhases)), dimensions) + 1;
    directions = 'xyz';

    encoding_direction = directions(type_index);

    fmt = 'DENSE %s-enc %s Scale:1 EncFreq:%0.4f Rep:0/1 Slc:1/0 Par:%d/%d Phs:%d/%d RCswap:0 RCSflip:0/1/0';
    comments = sprintf(fmt, encoding_direction, imtype, ...
        encodingFrequency, currentSlice, nSlices, ...
        currentPhase, nPhases);

    dcmdata.ImageComments = comments;

    % Take care of any strange rounding issues
    dcmdata.ImageOrientationPatient = round(dcmdata.ImageOrientationPatient .* 1000) ./ 1000;
    dcmdata.ImagePositionPatient = round(dcmdata.ImagePositionPatient .* 1000) ./ 1000;
    dcmdata.SliceLocation = round(dcmdata.SliceLocation .* 1000) ./ 1000;

    % Modify the series description to provide the user
    % more information when manually assigning DENSE groups
    dcmdata.SeriesDescription = sprintf('%s: %s-enc %s Slice:%d', ...
        dcmdata.SeriesDescription, encoding_direction, ...
        imtype, currentSlice);

    % Update the InstanceNumber to allow the rest of the
    % load function to operate appropriately.
    %
    % TODO: Fix the rest of this function to be more robust
    % and not as strict with InstanceNumber values
    dcmdata.InstanceNumber = currentPhase + 1;
end
