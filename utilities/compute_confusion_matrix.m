function confus = compute_confusion_matrix(y, ypred)

nclasses = length(unique(y));

confus = zeros(nclasses);

idx = sub2ind([nclasses, nclasses], y, ypred);
confus = vl_binsum(confus, ones(size(idx)), idx);
