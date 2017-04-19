function tf = maskGeneral(X, Y, C)
    tf = false(size(X));
    for n = 1:numel(C)
        tf = tf | inpolygon(X, Y, C{n}(:,1), C{n}(:,2));
    end
end
