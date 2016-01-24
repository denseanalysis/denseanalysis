% Class definition SliceViewer

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

classdef SliceViewer < DataViewer

    properties
        BackgroundColor = 'k';
        BorderColor     = [78 101 148]/255;
        SurfaceColor    = [0.5 0.5 0.5];
        HighlightColor  = 'y';
        ZoomVisible     = false;
    end

    properties (Dependent=true)
        SequenceVisible
        SequenceHighlight
    end

    properties (SetAccess='private',GetAccess='private');

        seqvisible   = false(0,1);
        seqhighlight = false(0,1);

        hax
        hsurf

        extents = zeros(0,4);

    end


    methods

        function obj = SliceViewer(varargin)
            options = struct(...
                'ControlVisible',   'off',...
                'PlaybarVisible',   'off');
            obj = obj@DataViewer(options,varargin{:});
            obj = sliceViewerFcn(obj);
            obj.redrawenable = true;
            redraw(obj);

        end

        function redraw(obj)
            redraw@DataViewer(obj);
            redrawFcn(obj);
        end


        function val = get.SequenceVisible(obj)
            val = obj.seqvisible;
        end

        function val = get.SequenceHighlight(obj)
            val = obj.seqhighlight;
        end

        function set.SequenceVisible(obj,val)
            setSequenceVisibleFcn(obj,val);
        end

        function set.SequenceHighlight(obj,val)
            setSequenceHighlightFcn(obj,val);
        end

        function set.BackgroundColor(obj,val)
            obj.BackgroundColor = checkColorFcn(val,'BackgroundColor');
            redraw(obj);
        end

        function set.BorderColor(obj,val)
            obj.BorderColor = checkColorFcn(val,'BorderColor');
            redraw(obj);
        end

        function set.SurfaceColor(obj,val)
            obj.SurfaceColor = checkColorFcn(val,'SurfaceColor');
            redraw(obj);
        end

        function set.HighlightColor(obj,val)
            obj.HighlightColor = checkHighlightColor(obj,val);
            redraw(obj);
        end

        function set.ZoomVisible(obj,val)
            obj.ZoomVisible = isequal(val,true);
            redraw(obj);
        end


%
%         function highlight(obj,idx)
%             highlightFcn(obj,idx);
%         end
%
%
%         function visible(obj,idx)
%             visibleFcn(obj,idx);
%         end
    end

    methods (Access=protected)


        function reset(obj)
            resetFcn(obj);
        end

        function loadseq(obj)
            loadseqFcn(obj)
        end

        function dataevent(obj,evnt)
            dataeventFcn(obj,evnt);
        end

    end
end




function obj = sliceViewerFcn(obj)

    % create axes
    obj.hax = axes(...
        'parent',       obj.hdisplay,...
        'box',          'on',...
        'xtick',        [],...
        'ytick',        [],...
        'ztick',        []);

    view(obj.hax,3);
    axis(obj.hax,'vis3d');
    daspect(obj.hax,[1 1 1]);

    zprPointerBehavior(obj.hax,'rotate3d');
    obj.hcontrast.setAllowAxes(obj.hax,false);

    % ready the object
    if isempty(obj.hdata)
        reset(obj);
    else
        loadseq(obj);
    end


end


function resetFcn(obj)

    % reset surfaces
    if ~isempty(obj.hsurf)
        h = obj.hsurf;
        delete(h(ishandle(h)));
        obj.hsurf = [];
    end

    % reset axes
    set(obj.hax,...
        'xlim',             [0 1],...
        'ylim',             [0 1],...
        'zlim',             [0 1],...
        'handlevisibility', 'off',...
        'hittest',          'off');
    view(obj.hax,3);
    axis(obj.hax,'vis3d');

    % reset parameters
    obj.seqvisible   = false(0,1);
    obj.seqhighlight = false(0,1);

    % redraw
    redraw(obj);

end



function redrawFcn(obj)

    if ~obj.redrawenable, return; end

    set(obj.hax,...
        'Color',            obj.BackgroundColor,...
        'xcolor',           obj.BorderColor,...
        'ycolor',           obj.BorderColor,...
        'zcolor',           obj.BorderColor,...
        'handlevisibility', 'off',...
        'hittest',          'off');

    if ~isempty(obj.hsurf)
        set(obj.hax,...
            'handlevisibility', 'on',...
            'hittest',          'on');

        h = obj.hsurf;
        set(h(ishandle(h)),...
            'EdgeColor',    obj.SurfaceColor,...
            'Visible',      'on');

        h = obj.hsurf(obj.seqhighlight);
        if ~iscell(obj.HighlightColor)
            set(h(ishandle(h)),...
                'EdgeColor',    obj.HighlightColor);
        else
            % for individual highlight colors, we give preference to lower
            % numbered series (hence the reversal of the handles)
            clr = obj.HighlightColor(obj.seqhighlight);
            h = h(ishandle(h));
            clr = clr(ishandle(h));
            set(h(end:-1:1),{'EdgeColor'},clr(end:-1:1));
        end

        h = obj.hsurf(~obj.seqvisible);
        set(h(ishandle(h)),...
            'Visible',      'off');

        if isequal(obj.ZoomVisible,true)
            tf = obj.seqvisible;
        else
            tf = true(size(obj.seqvisible));
        end

        % determine the display limits
        X = cell2mat(obj.extents(tf));
        xrng = [min(X(:,1)) max(X(:,1))];
        yrng = [min(X(:,2)) max(X(:,2))];
        zrng = [min(X(:,3)) max(X(:,3))];

        d = max([diff(xrng),diff(yrng),diff(zrng)])/2;
        xrng = mean(xrng) + [-d d];
        yrng = mean(yrng) + [-d d];
        zrng = mean(zrng) + [-d d];

        % update the slice display limits
        set(obj.hax,'xlim',xrng,'ylim',yrng,'zlim',zrng);

    end

end



function dataeventFcn(obj,evnt)

    switch lower(evnt.Action)
        case 'load'
            loadseqFcn(obj);
    end

end


function loadseqFcn(obj)

    % clear the display
    reset(obj);

    % make sure the DENSEdata is not empty
    if isempty(obj.hdata), return; end


    % gather slice information
    X3 = {obj.hdata.seq.extents3D}';
    sl = [obj.hdata.seq.sliceid]';

    obj.extents = X3;

    % draw unique slice patches
    [tmp,ndx,idx] = unique(sl);
    h = NaN(numel(ndx),1);
    for k = 1:numel(ndx)
        if isnan(ndx(k)), continue; end

        hsurf = patch(...
            'parent',       obj.hax,...
            'vertices',     X3{ndx(k)},...
            'faces',        [1 2 3 4],...
            'facecolor',    'none',...
            'edgecolor',    [.5 .5 .5]);

        h(idx==k) = hsurf;
    end

    % save to object
    obj.hsurf = h;


%     % determine initial slice limits
%     X = cell2mat(X3);
%     xrng = [min(X(:,1)) max(X(:,1))];
%     yrng = [min(X(:,2)) max(X(:,2))];
%     zrng = [min(X(:,3)) max(X(:,3))];
%
%     d = max([diff(xrng),diff(yrng),diff(zrng)])/2;
%     xrng = mean(xrng) + [-d d];
%     yrng = mean(yrng) + [-d d];
%     zrng = mean(zrng) + [-d d];
%
%     % update the slice display limits
%     set(obj.hax,'xlim',xrng,'ylim',yrng,'zlim',zrng);

    % update variables
    N = numel(obj.hdata.seq);
    obj.seqvisible   = true(N,1);
    obj.seqhighlight = false(N,1);


    % update display
    redraw(obj);
end



function setSequenceVisibleFcn(obj,val)

    if isempty(obj.seqvisible)
        errstr = 'DENSEdata is empty; cannot set SequenceVisible.';
    elseif numel(val) ~= numel(obj.seqvisible)
        errstr = 'SequenceVisible expects [Nx1] logical vector';
    end

    if exist('errstr','var')
        error(sprintf('%s:invalidSequenceVisible',mfilename),errstr);
    end

    obj.seqvisible(:) = logical(val(:));
    redraw(obj);
end

function setSequenceHighlightFcn(obj,val)

    if isempty(obj.seqhighlight)
        errstr = 'DENSEdata is empty; cannot set SequenceHighlight.';
    elseif numel(val) ~= numel(obj.seqhighlight)
        errstr = 'SequenceHighlight expects [Nx1] logical vector';
    end

    if exist('errstr','var')
        error(sprintf('%s:invalidSequenceHighlight',mfilename),errstr);
    end

    obj.seqhighlight(:) = logical(val(:));
    redraw(obj);
end


function val = checkColorFcn(val,name)
% check for a valid color specification (see COLORSPEC)
    [tf,errstr] = iscolor(val);
    if ~tf
        error(sprintf('%s:invalid%s',mfilename,name),errstr);
    end
    val = val(:)';
end


function val = checkHighlightColor(obj,val)
    if ~iscell(val)
        [tf,errstr] = iscolor(val);
    else
        if numel(val) ~= numel(obj.seqhighlight)
            tf = false;
            errstr = sprintf('Cell array of colors must be %dx1',...
                numel(obj.seqhighlight));
        else
            for k = 1:numel(val)
                [tf,errstr] = iscolor(val{k});
                if ~tf, break; end
            end
        end
    end

    if ~tf
        error(sprintf('%s:invalidHighlightColor',mfilename),errstr);
    end

    if ~iscell(val)
        val = val(:)';
    else
        val = val(:);
    end
end


