function f = getFigureClient(hfig)
    % getFigureClient - Get the underlying java handle to the figure client
    %
    % USAGE:
    %   f = getFigureClient(hfig)
    %
    % INPUTS:
    %   hfig:   Handle, handle to the figure
    %
    % OUTPUTS:
    %   f:      Object, a java object of type FigureHG1Mediator or similar

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 Jonathan Suever

    warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved')
    jFrame = get(handle(hfig), 'JavaFrame');

    try
        if isa(hfig, 'double') || isa(handle(hfig), 'figure')
            f = jFrame.fHG1Client;
        else
            f = jFrame.fHG2Client;
        end
    catch
        f = jFrame.fFigureClient;
    end
end
