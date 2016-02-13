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


% pointer to the image set used for the experiment
results.dset_dir = dset_dir;

% whether we want to extract features
results.extract_features = extract_features;

% which features we want to extract
results.feat_names = feat_names;

results = new_analyze_predictions(setup_data, experiment);

 
% keep track 
results.a = a;
   
% save
save(results.results_struct_path,'results');
    