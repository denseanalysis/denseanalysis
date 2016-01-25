% Class Definition ArialViewer

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

classdef ArialViewer < DataViewer

    properties (Dependent=true)
        SequenceIndex
        Limits
    end

    properties (SetAccess='private',GetAccess='private');

        seqidx = [];
        limits = [];

        hax
        him
        hline

        displaydata
    end


    methods

        function obj = ArialViewer(varargin)
            options = struct(...
                'ControlVisible',   'off',...
                'PlaybarVisible',   'off');
            obj = obj@DataViewer(options,varargin{:});
            obj = ArialViewerFcn(obj);
            obj.redrawenable = true;
            redraw(obj);
        end

        function val = get.SequenceIndex(obj)
            val = obj.seqidx;
        end

        function val = get.Limits(obj)
            val = obj.limits;
        end

        function set.SequenceIndex(obj,val)
            setSequenceIndexFcn(obj,val)
        end

        function set.Limits(obj,val)
            setLimitsFcn(obj,val)
        end

    end


    methods (Access=protected)

        function reset(obj)
            resetFcn(obj);
        end
    end



end



function obj = ArialViewerFcn(obj)

    edgeclr = [78 101 148]/255;
    axesclr = [.5 .5 .5];
    lineclr = [1 0.5 0];

    % create axes & image
    obj.hax = axes('parent',obj.hdisplay);
    obj.him = imshow(ones(10),'parent',obj.hax,'init','fit');
    obj.hline = line('parent',obj.hax);

    % create axes
    set(obj.hax,...
        'color',            axesclr,...
        'units',            'normalized',...
        'clim',             [-0.5 1],...
        'box',              'on',...
        'visible',          'on',...
        'xtick',            [],...
        'ytick',            [],...
        'xcolor',           edgeclr,...
        'ycolor',           edgeclr,...
        'HitTest',          'off',...
        'HandleVisibility', 'off');

    set(obj.him,...
        'Visible',          'off',...
        'HitTest',          'off',...
        'HandleVisibility', 'off');

    set(obj.hline,...
        'Visible',          'off',...
        'Color',            lineclr,...
        'marker',           'none',...
        'linewidth',        2);

end


function resetFcn(obj)

    set(obj.him,...
        'cdata',    ones(10),...
        'visible',  'off');
    set(obj.hax,...
        'xlim',     [0.5 10.5],...
        'ylim',     [0.5 10.5],...
        'visible',  'on');
    set(obj.hline,...
        'xdata',    [],...
        'ydata',    [],...
        'visible',  'off');

end


function setSequenceIndexFcn(obj,sidx)

    if isempty(sidx)
        obj.seqidx = [];
        reset(obj);
        return;
    end


    % check for empty DENSEdata
    if isempty(obj.hdata)
        error(sprintf('%s:noDENSEdata',mfilename),'%s',...
            'Invalid Sequence Index; no DENSEdata has been loaded.');
    end

    % ensure numeric
    if ~isnumeric(sidx)
        error(sprintf('%s:noDENSEdata',mfilename),'%s',...
            'Invalid Sequence Index; numeric values only.');
    end

    % eliminate any NaN, Inf, or duplicates
    sidx = sidx(isfinite(sidx));
    sidx = unique(sidx);

    % check sidx
    rng = [1,numel(obj.hdata.seq)];
    if isempty(sidx) || any(sidx < rng(1)) || any(rng(2) < sidx)
        error(sprintf('%s:invalidSequenceIndex',mfilename),'%s',...
            'Invalid Sequence Index.  Values must be on the ',...
            'range [', num2str(rng,'%d,%d'), '].');
    end

    % check for non-existant imagery
    if any(cellfun(@isempty,obj.hdata.img(sidx)))
        obj.seqidx = [];
        reset(obj);
        return;
    end

    % check sliceids
    sliceid = [obj.hdata.seq(sidx).sliceid];
    if any(sliceid ~= sliceid(1))
        error(sprintf('%s:invalidSequenceIndex',mfilename),'%s',...
            'Invalid Sequence Indices - not all sequences ',...
            'from the same slice.');
    end

    % load normalized 1st frame imagery
    obj.displaydata = obj.hdata.getDisplayData;
    Isz = obj.displaydata(sidx(1)).ImageSize;

    N = numel(sidx);
    I = zeros([Isz,N]);
    for k = 1:N
        clim = obj.displaydata(sidx(k)).ILim(1,:);
        im = double(obj.hdata.img{sidx(k)}(:,:,1));
        im = (im-clim(1)) / (clim(2)-clim(1));
        im = imtranslate(im,obj.displaydata(sidx(k)).TranslationRC);
        I(:,:,k) = im;
    end

    I = mean(I,3);
    set(obj.him,'cdata',I,'visible','on');
    set(obj.hax,'xlim',[0.5 Isz(2)+0.5],'ylim',[0.5 Isz(1)+0.5],...
        'visible','off');

    x = get(obj.hax,'xlim');
    y = get(obj.hax,'ylim');
    set(obj.hline,'xdata',x([1 1 2 2 1]),'ydata',y([1 2 2 1 1]),...
        'visible','on');

    obj.limits = [x,y];
    obj.seqidx = sidx;


end




function setLimitsFcn(obj,lim)

    if ~isnumeric(lim) || numel(lim) ~= 4 || ...
       lim(1) >= lim(2) || lim(3) >= lim(4)
        error(sprintf('%s:invalidLimits',mfilename),'%s',...
            'Limits must be a 4 element vector, of the form: ',...
            '[xmin, xmax, ymin, ymax].');
    end

    x = lim(1:2);
    y = lim(3:4);
    set(obj.hline,'xdata',x([1 1 2 2 1]),'ydata',y([1 2 2 1 1]));
    obj.limits = lim;

end

