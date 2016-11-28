classdef playbar < tests.DENSEtest & tests.EventTest
    methods (Test)
        function defaultConstructor(testCase)
            fig = testCase.figure();
            p = playbar();
            testCase.assertClass(p, 'playbar');
            testCase.assertEqual(fig, p.Parent);
        end

        function testParentArgument(testCase)
            fig = testCase.figure();
            panel = uipanel('Parent', fig);

            p = playbar(panel);

            testCase.assertClass(p, 'playbar');
            testCase.assertEqual(panel, p.Parent);
        end

        function testPlay(testCase)
            eventname = 'NewValue';

            p = playbar(testCase.figure());

            p.Max = 10;
            p.Min = 1;

            testCase.eventListener(p, eventname)

            p.TimerPeriod = [0.1, 0.1];

            testCase.assertFalse(p.IsPlaying);
            p.play();
            testCase.assertTrue(p.IsPlaying);
            pause(0.2);
            testCase.assertTrue(testCase.didEventFire(eventname));
            p.stop();
            testCase.resetEvent(eventname);
            testCase.assertFalse(p.IsPlaying);
            testCase.assertFalse(testCase.didEventFire(eventname));
        end

        function testNewValueEvent(testCase)
            % Ensure that we can add a listener for an event and clear it

            eventname = 'NewValue';

            p = playbar(testCase.figure());
            p.Max = 5;
            p.Min = 1;
            testCase.eventListener(p, eventname);
            p.Value = 2;
            testCase.assertEventFired(eventname);
            testCase.resetEvent(eventname);

            % Make sure event doesn't fire if it doesn't change
            p.Value = 2;
            testCase.assertEventNotFired(eventname);
        end

        function testValueRange(testCase)
            p = playbar(testCase.figure());

            prange = 1:5;
            p.Max = prange(end);
            p.Min = prange(1);

            % Make sure this doesn't throw any errors
            for k = prange;
                p.Value = k;
            end

            % Now make sure that we throw an error for invalid values

        end

        function testDeleteFigure(testCase)
            fig = testCase.figure();
            p = playbar(fig);

            testCase.assertClass(p, 'playbar');
            testCase.assertTrue(isvalid(p));
            delete(fig);
            testCase.assertFalse(isvalid(p));
        end

        function testDeletePlaybar(testCase)
            fig = testCase.figure();
            p = playbar(fig);

            testCase.assertClass(p, 'playbar');
            testCase.assertTrue(isvalid(p));

            % Now also make sure that it created the playbar panel
            testCase.assertNotEmpty(findall(fig, 'tag', 'Playbar'));

            delete(p);

            % Make sure all uicontrols were removed automatically
            testCase.assertFalse(isvalid(p));
            testCase.assertEmpty(findall(fig, 'tag', 'Playbar'));
        end
    end
end
