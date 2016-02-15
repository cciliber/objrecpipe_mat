
%% Core code
OBJREC_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(OBJREC_DIR));

%% Test code 
TEST_DIR = '/data/giulia/REPOS/objrecpipe_mat/test_objrecpipe_mat';


%% Analysis
ANALYSIS = 'invariance';


%% Config files
CONFIG_PATH = fullfile(TEST_DIR, ANALYSIS, 'config');
%% Struct files
STRUCT_PATH = fullfile(TEST_DIR, ANALYSIS, 'structs');



%% Create and save question (the registries)
question_config_filename = 'id15obj_10trials_tune2transf';
question_config_file = fullfile(CONFIG_PATH, 'question', question_config_filename);
question = create_question(fullfile(STRUCT_PATH, 'question'), question_config_filename, question_config_file);

%% Create and save network
network_config_file_list = dir(fullfile(CONFIG_PATH, 'network'));
network = {};
for ff=1:numel(network_config_file_list)
    if network_config_file_list(ff).name(1)~='.'
        network_config_file = fullfile(CONFIG_PATH, 'network', network_config_file_list(ff).name);
        network{end+1} = create_network(fullfile(STRUCT_PATH, 'network'), network_config_file_list(ff).name, network_config_file);
    end
end

%% Finetune!
finetune_config_filename = 'cc256';
finetune_config_file = fullfile(CONFIG_PATH, 'finetune', finetune_config_filename);
for ff=1:numel(network)
    network{ff} = finetune_network(question, network{ff}, finetune_config_file);
end

%% Predict!
experiment_config_filename = 'cc256_caffenet_withfeatures';
experiment_config_file = fullfile(CONFIG_PATH, 'experiment', experiment_config_filename);
experiment = {};
for ff=1:numel(network)
    experiment{ff} = experiment_network(fullfile(STRUCT_PATH, 'experiment'), experiment_config_filename, question, network{ff}, experiment_config_file);
end

%% Analyze!
results_config_filename = 'ciao';
results_config_file = fullfile(CONFIG_PATH, 'results', experiment_config_filename);
results = {};
for ff=1:numel(network)
    results{ff} = analyze_experiment(fullfile(STRUCT_PATH, 'results'), results_config_filename, experiment{ff}, results_config_file);
end

