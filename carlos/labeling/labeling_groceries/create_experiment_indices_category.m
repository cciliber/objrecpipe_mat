
function exp_indices=create_experiment_indices_category(p)

    class_list=p.class_list;


    reg=p.registry;
    
    if(strcmp(p.demo,'mix'))
        nGain=2;
    else
        nGain=1;
    end
    
    exp_indices=zeros(length(reg),1);
    
    for i=1:length(reg)

        %if the class is not in the active set, continue
        if sum(strcmp(reg{i}{2},class_list))==0
            continue;
        end
        
        if(strcmp(p.demo,'mix') || strcmp(p.demo,reg{i}{3}))
            exp_indices(i)=1;
        end
        
    end


    %select the indices that will be used
    select_indices = zeros(length(reg),1);
    
    for i=1:length(reg)/200
        
        idx=[ones(p.n_samples,1); zeros(200-p.n_samples,1)];   

        if(strcmp(p.sample,'random'))        

            idx=idx(randperm(length(idx)));        

        else
            if(strcmp(p.sample,'sparse'))
                
            idx = kron(ones(1,p.n_samples),[1 zeros(1,p.sampling_sparsity)]);
            idx = [idx' ; zeros(200-length(idx),1)];
            end
        end
        
        select_indices((i-1)*length(idx)+(1:length(idx)))=idx;
    end
    
    exp_indices=exp_indices.*select_indices;
    
end


