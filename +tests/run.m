function varargout = run(package, coverage)
    % tests.run - Runs all tests in the specified package
    %
    %   Often we want to run a whole suite of tests that are enclosed
    %   within a package. To keep things orderly these packages may contain
    %   sub-packages of tests. This function allows tests located within
    %   nested packages to be run properly.
    %
    %   Typically, we packages all tests in a +tests MATLAB package so if
    %   no input package is specified, TESTS is used by default.
    %
    % USAGE:
    %   res = tests.run(package)
    %
    % INPUTS:
    %   package:    String, Name of the package that contains all the tests
    %               to be run.
    %   coverage:   Boolean, Indicates whether to run a coverage report or
    %               not (default = False).
    %
    % OUTPUTS:
    %   res:        Object, An array of matlab.unittest.TestResult objects
    %               that contain information about the test run. This
    %               information can be used to determine what went wrong,
    %               etc.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    % Before we do anything check the version to make sure that we support
    % MATLAB's unittest framework
    if verLessThan('matlab', '8.1')
        error(sprintf('%s:incompatibleVersion', mfilename),...
            'MATLAB Version R2013a or newer is required');
    end

    % By default we want to use the "tests" package
    if ~exist('package', 'var')
        package = 'tests';
    end

    if ~exist('coverage', 'var')
        coverage = false;
    end

    profile('off');
    profile('on', '-nohistory');

    % Locate all tests in package and its subpackages
    alltests = gather_tests(package);

    if ~isempty(alltests)
        % Setup the runner and run it
        runner = matlab.unittest.TestRunner.withNoPlugins;
        runner.addPlugin(matlab.unittest.plugins.TestSuiteProgressPlugin)
        runner.addPlugin(matlab.unittest.plugins.FailureDiagnosticsPlugin)
        results = runner.run(alltests);

        % Compute stats on the run
        nPass   = sum([results.Passed]);
        nFail   = sum([results.Failed]);
        nIncomp = sum([results.Incomplete]);

        % Print just this results
        fprintf(' %d Passed, %d Failed, %d Incomplete.\n',nPass,nFail,nIncomp);
        fprintf(' %f seconds testing time\n\n', sum([results.Duration]));
    end

    % Provide output if requested
    if nargout
        varargout = {results};
    end

    profile('off')

    if coverage
        basedir = fileparts(mfilename('fullpath'));
        basedir = fileparts(basedir);
        report = tests.Coverage(basedir, basedir);
        printresults(report);
    end
end

function tests = gather_tests(package)
    % gather_tests - Locate all unittests within the specified package

    % By default we want to use the "tests" package
    if ~exist('package', 'var')
        package = 'tests';
    end

    packageName = package;

    if ischar(package)
        package = meta.package.fromName(package);
    end

    % If there was no package by this name, then look to see if its a class
    if ~isa(package, 'meta.package') || isempty(package)
        class = meta.class.fromName(packageName);

        % If it wasn't a class either, then throw an error
        if ~isa(class, 'meta.class') || isempty(class)
            error(sprintf('%s:invalidPackage', mfilename),...
            'Package by that name was not found')
        end

        % Gather tests from class
        tests = matlab.unittest.TestSuite.fromClass(class);
        return;
    end

    % Shut off this warning because we don't actually care if there are
    % non-tests
    warning('off', 'MATLAB:unittest:TestSuite:FileExcluded')

    base = fileparts(fileparts(mfilename('fullpath')));
    try
        selector = matlab.unittest.selectors.HasBaseFolder(base);

        % Check to see if there are any tests in this package
        tests = matlab.unittest.TestSuite.fromPackage(package.Name, selector);
    catch ME
        if strcmpi(ME.identifier, 'MATLAB:undefinedVarOrClass')
            tests = matlab.unittest.TestSuite.fromPackage(package.Name);
        else
            rethrow(ME);
        end
    end

    % Determine if we have any subpackages that need to be analyzed
    subpackages = package.PackageList;

    % Recursively run tests and concatenate results
    for i = 1:numel(subpackages)
        tests = cat(2, tests, gather_tests(subpackages(i).Name));
    end
end
