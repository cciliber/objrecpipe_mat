function [acc, C] = compute_accuracy(y, ypred, acc_method)
 
[classes, ~, ~] = unique(y);
n_classes = length(classes);

n_frames = size(y,1);

if strcmp(acc_method, 'carlo')
    
    C = accumarray([y, ypred], ones(n_frames,1), [n_classes,n_classes]);
    acc = sum(diag(C)) / sum(C(:));
    
elseif strcmp(acc_method, 'gurls')
    
    tmp_acc = zeros(1,n_classes);
    for i = 1:n_classes,
        tmp_acc(i) = sum((y == classes(i)) & (ypred == classes(i)))/(sum(y == classes(i)) + eps);
    end
    acc = mean(tmp_acc);
end

end

