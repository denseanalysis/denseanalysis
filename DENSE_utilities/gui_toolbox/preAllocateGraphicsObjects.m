function objs = preAllocateGraphicsObjects(varargin)
    % preAllocateGraphicsObjects - Initializes an array of empty handles
    %
    %   This is a function to ensure HG1/HG2 compatiblity. In HG1, graphics
    %   handles were often numeric and therefore to create an array of
    %   handles, with some missing you could simply do the following:
    %
    %   H = [gca, NaN, gcf]
    %
    %   As a result, any operations which were performed on the array of
    %   handles would simply ignore the NaN value.
    %
    %   Another thing to do, would be to pre-allocate an array of handles:
    %
    %   A = NaN(1,5);
    %
    %   Then fill this array within a loop
    %
    %   for k = 1:numel(A)
    %       A(k) = axes();
    %   end
    %
    %   In HG2, handles are no longer numeric but are rather objects. As a
    %   result, GraphicsPlaceholder objects should be used rather than
    %   NaNs.
    %
    %   The biggest issue with this is if NaN is used to pre-allocate (as
    %   in HG1), then inside the loop with the creation of axes, all HG2
    %   objects are coerced into being doubles and this causes all sorts of
    %   issues.
    %
    %   MATLAB's builtin gobjects could be used, except in HG1, it returns
    %   zeros rather than NaNs which when applying graphics operations to
    %   these, MATLAB confuses these with the root object (whos handle is
    %   the number 0).
    %
    %   This function eliminates all of this confusion hopefully.
    %
    % USAGE:
    %   objs = preAllocateGraphicsObjects(N)
    %   objs = preAllocateGraphicsObjects(s1, ..., sN)
    %   objs = preAllocateGraphicsObjects(v)
    %   objs = preAllocateGraphicsObjects()
    %
    % INPUTS:
    %   N:      Integer, If only one input is provided, the output is NxN
    %           array of empty objects
    %
    %   s1..sN: Integers, Each input is the size of the dimension. So s1 is
    %           the size of the first dimension, s2 is the size of the
    %           second dimension, etc.
    %
    %   v:      [1 x N] Array, Vector of dimensions.
    %
    %   []:     If no input is provided, the resulting output is empty
    %
    % OUTPUTS:
    %   objs:   Graphics Handles, Size determined by the inputs. On HG1,
    %           they will be all NaNs and on HG2, they will be
    %           GraphicsPlaceholder instances.

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    if feature('usehg2')
        objs = gobjects(varargin{:});
    else
        objs = NaN(varargin{:});
    end
end
