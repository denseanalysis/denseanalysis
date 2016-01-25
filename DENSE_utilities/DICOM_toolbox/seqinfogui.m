function tf = seqinfogui(seqdata)
% tf = seqinfogui(seqdata)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
    % check seqdata
    if ~isstruct(seqdata)
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'SEQDATA must be a structure.');
    end

    % mandatory SEQDATA fields
    tags = {'StudyInstanceUID';'StudyDate';...
        'NumberInSequence';'SeriesNumber'};
    tf = isfield(seqdata,tags);
    if any(~tf)
        str = sprintf('%s,',tags{~tf});
        error(sprintf('%s:missingDICOMinformation',mfilename),'%s',...
            'The following mandatory fields did not exist in ',...
            'any DICOM sequence: [',str(1:end-1),'].');
    end

    % replace any empty fields
    tags = {'StudyDescription';'PatientName';'SeriesDescription'};
    def  = {'no descr.','no name','no descr.'};
    for ti = 1:numel(tags)
        tag = tags{ti};
        if ~isfield(seqdata,tag)
            [seqdata.(tag)] = deal(def{ti});
        else
            for k = 1:numel(seqdata)
                if isempty(seqdata(k).(tag))
                    seqdata(k).(tag) = def{ti};
                end
            end
        end
    end


    % load gui
    hfig = hgload([mfilename '.fig']);
    cleanupObj = onCleanup(@()close(hfig(ishandle(hfig)),'force'));
    api.hfig = hfig;
    set(api.hfig,'visible','off');

    % gather controls
    hchild = findobj(hfig);
    tags = get(hchild,'tag');
    for ti = 1:numel(hchild)
        if ~isempty(tags{ti}) && strcmpi(tags{ti}(1),'h')
            api.(tags{ti}) = hchild(ti);
        end
    end

    % pass to the subfunction
    tf = mainFcn(api,seqdata);

end


%% MAIN FUNCTION
function tf = mainFcn(api,seqdata)

    % determine patient UIDs
    [uid,ndx,idx] = unique({seqdata.StudyInstanceUID}');
    api.patientid = idx;
    api.curid = 0;

    % measure number of sequences per patient
    N = arrayfun(@(k)sum(idx==k),(1:numel(uid))');

    % patient identifiers
    fmt = ['<HTML><FONT color=#000099>[%03d]</FONT> '...
           '<FONT color=#cc6600>%s</FONT> '...
           '<FONT color=#000099>%s</FONT> '...
           '<FONT color=#cc6600>%s</FONT></HTML>'];

    pbuf = cellfun(...
        @(n,dt,sd,pn)sprintf(fmt,n,parseDICOMdate(dt),...
            sd,parsePatientName(pn)),...
        num2cell(N),...
        {seqdata(ndx).StudyDate}',...
        {seqdata(ndx).StudyDescription}',...
        {seqdata(ndx).PatientName}',...
        'uniformoutput',0);
    api.pbuf = pbuf;

    % sequence identifiers
    fmt = ['<HTML><FONT color=#000099>[%03d]</FONT> '...
           '<FONT color=#cc6600>SN.%03d</FONT> '...
           '<FONT color=#000099>%s</FONT></HTML>'];

    sbuf = cellfun(...
        @(n,sn,sd)sprintf(fmt,n,sn,sd),...
            {seqdata.NumberInSequence}',...
            {seqdata.SeriesNumber}',...
            {seqdata.SeriesDescription}',...
        'uniformoutput',0);
    api.sbuf = sbuf;


    % populate patient listbox
    set(api.hplist,'string',pbuf,'value',1);


    % set callbacks
    set(api.hplist,'Callback',...
        @(varargin)plistCallback(api.hfig));
    set(api.hslist,'Callback',...
        @(varargin)slistCallback(api.hfig));
    set(api.hselectall,'Callback',...
        @(varargin)selectAllCallback(api.hfig));
    set(api.hok,'Callback',...
        @(varargin)okCallback(api.hfig));
    set(api.hcancel,'Callback',...
        @(varargin)cancelCallback(api.hfig));
    set(api.hfig,'CloseRequestFcn',...
        @(varargin)figCloseRequestFcn(api.hfig));

    % save to figure
    guidata(api.hfig,api);

    % simulate patient list callback
    plistCallback(api.hfig);
    uicontrol(api.hslist);
    uicontrol(api.hplist);

    % wait for figure to finish
    set(api.hfig,'visible','on');
    waitfor(api.hfig,'userdata')

    % output
    if ~ishandle(api.hfig) || ~isequal(get(api.hfig,'userdata'),'complete')
        tf = [];
    else
        val = get(api.hplist,'Value');
        idx = find(api.patientid == val);

        val = get(api.hslist,'Value');
        idx = idx(val);

        tf = false(numel(seqdata),1);
        tf(idx) = true;
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



%% SWITCH PATIENT
function plistCallback(hfig)

    % gather current application data
    api = guidata(hfig);

    % determine patient sequences to display
    val = get(api.hplist,'Value');
    if val == api.curid
        return;
    else
        api.curid = val;
    end

    % sequences to display
    tf = (api.patientid == val);
    set(api.hslist,'String',api.sbuf(tf),'Value',[]);
    set(api.hok,'Enable','off');

    guidata(api.hfig,api);


end



%% SELECT ALL BUTTON
function selectAllCallback(hfig)

    api = guidata(hfig);
    contents = get(api.hslist,'String');
    if ~iscell(contents)
        N = 1;
    else
        N = numel(contents);
    end
   set(api.hslist,'Value',1:N);
    set(api.hok,'Enable','on');
    uicontrol(api.hslist);

end



%% SEQUENCE LIST CALLBACK
function slistCallback(hfig)
    api = guidata(hfig);
    set(api.hok,'Enable','on')
end



%% END OF FILE=============================================================
