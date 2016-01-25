% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

clear all, close all, clear classes; drawnow
% function ex_imcline2

FLAG_test = 3;

if FLAG_test==1
    %% FIRST TEST

    % position & cLINE object
    pos = [1 0; 0 -1; -1 0; 0 1];
    hcline = cline({pos,0.5*pos});

    % constrained cLINE position
    hcline.PositionConstraintFcn = ...
        clineConstrainToRectFcn(hcline,[-2 2],[-2 2]);

    % initialize figure & axes
    hfig = figure;
    hax(1) = subplot(1,2,1);
    axis equal, axis([-2 2 -2 2]), box on
    hax(2) = subplot(1,2,2);
    axis equal, axis([-2 2 -2 2]), box on
    linkaxes(hax);

    % create interactive tools
    h(1) = imcline(hcline,hax(1));
    h(2) = imcline(hcline,hax(2));

    [h(1).Appearance(1:2).Color] = deal('r','g');
    [h(1).Appearance(1:2).MarkerFaceColor] = deal('r','g');
    h(1).IndependentDrag{2} = 'on';

    [h(2).Appearance(1:2).Color] = deal('r','g');
    [h(2).Appearance(1:2).MarkerFaceColor] = deal('r','g');
    h(2).IndependentDrag{2} = 'on';

    % start interactive edit
    iptPointerManager(hfig,'enable');


    return


    % initialize figures
    hfig = figure;
    hax(1) = subplot(1,2,1);
    axis equal, axis([-2 2 -2 2]), box on
    hax(2) = subplot(1,2,2);
    axis equal, axis([-2 2 -2 2]), box on

    hcline = getcline(hax(1));
    hcline.PositionConstraintFcn = ...
        makeConstrainToRectFcn('impoly',[-2 2],[-2 2]);

    h(1) = imcline(hcline,hax(1));
    % h.setResolution(0.01);
    h(2) = imcline(hcline,hax(2));
    % h.setResolution(0.01);


    [h.ContextOpenClosed] = deal('off');


    linkaxes(hax);
    iptPointerManager(hfig,'enable');


elseif FLAG_test==2
    %% SECOND TEST

    N = 8;
    theta = linspace(-pi,pi,N+1);
    theta = theta(1:end-1);

    pos = 1*[cos(theta); sin(theta)]';
    hep = cline(pos);

    pos = 0.5*[cos(theta); sin(theta)]';
    hen = cline('position',pos);

    fcn = makeConstrainToRectFcn('impoly',[-2 2],[-2 2]);
    hep.PositionConstraintFcn = fcn;
    hen.PositionConstraintFcn = fcn;


    msz = [1 1];
    hax = NaN(prod(msz),1);
    hfig = figure;

    for k = 1:prod(msz)
        hax(k) = subplot(msz(1),msz(2),k);
        axis equal, axis([-2 2 -2 2]), box on

        h1 = imcline(hep,hax(k));
%         h1.setAppearance('color','r','markerfacecolor','r');
%         h.setHighlight('color','b');
%         h.setResolution(0.01);

        h2 = imcline(hen,hax(k));
%         h2.setAppearance('color','g','markerfacecolor','g');
%         h.setHighlight('color','b');
%         h.setResolution(0.01);

    end
    linkaxes(hax);

    iptPointerManager(hfig,'enable')




elseif FLAG_test == 3
    %% THIRD TEST

    N = 8;
    theta = linspace(-pi,pi,N+1);
    theta = theta(1:end-1);

    posep = 1*[cos(theta); sin(theta)]';
    posen = 0.5*[cos(theta); sin(theta)]';
    hcline = cline({posep,posen});

%     fcn = makeConstrainToRectFcn('impoly',[-2 2],[-2 2]);
%     hcline.PositionConstraintFcn = {fcn,fcn};

    fcn = clineConstrainToRectFcn(hcline,[-2 2],[-2 2]);
    hcline.PositionConstraintFcn = fcn;

    msz = [1 1];
    hax = NaN(prod(msz),1);
    hfig = figure;

    for k = 1:prod(msz)
        hax(k) = subplot(msz(1),msz(2),k);
        axis equal, axis([-2 2 -2 2]), box on
        set(hax(k),'color','k')

        h(k) = imcline(hcline,hax(k));
        h(k).Enable = 'on';
        h(k).Visible = 'on';
        h(k).IndependentDrag{2} = 'on';

%         [h1.Appearance(1:2).Color] = deal('r',[0 .7 0]);
%         [h1.Appearance(1:2).MarkerFaceColor] = deal('r',[0 .7 0]);
%         h1.IndependentDrag{2} = 'on';

%         h1.Enable = 'off';
%         h1.setAppearance('color','r','markerfacecolor','r');
% %         h.setHighlight('color','b');
% %         h.setResolution(0.01);
%
%         h2 = imcline(hen,hax(k));
%         h2.setAppearance('color','g','markerfacecolor','g');
%         h.setHighlight('color','b');
%         h.setResolution(0.01);

    end
    linkaxes(hax);


%     hlisten = addlistener(h(1),'DragEvent',@(src,evnt)test(evnt));

    iptPointerManager(hfig,'enable')


end


% end

%
% function test(evnt)
%     if strcmpi(evnt.Type,'complete')
%         evnt
%
%     end
