function results = analyze_experiment(setup_data, results_root_path, results_name, experiment, results_config_script)

    check_output_dir(results_root_path);

    %% Run configuration script
    if nargin<5
        default_results_config;
    else
        run(results_config_script);
    end

    %% Assign defined values to the struct

    results = struct;

    results.results_struct_path = fullfile(results_root_path, results_name);

    results.acc_dimensions = acc_dimensions;

    results.RES = new_analyze_predictions(setup_data, experiment, results);

    % save
    save(results.results_struct_path,'results');

end