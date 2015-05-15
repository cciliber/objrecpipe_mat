function [i1,i2] = LMdetectduplicates(D1, D2, HOMEIMAGES1, HOMEIMAGES2)
%  Each pair (i1(n), i2(n)) is a duplicate.


R = 1; % radius to decide that two images are the same

[gist1, param] = LMgist(D1, HOMEIMAGES1);
[gist2, param] = LMgist(D2, HOMEIMAGES2);

i1 = [];
i2 = [];
for n = 1:length(D1);
    [m, dist12] = LMgistquery(gist1(n,:), gist2);
    k = find(dist12<R); 
    if ~isempty(k)
        m = m(k);
        i1 = cat(1,i1,1+m*0);
        i2 = cat(1,i1,m);
    end
end
