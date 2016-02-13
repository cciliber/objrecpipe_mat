function experiment = experiment_network(experiment_root_path, experiment_name, question, network, experiment_config_script)

    setup_data = setup_machine();
    
    if nargin<4
        default_experiment_network_config;
    else
        run(experiment_config_script);
    end
    
    
    experiment = struct;
  
    experiment.experiment_struct_path = fullfile(experiment_root_path, experiment_name);
    
    % pointer to the image set used for the experiment
    experiment.dset_dir = dset_dir;
    
    % whether we want to extract features
    experiment.extract_features = extract_features;
    
    % which features we want to extract    
    experiment.feat_names = feat_names;
    
    % whether to save only the features of the central crop
    % it is used only if NCROPS>1 
    % (depending on network.caffestuff.preprocessing defined in the config)
    experiment.save_only_central_feat = save_only_central_feat;
        
    experiment = new_extract_feat_and_pred_cat(setup_data,question,network,experiment);
    
    
    
    % keep track of which question and which network have been tested
    experiment.network_struct_path = network.network_struct_path;
    experiment.question_struct_path = question.question_struct_path;
    
    save(network.network_struct_path,'experiment');
    
end



