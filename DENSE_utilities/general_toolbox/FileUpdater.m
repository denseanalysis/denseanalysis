classdef FileUpdater < Updater
    % File-based updater
    %
    %   This class provides an Updater implementation that handles local
    %   zip files.

    properties (Constant)
        PATTERN = '^file:';
    end

    properties (Access = 'private')
        extractdir  % Folder containing unzipped contents
        listener    % Listener to ensure we clean up after ourselves
    end

    methods
        function self = FileUpdater(varargin)
            % FileUpdater - Constructor for FileUpdater object

            % Call the superclass constructor
            self@Updater(varargin{:});

            % Remove the file: from the beginning of the URL
            self.URL = regexprep(self.URL, '^file:', '');

            % Add listener to remove temp dir
            self.listener = addlistener(self, 'ObjectBeingDestroyed', ...
                @(s,e)cleanup(self));
        end

        function cleanup(self)
            % cleanup - Function to be executed during deletion
            %
            %   Ensures that we remove the directory we created (if any)
            %   during extraction of the zip file when the object is
            %   deleted.

            if exist(self.extractdir, 'dir')
                delete(self.extractdir)
            end
        end

        function release = latestRelease(self)
            % Load the plugin.json file to determine the version
            json = loadjson(self.readFile('plugin.json'));
            release = struct('URL', self.URL, ...
                             'Version', json.version);
        end

        function folder = download(self, varargin)
            % download - Overloaded download function
            %
            %   Since this class has it's own extract method, we want to
            %   use that instead so we don't unzip the file multiple times.
            %   We do this by overloading Updater.download()

            self.setStatus(sprintf('Extracting %s...', self.URL))
            folder = self.extract();
        end

        function [bool, newest] = updateAvailable(self)
            bool = false;
            newest = struct('URL', self.URL);
        end

        function contents = readFile(self, path, varargin)
            % Now attempt to load the file
            filename = fullfile(self.extract(), path);

            % Now actually read out the contents
            fid = fopen(filename, 'rt');
            contents = fread(fid, '*char').';
            fclose(fid);
        end

        function folder = extract(self)
            % extract - Function for extracting the zip file contents
            %
            %   This function extracts the contents (if they haven't
            %   already been) to the temp folder.
            %
            % USAGE:
            %   folder = u.extract()
            %
            % OUTPUTS:
            %   folder: String, Path to the folder where the contents were
            %           extracted to.

            % Don't worry about it if we've already extracted everything
            if isExtracted(self)
                folder = self.extractdir;
            else
                % Remove the file: from the filename
                filenames = unzip(self.URL, tempdir);

                % Determine common basepath and rename to remove subfolder
                folder = basepath(filenames);
                self.extractdir = folder;
            end
        end

        function bool = isExtracted(self)
            % isExtracted - See if we have already extracted the contents
            %
            % USAGE:
            %   bool = u.isExtracted()
            %
            % OUTPUTS:
            %   bool:   Logical, Indicates whether the contents have been
            %           extracted already (TRUE) or not (FALSE).

            % Check for the existence of the output directory
            bool = ~isempty(self.extractdir) && ...
                    exist(self.extractdir, 'dir');
        end
    end
end
