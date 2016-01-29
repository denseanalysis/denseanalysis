% ROI = GUIROISELECTION_GUIDE(NAME,COPYROI)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guiROIselection_GUIDE (see VARARGIN)

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% MAIN FUNCTION (created by GUIDE)

function varargout = guiROIselection_GUIDE(varargin)
% GUIROISELECTION_GUIDE M-file for guiROIselection_GUIDE.fig
% GUIROISELECTION_GUIDE, by itself, creates a new GUIROISELECTION_GUIDE or
% raises the existing singleton*.
%
%      H = GUIROISELECTION_GUIDE returns the handle to a new
%      GUIROISELECTION_GUIDE or the handle to the existing singleton*.
%
%      GUIROISELECTION_GUIDE('CALLBACK',hObject,eventData,handles,...)
%      calls the local function named CALLBACK in GUIROISELECTION_GUIDE.M
%      with the given input arguments.
%
%      GUIROISELECTION_GUIDE('Property','Value',...) creates a new
%      GUIROISELECTION_GUIDE or raises the existing singleton*.  Starting
%      from the left, property value pairs are applied to the GUI before
%      guiROIselection_GUIDE_OpeningFcn gets called.  An unrecognized
%      property name or invalid value makes property application stop.  All
%      inputs are passed to guiROIselection_GUIDE_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help guiROIselection_GUIDE

% Last Modified by GUIDE v2.5 10-Mar-2009 12:07:44

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 0;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @guiROIselection_GUIDE_OpeningFcn, ...
                       'gui_OutputFcn',  @guiROIselection_GUIDE_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);

    if nargin && ischar(varargin{1})
       gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end



%% OPENING FUNCTION
function guiROIselection_GUIDE_OpeningFcn(hObject, eventdata, handles, varargin)
% This function checks the inputs and sets up the figure accordingly.

    % gather togglehandle/texthandle/type
    handles.htb = [handles.roi_curve,     handles.roi_line,...
                   handles.roi_sa,        handles.roi_la];
    handles.htx = [handles.roi_curve_htx, handles.roi_line_htx,...
                   handles.roi_sa_htx,    handles.roi_la_htx];
    handles.type = {'curve','line','SA','LA'};

    % load ROI icons
    try
        data = load('ROIicons.mat');
    catch ERR
        data = struct;
    end

    % display icons (or default string if icon is not found)
    tags = {'curveicon','lineicon','SAicon','LAicon'};
    strs = {'C','PL','SA','LA'};
    for k = 1:numel(handles.htb)
        if isfield(data,tags{k})
            set(handles.htb(k),'cdata',data.(tags{k}),'string',[]);
        else
            set(handles.htb(k),'cdata',[],'string',strs{k});
        end
    end


    % check number of inputs
    narginchk(4, 6);

    % first argument should be 'ExternalInitialization'
    if ~ischar(varargin{1}) || ~isequal(varargin{1},'ExternalInitialization')
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'Setup not recognized.');
    else
        varargin = varargin(2:end);
    end

    % parse VARARGIN
    if numel(varargin) < 1 || isempty(varargin{1})
        name = 'ROI';
    else
        name = varargin{1};
    end

    if numel(varargin) < 2 || isempty(varargin{2})
        copydata = struct([]);
    else
        copydata = varargin{2};
    end

    % check inputs
    if ~ischar(name)
        error(sprintf('%s:invalidInput',mfilename),'%s',...
            'First input must be valid string.');
    end

    if ~isempty(copydata)
        tags = {'Name','UID','Type'};
        if ~isstruct(copydata) || ~all(isfield(copydata,tags)) || ...
           ~all(cellfun(@(x)any(strcmpi(x,handles.type)),{copydata.Type}))

            error(sprintf('%s:invalidInput',mfilename),'%s',...
                'Second input must be array of structures containing ',...
                'valid copy ROI information.');
        end
    end

    % load default name to figure
    set(handles.hname,'String',name);


    % load copy data to figure
    % determine "type" handle for each copydata element
    if isempty(copydata)
        buf = 'No ROI loaded...';
        clrbuf = 'No ROI loaded...';

        set(handles.source_copylist,'String',buf,'Value',1);
        set(handles.source_copy,'enable','off');

    else

        % gather strings
        buf = {copydata.Name};

        % gather colored strings
        clrbuf = buf;
        if isfield(copydata,'Color')
            for k = 1:numel(buf)
                if ~isempty(copydata(k).Color) && iscolor(copydata(k).Color)
                    clrbuf{k} = sprintf(...
                        '<HTML><FONT color=%s>%s</FONT></HTML>',...
                        clr2html(copydata(k).Color),clrbuf{k});
                end
            end
        end

        set(handles.source_copylist,'String',buf,'Value',1);
        set(handles.source_copy,'enable','on');

        % corresponding type index into toggle button handle array
        % of each "copydata" element
        idx = cellfun(...
            @(t)find(strcmpi(t,handles.type),1,'first'),...
            {copydata.Type});

        % save handles to "copydata"
        h = num2cell(handles.htb(idx));
        [copydata.handle] = deal(h{:});

    end


    % set button group events
    set(handles.source_group,'SelectionChangeFcn',...
        @(h,evnt)source_group_SelectionChangeFcn(h,evnt,guidata(h)));
    set(handles.type_group,'SelectionChangeFcn',...
        @(h,evnt)type_group_SelectionChangeFcn(h,evnt,guidata(h)));

    % Update handles structure
    handles.output   = [];
    handles.copydata = copydata;
    handles.buf      = buf;
    handles.clrbuf   = clrbuf;
    guidata(handles.hfig,handles);

    % set focus
    uicontrol(handles.hname);

end



%% OUTPUT FUNCTION
% This function waits for the GUI figure 'UserData' to be updated (possible
% values include "complete", "cancel", "cleanup", "close").  The output
% function will then determine the new ROI definition (or empty output) and
% return.
%
% To ensure that the figure is ALWAYS closed, we utilize an onCleanup
% object to run a cleanup routine on success or error

function varargout = guiROIselection_GUIDE_OutputFcn(hObject, eventdata, handles)

    % initialize cleanup object - this will be deleted after this function
    % completes (after success or error), permanently deleting the figure
    cleanupObj = onCleanup(@()hfig_CleanupFcn(handles.hfig));

    % UIWAIT makes figure wait for user response
    % UIRESUME is issued just prior to object deletion
    waitfor(handles.hfig,'UserData');

    % ensure the figure is still valid
    if ~ishandle(handles.hfig)
        error(sprintf('%s:invalidHandle',mfilename),...
            'The figure handle was lost.');
    end

    % get new handles
    % ('handles' input is no longer valid after UIWAIT)
    handles = guidata(handles.hfig);

    % output
    if strcmpi(get(handles.hfig,'UserData'),'complete') && ...
       isfield(handles,'output')
        varargout{1} = handles.output;
    else
        varargout{1} = [];
    end

end



%% CLOSE REQUEST AND CLEANUP FUNCTIONS
% The Close Request function allows the Output function above a chance to
% output without error when the user prematurely closes the GUI figure
% (imitaiting a "cancel" event). The cleanup function is called after the
% Output function exits (with success or error), ensuring the GUI figure is
% permanently deleted.


function hfig_CleanupFcn(hfig)
% The cleanup function simply sets the figure UserData, thus ensuring
% the CloseRequest function will not halt figure deletion, and deletes
% the GUI figure

    if ishandle(hfig)
        set(hfig,'UserData','cleanup');
        delete(hfig);
    end

end


function hfig_CloseRequestFcn(hObject, eventdata, handles)
% If the GUI has not completed (as indiciated by an empty "UserData"
% property), indicate a completion request. The second call to close the
% figure will always succeed (assuming the UserData has not been cleared).

    try
        if isempty(get(handles.hfig,'UserData'))
            set(handles.hfig,'UserData','close');
        else
            delete(handles.hfig);
        end
    catch ERR
        close(handles.hfig,'force');
        rethrow(ERR);
    end
end



%% SOURCE/TYPE FUNCTIONS

function source_group_SelectionChangeFcn(hObject,eventdata,handles)
% If the "new roi" button is selected, the available copy information is
% disabled and the ROI type button group is enabled.
% If the "copy roi" button is selected, the ROI type button group is
% disabled, and the copy list is enabled.

    % "copy" radiobutton update
    if eventdata.NewValue == handles.source_copy
        set(handles.source_copylist,'Enable','on','String',handles.clrbuf);
        setChildProperty(handles.type_group,'Enable','off');

        val = get(handles.source_copylist,'value');
        h = handles.copydata(val).handle;

        handles.newtype = get(handles.type_group,'SelectedObject');
        guidata(handles.hfig,handles);

    % "new" button radio update
    else
        set(handles.source_copylist,'Enable','off','String',handles.buf);
        setChildProperty(handles.type_group,'Enable','on');
        h = handles.newtype;
    end

    % update type display
    typeVirtualCallback(h,handles);

end


function source_copylist_Callback(hObject, eventdata, handles)
% update the ROI type toggle buttons according to the currently
% selected ROI copy.

    val = get(handles.source_copylist,'value');
    typeVirtualCallback(handles.copydata(val).handle,handles);

end


function type_group_SelectionChangeFcn(hObject,eventdata,handles)
% This function highlights the text associated with each
% ROI type toggle button

    % locate text to highlight
    tf = (eventdata.NewValue == handles.htb);

    % set text properties
    set(handles.htx(~tf),'FontWeight','normal',...
        'ForegroundColor',[0 0 0]);
    set(handles.htx(tf), 'FontWeight','bold',...
        'ForegroundColor',[78 101 148]/255);

end


function typeVirtualCallback(hnew,handles)
% This function creates a "virtual" call to the ROI type button group,
% allowing programmatic activation of any toggle button within the group.
% (i.e. setting a toggle button value programmatically does not
% automatically call the corresponding SelectionChangeFcn)

    hold = get(handles.type_group,'SelectedObject');

    set(hnew,'Value',1);
    eventdata = struct('EventName','SelectionChanged',...
        'OldValue',hold,'NewValue',hnew);
    type_group_SelectionChangeFcn(...
        handles.type_group,eventdata,handles);

end



%% OK/CANCEL

function hok_Callback(hObject, eventdata, handles)
% Pressing the OK button creates the proper output data structure and
% notifies the waiting Output function of completion.

    tf = (get(handles.type_group,'SelectedObject') == handles.htb);

    % gather data
    data = struct(...
        'Name',     get(handles.hname,'String'),...
        'Action',   'new',...
        'Type',     handles.type(tf),...
        'UID',      dicomuid,...
        'CopyUID',  []);

    % gather copy instructions
    if get(handles.source_copy,'value')
        data.Action  = 'copy';
        val = get(handles.source_copylist,'value');
        data.CopyUID = handles.copydata(val).UID;
    end

    % save to figure & notify completion
    handles.output = data;
    guidata(handles.hfig,handles);
    set(handles.hfig,'UserData','complete');

end


function hcancel_Callback(hObject, eventdata, handles)
% Pressing the "cancel" button notifies the waiting output function of the
% cancellation request.

    set(handles.hfig,'UserData','cancel');

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



%% END OF FILE=============================================================
