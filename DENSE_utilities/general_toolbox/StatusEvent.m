classdef StatusEvent < event.EventData
    % StatusEvent - Event data specific to reporting operating status
    %
    %   Sometimes it is ideal to have a listener for any status that a
    %   sub-routine or class may report. This EventData subclass allows the
    %   status-issuing entity to report the TYPE of a status (Error,
    %   warning, info) as well as the message itself along with an
    %   identifier. Essentially this acts like an MException on steroids.
    %
    %   This StatusEvent object should be created when a NOTIFY event
    %   is called and passed as the last argument.
    %
    %   Any listener that is listening for the event which was triggered
    %   using the NOTIFY method will receive the object and can then access
    %   the properties and act accordingly.
    %
    % USAGE:
    %   data = StatusEvent(identifier, message, type)
    %
    % INPUTS:
    %   identifier: String, Message identifier similar to the Message
    %               identifiers that Matlab uses for warnings and errors.
    %
    %   message:    String, Message to be reported to the listener.
    %
    %   type:       String, Indicates the type of status update. Valid
    %               options include: INFO, WARN, DEBUG, and ERROR

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    properties
        Identifier  % Identifier of the form group:subgroup:subsubgroup
        Message     % Message to be reported to listeners
        Type        % INFO, WARN, DEBUG, ERROR
    end

    methods
        function self = StatusEvent(id, message, type)
            % StatusEvent - Event data constructor
            %
            % USAGE:
            %   data = StatusEvent(identifier, message, type)
            %
            % INPUTS:
            %   identifier: String, Message identifier similar to the
            %               Message identifiers that Matlab uses for
            %               warnings and errors.
            %
            %   message:    String, Message to be reported to the listener.
            %
            %   type:       String, Indicates the type of status update.
            %               Valid options include: INFO, WARN, DEBUG,
            %               and ERROR

            self.Identifier = id;
            self.Message = message;
            self.Type = type;
        end
    end
end
