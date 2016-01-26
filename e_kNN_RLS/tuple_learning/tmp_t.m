

function tuples_c = tmp_t(T,t,n)
   
    if n > nchoosek(T,t)
        n = nchoosek(T,t);
    end

    idx = randperm(nchoosek(T,t),n);
    
    tuples_c = cell(n,1);
    
    for i=1:n
        tuples_c{i} = zeros(1,t);
        
        val = idx(i);
        
        tmp_n = T;
        tmp_k = t;
        
        selected = 0;
        %number of levels
        for idx_t = 1:t
            vec = gen_vec(tmp_n,tmp_k);
               
            selected=sum(vec<=val)+selected;
            tuples_c{i}(idx_t)=selected;
            
            val = val - vec(find(vec<=val,1,'last')) + 1;
            
            tmp_n = T - selected;
            tmp_k = tmp_k - 1;
            
        end
        
    end
    
    
    verify_mat = cell2mat(tuples_c);
    verify_mat = unique(verify_mat,'rows');
    
    if size(verify_mat,1)~=n
        cell2mat(tuples_c)
        error('Error! Something went awry!');
    end
    
    if sum(sum(verify_mat>T))>0
        error('Error! values exceed T!');
    end

end



function v = gen_vec(n,k)
    
    v = zeros(1,n-k+1);
    for i=1:(n-k+1)
       v(i) = nchoosek(n-i,k-1);
    end
    v = [1 v(1:(end-1))];
    v = cumsum(v);
    
end










