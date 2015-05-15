function e=perform_experiments(e,params)

   curr_path=pwd;
   cd(params.save_path);
   
    %perform the experiments one by one
    for i=1:numel(e)
        
        Xtr=load_descriptors(e{i}.Xtr,e{i}.feature_size);
        Xtr=Xtr';
        
        max_train=min(size(Xtr,1),e{i}.max_train);

        rand_idx=randperm(size(Xtr,1));
        rand_idx=rand_idx(1:max_train);

        Xtr=Xtr(rand_idx,:);
        
        ytr=load(e{i}.ytr);
        ytr=ytr(rand_idx,:);
        
        Xts=load_descriptors(e{i}.Xts,e{i}.feature_size);
        Xts=Xts';

        yts=load(e{i}.yts);
        
        e{i}=train_test(e{i},Xtr,ytr,Xts,yts,params);
    end
   
    cd(curr_path);
end

