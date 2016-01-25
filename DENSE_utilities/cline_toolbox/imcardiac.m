%% IMCARDIAC HANDLE CLASS DEFINITION
%Interactive placement of a cardiac definition object.
%Subclass of IMCLINE object (see IMCLINE for more information)
%
%This object is a subclass of the IMCLINE object, including all the same
%properties and methods. IMCARDIAC makes the following changes:
%
%   • New 'CardiacType' property
%     This get-enabled property will be set to three different values,
%     [unknown|SA|LA]. A short-axis cardiac definition ('SA') occurs when
%     the reference cLine consists of two closed contours. A long-axis
%     cardiac definition ('LA') occurs when the reference cLine consists
%     of two open contours.  All other cLine conditions result in an
%     'unknown' CardiacType.
%
%   • New default 'Appearance'
%     The IMCARDIAC object defines a 0.5pt red solid line with 6pt red
%     circle control point markers for the first cLine contour (epicardial
%     border), and a 0.5pt green solid line with 6pt green circle control
%     point markers for the second cLine contour (endocardial border).
%
%   • New default 'IndependentDrag'
%     The second cLine contour (endocardial border) has its
%     'IndependentDrag' option set to 'on' (i.e. dragging the epicardial
%     border moves the entire cLine object, while the endocardial border
%     can be dragged indepenedently).
%
%   • New default 'ContextOpenClosed'
%     This parameter is set to 'off', disabling the ability of users to
%     change the IsClosed property of any cLine object.
%
%   • Additional display graphics for Long-Axis cardiac definition
%     Defining the "inside" of a long-axis cardiac definition can be
%     difficult, as both cLine contours are "open".  We therefore add
%     two lines at the open ends of the cLine contours to visually close
%     the cardiac definition.  These lines are only visible when the
%     'CardiacType' is 'LA' and the 'Visible' property is 'on'.
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.03     Drew Gilliam
%     --creation



%% SUBCLASS DEFINITION
classdef imcardiac < imcline

    properties (SetAccess='private');
        CardiacType = 'unknown';
    end

    properties (SetAccess='private',GetAccess='private')
        hconnect
    end

    methods

        % constructor
        function obj = imcardiac(varargin)
            obj = obj@imcline(varargin{:});
            obj = imcardiacFcn(obj);
        end

        % modified redraw
        function redraw(obj)
            redraw@imcline(obj);
            redrawFcn(obj);
        end

    end

end



%% CONSTRUCTOR
% The child changes some default values, and creates the long-axis
% connector line which will bridge the epicardial and endocardial borders
% on the display.

function obj = imcardiacFcn(obj)

    % change the default values
    obj.redrawenable = false;
    [obj.Appearance(1:2).Color] = deal('r',[0 0.75 0]);
    [obj.Appearance(1:2).MarkerFaceColor] = deal('r',[0 0.75 0]);
    obj.IndependentDrag = {'off','on'};
    obj.ContextOpenClosed = 'off';

    % create line object for LA display
    obj.hconnect = line(...
        'parent',           obj.hgroup,...
        obj.Appearance(1),...
        'marker',           'none',...
        'color',            'b',...
        'hittest',          'off',...
        'handlevisibility', 'off',...
        'Visible',          'off');

	% move connector line to bottom of IMCLINE graphics hierarchy
    h = allchild(obj.hgroup);
    idx   = find(h == obj.hconnect);
    order = [setdiff(1:numel(h),idx),idx];
    set(obj.hgroup,'Children',h(order));

    % update appearance
    obj.redrawenable = true;
    redraw(obj);

end



%% REDRAW
% The child redraw function updates the 'CardiacType' field according to
% the 'IsClosed' parameters of the CLINE reference object, and sets the
% connector display if necessary.

function redrawFcn(obj)

    % determine the object type, regardless of "redrawenable"
    if isempty(obj.hcline) || ...
       obj.hcline.NumberOfLines ~= 2 || ...
       obj.hcline.IsClosed{1} ~= obj.hcline.IsClosed{2}
        obj.CardiacType = 'unknown';
    elseif obj.hcline.IsClosed{1}
        obj.CardiacType = 'SA';
    else
        obj.CardiacType = 'LA';
    end


    % update connector line
    if ishandle(obj.hconnect)

        if ~obj.redrawenable || ~strcmpi(obj.CardiacType,'LA') || ...
           strcmpi(obj.Visible,'off') || ...
           ~all(cellfun(@(x)~isempty(x),obj.hcline.Position))

            set(obj.hconnect,'visible','off');

        else

            % determine new position
            pos = obj.hcline.Position;
            pos = [pos{1}(1,:);...
                   pos{2}(end,:);...
                   NaN NaN;...
                   pos{2}(1,:);...
                   pos{1}(end,:)];

            % update connector object
            set(obj.hconnect,...
                'xdata',    pos(:,1),...
                'ydata',    pos(:,2),...
                obj.Appearance(1),...
                'color',    'b',...
                'marker',   'none',...
                'visible',  'on');
            if strcmpi(obj.selectiontype,'all')
                set(obj.hconnect,obj.Highlight,'marker','none');
            end

        end

    end

end



%% END OF FILE=============================================================
