function [b,ndx,pos] = unique_struct(a,tags,occurance)

%UNIQUE_STRUCT locate unique structures from a vector of structures, based
%   on user-defined fields of interest.
%
%INPUTS
%   a...........vector of structures
%   tags........structure fieldnames of interest
%   occurance...'first' or 'last' occurance of unique values in 'a'
%
%OUTPUTS
%   b.....unique structures
%   ndx...indices into 'a' representing unique structures
%   pos...unique id of each element in 'a'
%
%USAGE
%   B = UNIQUE_STRUCT(A,TAGS) locates the unique structures B within the
%   array of structures A, defining uniqueness via the structure fields
%   TAGS. Note that TAGS defaults to FIELDNAMES(A).  Note that
%   FIELDNAMES(B) == TAGS (assuming all TAGS exist within A).
%
%   [B,NDX,POS] = UNIQUE_STRUCT(...) optionally returns index vectors
%   NDX and POS such that B = A(NDX) and A = B(POS) for all fields
%   represented within TAGS.
%
%   [B,NDX,POS] = UNIQUE_STRUCT(...,OCCURANCE) alternatively define the
%   index vector NDX to refer to the 'first' or 'last' occurance of each
%   unique structure in A (default to 'last');
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation


    %% SETUP

    % check for vector of structures
    if ~isstruct(a) || ndims(a) ~= 2 || ~any(size(a)==1)
        error(sprintf('%s:inputerror',mfilename),...
            'First input must be a vector of structures.');
    end

    % all structure fields
    alltags = fieldnames(a);

    % default tags
    if nargin < 2 || isempty(tags), tags = alltags; end
    if ischar(tags), tags = {tags}; end
    if ~iscellstr(tags)
        error(sprintf('%s:inputerror',mfilename),...
            '''tags'' input must be cell array of strings.');
    end

    % valid test fields
    tf = ismember(tags,alltags);
    tags = tags(tf);
    if isempty(tags)
        error(sprintf('%s:inputerror',mfilename),...
            'No valid structure fields to test.');
    end

    % default occurance
    if nargin < 3 || isempty(occurance), occurance = 'last'; end

    tf = strcmpi(occurance,{'first','last'});
    if ~any(tf)
        error(sprintf('%s:inputerror',mfilename),...
            'The ''occurance'' input must be ''first'' or ''last''.');
    end
    flaglast = tf(2);

    % input length
    N = numel(a);



    %% LOCATE UNIQUE STRUCTURES

    % special case: single input
    if N == 1
        b   = copystruct(a,tags);
        ndx = 1;
        pos = 1;
        return;
    end

    % initialize output
    b   = repmat(cell2struct(cell(numel(tags),1),tags),[N,1]);
    ndx = zeros(N,1);
    pos = zeros(N,1);

    % number of unique groups
    cnt = 0;

    % cycle through all input values once
    for k = 1:N

        % the first index is always "unique"
        if k == 1
            b(1) = copystruct(a(1),tags);
            ndx(1) = 1;
            pos(1) = 1;
            cnt = 1;

        % for all remaining indices into "a", compare with exisiting
        % unique values.  If the current value is unique, update outputs.
        else

            % new value flag
            newval = true;

            % cycle through existing unique values.  If we find a match,
            % save to the "pos" value.  If we're recording the last
            % occurance, save to "ndx" value.
            for i = 1:cnt
                if isequalstruct(b(i),a(k),tags);
                    pos(k) = i;
                    newval = false;
                    if flaglast, ndx(i) = k; end
                    break;
                end
            end

            % if the current value is unique, update the outputs
            % and increment the unique counter.
            if newval
                cnt = cnt+1;
                b(cnt) = copystruct(a(k),tags);
                ndx(cnt) = k;
                pos(k) = cnt;
            end

        end
    end

    % truncate the outputs
    b   = b(1:cnt);
    ndx = ndx(1:cnt);

end



%% HELPER FUNCTION: COPY FIELDS OF STRUCTURE
function b = copystruct(a,tags)
    b = struct;
    for ti = 1:numel(tags)
        b.(tags{ti}) = a.(tags{ti});
    end
end



%% END OF FILE-------------------------------------------------------------
