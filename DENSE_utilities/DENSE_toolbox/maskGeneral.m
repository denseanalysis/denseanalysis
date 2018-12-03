function tf = maskGeneral(X, Y, C)
	% % Previous code before 11/30/2018 resulted in a filled chamber for
	% % LVLongAxis type contours
 %    tf = false(size(X));
 %    for n = 1:numel(C)
 %        tf = tf | inpolygon(X, Y, C{n}(:,1), C{n}(:,2));
 %    end
 	% New version as of 11/30/2018 - all 8 contour types
 	% (including dual ventricle types from the dense3D_plugin)
 	% work correctly after this update - EDC
 	C = cat(1,C{:});
 	tf = inpolygon(X, Y, C(:,1), C(:,2));
end
