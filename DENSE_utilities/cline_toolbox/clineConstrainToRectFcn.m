function fcn = clineConstrainToRectFcn(hcline,xlim,ylim)
%CLINECONSTRAINTORECTFCN function to constrain hcline object
%   to a user-specified rectangle
%   Similar to the MATLAB function MAKECONSTRAINTORECT
%
%INPUTS
%   hcline.....cline object
%   xlim.......[1x2] matrix specifying x-limits
%   ylim.......[1x2] matrix specifying y-limits
%
%OUPTUS
%   fcn........position contraint function, suitable for
%              input into the CLINE object POSITIONCONTRAINTFCN
%
%USAGE
%
%   FCN = CLINECONSTRAINTORECT(HCLINE,XLIM,YLIM) creates a position
%   constraint function suitable for CLINE object, constraining the
%   position to lie between the x-limits XLIM and y-limits YLIM.
%   This function is most useful in conjuction with CLINE and IMCLINE,
%   ensuring that various interactive drags do not exceed certain limits.
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors
  
%WRITTEN BY:    Drew Gilliam
%
%MODIFICATION HISTORY:
%   2009.03     Drew Gilliam
%     --creation


    % floating point tolerance
    tol = 1e-10;

    % check number of inputs
    error(nargchk(3,3,nargin));

    % check first input
    if ~isobject(hcline) || ~isequal(class(hcline),'cline')
        error(sprintf('%s:invalidInput',mfilename),...
            'First input must be a valid hcline object.');
    end

    % check additional inputs
    if ~isnumeric(xlim) || ~isnumeric(ylim) || ...
       numel(xlim)~=2 || numel(ylim)~=2 || ...
       xlim(1)>=xlim(2) || ylim(1)>=ylim(2)

        error(sprintf('%s:invalidInput',mfilename),...
            'XLIM and YLIM must be specified as two-element vectors.');
    end

    % test if hcline is currently within limits
    posall = cat(1,hcline.Position{:});
    if any(posall(:,1) < xlim(1) | xlim(2) < posall(:,1)) || ...
       any(posall(:,2) < ylim(1) | ylim(2) < posall(:,2))

        warning(sprintf('%s:hclineNotWithinLimits',mfilename),'%s',...
            'The hcline is not currently within the specified limits. ',...
            'Function may constrain the hcline as expected.');
    end

    % axis lengths
    xlen = diff(xlim);
    ylen = diff(ylim);

    % test constraint function for success
    try
        tmp = constrainFcn(hcline.Position);
    catch ME1
        ERR = MException(sprintf('%s:testFailure',mfilename),...
            'Constraint function test failure.');
        ERR.addCause(ME1);
        ME1.getReport('extended')
        ERR.throw;
    end

    % return access to the internal function
    fcn = @constrainFcn;


    % constraint function
    function newpos = constrainFcn(pos)

        % current position
        poscache = hcline.Position;

        % determine if new positions are shifted versions of old positions
        isshft = false(size(pos));
        if isequal(size(pos),size(poscache))
            for k = 1:numel(pos)
                if ~isempty(pos{k}) && ...
                   isequal(size(pos{k}),size(poscache{k}))

                    shft = poscache{k} - pos{k};
                    dx = abs(shft(:,1)-shft(1,1)) / xlen;
                    dy = abs(shft(:,2)-shft(1,2)) / ylen;
                    isshft(k) = all(dx <= tol & dy <= tol);
                end
            end
        end


        % if all hcline children have been shifted, constrain the
        % ENTIRE hcline bounding box.
        if all(isshft)

            posall = cat(1,pos{:});
            bbox = findBoundingBox(posall(:,1),posall(:,2));
            cbox = rectConstrainToRect(bbox,xlim,ylim);
            shft = cbox - bbox;
            for k = 1:numel(pos)
                pos{k}(:,1) = pos{k}(:,1) + shft(1);
                pos{k}(:,2) = pos{k}(:,2) + shft(2);
            end

        % otherwise, if an internal line has been shifted, contrain just
        % that line bounding box.  Finally, if only some vertices have
        % changed, constrain every point separately.
        else

            for k = 1:numel(pos)
                if isshft(k)
                    bbox = findBoundingBox(pos{k}(:,1),pos{k}(:,2));
                    cbox = rectConstrainToRect(bbox,xlim,ylim);
                    shft = cbox - bbox;
                    pos{k}(:,1) = pos{k}(:,1) + shft(1);
                    pos{k}(:,2) = pos{k}(:,2) + shft(2);
                else
                    pos{k}(:,1) = min(xlim(2),max(xlim(1),pos{k}(:,1)));
                    pos{k}(:,2) = min(ylim(2),max(ylim(1),pos{k}(:,2)));
                end
            end

        end

        % output position
        newpos = pos;

    end

end



%% HELPER FUNCTIONS

function newrect = rectConstrainToRect(rect,xlim,ylim)
%RECTCONSTRAINTORECT constrain rectangle to limits
%   (from MAKECONSTRAINTORECT)
%
%   NEWRECT = RECTCONSTRAINTORECT(RECT,XLIM,YLIM) returns a rectangle
%   NEWRECT defining the [x,y,width,height] constrained within the XLIM
%   and YLIM limits.

    x_min = min( xlim(2) - rect(3), max(rect(1), xlim(1)) );
    y_min = min( ylim(2) - rect(4), max(rect(2), ylim(1)) );
    newrect = [x_min y_min rect(3:4)];

end


function [bbox] = findBoundingBox(x,y)
%FINDBOUNDINGBOX Finds the bounding box for a given set of coordinates.
%   (from MAKECONSTRAINTORECT)
%
%   BBOX = FINDBOUNDINGBOX(X,Y) returns a rectangle in BBOX defining the
%   [X_MIN Y_MIN WIDTH HEIGHT] of the coordinates specified in the
%   vectors X and Y.

    x_min = min(x);
    x_max = max(x);
    y_min = min(y);
    y_max = max(y);
    bbox = [x_min y_min (x_max-x_min) (y_max-y_min)];

end



%% END OF FILE=============================================================
