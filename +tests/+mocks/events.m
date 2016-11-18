classdef events < handle

    methods
        function self = events(object)
            if ~ishghandle(object)
                error(sprintf('%s:InvalidHandle', mfilename), ...
                    'Object must be a graphics handle');
            end
            allprops = fieldnames(get(object));

            callbacks = regexp(allprops, '.*Fcn$', 'match');
            callbacks = cat(1, callbacks{:});
        end
    end

end
