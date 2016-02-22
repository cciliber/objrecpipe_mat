function results = t_sne_experiment(results_root_path, results_name, experiment, results_config_script)

    check_output_dir(results_root_path);

    %% Setup machine
    setup_data = setup_machine();

    %% Run configuration script
    if nargin<4
        default_t_sne_config_script;
    else
        run(results_config_script);
    end

    %% Assign defined values to the struct

    results = struct;

    results.results_struct_path = fullfile(results_root_path, results_name);

    
    results.feat_name = feat_names{1};
    
%     % override!! 
%     results.feat_name = 'pool5';
%     results.feat_name = 'fc7';
    
    
    results.acc_dimensions = acc_dimensions;

    [results.RES,results.feature_matrix,results.labels_matrix] = new_t_sne_predictions(setup_data, experiment, results);

    % save... not for now
%     save(results.results_struct_path,'results');

end