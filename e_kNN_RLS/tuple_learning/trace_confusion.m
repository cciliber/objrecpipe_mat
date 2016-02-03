function [accuracy,confus] = trace_confusion(Ytrue, Ypred, T)

    if size(Ytrue,2)>1
        [~,Ytrue]=max(Ytrue,[],2); 
    end
    
    if size(Ypred,2)>1
        [~,Ypred]=max(Ypred,[],2); 
    end
    
    T = max(unique(Ytrue));    

    idx = sub2ind([T, T], Ytrue, Ypred) ;
    confus = zeros(T) ;
    confus = vl_binsum(confus, ones(size(idx)), idx) ;

    accuracy = mean(diag(confus)./sum(confus,2));


end


