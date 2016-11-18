classdef DENSEtest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function setup(testCase)
            % Cache the original path when we start
            testCase.addTeardown(@path, path);

            % Add necessary DENSE files to path if they arent already there
            if exist('imcline', 'file') ~= 2
                DENSEsetup;
            end
        end
    end

    methods
        function h = figure(testCase, varargin)
            % figure - Helper for creating self-destroying figure
            %
            %   This method creates a new figure with the specified
            %   parameters and automatically adds a teardown function to
            %   the testCase so that it is certain to be destroyed even on
            %   test failure.
            %
            % USAGE:
            %   h = DENSEtest.figure(params)
            %
            % INPUTS:
            %   params: Parameter/Value Pairs, indicates properties to pass
            %           along to the figure for creation.
            %
            % OUTPUTS:
            %   h:      Handle, Handle to the generated figure object.
            %
            % Last Modified: 06-08-2015
            % Modified By: Jonathan Suever (suever@gmail.com)

            h = figure('Visible', 'off', varargin{:});

            % Add a teardown so that this automatically removed
            testCase.addTeardown(@()delete(h(ishandle(h))));
        end
    end
end
