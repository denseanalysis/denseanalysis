function result = ruodialog()
    % ruidialog - Research Use Only dialog
    %
    %   Displays a disclaimer about the software being for research use
    %   only and requires the user to agree.
    %
    % USAGE:
    %   result = ruodialog()
    %
    % OUTPUTS:
    %   result: Logical, Indicates whether the user selected "I understand"
    %           (true) or not (false)

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    d = dialog( ...
        'Name',     'DENSEanalysis - Research Use Only', ...
        'Position', [0 0 300 150], ...
        'Visible',  'off');

    fc = uiflowcontainer('v0', ...
        'FlowDirection',    'topdown', ...
        'Parent',           d);


    message = {
        'DENSEanalysis is not certified as a medical device for primary '
        'diagnosis and is not intended for clinical diagnosis or patient '
        'management. This software is distributed for research use only.'
    };

    message = cat(2, message{:});


    uicontrol( ...
        'Parent',   fc, ...
        'Style',    'text', ...
        'String',   message, ...
        'FontSize', 16);

    btn = uicontrol(...
        'Parent',   fc, ...
        'String',   'I Understand', ...
        'Callback', @(s,e)callback(s));

    set(btn, 'HeightLimits', [40 40])

    % Center the figure and display it
    movegui(d, 'center');
    set(d, 'Visible', 'on')

    % Wait for the user and the return the result
    waitfor(d, 'UserData');

    if ~ishghandle(d)
        result = false;
    else
        result = get(d, 'UserData');
        delete(d);
    end

    function callback(src)
        set(ancestor(src, 'figure'), 'UserData', 1)
    end
end
