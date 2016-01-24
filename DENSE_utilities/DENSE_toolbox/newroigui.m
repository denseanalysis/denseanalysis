function output = newroigui(hdata,sidx,varargin)
% output = newroigui(hdata,sidx,varargin)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------
  
    % check number of inputs
    error(nargchk(2,Inf,nargin));

    % close figure on output?
    FLAG_close = true;

    % check DENSEdata input
    if ~isa(hdata,'DENSEdata')
        error(sprintf('%s:invalidDENSEdata',mfilename),...
            '1st input must be valid DENSEdata object');

    end

    % check for empty object
    if isempty(hdata.seq)
        error(sprintf('%s:cannotCreateROI',mfilename),...
            'DENSEdata object is empty.')
    end

    % check sequence index
    rng = [1 numel(hdata.seq)];
    if ~isnumeric(sidx) || ~isscalar(sidx) || ...
       sidx < rng(1) || rng(2) < sidx
        error(sprintf('%s:invalidSequenceIndex',mfilename),...
            'Invalid sequence index.')
    end

    % default name
    name = sprintf('ROI.%d',numel(hdata.roi) + 1);

    % locate copy-able ROIs
    % --any ROI whose parent sequence has the same sliceid as the
    %   sidx sliceid is fully copy-able.  Here, we'll check for a single
    %   frame with a non-empty position.
    % --The first frame of any ROI from the same slice plane may be
    %   copy-able.  Here, we'll check that the first frame has a non-empty
    %   position.

    Nfr     = hdata.seq(sidx).NumberInSequence;
    sliceid = hdata.seq(sidx).sliceid;
    planeid = hdata.seq(sidx).planeid;
    parallelid = hdata.seq(sidx).parallelid;

    Nroi = numel(hdata.roi);
    curdata = repmat(struct,[Nroi 1]);
    curtf   = false([Nroi 1]);
    pardata = repmat(struct,[Nroi 1]);
    partf   = false([Nroi 1]);

    for k = 1:Nroi

        % current ROI information
        uid  = hdata.roi(k).UID;
        typ  = hdata.roi(k).Type;
        idx  = hdata.roi(k).SeqIndex(1);
        sid  = hdata.seq(idx).sliceid;
        plid = hdata.seq(idx).planeid;
        paid = hdata.seq(idx).parallelid;
        n    = hdata.seq(idx).NumberInSequence;

        % test for valid contour def on each frame
        valid = all(~cellfun(@isempty,hdata.roi(k).Position),2);

        % create copydata
        if (sid == sliceid) && any(valid)
            str = strcat(hdata.roi(k).Name,' (all frames)');
            action = 'all';
            curtf(k) = true;
        elseif plid == planeid && valid(1)
            str = strcat(hdata.roi(k).Name,' (first frame only)');
            action = 'one';
            curtf(k) = true;
        elseif paid == parallelid && n==Nfr && any(valid)
            str = strcat(hdata.roi(k).Name,' (all frames)');
            action = 'all';
            partf(k) = true;
        elseif paid == parallelid && n~=Nfr && valid(1)
            str = strcat(hdata.roi(k).Name,' (first frame only)');
            action = 'one';
            partf(k) = true;
        else
            continue;
        end

        % save data
        if curtf(k)
            curdata(k).Name     = str;
            curdata(k).UID      = uid;
            curdata(k).Type     = typ;
            curdata(k).Action   = action;
            curdata(k).ROIIndex = k;
            curdata(k).SeqIndex = idx;
        else
            pardata(k).Name     = str;
            pardata(k).UID      = uid;
            pardata(k).Type     = typ;
            pardata(k).Action   = action;
            pardata(k).ROIIndex = k;
            pardata(k).SeqIndex = idx;
        end

    end

    curdata = curdata(curtf);
    pardata = pardata(partf);

%     for k = 1:numel(curdata)
%         curdata(k)
%     end
%
%     for k = 1:numel(pardata)
%         pardata(k)
%     end

    % parse the application data
    defapi = struct(...
        'Name',name);
    api = parseinputs(defapi,[],varargin{:});

    % check name
    if ~ischar(api.Name)
        api.Name = defapi.Name;
    end

    % save other options
    api.DENSEdata = hdata;
    api.SeqIndex  = sidx;
    api.Nfr       = Nfr;
    api.sliceid   = sliceid;
    api.planeid   = planeid;
    api.CopyData = curdata;
    api.ParallelData = pardata;

    % load gui
    try
        hfig = hgload([mfilename '.fig']);
        api.hfig = hfig;

        % force close after output (on function cleanup)
        if FLAG_close
            cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
        end

        % gather controls
        hchild = findobj(hfig);
        tags = get(hchild,'tag');
        for ti = 1:numel(hchild)
            if ~isempty(tags{ti}) && strcmpi(tags{ti}(1),'h')
                api.(tags{ti}) = hchild(ti);
            end
        end

        % pass to the subfunction
        set(hfig,'visible','off');
        guidata(hfig,api);
        output = mainFcn(api);

    catch ERR
        close(hfig(ishandle(hfig)),'force');
        rethrow(ERR);
    end

end


function newroi = mainFcn(api)

    % place figure in screen center
    posscr = get(0,'ScreenSize');
    posfig = getpixelposition(api.hfig);
    posfig(1:2) = (posscr(3:4)-posfig(3:4))/2;
    setpixelposition(api.hfig,posfig);

    % gather togglehandle/texthandle
    api.types = {'curve','line','SA','LA','closed','open'};
    api.htb = NaN(size(api.types));
    api.htx = api.htb;
    for k = 1:numel(api.types)
        api.htb(k) = eval(['api.h' api.types{k}]);
        api.htx(k) = eval(['api.h' api.types{k} 'text']);
    end


    % load copy data to figure
    % determine "type" handle for each copydata element
    if isempty(api.CopyData)
        buf = 'No ROI available...';
        set(api.hcurrentlist,'String',buf,'Value',1);
        set(api.hcurrent,'enable','off');

    else

        % gather strings
        buf = {api.CopyData.Name};

        set(api.hcurrentlist,'String',buf,'Value',1);
        set(api.hcurrent,'enable','on');

        % corresponding type index into toggle button handle array
        % of each "copydata" element
        idx = cellfun(@(t)find(strcmpi(t,api.types),1,'first'),...
            {api.CopyData.Type});

        % save handles to "copydata"
        h = num2cell(api.htb(idx));
        [api.CopyData.Handle] = deal(h{:});

    end

    % load parallel data to figure
    % determine "type" handle for each copydata element
    if isempty(api.ParallelData)
        buf = 'No ROI available...';
        set(api.hparallellist,'String',buf,'Value',1);
        set(api.hparallel,'enable','off');

    else

        % gather strings
        buf = {api.ParallelData.Name};

        set(api.hparallellist,'String',buf,'Value',1);
        set(api.hparallel,'enable','on');

        % corresponding type index into toggle button handle array
        % of each "copydata" element
        idx = cellfun(@(t)find(strcmpi(t,api.types),1,'first'),...
            {api.ParallelData.Type});

        % save handles to "copydata"
        h = num2cell(api.htb(idx));
        [api.ParallelData.Handle] = deal(h{:});

    end

    % update name
    set(api.hname,'String',api.Name);


    % set button group events
    set(api.hsource,'SelectionChangeFcn',...
        @(h,evnt)sourceSelectionChangeFcn(evnt,api.hfig));
    set(api.htype,'SelectionChangeFcn',...
        @(h,evnt)typeSelectionChangeFcn(evnt,api.hfig));

    set(api.hcurrentlist,'Callback',...
        @(varargin)hcurrentlistCallback(api.hfig));
    set(api.hparallellist,'Callback',...
        @(varargin)hparallellistCallback(api.hfig));

    % set callbacks
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));


    % wait for figure to finish
    guidata(api.hfig,api);
    set(api.hfig,'visible','on');
    waitfor(api.hfig,'userdata')

    % output
    if ~ishandle(api.hfig) || ~isequal(get(api.hfig,'userdata'),'complete')
        newroi = [];
    else
        api = guidata(api.hfig);

        % initialize new ROI object
        tf = (get(api.htype,'SelectedObject') == api.htb);
        type = api.types{tf};
        newroi = struct(...
            'Name',   get(api.hname,'String'),...
            'Type',   type,...
            'UID',    dicomuid);

        % new/copy action
        if get(api.hnew,'value')
            action = 'new';
        elseif get(api.hcurrent,'value')
            action = 'copy';
            val = get(api.hcurrentlist,'value');
            copydata = api.CopyData(val);
        else
            action = 'copy';
            val = get(api.hparallellist,'value');
            copydata = api.ParallelData(val);
        end

        % type-specific values
        switch lower(type)
            case 'sa'
                Nline = 2;
                iscls = true;
                iscrv = true;
            case 'la'
                Nline = 2;
                iscls = false;
                iscrv = true;
            case 'line'
                Nline = 1;
                iscls = true;
                iscrv = false;
            case 'open'
                Nline = 1;
                iscls = false;
                iscrv = true;
            otherwise
                Nline = 1;
                iscls = true;
                iscrv = true;

        end

        % add fields to ROI
        ind = find(cellfun(@(x)isequal(x,api.sliceid),...
            {api.DENSEdata.seq.sliceid}));
        Nfr = api.Nfr;

        newroi.SeqIndex = ind(:)';
        newroi.Position = repmat({zeros(0,2)}, [Nfr,Nline]);
        newroi.IsClosed = repmat({iscls},      [Nfr,Nline]);
        newroi.IsCurved = repmat({iscrv},      [Nfr,Nline]);
        newroi.IsCorner = repmat({false},      [Nfr,Nline]);


        % copy action
        if strcmpi(action,'copy')

            copyaction = copydata.Action;
            copyidx    = copydata.ROIIndex;
            roi        = api.DENSEdata.roi(copyidx);

            if strcmpi(copyaction,'all')
                rng = 1:Nfr;
            else
                rng = 1;
            end

            % convert positions between image spaces
            seqA = roi.SeqIndex(1);
            tformAto3D = api.DENSEdata.seq(seqA).tform;
            seqB = api.SeqIndex;
            tformBto3D = api.DENSEdata.seq(seqB).tform;

            for fr = rng
                for k = 1:Nline
                    postmp = roi.Position{fr,k};
                    postmp(:,3) = 0;
                    postmp = tforminv(tformBto3D,tformfwd(tformAto3D,postmp));
                    newroi.Position{fr,k} = postmp(:,[1 2]);
                end
            end

            % copy other roi parameters
            newroi.IsClosed(rng,:) = roi.IsClosed(rng,:);
            newroi.IsCurved(rng,:) = roi.IsCurved(rng,:);
            newroi.IsCorner(rng,:) = roi.IsCorner(rng,:);

        end

    end


end


%% BUTTON CALLBACKS (OK/CANCEL/FIGURECLOSE)

function okCallback(hfig)
    set(hfig,'userdata','complete');
end

function cancelCallback(hfig)
    set(hfig,'userdata','cancel');
end

function figCloseRequestFcn(hfig)
    set(hfig,'userdata','cancel');
end



%% SOURCE/TYPE FUNCTIONS

function sourceSelectionChangeFcn(eventdata,hfig)
% If the "new roi" button is selected, the available copy information is
% disabled and the ROI type button group is enabled.
% If any "copy roi" button is selected, the ROI type button group is
% disabled, and the copy list is enabled.
    api = guidata(hfig);

    % "slice copy" radiobutton update
    tag = get(eventdata.NewValue,'tag');
    if any(strcmpi(tag,{'hcurrent','hparallel'}))

        set([api.hcurrentlist,api.hparallellist],'enable','off');

        hlist = eval(['api.' tag 'list']);
        set(hlist,'Enable','on');

        val = get(hlist,'value');
        if hlist == api.hcurrentlist
            h = api.CopyData(val).Handle;
        else
            h = api.ParallelData(val).Handle;
        end

        api.newtype = get(api.htype,'SelectedObject');
        guidata(api.hfig,api);
        setChildProperty(api.htype,'Enable','off');

%     % "parallel slice copy" radiobutton update
%     if eventdata.NewValue == api.hparallel
%         set(api.hparallellist,'Enable','on');
%         setChildProperty(api.htype,'Enable','off');
%
%         val = get(api.hparallellist,'value');
%         h = api.CopyData(val).Handle;
%
%         api.newtype = get(api.htype,'SelectedObject');
%         guidata(api.hfig,api);

    % "new" button radio update
    else
        set(api.hcurrentlist,'Enable','off');
        setChildProperty(api.htype,'Enable','on');
        h = api.newtype;
    end

    % update type display
    typeVirtualCallback(h,api);

end


function hcurrentlistCallback(hfig)
% update the ROI type toggle buttons according to the currently
% selected ROI copy.
    api = guidata(hfig);
    val = get(api.hcurrentlist,'value');
    typeVirtualCallback(api.CopyData(val).Handle,api);

end

function hparallellistCallback(hfig)
% update the ROI type toggle buttons according to the currently
% selected ROI copy.
    api = guidata(hfig);
    val = get(api.hparallellist,'value');
    typeVirtualCallback(api.ParallelData(val).Handle,api);

end


function typeSelectionChangeFcn(eventdata,hfig)
% This function highlights the text associated with each
% ROI type toggle button
    api = guidata(hfig);

    % locate text to highlight
    tf = (eventdata.NewValue == api.htb);

    % set text properties
    set(api.htx(~tf),'FontWeight','normal',...
        'ForegroundColor',[0 0 0]);
    set(api.htx(tf), 'FontWeight','bold',...
        'ForegroundColor',[78 101 148]/255);

end


function typeVirtualCallback(hnew,api)
% This function creates a "virtual" call to the ROI type button group,
% allowing programmatic activation of any toggle button within the group.
% (i.e. setting a toggle button value programmatically does not
% automatically call the corresponding SelectionChangeFcn)
    hold = get(api.htype,'SelectedObject');

    set(hnew,'Value',1);
    eventdata = struct('EventName','SelectionChanged',...
        'OldValue',hold,'NewValue',hnew);
    typeSelectionChangeFcn(eventdata,api.hfig);

end


%% HELPER FUNCTION
% Set a property for a given object and all children of the object

function setChildProperty(hparent,prop,val)

    % entire object hierarchy, including parent
    h = findall(hparent);

    % set objects with propert to value
    tf = isprop(h,prop);
    set(h(tf),prop,val);

end
