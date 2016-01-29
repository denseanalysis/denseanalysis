function [valid_args, other_args] = parseinputs...
    (valid_param, valid_default, varargin)

%PARSEINPUTS find specified parameter values within VARARGIN
%
%INPUTS
%   valid_param.........input parameters to find
%   valid_default.......default input parameter values
%   varargin............variable input arguments
%
%OUTPUT
%   valid_args..........structure of valid input arguments
%   other_args..........additional input arguments
%
%USAGE
%   Creates an output structure VALID_ARGS containing VALID_PARAM
%   fields, initially set to VALID_DEFAULT values. The program then
%   searches VARARGIN for these fields, and replaces default values with
%   user specifed values
%
%   This function finds parameter values within an input set to some
%   arbitrary function. For example, we could locate the 'DisplayRange'
%   field & associated value in the following function:
%
%       IMSHOW(I,'DisplayRange',[0 255])
%
%   We would return a structure VALID_ARGS with the field 'DisplayRange'
%   and the value [0 255]. OTHER_ARGS returns the remaining fields.

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2005.10     Drew Gilliam
%     --modification (creation date unknown)
%   2009.03     Drew Gilliam
%     --modification to accept structure inputs as well as
%       parameter/value pairs
%   2009.04     Drew Gilliam
%     --modification to accept input structure

    % check for proper number of inputs
    narginchk(2, Inf);

    % default argument structure
    if isstruct(valid_param)
        valid_args = valid_param;
        valid_param = fieldnames(valid_args);
    else
        valid_args = cell2struct(valid_default(:)', valid_param(:)', 2);
    end

    % return on empty
    if nargin == 2
        other_args = {};
        return;
    end

    % create empty "other_args" structure
    other_args = struct;

    % parse input arguments
    Nvar = numel(varargin);
    k = 1;
    while k <= Nvar

        % parse structure
        if isstruct(varargin{k})

            tags = fieldnames(varargin{k});
            for ti = 1:numel(tags)
                tf = strcmpi(tags{ti},valid_param);
                if any(tf)
                    valid_args.(valid_param{tf}) = varargin{k}.(tags{ti});
                else
                    tag = tags{ti};
                    other_args.(tag) = varargin{k}.(tags{ti});
                end
            end

            k = k+1;

        % parse param/value pair
        elseif ischar(varargin{k}) && k+1 <= Nvar

            tf = strcmpi(varargin{k},valid_param);
            if any(tf)
                valid_args.(valid_param{tf}) = varargin{k+1};
            else
                other_args.(varargin{k}) = varargin{k+1};
            end
            k = k+2;

        % unrecognized input
        else
           error(sprintf('%s:unrecognizedInput',mfilename),...
               'Param/Value pairs not as expected.');
        end

    end

    % separate "other_args" into param/value pairs
    C = [fieldnames(other_args), struct2cell(other_args)]';
    other_args = C(:)';



    %% OLD CODE
    % % all argument indices
    % other_argind = 1:numel(varargin);
    %
    % % find each valid parameter
    % % note - we assume the associated value is present & in the right form.
    % % any error checking needs to be done outside this function
    % for k = 1:numel(valid_param)
    %
    %     % get current parameter
    %     param = valid_param{k};
    %
    %     % find last parameter in "varargin"
    %     ind = find(strcmpi(varargin,param),1,'last');
    %     if isempty(ind) || ind == numel(varargin)
    %         continue;
    %     end
    %
    %     % get corresponding value
    %     val = varargin{ind+1};
    %
    %     % save value
    %     valid_args.(param) = val;
    %
    %     % remove indices from other_argind
    %     other_argind = setdiff(other_argind,[ind + (0:1)]);
    %
    % end
    %
    % % remove indicies from total set
    % other_args = {varargin{other_argind}};

end



%**************************************************************************
% END OF FILE
%**************************************************************************
