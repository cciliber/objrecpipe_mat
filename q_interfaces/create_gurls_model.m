function gurls_model = create_gurls_model(gurls_model_root_path,gurls_model_name,gurls_model_config_script) 
  
    if nargin<3
        error('Provide configuration scrip!');
    end

    % create/check the question struct path
    check_output_dir(gurls_model_root_path);
    
    % setup the machine parameters as usual
    setup_data = setup_machine();
    
        % call the config file 
    run(gurls_model_config_script);
    
    
    gurls_model = struct;
    
    gurls_model.gurls_model_dir = gurls_model_name;
    
    gurls_model.gurls_model_struct_path = fullfile(gurls_model_root_path,gurls_model_name);

    
    gurls_model.gurls_options = gurls_options;
    
    gurls_model.mode = mode;
    
    gurls_model.selected_feature = selected_feature;
    
    
    
    save(gurls_model.gurls_model_struct_path,'gurls_model');
    
    
end

