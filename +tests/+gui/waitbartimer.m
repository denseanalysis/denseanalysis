classdef waitbartimer < tests.DENSEtest

    properties (Hidden)
        PreviousTimers = [];
    end

    methods (TestMethodTeardown)
        function removeFigures(testCase)
            delete(testCase.findFigure());
        end
    end

    methods (TestMethodSetup)
        function findTimers(testCase)
            testCase.PreviousTimers = timerfind();
        end
    end

    methods
        function timers = newTimers(testCase)
            currentTimers = timerfind();

            toremove = false(size(currentTimers));

            % Now remove all the timers that existed before
            for k = 1:length(testCase.PreviousTimers)
                toremove(currentTimers == testCase.PreviousTimers(k)) = true;
            end

            timers = currentTimers(~toremove);
        end

        function assertNoNewTimers(testCase)
            testCase.assertEmpty(testCase.newTimers());
        end
    end

    methods (Test)
        function basicConstructor(testCase)
            w = waitbartimer();

            testCase.assertTrue(isscalar(w));
            testCase.assertTrue(isvalid(w));

            % Make sure that the figure was created
            testCase.assertNotEmpty(testCase.findFigure());
        end

        function allowClose(testCase)
            w = waitbartimer();
            w.AllowClose = false;

            fig = testCase.findFigure();
            testCase.assertNotEmpty(fig);
            testCase.assertTrue(ishghandle(fig));

            % Try to close
            close(fig);

            fig = testCase.findFigure();
            testCase.assertNotEmpty(fig);
            testCase.assertTrue(ishghandle(fig));
        end

        function deleteFigure(testCase)
            % These are the timers we want to ignore
            w = waitbartimer();

            % Delete the figure
            testCase.assertWarningFree(@()delete(testCase.findFigure()));
            testCase.assertFalse(isvalid(w));
            testCase.assertNoNewTimers();
        end

        function deleteWaitbar(testCase)
            w = waitbartimer();

            testCase.assertTrue(ishghandle(testCase.findFigure()));
            testCase.assertWarningFree(@()delete(w))
            testCase.assertEmpty(testCase.findFigure());
            testCase.assertNoNewTimers();
        end

        function deleteFigureWhileRunning(testCase)
            w = waitbartimer();
            w.start();

            % Delete the figure
            testCase.assertWarningFree(@()delete(testCase.findFigure()));
            testCase.assertFalse(isvalid(w));
            testCase.assertNoNewTimers();
        end

        function deleteWaitbarWhileRunning(testCase)
            w = waitbartimer();
            w.start();

            testCase.assertTrue(ishghandle(testCase.findFigure()));
            testCase.assertWarningFree(@()delete(w))
            testCase.assertEmpty(testCase.findFigure());
            testCase.assertNoNewTimers();
        end

        function find(testCase)
            w = waitbartimer();
            wfind = waitbartimer.find();
            testCase.assertEqual(wfind, w);

            % Now make sure that we can find two objects
            w2 = waitbartimer();
            wfind= waitbartimer.find();

            % Have to sort (not sure what it's sorting on as long as it's
            % consistent) to do the comparison
            testCase.assertEqual(sort(wfind), sort([w w2]));
        end

        function testTimer(testCase)
            w = waitbartimer();
            w.start();

            t = testCase.newTimers();
            testCase.assertNotEmpty(t);
            testCase.assertEqual(t.Running, 'on');

            w.stop();

            t = testCase.newTimers();
            testCase.assertNotEmpty(t);
            testCase.assertEqual(t.Running, 'off');
        end

        function stopVisible(testCase)
            w = waitbartimer();
            w.start();

            t = testCase.newTimers();
            testCase.assertEqual(t.Running, 'on');

            % We know this is going to throw a warning
            warning('off', 'waitbartimer:invisibleRunning');
            w.Visible = 'off';
            warning('on', 'waitbartimer:invisibleRunning');

            t = testCase.newTimers();
            testCase.assertNotEmpty(t);
            testCase.assertEqual(t.Running, 'off');
        end
    end

    methods (Static)
        function fig = findFigure()
            fig = findall(0, 'type', 'figure', 'tag', 'WaitbarTimer');
        end
    end
end
