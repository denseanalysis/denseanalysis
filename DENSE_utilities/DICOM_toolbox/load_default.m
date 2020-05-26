function [files, filedata] = load_default(files, headerFilterFcn, continueFcn)
% load_default - Default method for loading DICOM header info for files
  nFiles   = numel(files);
  filedata = repmat(struct, [nFiles, 1]);
  valid    = false(nFiles, 1);

  for k = 1:numel(files)
    filename = files{k};
    try
      dcmdata = dicominfo(files{k});
    catch
      continue
    end

    fields = headerFilterFcn(dcmdata);
    for m = 1:numel(fields)
      tag = fields{m};
      filedata(k).(tag) = dcmdata.(tag);
    end

    % Specify function to load corresponding pixel data
    filedata(k).LoadFcn = @()dicomgray(filename, 'frames', 1');

    valid(k)    = true;

    % Check if the user cancelled the load, and bail if needed
    if continueFcn(k) == false
      return
    end
  end

  % Only return the valid ones
  files    = files(valid);
  filedata = filedata(valid);
end
