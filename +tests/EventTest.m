classdef EventTest < matlab.unittest.TestCase

    properties (Hidden)
        eventData_
    end

    events (Hidden)
        TestEvent
    end

    methods (TestMethodSetup)
        function resetEvents(testCase)
            testCase.eventData_ = repmat(struct('listener', {}, ...
                                                'name',     {}, ...
                                                'fired',    {}, ...
                                                'inputs',   {}), [0 1]);
        end
    end

    methods
        function [bool, evnt] = didEventFire(testCase, name)
            evnt = testCase.findEvent(name);

            if isempty(evnt)
                error(sprintf('%s:NoEvent', mfilename), ...
                    'Listener for %s event not set', name);
            end

            bool = evnt.fired;
        end

        function assertEventFired(testCase, name)
            testCase.assertTrue(testCase.didEventFire(name));
        end

        function assertEventNotFired(testCase, name)
            testCase.assertFalse(testCase.didEventFire(name));
        end

        function resetEvent(testCase, name)
            % Error will be thrown if event doesn't exist
            [~, evnt] = testCase.didEventFire(name);
            evnt.fired = false;
            testCase.setEvent(evnt);
        end

        function [evnt, ind] = findEvent(testCase, name)
            [tf, ind] = ismember(name, {testCase.eventData_.name});

            if tf
                evnt = testCase.eventData_(ind);
            else
                evnt = [];
                ind = numel(testCase.eventData_) + 1;
            end
        end

        function setEvent(testCase, value)
            [~, ind] = testCase.findEvent(value.name);
            fields = fieldnames(value);

            for k = 1:numel(fields)
                testCase.eventData_(ind).(fields{k}) = value.(fields{k});
            end
        end

        function eventListener(testCase, object, name)
            % Determine if we are already listening for this event
            evnt = testCase.findEvent(name);

            if ~isempty(evnt)
                warning('Event listener already exists');
            end

            evnt.fired = false;

            function eventCallback(varargin)
                evnt = testCase.findEvent(name);
                evnt.fired = true;
                evnt.inputs = varargin;
                testCase.setEvent(evnt);
            end

            evnt.name = name;
            evnt.inputs = {};
            evnt.listener = addlistener(object, name, @eventCallback);

            testCase.setEvent(evnt);
        end
    end
end
