function id_out = iptaddcallback_mod(h, callback, func_handle)

% This function is a slightly modified version of IPTADDCALLBACK,
% primarily eliminating an error due to objects without the "type" field.
%
% The following changes were made:
% --line 39: error check in try/catch
% --line 62: replace "iptaddcallback" with "iptaddcallback_mod"
% --line 66: replace "iptaddcallback" with "iptaddcallback_mod"
%
% See IPTADDCALLBACK for more information.
%
% --Drew Gilliam

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

iptchecknargin(3, 3, nargin, mfilename);
if (numel(h) ~= 1) || ~ishandle(h)
    error('Images:iptaddcallback:invalidHandle', ...
        'H must be a scalar handle.');
end

iptcheckinput(callback, {'char'}, {'row'}, mfilename, ...
    'CALLBACK', 2);

% Note that the variable func_handle can also be a char or cell array. This is
% primarily for backwards compatibility with users who may have a preexisting
% callback specified in one of these old-style ways. Since we don't advocate
% these programming patterns anymore, the documentation above only refers to
% function handles. The main way a char or cell array callback would come into
% the callback processor is as a preexisting callback that a user set via the
% SET command prior to some subsequent call to IPTADDCALLBACK.
iptcheckinput(func_handle, {'function_handle','char','cell'},...
    {'vector'}, mfilename, 'FUNC_HANDLE', 3);

% check if the figure has an active mode from a UIModeManager.  This would
% happen if a user had clicked on any of the default modes of the figure
% window.  We cannot set figure callbacks if there is an active
% UIModeManager mode, so we error nicely instead of recursing infinitely.
try
    if strcmpi(get(h,'type'),'figure')
        hMan = uigetmodemanager(h);
        if ~isempty(hMan.CurrentMode)
            eid = 'Images:iptaddcallback:activeMode';
            error(eid,'%s%s','iptaddcallback cannot set callbacks on ',...
                'figure with an active mode.');
        end
    end
catch ERR
end

% State for callbackProcessor nested function.  There will be one of
% these callback lists for each H/CALLBACK combination.
callback_list = struct('func', {}, 'id', {});
next_available_id = 1;

% If the currently installed callback is not a function handle to
% callbackProcessor, then remember the currently installed callback,
% set the callback to @callbackProcessor, and then add the current
% callback to the callback list using a recursive call to iptaddcallback.
current_callback = get(h, callback);
if ~( isa(current_callback, 'function_handle') && ...
        strcmp(func2str(current_callback), 'iptaddcallback_mod/callbackProcessor') )

    set(h, callback, @callbackProcessor);
    if ~isempty(current_callback)
        iptaddcallback_mod(h, callback, current_callback);
    end
end

% Get the particular callbackProcessor function handle in use for this
% H/CALLBACK combination and use its 'add' syntax to add the new function
% handle to the callback list.
cpFun = get(h, callback);
id_out = cpFun('add', func_handle);

    function varargout = callbackProcessor(varargin)
        %   id = callbackProcessor('add', func_handle) adds the function
        %   handle to the callback list.
        %
        %   callbackProcessor('delete', id) deletes the callback with the
        %   associated identifier from the callback list.  id is the value
        %   returned by iptaddcallback.  If no matching callback is found,
        %   return silently.
        %
        %   list = callbackProcessor('list') returns the callback list.
        %   This syntax is provided as a debugging and testing aid.
        %
        %   With any other form of input arguments, callbackProcessor
        %   invokes each entry in the callback list in turn, passing the
        %   input arguments along to them.

        if ischar(varargin{1}) && strcmp(varargin{1}, 'add')
            % Syntax: callbackProcessor('add', func_handle)
            callback_list(end+1).func = varargin{2};
            id = next_available_id;
            next_available_id = next_available_id + 1;
            callback_list(end).id = id;
            varargout{1} = id;

        elseif ischar(varargin{1}) && strcmp(varargin{1}, 'delete')
            % Syntax: callbackProcessor('delete', func_handle)
            id = varargin{2};
            for k = 1:numel(callback_list)
                if callback_list(k).id == id
                    callback_list(k) = [];
                    return;
                end
            end

        elseif ischar(varargin{1}) && strcmp(varargin{1}, 'list')
            % Syntax: list = callbackProcessor('list')
            varargout{1} = callback_list;

        else
            % All other syntaxes.

            % Create a local copy of the callback list to avoid issues that
            % arise when a callback actually modifies the list when it is
            % executed.
            local_callback_list = callback_list;
            for k = 1:numel(local_callback_list)
                fun = local_callback_list(k).func;
                if ischar(fun)
                    evalin('base',fun);
                elseif iscell(fun)
                    fun{1}(varargin{:},fun{2:end});
                else
                    fun(varargin{:});
                end
            end
        end

    end % callbackProcessor

end % iptaddcallback
