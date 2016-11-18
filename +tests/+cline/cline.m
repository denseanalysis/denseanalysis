classdef cline < tests.DENSEtest & tests.EventTest
    % EVENTS TO CHECK:
    %   NewProperty

    methods (Test)
        function defaultConstructor(testCase)
            c = cline();
            testCase.assertNumElements(c, 1);
            testCase.assertEqual(c.NumberOfLines, 1);

            testCase.assertNumElements(c.Position, 1);
            testCase.assertSize(c.Position{1}, [0 2]);

            testCase.assertNumElements(c.IsCurved, 1);
            testCase.assertSize(c.IsCurved{1}, [0 1]);

            testCase.assertNumElements(c.IsCorner, 1);
            testCase.assertSize(c.IsCorner{1}, [0 1]);

            testCase.assertTrue(c.UndoEnable);
        end

        function multiLineConstructor(testCase)
            c = cline('NumberOfLines', 4);

            testCase.assertEqual(c.NumberOfLines, 4);
            testCase.assertSize(c.Position, [1 4]);
            testCase.assertSize(c.IsCorner, [1 4]);
            testCase.assertSize(c.IsCurved, [1 4]);
        end

        function singleClineConstructor(testCase)
            pos = [0 0; 0 1; 1 1; 1 0];
            nPts = size(pos, 1);
            c = cline(pos);

            testCase.assertNumElements(c.Position, 1);
            testCase.assertEqual(c.Position{1}, pos);

            testCase.assertNumElements(c.IsCurved, 1);
            testCase.assertSize(c.IsCurved{1}, [nPts 1]);
            testCase.assertEqual(c.IsCurved{1}, true(nPts, 1));

            testCase.assertNumElements(c.IsCorner, 1);
            testCase.assertSize(c.IsCorner{1}, [nPts 1]);
            testCase.assertEqual(c.IsCorner{1}, false(nPts, 1));
        end

        function testDelete(testCase)
            c = cline();

            testCase.assertTrue(isvalid(c));

            testCase.assertWarningFree(@()delete(c));

            testCase.assertFalse(isvalid(c));
        end


        function undoreset(testCase)
            rng(50);
            pos = rand(4,2);
            newpt = rand(1,2);

            c = cline(pos);

            testCase.assertTrue(c.UndoEnable);

            c.addPoint(1, 1, newpt);

            testCase.assertEqual(c.Position{1}, cat(1, newpt, pos));

            % Clear out undo buffer
            c.undoReset();

            testCase.assertEqual(c.Position{1}, cat(1, newpt, pos));
        end

        function plot(testCase)
            fig = testCase.figure();
            ax = axes('Parent', fig);

            rng(72);
            pos = rand(10,2);

            c = cline(pos);

            p = plot(c, 'Parent', ax);

            testCase.assertTrue(ishghandle(p));
            testCase.assertSize(findall(ax, 'type', 'hggroup'), [1 1]);

            % The control points are child 1 and child2 is the contour
            children = get(p, 'Children');

            testCase.assertEqual(get(children(1), 'XData'), pos(:,1)');
            testCase.assertEqual(get(children(1), 'YData'), pos(:,2)');

            % Child2 should be the result of getcontour
            con = c.getContour([], 1);

            testCase.assertEqual(get(children(2), 'XData'), con(:,1)');
            testCase.assertEqual(get(children(2), 'YData'), con(:,2)');
        end

        function emptyPlot(testCase)
            fig = testCase.figure();
            ax = axes('Parent', fig);
            c = cline();

            p = plot(c, 'Parent', ax);

            testCase.assertTrue(ishghandle(p));
            testCase.assertSize(findall(ax, 'type', 'hggroup'), [1 1]);
        end

        function resetEmpty(testCase)
            rng(50);
            pos = rand(4,2);
            nPts = size(pos, 1);

            c = cline(pos);

            testCase.assertNumElements(c.Position, 1);
            testCase.assertEqual(c.Position{1}, pos);

            testCase.assertNumElements(c.IsCurved, 1);
            testCase.assertSize(c.IsCurved{1}, [nPts 1]);
            testCase.assertEqual(c.IsCurved{1}, true(nPts, 1));

            testCase.assertNumElements(c.IsCorner, 1);
            testCase.assertSize(c.IsCorner{1}, [nPts 1]);
            testCase.assertEqual(c.IsCorner{1}, false(nPts, 1));

            c.reset();

            testCase.assertNumElements(c, 1);
            testCase.assertEqual(c.NumberOfLines, 1);

            testCase.assertNumElements(c.Position, 1);
            testCase.assertSize(c.Position{1}, [0 2]);

            testCase.assertNumElements(c.IsCurved, 1);
            testCase.assertSize(c.IsCurved{1}, [0 1]);

            testCase.assertNumElements(c.IsCorner, 1);
            testCase.assertSize(c.IsCorner{1}, [0 1]);
        end

        function testNewPropertyEvent(testCase)
            c = cline();

            testCase.eventListener(c, 'NewProperty');

            % Change a property
            c.PositionConstraintFcn = @(d)d;

            testCase.assertEventFired('NewProperty');
            testCase.resetEvent('NewProperty');
        end

        function resetPosition(testCase)
            rng(140);
            pos1 = rand(5,2);
            pos2 = rand(7,2);

            c = cline(pos1);
            testCase.assertEqual(c.Position{1}, pos1);

            c.reset(pos2);
            testCase.assertEqual(c.Position{1}, pos2);

            % Now change it back as param/value
            c.reset('Position', pos1, 'IsClosed', false);
            testCase.assertEqual(c.Position{1}, pos1);
            testCase.assertFalse(c.IsClosed{1});
            testCase.assertEqual(c.IsCorner{1}, false(size(pos1, 1), 1));

            c.reset('IsClosed', true);
            testCase.assertTrue(c.IsClosed{1});
        end

        function checkPositionLimits(testCase)
            rng(161);
            pos = rand(10,2);

            function point = positionCheck(point)
                if any(point < 0)
                    point = [];
                end
            end

            c = cline(pos);
            c.PositionConstraintFcn = @positionCheck;

            % Now try to add an invalid point
            func = @()c.addPoint(1, 1, [-1 -1]);
            testCase.assertError(func, 'cline:invalidPosition');
        end

        function getContour(testCase)
            rng(164);
            pos = rand(10,2);

            c = cline(pos);

            con = c.getContour([], 1);

            testCase.assertTrue(size(con, 2) == 2);

            % This is a closed contour
            testCase.assertEqual(con(1,:), con(end,:));
        end

        function getSegments(testCase)
            rng(178);
            pos = rand(10,2);
            nPts = size(pos, 1);

            c = cline(pos);

            segs = c.getSegments([], 1);

            testCase.assertTrue(iscell(segs));
            testCase.assertNumElements(segs, nPts);
            for k = 1:numel(segs)
                testCase.assertTrue(size(segs{k},2) == 2);
            end
        end

        function multiClineConstructor(testCase)
            pos = [0 0; 0 1; 1 1; 1 0];
            nPts = size(pos, 1);
            P = {pos, 2 * pos};

            c = cline(P);

            testCase.assertSize(c.Position, size(P));
            testCase.assertSize(c.IsCurved, size(P));
            testCase.assertSize(c.IsCorner, size(P));

            for k = 1:numel(P)
                testCase.assertEqual(c.Position{k}, P{k});
                testCase.assertSize(c.IsCurved{k}, [nPts, 1]);
                testCase.assertEqual(c.IsCurved{k}, true(nPts, 1));
                testCase.assertSize(c.IsCorner{k}, [nPts, 1]);
                testCase.assertEqual(c.IsCorner{k}, false(nPts, 1));
            end

            testCase.assertEqual(c.NumberOfLines, numel(P));
        end

        function testCopyByReference(testCase)
            rng(11111);
            pos = rand(4,2);

            c = cline(pos);
            c2 = c;

            testCase.assertSameHandle(c2, c);
        end

        function testCopy(testCase)
            rng(12356);
            pos = rand(4,2);

            c = cline(pos);

            c2 = cline(c);

            c2.addPoint(1, 1, rand(1,2));

            testCase.assertNotSameHandle(c2, c);
            testCase.assertNotEqual(c2.Position, c.Position);
        end

        function undo(testCase)
            % Add a point and then undo it
            rng(97);

            pos = rand(4,2);
            newpt = rand(1,2);

            c = cline(pos);

            testCase.assertTrue(c.UndoEnable);

            c.addPoint(1, 1, newpt);

            testCase.assertSize(c.Position{1}, [5 2]);

            c.undo();

            testCase.assertEqual(c.Position{1}, pos);

            % Delete a point and then undo it

            c.deletePoint(1, 1);

            testCase.assertNotEqual(c.Position{1}, pos);

            c.undo();

            testCase.assertEqual(c.Position{1}, pos);
        end

        function deletePoint(testCase)
            rng(126);
            pos = rand(6,2);

            c = cline(pos);

            testCase.assertEqual(c.Position{1}, pos);

            c.deletePoint(1,1);

            testCase.assertEqual(c.Position{1}, pos(2:end,:));

            c.deletePoint(1,1);

            testCase.assertEqual(c.Position{1}, pos(3:end,:));
        end

        function addPoint(testCase)
            rng(816);
            pos = rand(4,2);
            newpt = rand(1,2);

            c = cline(pos);

            testCase.assertEqual(c.Position{1}, pos);

            % Now add a point
            c.addPoint(1, 1, newpt);

            testCase.assertEqual(c.Position{1}, cat(1, newpt, pos));
        end
    end
end
