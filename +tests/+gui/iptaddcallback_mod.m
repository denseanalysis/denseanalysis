classdef iptaddcallback_mod < tests.DENSEtest
    methods (Test)
        function basicAdd(testCase)
            fig = testCase.figure();
            cb = @callback;

            event = 'WindowButtonDownFcn';

            triggered = false;

            function callback(varargin)
                triggered = true;
            end

            id = iptaddcallback_mod(fig, event, cb);

            % Get a listing and make sure everything is good
            list = hgfeval(get(fig, event), 'list');

            testCase.assertNumElements(list, 1);
            testCase.assertClass(list, 'struct');
            testCase.assertEqual(list.id, id);
            testCase.assertEqual(cb, list.func);

            % Actually fire the event
            hgfeval(get(fig, event), fig, []);

            testCase.assertTrue(triggered);
        end

        function addRemove(testCase)
            fig = testCase.figure();
            cb = @callback;

            event = 'WindowButtonDownFcn';

            triggered = false;

            function callback(varargin)
                triggered = true;
            end

            id = iptaddcallback_mod(fig, event, cb);

            % Actually fire the event
            hgfeval(get(fig, event), fig, []);

            testCase.assertTrue(triggered);

            triggered = false;

            % Now remove the callback
            iptremovecallback_mod(fig, event, id);

            % Make sure event wasn't triggered this time
            hgfeval(get(fig, event), fig, []);
            testCase.assertFalse(triggered);

            % Also make sure the list is empty
            list = hgfeval(get(fig, event), 'list');
            testCase.assertEmpty(list);
        end
    end
end
