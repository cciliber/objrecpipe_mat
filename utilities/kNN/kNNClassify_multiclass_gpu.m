function Ypred_gpu = kNNClassify_multiclass_gpu(Xtr_gpu, Ytr_gpu, k, Xte_gpu)
%
% function Y_pred = kNNClassify(Xtr, Ytr,  k, Xte)
%
% INPUT PARAMETERS
%   Xtr training input
%   Ytr training output 
%   k number of neighbours
%   Xte test input
% 
% OUTPUT PARAMETERS
%   Ypred estimated test output
%
% EXAMPLE
%   Ypred=kNNClassify(Xtr,Ytr,5,Xte);

n = size(Xtr_gpu,1);
m = size(Xte_gpu,1);

k = min(k, n);

%tic

D_gpu = sum(Xtr_gpu.*Xtr_gpu,2)*ones([1,m], 'double', 'gpuArray') + ones([n,1], 'double', 'gpuArray')*sum(Xte_gpu.*Xte_gpu,2)' - 2*(Xtr_gpu*Xte_gpu');

[~, I] = sort(D_gpu);
idx = I(1:k, :);
if k==1
    Ypred_gpu = mode(Ytr_gpu(idx)',1)';
else
    Ypred_gpu = mode(Ytr_gpu(idx),1)';
end

%toc
end

