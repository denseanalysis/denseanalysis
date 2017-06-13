function tf = maskLine(X, Y, C)
    tf = false(size(X));
    for n = 1:numel(C)
        tf = tf | pixelize(C{n}, X, Y);
    end
end
