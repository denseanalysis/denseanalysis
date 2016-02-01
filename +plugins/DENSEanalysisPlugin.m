classdef DENSEanalysisPlugin < hgsetget &  matlab.mixin.Heterogeneous
    % DENSEanalysisPlugin - Base class for all DENSeanalysis plugins
    %
    %   This is a bare-bones plugin class that provides the API for all
    %   plugins to DENSEanalysis
    %
    %   The required methods are:
    %
    %       run(self, DENSEdata)
    %
    %   This class is an abstract class and must be subclassed in order to
    %   create a custom plugin.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties
        Name        % Plugin name specified in menus and elsewhere
        Description % Brief, description of the plugin
        Version     % String representing the version
        Author      % Author of the plugin
        Email       % Email of the author
        URL         % Url where the plugin was obtained from
    end

    properties (Hidden)
        hwait       % Handle to the waitbartimer object
    end

    properties (SetAccess = 'private')
        Path        % Path to where the plugin code is located
    end

    events
        Status
    end

    methods
        function self = DENSEanalysisPlugin(varargin)
            % Relative path of the plugin
            classpath = which(class(self));
            plugindir = fileparts(mfilename('fullpath'));
            pattern = regexptranslate('wildcard', plugindir);

            self.Path = fullfile('.', regexprep(classpath, pattern, '.'));

            % Look to see if there is a plugin.json file
            plugindir = fileparts(classpath);
            jsonconfig = fullfile(plugindir, 'plugin.json');

            if exist(jsonconfig, 'file')
                varargin = [{loadjson(jsonconfig)}, varargin];
            end

            ip = inputParser();
            ip.KeepUnmatched = true;
            ip.addParamValue('Name', '', @(x)ischar(x) && ~isempty(x));
            ip.addParamValue('Description', '', @ischar);
            ip.addParamValue('Version', '', @ischar);
            ip.addParamValue('Author', '', @ischar);
            ip.addParamValue('Email', '', @ischar);
            ip.addParamValue('URL', '', @ischar);
            ip.parse(varargin{:})
            set(self, ip.Results);
        end

        function setStatus(self, message, varargin)
            % setStatus - Fires a `Status` event with the supplied string
            %
            % USAGE:
            %   obj.setStatus(message)
            %
            % INPUTS:
            %   message:    String, Status string to send out with the
            %               event

            if isempty(varargin); varargin = {'INFO'}; end
            eventData = StatusEvent('', message, varargin{:});
            self.notify('Status', eventData);
        end

        function validate(varargin)
            % validate - Checks whether the plugin can run
            %
            %   If any requirements of the plugin are not met, an error
            %   with a descriptive error message is thrown. This message
            %   can be checked with `isAvailable()`

            return;
        end

        function cleanup(self, varargin)
            % cleanup - Cleanup routine that is run by the plugin manager
            %
            % USAGE:
            %   self.cleanup()

            if ~isempty(self.hwait) && isvalid(self.hwait)
                delete(self.hwait)
            end
        end

        function hwait = waitbar(self, varargin)
            % waitbar - Creates a waitbartimer specific to the plugin
            %
            % USAGE:
            %   hwait = self.waitbar(...)
            %
            % INPUTS:
            %   ...:    Any parameter/value pair accepted by the
            %           waitbartimer. This includes 'String',
            %           'WindowStyle', etc.
            %
            % OUTPUTS:
            %   hwait:  Object, Waitbartimer object that can be used to
            %           start, stop, or modify the waitbartimer object

            if isempty(self.hwait) || ~isvalid(self.hwait)
                hwait = waitbartimer();
                self.hwait = hwait;
            else
                hwait = self.hwait;
            end

            set(hwait, varargin{:})
        end
    end

    methods (Sealed)
        function [available, msg] = isAvailable(self, data)
            % isAvailable - Indicates whether the plugin can run
            %
            %   If the plugin can run, this function will return true. If
            %   it cannot, it will return false along with a detailed
            %   message supplying as much information about why it can't
            %   run.
            %
            % USAGE:
            %   [bool, msg] = obj.isAvailable(data)
            %
            % INPUTS:
            %   data:   Data object that would be passed to `run` method
            %
            % OUTPUTS:
            %   bool:   Logical, Indicates whether the plugin can run
            %           (true) or not (false)
            %
            %   msg:    String, Message detailing why the plugin won't be
            %           able to be run

            msg = '';
            available = false;

            try
                self.validate(data)
                available = true;
            catch ME
                msg = ME.message;
            end
        end
    end

    % Abstract methods that must be overloaded by each plugin
    methods (Abstract)
        run(self, data);
    end
end
