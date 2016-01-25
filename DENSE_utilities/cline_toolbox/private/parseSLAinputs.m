function args = parseSLAinputs(args_default,varargin)

%PARSESLAINPUTS private helper function to parse getSA and getLA inputs
%
%INPUTS
%   args_default...new default arguments (structure)
%   varargin.......all other inputs to getSA/getLA
%
%OUTPUTS
%   args....parsed argument structure, including:
%       'Axes'
%       'Figure
%       'ConstrainToAxes'
%       'PointsPerContour'
%       'Color'
%       'MarkerVisible'
%       'Marker'
%       'MarkerSize'
%       'MarkerLineWidth'
%       'MarkerFill'
%       'LineWidth'
%       'LineStyle'
%       'ConstructionVisible'
%       'ConstructionLineStyle'
%       'ConstructionLineWidth'
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation

    % default inputs
    args = struct(...
        'ConstrainToAxes',          true,...
        'PointsPerContour',         8,...
        'Color',                    'r',...
        'LineWidth',                2,...
        'LineStyle',                '-',...
        'Marker',                   'x',...
        'MarkerSize',               10,...
        'MarkerLineWidth',          2,...
        'MarkerFill',               true,...
        'MarkerVisible',            'on',...
        'ConstructionLineStyle',    ':',...
        'ConstructionLineWidth',    0.5,...
        'ConstructionVisible',      'on');


    % handle input
    if nargin <= 1
        h = gca;
    elseif isnumeric(varargin{1})
        h = varargin{1};
        varargin = varargin(2:end);
    else
        h = gca;
    end

    % check for valid handle
    if ~ishandle(h) || ~any(strcmpi(get(h,'type'),{'Figure','Axes'}))
        error(sprintf('%s:expectedFigureOrAxesHandle',mfilename), ...
            'First argument should be a figure or axes handle');
    end

    % replace default inputs with API values
    tags = intersect(fieldnames(args),fieldnames(args_default));
    for ti = 1:numel(tags)
        args.(tags{ti}) = args_default.(tags{ti});
    end

    % expected argument sizes
    Nclr = numel(args.Color);
    Ncon = numel(args.ConstructionVisible);

    % parse input parameters
    [args,other_args] = parseinputs(fieldnames(args),...
        struct2cell(args),varargin{:});
    if ~isempty(other_args)
        error(sprintf('%s:invalidParameters',mfilename), ...
            'Invalid input parameter pair.');
    end


    % parse color argument
    if ischar(args.Color) || (isnumeric(args.Color) && numel(args.Color)==Nclr)
        clr = repmat({args.Color},[Nclr 1]);
    elseif isnumeric(args.Color) && all(size(args.Color) == [Nclr 3])
        clr = mat2cell(args.Color,[1 1 1],Nclr);
    elseif iscell(args.Color) && numel(args.Color)==Nclr
        clr = args.Color;
    else
        error(sprintf('%s:invalidColor',mfilename),'%s', ...
            'Invalid color argument, expected [',...
            num2str(Nclr),'x1] cell vector.');
    end
    args.Color = clr(:);


    % parse construction line visibility
    vis = args.ConstructionVisible;
    if ischar(vis)
        vis = repmat({vis},[Ncon 1]);
    elseif iscell(vis) && numel(vis)==Ncon
        % do nothing
    else
        error(sprintf('%s:invalidConstructVisible',mfilename), ...
            'Invalid construction line visibility.');
    end
    args.ConstructionVisible = vis(:);


    % parse PointsPerContour
    args.PointsPerContour = round(double(args.PointsPerContour));
    if args.PointsPerContour <= 0
        error(sprintf('%s:expectedPositivePointsPerContour',mfilename), ...
            'Expected a positive integer for Points per contour.');
    end


    % flags
    args.ConstrainToAxes = logical(args.ConstrainToAxes);

    % save handle to output
    args.handle = h;


end

