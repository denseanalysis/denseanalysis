classdef dragEventData < tests.DENSEtest & tests.EventTest;
   methods (Test)
      function testBasic(testCase)
         type = 'type';
         lidx = 0;
         pidx = 100;
         ed = dragEventData(type, lidx, pidx);

         testCase.assertEqual(ed.Type, type);
         testCase.assertEqual(ed.LineIndex, lidx);
         testCase.assertEqual(ed.PointIndex, pidx);
      end

      function addAsNotify(testCase)

         % Ensure that it has the appropriate subclasses to be processed by
         % MATLAB's event/listener framework

         ed = dragEventData('type', 'lidx', 'pidx');

         testCase.eventListener(testCase, 'TestEvent');

         testCase.notify('TestEvent', ed)

         testCase.assertEventFired('TestEvent');

         evnt = testCase.findEvent('TestEvent');

         testCase.assertNotEmpty(evnt);
         testCase.assertEqual(evnt.inputs{end}, ed);
      end
   end
end
