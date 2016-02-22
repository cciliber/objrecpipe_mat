function a = unroll(c)

if iscell(c)
    a = squeeze(c);
    a = cell2mat(a(:));
else
    a=c(:);
end