function a = unroll(c)

a = squeeze(c);
a = cell2mat(a(:));