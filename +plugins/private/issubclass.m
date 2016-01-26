function bool = issubclass(classname, supertest)
    % Determines if a class is a subclass of the specified superclass
    %
    % USAGE:
    %   bool = issubclass(classname, superclass)
    %
    % INPUTS
    %   classname:  String or meta.class, Indicates the class to use to
    %               perform the issubclass check
    %
    %   superclass: String or meta.class, Indicates the desired superclass
    %               to check for.
    %
    % OUTPUTS:
    %   bool:       Boolean, indicates whether classname is derived from
    %               the specified superclass (TRUE) or not (FALSE).

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    if ischar(classname)
        classname = meta.class.fromName(classname);
    end

    if ischar(supertest)
        supertest = meta.class.fromName(supertest);
    end

    % If this isn't a class or there are no superclasses
    if isempty(classname) || isempty(classname.SuperclassList)
        bool = false;
        return
    end

    if ismember(supertest, classname.SuperclassList)
        bool = true;
        return;
    end

    for ind = 1:numel(classname.SuperclassList)
        super = classname.SuperclassList(ind);
        if issubclass(super, supertest)
            bool = true;
            return;
        end
    end

    bool = false;
end
