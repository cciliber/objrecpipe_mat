function Ypred = kNNClassify_multiclass(Xtr, Ytr, k, Xte)
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

    n = size(Xtr,1);
    m = size(Xte,1);
    
    k = min(k,n);
    
    %tic
    
    D = sum(Xtr.*Xtr,2)*ones(1,m) - 2*(Xtr*Xte') + ones(n,1)*(sum(Xte.*Xte,2)');
    
    [~, I] = sort(D);
    idx = I(1:k, :);
    if k==1
        Ypred = mode(Ytr(idx)',1)';
    else
        Ypred = mode(Ytr(idx),1)';
    end
    
    %toc
end

