classdef contrasttool < tests.DENSEtest

    methods (Test)
        function testConstructor(testCase)
            hcontrast = contrasttool(testCase.figure());

            testCase.assertNotEmpty(hcontrast);
            testCase.assertClass(hcontrast, 'contrasttool');
        end

        function testToggle(testCase)
            % Make sure that we can create and remove the toggle
            fig = testCase.figure('Toolbar', 'none');

            % Setup an empty toolbar
            tb = uitoolbar(fig);

            hcontrast = contrasttool(fig);

            % There should be no toggle handle by default
            testCase.assertEmpty(hcontrast.ToggleHandle);

            % Add the uitoggletool
            hcontrast.addToggle(tb);

            % Find the uitoggletool that was added to the empty toolbar
            toggleHandle = findall(tb, 'Type', 'uitoggletool');
            testCase.assertEqual(hcontrast.ToggleHandle, toggleHandle)
            testCase.assertTrue(ishghandle(toggleHandle))

            % Now make sure that when we delete it, the toggle disappears
            testCase.assertTrue(ishghandle(toggleHandle))
            delete(hcontrast);
            testCase.assertFalse(ishghandle(toggleHandle))
        end

        function testFigureDeleteListener(testCase)
            % Make sure that when the figure is removed, class is deleted
            fig = testCase.figure();

            hcontrast = contrasttool(fig);

            % Ensure successful creation
            testCase.assertNotEmpty(hcontrast);
            testCase.assertClass(hcontrast, 'contrasttool');
            testCase.assertTrue(isvalid(hcontrast));

            % Now delete the figure
            delete(fig);

            % The contrasttool instance should also be removed
            testCase.assertFalse(ishghandle(fig));
            testCase.assertFalse(isvalid(hcontrast));
        end

        function testEnable(testCase)
            % Enabling the control should set the uimode
            fig = testCase.figure();
            hcontrast = contrasttool(fig);

            mm = uigetmodemanager(fig);

            testCase.assertEmpty(get(mm, 'CurrentMode'));

            hcontrast.Enable = 'on';

            curmode = get(mm, 'CurrentMode');
            testCase.assertEqual(curmode.Name, hcontrast.modename);

            hcontrast.Enable = 'off';
            testCase.assertEmpty(get(mm, 'CurrentMode'));
        end
    end
end
