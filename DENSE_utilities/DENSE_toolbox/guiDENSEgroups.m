%% GUIDENSEGROUPS interatively define DENSE groups within DICOM sequences
%
%INPUTS
%   seqdata....DICOM sequence data
%
%INPUT PARAMETERS
%
%   'Types'..........requested group types
%       ['x'|'y'|'z'|'xy'|'xyz'|{'all'}]
%
%   'InitialGroups'..[Ngroup0 x 1] array of structures with at
%       least the following fields:
%           Name.......group name
%           UID........unique group identifier
%           Type.......group type: 'x','y','z','xy', or 'xyz'
%           MagIndex...indices into SEQDATA of magnitude information
%           PhaIndex...indices into SEQDATA of phase information
%
%OUTPUTS
%   groups.....[Ngroupx1] output array of structures
%
%USAGE
%
%   GROUPS = GUIDENSEGROUPS(SEQDATA) this function allows a user
%   to interactively define DENSE DICOM sequence groupings of magnitude and
%   phase information from the array of structures SEQDATA, containing
%   DICOM header information given by DICOMSEQ. The output GROUPS contains
%   the resulting groups in an array of structures. Each element of GROUPS
%   identifies the DENSE encoding type ('x','y','z','xy','xyz'), as well
%   as the sequence indices of the magnitude & phase data.
%
%   [...] = GUIDENSEGROUPS(...,'InitialGroups',GROUPS0,...)
%   defines an initial state GROUPS0 for the DENSE grouping
%   (see AUTODENSEGROUPS).
%
%   [...] = GUIDENSEGROUPS(...,'Types',C,...) controls the types of groups
%   the function will allow.  C may be any of the following character
%   strings (defaulting to 'all') : ['x'|'y'|'z'|'xy'|'xyz'|'all'].
%   C may alternatively be a CELLSTR, indicating more than one type
%   (e.g. {'x','y'}).
%

%GENERAL FUNCTION INPUTS & OUTPUTS
%   varargout  cell array for returning output args (see VARARGOUT);
%   hObject    handle to calling object (see GCO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)

%-----------------------------------------------------------------------------
% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
%-----------------------------------------------------------------------------

%%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation
%   2009.06     Drew Gilliam
%     --visual/functional redesign



function groups = guiDENSEgroups(seqdata,varargin)


    % check for struct
    if ~isstruct(seqdata) || numel(seqdata)<2
       error(sprintf('%s:invalidData',mfilename),...
            'SEQDATA must be an array of structures!');
    end

    % parse additional inputs
    defapi = struct(...
        'InitialGroups',    [],...
        'Types',            'all');
    [api,other_args] = parseinputs(defapi,[],varargin{:});
    if ~isempty(other_args)
        error(sprintf('%s:invalidParameters',mfilename), ...
            'Invalid input parameter pair.');
    end


    % locate DENSE sequences
    tf = [seqdata.ValidSequence] & ...
        cellfun(@(s)~isempty(s),{seqdata.DENSEid});
    if ~any(tf)
        error(sprintf('%s:noDENSEsequences',mfilename),...
            'No valid DENSE sequences were found.');
    end
    api.dnsidx = find(tf);


    % parse 'Types'
    tags = {'x','y','z','xy','xyz','all'};
    if ischar(api.Types), api.Types = {api.Types}; end
    if ~iscellstr(api.Types) || ...
       ~all(cellfun(@(x)any(strcmpi(x,tags)),api.Types))

        str = sprintf('%s|',tags{:});
        error(sprintf('%s:invalidTypes',mfilename),'%s',...
            'Unrecognized ''Types'' input. Valid identifiers are: ',...
            '[',str(1:end-1),'].');
    end

    if any(strcmpi(api.Types,'all'))
        api.Types = {'x','y','z','xy','xyz'};
    end


    % parse 'InitialGroups'
    if isempty(api.InitialGroups)
        api.groups = repmat(...
            struct('Name',[],'UID',[],'Type',[],...
            'MagIndex',[],'PhaIndex',[]),[0 1]);
    else
        api.groups  = api.InitialGroups(:);
    end


    % check 'groups' for expected fields
    tags = {'Name','UID','Type','MagIndex','PhaIndex'}';
    if ~isstruct(api.groups) || ~all(isfield(api.groups,tags))
        error(sprintf('%s:invalidGroups',mfilename),'%s',...
            'The second input expects a structure with at least ',...
            'the fields ''Type'', ''MagIndex'', and ''PhaIndex''.');
    end

    % eliminate any InitialGroups of invalid return type
    tf = cellfun(@(x)any(strcmpi(x,api.Types)),...
        {api.groups.Type});
    api.groups = api.groups(tf);

    % mark old groups
    api.newgroupflag = false(numel(api.groups),1);


    %% LOAD GUI & PASS TO MAIN FUNCTION

    % load gui
    hfig = hgload([mfilename '.fig']);
    cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
    api.hfig = hfig;

    % gather controls
    hchild = findobj(hfig);
    tags = get(hchild,'tag');
    for ti = 1:numel(hchild)
        if ~isempty(tags{ti}) && strcmpi(tags{ti}(1),'h')
            api.(tags{ti}) = hchild(ti);
        end
    end

    % pass to the subfunction
    groups = mainFcn(seqdata,api);





end



%% MAIN FUNCTION
function groups = mainFcn(seqdata,api)




    % set the figure name according to acceptable types
    str = sprintf('%s|',api.Types{:});
    name = sprintf('DENSE grouping tool: [%s]',str(1:end-1));
    set(api.hfig,'Name',name);


    % enabled strings
    api.seqenable = true(size(api.dnsidx));

    % create empty newgroup
    fields = fieldnames(api.groups);
    api.newgroup = cell2struct(cell(numel(fields),1),fields(:));
    api.newgroup.MagIndex = NaN(1,3);
    api.newgroup.PhaIndex = NaN(1,3);


    % slice identifiers
    slicedata = DICOMslice(seqdata);
    api.sliceid    = [slicedata.sliceid];
    api.sliceplane = [slicedata.planeid];

    % other identifiers identifier
    api.denseid  = {seqdata.DENSEid};
    api.seriesid = [seqdata.SeriesNumber];


    % sequence format strings
    fmt{2} = ['<HTML>[%3d] ',...
        '<FONT color=#CC6600>%5s (%2d frames)</FONT> ',...
        '<FONT color=#000099>%s, %s</FONT></HTML>'];
    fmt{1} = ['<HTML><FONT color=#CCCCCC>',...
        '[%3d] %5s (%2d frames) %s, %s</FONT></HTML>'];

    % sequence strings
    idx = api.dnsidx;
    dnsstr = cell(numel(idx),2);
    for k = 1:2
    dnsstr(:,k) = cellfun(...
            @(sn,id,nf,sd,pn)sprintf(fmt{k},sn,id,nf,sd,pn),...
            {seqdata(idx).SeriesNumber}',...
            {seqdata(idx).DENSEid}',...
            {seqdata(idx).NumberInSequence}',...
            {seqdata(idx).SeriesDescription}',...
            {seqdata(idx).ProtocolName}',...
            'uniformoutput',0);
    end
    dnsstr = cellfun(@(s)regexprep(s,'.overall','..'),...
        dnsstr,'uniformoutput',0);
    api.dnsstr = dnsstr;


    % cycle listbox focus
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));

    h = [api.hxmag,api.hymag,api.hzmag,...
         api.hxpha,api.hypha,api.hzpha];
    set(h(:),{'Callback'},...
        {@(varargin)newgroupUpdate( true,1,api.hfig,seqdata);...
         @(varargin)newgroupUpdate( true,2,api.hfig,seqdata);...
         @(varargin)newgroupUpdate( true,3,api.hfig,seqdata);...
         @(varargin)newgroupUpdate(false,1,api.hfig,seqdata);...
         @(varargin)newgroupUpdate(false,2,api.hfig,seqdata);...
         @(varargin)newgroupUpdate(false,3,api.hfig,seqdata)});

    set(api.hseq,'Callback',@(varargin)redrawButtons(api.hfig));


    set(api.hclear,'Callback',@(varargin)clearCallback(api.hfig));
    set(api.hadd,'Callback',@(varargin)addCallback(api.hfig));

    set(api.hname,'Callback',@(varargin)nameCallback(api.hfig));

    set(api.hdelete,'Callback',@(varargin)deleteCallback(api.hfig));

    % update figure
    guidata(api.hfig,api);
    redrawListboxes(api.hfig);
    redrawButtons(api.hfig);

    % cycle listbox focus
    uicontrol(api.hseq);
    uicontrol(api.hgroup);

    % wait for figure to finish
    set(api.hfig,'visible','on');
    waitfor(api.hfig,'userdata')

    % output
    if ~ishandle(api.hfig) || ~isequal(get(api.hfig,'userdata'),'complete')
        groups = [];
    else

        api = guidata(api.hfig);
        if isempty(api.groups)
            groups = repmat(struct,[0 1]);
        else
            groups = api.groups;
            tf = api.newgroupflag;
            for gk = 1:numel(groups)
                if ~tf(gk), continue; end

                midx = groups(gk).MagIndex;
                pidx = groups(gk).PhaIndex;

                scale   = NaN(1,3);
                encfreq = NaN(1,3);
                for k = 1:3
                    if ~isnan(pidx(k))
                        data = seqdata(pidx(k)).DENSEdata;
                        scale(k)   = data.Scale(1);
                        encfreq(k) = data.EncFreq(1);
                    end
                end

                idx = midx(find(~isnan(midx),1,'first'));
                data = seqdata(idx).DENSEdata;

                groups(gk).Number   = data.Number;
                groups(gk).PixelSpacing = seqdata(idx).PixelSpacing(:)';
                groups(gk).Scale    = scale;
                groups(gk).EncFreq  = encfreq;
                groups(gk).SwapFlag = data.SwapFlag;
                groups(gk).NegFlag  = data.NegFlag;

            end
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







%% PUSHBUTTON CALLBACKS

function addCallback(hfig)
% ADD NEWGROUP TO GROUPS

    % application data
    api = guidata(hfig);
    ng = api.newgroup;

    % determine the type
    type = 'xyz';
    type = type(~isnan(ng.MagIndex));
    ng.Type = type;

    % check if newgroup already exists.
    for k = 1:numel(api.groups)
        grp = api.groups(k);
        if isequal(grp.Type,ng.Type) && ...
           isequalwithequalnans(grp.MagIndex,ng.MagIndex) && ...
           isequalwithequalnans(grp.PhaIndex,ng.PhaIndex)

            warndlg('Group already exists.',...
                'Group Exists','modal');
            return;
        end
    end

    % generate a unique identifier
    ng.UID = dicomuid;

    % add new group to groups
    tags = fieldnames(ng);
    api.groups(end+1).Name = [];
    for ti = 1:numel(tags)
        api.groups(end).(tags{ti}) = ng.(tags{ti});
    end

    % mark as new group
    api.newgroupflag(end+1) = true;

    % save data & clear new group
    guidata(hfig,api);
    clearCallback(hfig);

end


function clearCallback(hfig)
% CLEAR NEW GROUP

    api = guidata(hfig);

    % clear the newgroup
    tags = fieldnames(api.newgroup);
    for ti = 1:numel(tags)
        api.newgroup.(tags{ti}) = [];
    end
    api.newgroup.MagIndex = NaN(1,3);
    api.newgroup.PhaIndex = NaN(1,3);
    api.newgroup.Name     = [];

    % clear the name edit box
    set(api.hname,'string',[]);

    % enable all sequences
    api.seqenable(:) = true;

    % save & redraw
    guidata(hfig,api);
    redrawListboxes(hfig);
    redrawButtons(hfig);

end


function deleteCallback(hfig)
% DELETE SELECTED GROUPS FROM LIST OF GROUPS

    % application data
    api = guidata(hfig);

    % sslected group
    sel = get(api.hgroup,'Value');
    contents = get(api.hgroup,'string');
    strs = contents(sel);

    % confirm delete
    str  = ['Are you sure you want to delete the following groups?';...
           strtrim(strs(:))];
    button = questdlg(str,'Delete Group');
    if ~strcmpi(button,'yes'), return; end

    % delete
    api.groups(sel) = [];
    api.newgroupflag(sel) = [];
    guidata(hfig,api);

    % update display
    set(api.hgroup,'Value',1);
    uicontrol(api.hgroup);
    redrawListboxes(hfig)
    redrawButtons(hfig)

end


%% NEW NAME CALLBACK
function nameCallback(hfig)
    api = guidata(hfig);
    api.newgroup.Name = get(api.hname,'String');
    guidata(hfig,api);
    redrawButtons(hfig);
end



%% UPDATE NEWGROUP
% update the NEWGROUP structure (as well as SEQENABLE) with the
% latest user selection

function newgroupUpdate(FLAG_mag,ind,hfig,seqdata)

    % application data
    api = guidata(hfig);

    % current sequence index
    idx = api.dnsidx(get(api.hseq,'Value'));

    % save index
    if FLAG_mag
        api.newgroup.MagIndex(ind) = idx;
    else
        api.newgroup.PhaIndex(ind) = idx;
    end

    % current type
%     types = {'x','y','z'};
%     type = types(ind);

    % current information
    data = seqdata(idx);

    % search for allowable matches
    tf = true(size(api.dnsidx));
    for k = 1:numel(api.dnsidx)

        % current sequence index
        idxk = api.dnsidx(k);

        % Study & DENSEdata must be equal
        tf(k) = isequalstruct(...
                    data,seqdata(idxk),...
                    {'StudyInstanceUID'}) ...
             && isequalstruct(...
                    data.DENSEdata,...
                    seqdata(idxk).DENSEdata,...
                    {'Number','SwapFlag','NegFlag'});
        if ~tf(k), continue; end

        % The slice ids must match exactly to add to group
        tf(k) = isequal(api.sliceid(idx),...
                        api.sliceid(idxk));

        %-----REMOVED-----
        % if the current sequence is the same type ('x'/'y'/'z') as the
        % newly selected sequence, the slice identifiers must match
        % exactly. Otherwise, they must lie within the same slice plane.
        %if isequal(type,seqdata(idxk).DENSEid(5:end));
        %    tf(k) = isequal(api.sliceid(idx),...
        %                    api.sliceid(idxk));
        %else
        %    tf(k) = isequal(api.planeid(idx),...
        %                    api.planeid(idxk));
        %end
        %-----------------

    end

    % update sequence enable
    api.seqenable = api.seqenable & tf;

    % save to figure & update display
    guidata(hfig,api);
    uicontrol(api.hseq);
    redrawListboxes(hfig);
    redrawButtons(hfig);

end



%% REDRAW ALL BUTTONS
% enable/disbale all buttons based on current figure state
function redrawButtons(hfig)

    % application data
    api = guidata(hfig);

    % newgroup button handles
    h = [api.hxmag,api.hymag,api.hzmag,...
         api.hxpha,api.hypha,api.hzpha];

    % disable buttons
    set([h(:);api.hadd],'enable','off');

    % if all mag/pha data is paired AND the name is not empty AND
    %   it is a requested return type, the group is valid and ADD-able
    % if any data has been set, the group is CLEAR-able.
    mtf = ~isnan(api.newgroup.MagIndex);
    ptf = ~isnan(api.newgroup.PhaIndex);
    ntf = ~isempty(api.newgroup.Name);
    if all(mtf==ptf) && any(mtf) && ntf
        str  = 'xyz';
        type = str(~isnan(api.newgroup.MagIndex));
        if any(strcmpi(type,api.Types))
            set(api.hadd,'enable','on');
        end
    end

    % enable delete button if any groups exist
    if numel(api.groups) > 0
        set(api.hdelete,'enable','on');
    else
        set(api.hdelete,'enable','off');
    end

    % enable newgroup buttons based on current sequence selection
    sel = get(api.hseq,'Value');

    if api.seqenable(sel)
        idx = api.dnsidx(sel);
        denseid = api.denseid{idx};
        switch lower(denseid)
            case 'mag.x',       n = 1;
            case 'mag.y',       n = 2;
            case 'mag.z',       n = 3;
            case 'pha.x',       n = 4;
            case 'pha.y',       n = 5;
            case 'pha.z',       n = 6;
            case 'mag.overall', n = [1 2 3];
            otherwise,          n = [];
        end
        set(h(n),'enable','on');
    end

end


%% REDRAW LISTBOXES
% redraw all listboxes based on current figure state
function redrawListboxes(hfig)


    % application data
    api = guidata(hfig);

    % gather group strings
    Ngroup = numel(api.groups);

    if Ngroup ~= 0
        grpstr = cell(Ngroup,1);
        for k = 1:Ngroup
            idx = [api.groups(k).MagIndex; ...
                   api.groups(k).PhaIndex];
            idx = idx(~isnan(idx));
            sn  = api.seriesid(idx(:));
            str = sprintf('[%d/%d] ',sn);
            grpstr{k} = sprintf('%3s: %s %s',...
                api.groups(k).Type,api.groups(k).Name,str);
        end
    else
        grpstr = cell(0,1);
    end


    % new group sequence indices
    idx = [api.newgroup.MagIndex;
           api.newgroup.PhaIndex];
    idx = idx(:);
    tf = ~isnan(idx);

    % newgroup seriesnumbers
    sn = cell(size(idx));
    sn( tf) = num2cell(api.seriesid(idx(tf)));
    sn(~tf) = {''};


    % sequence listbox strings
    tf = api.seqenable(:)';
    idx = sub2ind(size(api.dnsstr),1:numel(tf),round(tf+1));
    dnsstr = api.dnsstr(idx);


    % update new group strings
    h = [api.hxmagtext,api.hxphatext,...
         api.hymagtext,api.hyphatext,...
         api.hzmagtext,api.hzphatext];
    set(h(:),{'String'},sn(:));

    % populate listboxes
    set(api.hgroup,'string',grpstr);
    set(api.hseq,'String',dnsstr);

end



%% END OF FILE=============================================================
