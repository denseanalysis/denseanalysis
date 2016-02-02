function htext = textfig(varargin)
    %TEXTFIG create a floating TEXT object within a figure (or uipanel)
    %
    %USAGE
    %
    %   TEXTFIG(HFIG) create a text object in an invisible non-selectable
    %   axes, where the axes is parented to the figure HFIG.
    %
    %   TEXTFIG(HFIG,param,val...) allows parameter/value input pairs as
    %   specified by TEXT.  See note below.
    %
    %   TEXTFIG() and TEXTFIG(param,val,...) are the same as TEXTFIG(GCF)
    %   and TEXTFIG(GCF,param,val) respectively
    %
    %   TEXTFIG(HPANEL) parents the text axes to the uipanel object HPANEL.
    %
    %   H = TEXTFIG(...) returns the handle H to the text object.
    %
    %
    %NOTES
    %
    %   This function extents the functionality of the TEXT tool to more
    %   than just axes. We create an invisible & non-selectable axes
    %   covering the entire parent object (figure or uipanel), and place
    %   the TEXT within that object.  --Almost all of the TEXT properties
    %   are available.  --TEXT position is specified as [x,y] rather than
    %   the general style of [x,y,width,height].  --Changing the 'Parent'
    %   property is not suggested, and may result in unrecoverable
    %   problems.
    %

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    % default parent
    if nargin > 0 && ishandle(varargin{1}) && isscalar(varargin{1})
        hparent  = varargin{1};
        varargin = varargin(2:end);
    else
        hparent = gcf;
    end

    % check for valid parent
    if ~ishghandle(hparent, 'figure') && ~ishghandle(hparent, 'uicontainer')
        error(sprintf('%s:invalidParent',mfilename),'%s',...
            'Parent must be a figure or uipanel.');
    end

    % test for invisible axes
    hax = [];
    if isappdata(hparent,'HiddenTextAxes')
        hax = getappdata(hparent,'HiddenTextAxes');
        if ~ishghandle(hax, 'axes')
            warning(sprintf('%s:invalidHiddenAxes',mfilename),'%s',...
                'You have run TEXTFIG before, but a necessary ',...
                'graphic handle (hidden text axes) is no longer valid.');
            hax = [];
        end
    end

    % create invisible axes, if it doesn't already exist
    % cache handle to invisible axes to the parent object
    if isempty(hax)
        hax = axes('parent',hparent,'hittest','off',...
            'HandleVisibility','off','units','normalized',...
            'position',[0 0 1 1],'visible','off',...
            'XLimMode','manual','ylimmode','manual','zlimmode','manual',...
            'XTickMode','Manual','YTickMode','Manual','ZTickMode','manual');
        setappdata(hparent,'HiddenTextAxes',hax);
    end

    % create text as specified by the user
    try
        htext = text(varargin{:},'parent',hax);
        setappdata(htext,'TextFigIdentifier',true);
    catch ERR
        hchild = allchild(hax);
        if isempty(hchild), delete(hax); end
        rethrow(ERR);
    end

    % add deletion function to text, eliminating the hidden axes if no
    % other text exists
    iptaddcallback(htext,'DeleteFcn',@(varargin)deleteFcn());

    % move axes to top of display stack
    uistack(hax,'top');

    % DELETE FUNCTION
    function deleteFcn()
        % test for exisiting axes
        if isempty(hax) || ~ishandle(hax) || ...
           strcmpi(get(hax,'BeingDeleted'),'on')
            return;
        end

        % locate all textfig children
        hchild = allchild(hax);
        tf = arrayfun(@(h)isappdata(h,'TextFigIdentifier'),hchild);
        hchild = hchild(tf);

        % delete axes if no other children
        if isempty(setdiff(hchild,htext))
            delete(hax);
            rmappdata(hparent,'HiddenTextAxes');
        end
    end
end
