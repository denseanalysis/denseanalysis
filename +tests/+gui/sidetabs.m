classdef sidetabs < tests.DENSEtest & tests.EventTest
    methods (Test)
        function st = constructor(testCase)
            fig = testCase.figure();
            st = sidetabs(fig);

            testCase.assertEqual(st.Parent, fig);
            testCase.assertTrue(ishandle(st));
        end

        function figureDelete(testCase)
            st = testCase.constructor();
            testCase.assertWarningFree(@()delete(st.Parent));
            testCase.assertFalse(isvalid(st));
        end

        function switchTabEvent(testCase)
            st = testCase.constructor();
            st.addTab('Tab1');
            st.addTab('Tab2');
            st.addTab('Tab3');

            testCase.eventListener(st, 'SwitchTab');

            for k = 1:st.NumberOfTabs
                st.ActiveTab = mod(k, st.NumberOfTabs) + 1;
                testCase.assertEventFired('SwitchTab');
                testCase.resetEvent('SwitchTab')
            end
        end

        function st = addTab(testCase)
            st = testCase.constructor();

            tabnames = {'Tab 1', 'Tab 2', 'Tab 3'};

            for k = 1:numel(tabnames)
                st.addTab(tabnames{k});
            end

            testCase.assertEqual(st.TabNames, tabnames);
            testCase.assertEqual(st.NumberOfTabs, numel(tabnames));
        end

        function addTabWithPanel(testCase)
            st = testCase.constructor();

            tabnames = {'Tab 1', 'Tab 2', 'Tab 3'};
            panels = nan(size(tabnames));
            nTabs = numel(tabnames);

            for k = 1:nTabs
                panels(k) = uipanel('Parent', st.Parent);
                st.addTab(tabnames{k}, panels(k));
            end

            testCase.assertEqual(st.TabNames, tabnames);
            testCase.assertEqual(st.NumberOfTabs, nTabs);

            % First tab active by default
            testCase.assertEqual(st.ActiveTab, 1);

            % Now change active tab and check panel visibilty as we go
            for k = 1:nTabs
                st.ActiveTab = k;
                visibles = get(panels, 'Visible');
                expected = repmat({'off'}, size(tabnames));
                expected{k} = 'on';
                testCase.assertEqual(visibles(:), expected(:));
            end
        end

        function destructor(testCase)
            st = testCase.constructor();
            testCase.assertWarningFree(@()delete(st));
        end
    end
end
