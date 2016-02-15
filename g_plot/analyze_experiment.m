function results = analyze_experiment(results_root_path, results_name, experiment, results_config_script)

%% Setup machine
setup_data = setup_machine();

%% Run configuration script
if nargin<4
    default_results_config_script;
else
    run(results_config_script);
end
  
%% Assign defined values to the struct

results = struct;

results.results_struct_path = fullfile(results_root_path, results_name);

results.acc_dimensions = acc_dimensions;

results = new_analyze_predictions(setup_data, experiment, results);
   
% save
save(results.results_struct_path,'results');
    