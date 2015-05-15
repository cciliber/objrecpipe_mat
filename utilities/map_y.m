function y_cat = map_y(y, lut)

y_cat = y;

for ii=1:size(lut,1)
    y_cat(y==lut(ii,1)) = lut(ii,2);
end