function varargout = DENSEanalysis(varargin)
% DENSEANALYSIS M-file for DENSEanalysis.fig
%   DENSEANALYSIS, by itself, creates a new DENSEANALYSIS or
%   raises the existing singleton*.
%
%   H = DENSEANALYSIS returns the handle to a new DENSEANALYSIS or
%   the handle to the existing singleton*.
%
%   DENSEANALYSIS('CALLBACK',hobj,eventData,handles,...) calls the
%   local function named CALLBACK in DENSEANALYSIS.M with the given
%   input arguments.
%
%   DENSEANALYSIS('Property','Value',...) creates a new
%   DENSEANALYSIS or raises the existing singleton*.  Starting from
%   the left, property value pairs are applied to the GUI before
%   DENSEanalysis_OpeningFcn gets called.  An unrecognized property
%   name or invalid value makes property application stop.  All inputs
%   are passed to DENSEanalysis_OpeningFcn via varargin.
%
%   *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%   instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DENSEanalysis

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

% Last Modified by GUIDE v2.5 13-May-2013 13:28:30

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @DENSEanalysis_OpeningFcn, ...
                       'gui_OutputFcn',  @DENSEanalysis_OutputFcn, ...
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
function DENSEanalysis_OpeningFcn(hobj, evnt, handles, varargin)
    if ~isappdata(handles.hfig,'GUIInitializationComplete')
        DENSEsetup;
        handles = initFcn(handles.hfig,mfilename);
    end

    % update the figure
    setappdata(handles.hfig,'GUIInitializationComplete',true);
    handles = resetFcn(handles.hfig);

    % start pointer manager
    iptPointerManager(handles.hfig,'enable')


    % UIWAIT makes DENSEanalysis_v2 wait for user response (see UIRESUME)
    % uiwait(handles.hfig);

end



%% OUTPUT FUNCTION
% Outputs from this function are returned to the command line.
function varargout = DENSEanalysis_OutputFcn(hobj, evnt, handles)
end



%% DELETION FUNCTION
function hfig_DeleteFcn(hobj, evnt, handles)
    % ensure all objects/listeners are deleted
    tags = {'hlisten_sidebar','hsidebar','hpopup',...
        'hdicom','hdense','hanalysis','hdata'};

    for ti = 1:numel(tags)
        try
            h = handles.(tags{ti});
            if isobject(h)
                if isvalid(h), delete(h); end
            elseif ishandle(h)
                delete(h);
            end
        catch ERR
            fprintf('could not delete handles.%s...\n',tags{ti});
        end
    end

    % save some GUI information to disk
    filename = fullfile(userdir(), ['.' mfilename]);
    tags = {'dicompath','matpath','exportpath','roipath'};
    if all(isfield(handles,tags))
        save(filename,'-struct','handles',tags{:});
    end
end



%% LOAD/SAVE

function menu_new_Callback(hobj, evnt, handles)
    loadFcn(handles,'dicom');
end

function menu_open_Callback(hobj, evnt, handles)
    loadFcn(handles,'mat');
end

function menu_save_Callback(hobj, evnt, handles)
    saveFcn(handles,false);
end

function menu_saveas_Callback(hObject, eventdata, handles)
    saveFcn(handles,true);
end

function tool_new_ClickedCallback(hobj, evnt, handles)
    loadFcn(handles,'dicom');
end

function tool_open_ClickedCallback(hobj, evnt, handles)
    loadFcn(handles,'mat');
end

function tool_save_ClickedCallback(hobj, evnt, handles)
    saveFcn(handles,false);
end

function loadFcn(handles,type)

    % proper startpath
    switch type
        case 'dicom', startpath = handles.dicompath;
        otherwise,    startpath = handles.matpath;
    end

    % try to load new data
    try
        [uipath,uifile] = load(handles.hdata,type,startpath);
    catch ERR
        uipath = [];
        errstr = ERR.message;
        h = errordlg(errstr,'','modal');
        ERR.getReport()
        waitfor(h);
    end
    if isempty(uipath), return; end

    % save path to figure
    switch type
        case 'dicom',
            handles.dicompath = uipath;
            handles.matfile = '';
            f = 'new';
        otherwise,
            handles.matpath = uipath;
            handles.matfile = uifile;
            [~,f,~] = fileparts(uifile);
    end
    guidata(handles.hfig,handles);

    % figure name
    set(handles.hfig,'Name',['DENSEanalysis: ' f]);

    % update figure
    resetFcn(handles.hfig);

end


function saveFcn(handles,flag_saveas)
    file = save(handles.hdata,handles.matpath,handles.matfile,flag_saveas);
    if ~isempty(file)
        [p,f,e] = fileparts(file);
        handles.matpath = p;
        handles.matfile = [f e];
        guidata(handles.hfig,handles);
        set(handles.hfig,'Name',['DENSEanalysis: ' f]);
    end
end



%% INITIALIZE GUI
function handles = initFcn(hfig,callingfile)
% The majority of the operations here are concerned with the creation of
% support objects (tabs, playbars, images, etc.) and the setting of
% permanent display parameters (colors, axes properties, listeners).

    % report
    disp('Initializing software...');

    % set some appdata
    setappdata(hfig,'GUIInitializationComplete',false);
    setappdata(hfig,'WorkspaceLoaded',false);

    % gather guidata
    handles = guidata(hfig);



    % LOAD GUI DATA FROM FILE----------------------------------------------
    % Here, we attempt to locate and load saved GUI variables from a known
    % file.  Note if this doesn't work, we ensure that the variables
    % contain some default information.

    % try to load some guiinformation from file
    filename = fullfile(userdir(), ['.' callingfile]);
    tags = {'dicompath','matpath','exportpath','roipath'};

    try
        s = load(filename,'-mat');
    catch ERR
        s = struct;
    end

    for ti = 1:numel(tags)
        if isfield(s,tags{ti})
            val = s.(tags{ti});
        else
            val = [];
        end
        if ~ischar(val) || exist(val,'dir')~=7
            val = pwd;
        end
        handles.(tags{ti}) = val;
    end

    % last accessed file
    handles.matfile = '';


    % CREATE DENSE DATA OBJECT---------------------------------------------
    hdata = DENSEdata;

    dicom_hpanel = uipanel(...
        'parent',handles.hfig,...
        'BorderType','none',...
        'BackgroundColor',get(hfig,'color'));
    hdicom = DICOMviewer(hdata,...
        dicom_hpanel,handles.popup_dicom);

    dense_hpanel = uipanel(...
        'parent',handles.hfig,...
        'BorderType','none',...
        'BackgroundColor',[0 0 0]);
    hdense = DENSEviewer(hdata,...
        dense_hpanel,handles.popup_dense);

    analysis_hpanel = uipanel(...
        'parent',handles.hfig,...
        'BorderType','none',...
        'BackgroundColor',[0 0 0]);
    hanalysis = AnalysisViewer(hdata,...
        analysis_hpanel,handles.popup_analysis);

    hslice = SliceViewer(hdata,handles.popup_slice);
    harial = ArialViewer(hdata,handles.popup_arial);

    % Turn off all listeners
    items = {hdense, hdicom, hanalysis, hslice, harial};
    cellfun(@(x)x.disable('redraw'), items);

    % CREATE TAB OBJECTS---------------------------------------------------

    % initialize the SIDETABS object
    hsidebar = sidetabs(handles.hfig);
    hsidebar.addTab({'DICOM','data'},dicom_hpanel);
    hsidebar.addTab({'DENSE','data'},dense_hpanel);
    hsidebar.addTab({'DENSE','analysis'},analysis_hpanel);
    hsidebar.TabWidth  = 40;
    hsidebar.TabHeight = 70;

    % initialize POPUPTABS object
    hpopup = popuptabs(handles.hfig);
    hpopup.addTab('DICOM controls',handles.popup_dicom);
    hpopup.addTab('DENSE controls',handles.popup_dense);
    hpopup.addTab('Arial View',handles.popup_arial);
    hpopup.addTab('Slice View',handles.popup_slice);
    hpopup.addTab('Analysis controls',handles.popup_analysis);
    hpopup.TabWidth = 200;
    hpopup.TabHeight = 20;

    % determine sidetabs/popuptabs position options
    pos = getpixelposition(hpopup);
    hsidebar.DistanceToPanel = pos(3);
    hpopup.LeftOffset = hsidebar.Width;


    % initialize SIDETABS listener
    hlisten_sidebar = addlistener(hsidebar,...
        'SwitchTab',@(varargin)switchstate(handles.hfig));
    hlisten_sidebar.Enabled = false;


    % ZOOM/PAN/ROTATE BEHAVIOR---------------------------------------------

    % zoom/pan/rotate objects
    hzoom = zoom(handles.hfig);
    hpan  = pan(handles.hfig);
    hrot  = rotate3d(handles.hfig);

    % contrast tool
    hcontrast = contrasttool(handles.hfig);
    hcontrast.addToggle(handles.htoolbar);
    hchild = get(handles.htoolbar,'children');
    set(handles.htoolbar,'children',hchild([2:3 1 4:end]));


    % default renderers
    if feature('hgusingmatlabclasses')
        handles.renderer = repmat({'opengl'},[3 1]);
    else
        handles.renderer = repmat({'painters'},[3 1]);
    end
    handles.LastTab = 1;


    % CLEANUP--------------------------------------------------------------

    % save new objects to figure
    handles.hdata               = hdata;
    handles.hsidebar            = hsidebar;
    handles.hlisten_sidebar     = hlisten_sidebar;
    handles.hpopup              = hpopup;
    handles.dicom_hpanel        = dicom_hpanel;
    handles.hdicom              = hdicom;
    handles.dense_hpanel        = dense_hpanel;
    handles.hdense              = hdense;
    handles.analysis_hpanel     = analysis_hpanel;
    handles.hanalysis           = hanalysis;
    handles.hslice              = hslice;
    handles.harial              = harial;
    handles.hzoom               = hzoom;
    handles.hpan                = hpan;
    handles.hrot                = hrot;
    handles.hcontrast           = hcontrast;




    % some of the toolbar items have strange tags, so lets gather 'em up.
    handles.htools = allchild(handles.htoolbar);

    % link some menu enable to tool enable
    hlink = linkprop([handles.tool_new,handles.menu_new],'Enable');
    setappdata(handles.tool_new,'linkMenuToolEnable',hlink);
    hlink = linkprop([handles.tool_open,handles.menu_open],'Enable');
    setappdata(handles.tool_open,'linkMenuToolEnable',hlink);
    hlink = linkprop([handles.tool_save,...
        handles.menu_save,handles.menu_saveas],'Enable');
    setappdata(handles.tool_save,'linkMenuToolEnable',hlink);

    % save all data to the figure
    guidata(handles.hfig,handles);

    set(handles.hfig, 'ResizeFcn', @(s,e)resizeFcn(s));
end

function resizeFcn(hfig)
    h = guidata(hfig);

    h.hsidebar.redraw();
    h.hpopup.redraw();

    % Redraw only the visible tab because the others will automatically
    % redraw when the tab is changed
    objs = {h.hdicom, h.hdense, h.hanalysis};
    objs{h.hsidebar.ActiveTab}.redraw();
end


%% RESET GUI
function handles = resetFcn(hfig)
% this function ensures the state of the GUI matches the data loaded into
% the DENSEdata object (handles.hdata)

    % gather gui data
    handles = guidata(hfig);

    % disable zoom/pan/rot
    handles.hzoom.Enable = 'off';
    handles.hpan.Enable  = 'off';
    handles.hrot.Enable  = 'off';

    % deactivate listeners
    handles.hlisten_sidebar.Enabled   = false;

    % reset tabs to initial state
    handles.hsidebar.ActiveTab      = 1;
    handles.hsidebar.Enable(2:end)  = {'off'};
    handles.hpopup.Visible(:)       = {'on'};
    handles.hpopup.Visible([2 end]) = {'off'};
    handles.hpopup.Enable(:)        = {'off'};

    % reset renderer
    handles.renderer(:) = {'painters'};
    handles.LastTab = 1;

    % disable toolbar tools
    set(handles.htools,'Enable','off');
    wild = {'*open','*new'};
    tf = cellfun(@(tag)any(strwcmpi(tag,wild)),get(handles.htools,'tag'));
    set(handles.htools(tf),'Enable','on');


    % quit if no data to display
    if numel(handles.hdata.seq) == 0
        handles.hsidebar.redraw();
        handles.hpopup.redraw();
        return
    end

    % enable/open popups
    handles.hpopup.Enable(:) = {'on'};
    handles.hpopup.IsOpen(:) = 1;

    % enable sidetabs
    handles.hsidebar.Enable(1:3) = {'on'};

    % activate listeners
    handles.hlisten_sidebar.Enabled = true;

    % activate/deactivate stuff
    switchstate(handles.hfig)

    % trigger resize functions
    % (panels are resized via "hsidebar" object)
    handles.hsidebar.redraw();
    handles.hpopup.redraw();

end


%% SWITCH TAB (DICOM/DENSE/ANALYSIS)
function switchstate(hfig)
    handles = guidata(hfig);

    % current tab
    tabidx = handles.hsidebar.ActiveTab;

    % store current renderer
    handles.renderer{handles.LastTab} = get(handles.hfig,'renderer');

    wild = {'*zoom*','*pan','*rotate*','tool*','*save*','*contrast*'};
    tf = cellfun(@(tag)any(strwcmpi(tag,wild)),get(handles.htools,'tag'));
    set(handles.htools(tf),'Enable','on');

    handles.hdicom.ROIEdit = 'off';
    handles.hdense.ROIEdit = 'off';
    set(handles.tool_roi,'State','off','enable','on');


    switch tabidx

        case 1

            tf = logical([1 0 1 1 0]);
            handles.hpopup.Visible( tf) = {'on'};
            handles.hpopup.Visible(~tf) = {'off'};

            handles.hanalysis.Enable = 'off';
    %         suspend(handles.hdense);
    %         restore(handles.hdicom);

            % transfer slice/arial to DICOM viewer
            handles.hdense.SliceViewer = [];
            handles.hdense.ArialViewer = [];
            handles.hdicom.SliceViewer = handles.hslice;
            handles.hdicom.ArialViewer = handles.harial;
            redraw(handles.hdicom);

        case 2
            tf = logical([0 1 1 1 0]);
            handles.hpopup.Visible( tf) = {'on'};
            handles.hpopup.Visible(~tf) = {'off'};

            handles.hanalysis.Enable = 'off';
    %         suspend(handles.hdicom);
    %         restore(handles.hdense);

            % transfer slice/arial to DENSE viewer
            handles.hdicom.SliceViewer = [];
            handles.hdicom.ArialViewer = [];
            handles.hdense.SliceViewer = handles.hslice;
            handles.hdense.ArialViewer = handles.harial;

            redraw(handles.hdense);

        case 3

            tf = logical([0 0 0 0 1]);
            handles.hpopup.Visible( tf) = {'on'};
            handles.hpopup.Visible(~tf) = {'off'};
            handles.hanalysis.Enable = 'on';
            set(handles.tool_roi,'enable','off');
            redraw(handles.hanalysis);

    end


    set(handles.hfig,'renderer',handles.renderer{tabidx});
    handles.LastTab = tabidx;
    guidata(hfig,handles);

end


%% ROI TOOL CALLBACK
function tool_roi_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to tool_roi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    state = get(handles.tool_roi,'State');

    if handles.hsidebar.ActiveTab == 2
        handles.hdense.ROIEdit = state;
    else
        handles.hdicom.ROIEdit = state;
    end
end


%% MENU: EXPORT UIMENU SELECT
function menu_export_Callback(hObject, eventdata, handles)

    switch handles.hsidebar.ActiveTab
        case 1, h = handles.hdicom;
        case 2, h = handles.hdense;
        case 3, h = handles.hanalysis;
    end

    imgen = h.isAllowExportImage;
    viden = h.isAllowExportVideo;
    if h == handles.hanalysis
        maten = h.isAllowExportMat;
        exlen = h.isAllowExportExcel;
    else
        maten = false;
        exlen = false;
    end

    if h == handles.hdense
        roien = isAllowExportROI(handles.hdata,h.ROIIndex);
    else
        roien = false;
    end


    strs  = {'off','on'};
    imgen = strs{imgen+1};
    viden = strs{viden+1};
    maten = strs{maten+1};
    exlen = strs{exlen+1};
    roien = strs{roien+1};


    set(handles.menu_exportimage,'enable',imgen);
    set(handles.menu_exportvideo,'enable',viden);
    set(handles.menu_exportmat,  'enable',maten);
    set(handles.menu_exportexcel,'enable',exlen);
    set(handles.menu_exportroi,  'enable',roien);

end


%% MENU: EXPORT IMAGE/VIDEO
function menu_exportimage_Callback(hObject, eventdata, handles)
    switch handles.hsidebar.ActiveTab
        case 1, h = handles.hdicom;
        case 2, h = handles.hdense;
        case 3, h = handles.hanalysis;
    end

    file = h.exportImage(handles.exportpath);
    if isempty(file), return; end

    [p,f,e] = fileparts(file);
    handles.exportpath = p;
    guidata(handles.hfig,handles);

end

function menu_exportvideo_Callback(hObject, eventdata, handles)
    switch handles.hsidebar.ActiveTab
        case 1, h = handles.hdicom;
        case 2, h = handles.hdense;
        case 3, h = handles.hanalysis;
    end

    file = h.exportVideo(handles.exportpath);
    if isempty(file), return; end

    [p,f,e] = fileparts(file);
    handles.exportpath = p;
    guidata(handles.hfig,handles);

end


%% MENU: EXPORT MAT/EXCEL/ROI
function menu_exportmat_Callback(hObject, eventdata, handles)
    file = handles.hanalysis.exportMat(handles.exportpath);
    if isempty(file), return; end

    [p,f,e] = fileparts(file);
    handles.exportpath = p;
    guidata(handles.hfig,handles);
end

function menu_exportexcel_Callback(hObject, eventdata, handles)
    file = handles.hanalysis.exportExcel(handles.exportpath);
    if isempty(file), return; end

    [p,f,e] = fileparts(file);
    handles.exportpath = p;
    guidata(handles.hfig,handles);
end

function menu_exportroi_Callback(hObject, eventdata, handles)
    path = handles.hdense.exportROI(handles.roipath);
    if isempty(path), return; end

    handles.roipath = path;
    guidata(handles.hfig,handles);
end


%% MENU: ANALYSIS UIMENU SELECT
function menu_analysis_Callback(hObject, eventdata, handles)
    enable = 'off';
    if handles.hsidebar.ActiveTab == 2
        didx  = handles.hdense.DENSEIndex;
        ridx  = handles.hdense.ROIIndex;
        frame = handles.hdense.frame;
        if handles.hdata.isAllowAnalysis(didx,ridx,frame)
            enable = 'on';
        end
    end
    set(handles.menu_runanalysis,'enable',enable)

end


%% MENU: RUN ANALYSIS
function menu_runanalysis_Callback(hObject, eventdata, handles)
    didx = handles.hdense.DENSEIndex;
    ridx = handles.hdense.ROIIndex;
    frame = handles.hdense.Frame;
    spdata = handles.hdata.analysis(didx,ridx,frame);
    if isempty(spdata), return; end
    handles.hsidebar.ActiveTab = 3;
end


%% MENU: ANALYSIS DISPLAY OPTIONS
function menu_analysisopt_Callback(hObject, eventdata, handles)
    handles.hanalysis.strainoptions;
end


%% MENU: ABOUT THE PROGRAM
function menu_about_Callback(hObject, eventdata, handles)

    screenpos = get(0,'screensize');
    sz = [400 400];
    pos = [(screenpos(3:4)-sz)/2,sz];

    hfig = figure('windowstyle','modal','resize','off',...
        'position',pos,'Name','About DENSEanalysis','NumberTitle','off');
    I = imread('DENSEabout.png');
    imshow(I,[],'init','fit');
    set(gca,'units','normalized','position',[0 0 1 1]);

end


%% MENU: TEST FUNCTION
function menu_test_Callback(hobj, evnt, handles)
%     handles.hdata.roi
%     handles.hdense.ROIIndex
%     seq = handles.hdata.seq;
%     save('seqdata.mat','seq')


hdata = handles.hdata
hdata.roi(end).IsClosed

return


%
% vert = data.fv.vertices';
% vert
%     dX =
%
%     for k = 1:
%     dX = fnvalmod(hdata.spl.spldx,vert);
%     dY = fnvalmod(hdata.spl.spldy,vert);
%     dZ = fnvalmod(hdata.spl.spldz,vert);

%     dxbulk = mean(dx);
%     dybulk = mean(dy(mask0));
%     dzbulk = mean(dz(mask0));
%     dx = dx - dxbulk;
%     dy = dy - dybulk;
%     dz = dz - dzbulk;


    return

    handles.dicom_hpanel
    handles.hdicom.DisplayParent

    set(handles.dicom_hpanel,'BackgroundColor',rand(1,3))
%     pfig = getpixelposition(handles.hfig);
%     setpixelposition(handles.hfig,pfig + [10 10 0 0]);
    return

    handles.hanalysis.straindata
    handles.hanalysis.straindata.fvpix
    handles.hanalysis.straindata.fv

    fv = handles.hanalysis.straindata.fvpix
    mn = min(fv.vertices,[],1);
    mx = max(fv.vertices,[],1);
    dsprng = [mn-5; mx+5];

    hfig = figure('colormap',jet(256));
    hax  = axes('parent',hfig,'dataaspectratio',[1 1 1],...
        'xlim',dsprng(:,1),'ylim',dsprng(:,2),...
        'zlim',[0 1],'box','on','ydir','reverse',...
        'clim',[-180 180]);

%     val = fv.orientation;
%     rng =

    obj = handles.hanalysis;

    Isz = size(handles.hdata.spl.Xwrap(:,:,1));
    Nfr = size(handles.hdata.spl.Xwrap,3);

    x = 1:Isz(2);
    y = 1:Isz(1);
    [X,Y,Z] = meshgrid(x,y,0);

    mask0 = handles.hdata.spl.MaskFcn(...
        X,Y,handles.hdata.spl.RestingContour);
    Npts = sum(mask0(:));

    X = X(mask0);
    Y = Y(mask0);


    origin  = obj.straindata.PositionA;
    posB    = obj.straindata.PositionB;
    flag_clockwise = obj.straindata.Clockwise;

    theta0 = atan2(posB(2)-origin(2),posB(1)-origin(1));
    theta  = atan2(Y-origin(2),X-origin(1)) - theta0;
    if ~flag_clockwise, theta = -theta; end

    theta(theta<0) = theta(theta<0) + 2*pi;

    theta = theta*180/pi;
    set(hax,'clim',[min(theta),max(theta)]);
%     theta = obj.straindata.fvpix.orientation;
%
%         % transform orientation into 0->2pi angle
%
%     theta0*180/pi

%         if ~flag_clockwise, theta = -theta; end
%         theta = theta - theta0;

    hpatch = patch('vertices',fv.vertices,...
        'faces',fv.faces,'parent',hax,...
        'facecolor','flat','edgecolor','none',...
        'facevertexcdata',theta);
    colorbar
%     [handles.hdata.seq.ImagePositionPatient]
%     [handles.hdata.seq.ImageOrientationPatient]
%     handles.hdata.seq.sliceid




% %     [val,id] = unique([handles.hdata.seq.sliceid]);
% %     extents = cat(3,handles.hdata.seq(id).extents3D);
% %
% %
% %     mn = min(extents(:,:),[],1);
% %     mx = max(extents(:,:),[],1);
% %     hfig = figure;
% %     hax  = axes('parent',hfig,'dataaspectratio',[1 1 1],...
% %         'xlim',[mn(1),mx(1)],'ylim',[mn(2),mx(2)],...
% %         'zlim',[mn(3),mx(3)],'box','on');
% %     view(hax,3)
% %     axis vis3d
% %     for k = 1:size(extents,3)
% %         patch('vertices',extents(:,:,k),'faces',1:4,'facecolor','none',...
% %             'edgecolor','r');
% %     end


%     hax =
end


%% END OF FILE=============================================================
