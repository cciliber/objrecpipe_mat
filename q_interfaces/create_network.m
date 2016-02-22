function network = create_network(setup_data, network_root_path, network_name, network_config_script) 
  
    % call the config file 
    run(network_config_script);
    

    % put everything in the struct
    network = struct;
    
    % the location of the struct itself
    check_output_dir(network_root_path);
    network.network_struct_path = fullfile(network_root_path, network_name);
    

    % must be empty in the case of off the shelf net!
    network.network_dir = network_name;
    
    
    % setup only once the caffestuff
    caffestuff = new_setup_caffemodel(setup_data.caffe_dir, network_kind);
        
    
    if strcmp(caffestuff.network_kind, 'caffenet')
        
        
        % net definition
        caffestuff.net_model_template = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'train_val_template.prototxt');
        caffestuff.net_model_struct_types = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'train_val_struct_types.txt');
        caffestuff.net_model_struct_values = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'train_val_struct_values.txt');
        
        % net initialization
        trainval_params = create_struct_from_txt(caffestuff.net_model_struct_types, caffestuff.net_model_struct_values);
        
        
        % deploy definition
        caffestuff.deploy_model_template = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'deploy_template.prototxt');
        caffestuff.deploy_model_struct_types = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'deploy_struct_types.txt');
        caffestuff.deploy_model_struct_values = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'deploy_struct_values.txt');
        
        % deploy initialization
        deploy_params = create_struct_from_txt(caffestuff.deploy_model_struct_types, caffestuff.deploy_model_struct_values);
        
        
        % solver definition
        caffestuff.solver_template = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'solver_template.prototxt');
        caffestuff.solver_struct_types = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'solver_struct_types.txt');
        caffestuff.solver_struct_values = fullfile(setup_data.template_prototxts_path, caffestuff.network_kind, 'solver_struct_values.txt');
        
        % solver initialization
        solver_params = create_struct_from_txt(caffestuff.solver_struct_types, caffestuff.solver_struct_values);
        
        if exist('fc8_name', 'var')
            
            trainval_params.fc8_lr_mult_W = fc8_final_W/base_lr;
            trainval_params.fc8_lr_mult_b = fc8_final_b/base_lr;
        
            trainval_params.fc8_name = fc8_name;
            trainval_params.fc8_top = fc8_name;
            trainval_params.accuracy_bottom = fc8_name;
            trainval_params.loss_bottom = fc8_name;
        
        end

        if exist('fc7_name', 'var')
            
            trainval_params.fc7_lr_mult_W = fc7_final_W/base_lr;
            trainval_params.fc7_lr_mult_b = fc7_final_b/base_lr;
            
            trainval_params.fc7_name = fc7_name;
            trainval_params.fc7_top = fc7_name;
            trainval_params.relu7_bottom = fc7_name;
            trainval_params.relu7_top = fc7_name;
            trainval_params.drop7_bottom = fc7_name;
            trainval_params.drop7_top = fc7_name;
            trainval_params.fc8_bottom = fc7_name;
            
            
        end
        
        if exist('fc6_name', 'var')
            
            trainval_params.fc6_lr_mult_W = fc6_final_W/base_lr;
            trainval_params.fc6_lr_mult_b = fc6_final_b/base_lr;
            
            trainval_params.fc6_name = fc6_name;
            trainval_params.fc6_top = fc6_name;
            trainval_params.relu6_bottom = fc6_name;
            trainval_params.relu6_top = fc6_name;
            trainval_params.drop6_bottom = fc6_name;
            trainval_params.drop6_top = fc6_name;
            trainval_params.fc7_bottom = fc6_name;
            
            
        end
        
        if exist('drop7_dropout_ratio', 'var')
            trainval_params.drop7_dropout_ratio = drop7_dropout_ratio;
        end
        
        if exist('drop6_dropout_ratio', 'var')
            trainval_params.drop6_dropout_ratio = drop6_dropout_ratio;
        end
        
        % assign trainval_params to deploy_params
        fnames = fieldnames(deploy_params);
        for ii=1:length(fnames)
            if isfield(trainval_params, fnames{ii})
                deploy_params.(fnames{ii}) = trainval_params.(fnames{ii});
            else
                warning('Field not present in trainval: %s. Are you assigning it separately?', fnames{ii});
            end
        end
        deploy_params.prob_bottom = deploy_params.fc8_top;
        
        if exist('base_lr', 'var')
            % fill the solver informations
            solver_params.base_lr = base_lr;
        end
        
        network.trainval_params     = trainval_params;
        network.deploy_params       = deploy_params;
        network.solver_params       = solver_params;
        
    end
    
    %% Assign
    
    network.caffestuff = caffestuff;
    
    save(network.network_struct_path,'network');
    
end










