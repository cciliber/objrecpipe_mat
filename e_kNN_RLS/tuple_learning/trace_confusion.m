function [accuracy, accuracy_xclass, confus] = trace_confusion(Ytrue, Ypred, T)

    if size(Ytrue,2)>1
        [~,Ytrue]=max(Ytrue,[],2); 
    end
    
    if size(Ypred,2)>1
        [~,Ypred]=max(Ypred,[],2); 
    end    

    idx = sub2ind([T, T], Ytrue, Ypred) ;
    confus = zeros(T) ;
    confus = vl_binsum(confus, ones(size(idx)), idx) ;

    tp = diag(confus);
    tp = tp(unique(Ytrue));
    
    if length(unique(Ytrue))<T
        confus = confus(unique(Ytrue), :);
    end
      
    tp_fn = sum(confus,2);
    
    accuracy_xclass = tp./tp_fn;
    
    accuracy = mean(accuracy_xclass);


end


