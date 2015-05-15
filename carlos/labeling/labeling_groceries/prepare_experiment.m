function  prepare_experiment(p,exp_params,codes_params)
%   Detailed explanation goes here



    indices_path=fullfile(p.exp_root_path,exp_params.name,'indices');
    mkdir(indices_path);
    
    folder_path=fullfile(p.exp_root_path,exp_params.name,exp_params.type);
    mkdir(folder_path);

    
    tmp_exp=exp_params;
    tmp_exp.registry=getfield(codes_params,exp_params.type);
    tmp_exp.registry=tmp_exp.registry.registry;
    for i=1:length(exp_params.n_samples)
        tmp_exp.n_samples=exp_params.n_samples(i);
        %if the indices already exist loade them
        exp_string=[tmp_exp.sample '_' num2str(tmp_exp.n_samples) '_' tmp_exp.demo '_' exp_params.type '.idx'];
        tmp_indices_path=fullfile(indices_path,exp_string);
        if(exist(tmp_indices_path))
            tmp=load(tmp_indices_path,'-mat');
            tmp_exp.indices=tmp.indices;
        else
            tmp_exp.indices=create_experiment_indices(tmp_exp);
            indices=tmp_exp.indices;
            save(tmp_indices_path,'indices','-v7.3');
        end
        
            
        exp_string=[tmp_exp.sample '_' num2str(tmp_exp.n_samples) '_' tmp_exp.demo '.codes'];
        
        for j=1:length(p.features)  
            feat=getfield(codes_params,p.features{j});
            
            tmp_codes=getfield(feat,exp_params.type);
            tmp_exp.input_codes=tmp_codes.codes;
            
            tmp_out=getfield(codes_params,exp_params.out);
            tmp_codes=getfield(tmp_out,exp_params.type);
            tmp_exp.output_codes=tmp_codes.codes;
            
            [X,y]=create_experiment_from_indices(tmp_exp);
            experiment=struct;
            experiment.X=X;
            experiment.y=y;

            save_string=[p.features{j} '_' exp_string];
            save(fullfile(folder_path,save_string),'experiment','-v7.3');
        end
        
        
    end
    
    


end

