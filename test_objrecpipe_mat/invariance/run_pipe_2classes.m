


% question_config_filename = 'id10obj_1trials_tune2transl';
% question_config_filename = 'id15obj_10trials_tune2transf_10Cat_trasl_one_shot';
question_config_filename = 'debug_id10obj_1trials_tune2transl';


% selected_net = [4,6];
selected_net = [1];

create_new_question = true;
create_new_networks = false;



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


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%% Create and save question (the registries)
if create_new_question
    question_config_file = fullfile(CONFIG_PATH, 'question', question_config_filename);
    question = create_question(fullfile(STRUCT_PATH, 'question'), question_config_filename, question_config_file);
end

%% Load question
question = load(fullfile(STRUCT_PATH,'question',question_config_filename));
question = question.question;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Create and save network
if create_new_networks
    
    network_config_file_list = dir(fullfile(CONFIG_PATH, 'network'));
    network = {};
    for ff=1:numel(network_config_file_list)
        if network_config_file_list(ff).name(1)~='.'
            network_config_file = fullfile(CONFIG_PATH, 'network', network_config_file_list(ff).name);
            network{end+1} = create_network(fullfile(STRUCT_PATH, 'network'), network_config_file_list(ff).name(1:end-2), network_config_file);
        end
    end

end

%% Load network
network_config_file_list = dir(fullfile(CONFIG_PATH, 'network'));
network = {};
for ff=1:numel(network_config_file_list)
    if network_config_file_list(ff).name(1)~='.'
        network{end+1} = load(fullfile(STRUCT_PATH,'network',network_config_file_list(ff).name(1:end-2)));    
        network{end} = network{end}.network;
    end
end

if isempty(selected_net)
    selected_net = 1:numel(network);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Finetune
finetune_config_filename = 'cc256';
finetune_config_file = fullfile(CONFIG_PATH, 'finetune', finetune_config_filename);
% for ff=1:numel(network)
%     network{ff} = finetune_network(question, network{ff}, finetune_config_file);
% end

for ff=selected_net
    network{ff} = finetune_network(question, network{ff}, finetune_config_file);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Predict and save experiment
experiment_config_filename = 'cc256_caffenet_withfeatures';
experiment_config_file = fullfile(CONFIG_PATH, 'experiment', experiment_config_filename);
experiment = {};
for ff=selected_net%:numel(network)
    ff
    experiment_name = [experiment_config_filename '_' question.question_dir '_' network{ff}.network_dir];
    experiment{ff} = experiment_network(fullfile(STRUCT_PATH, 'experiment'), experiment_name, question, network{ff}, experiment_config_file);
    close;
end

% %% Load experiment
% experiment_config_filename = 'cc256_caffenet_withfeatures';
% experiment = {};
% for ff=selected_net%:numel(network)
%     experiment_name = [experiment_config_filename '_' question.question_dir '_' network{ff}.network_dir];
%     experiment{end+1} = load(fullfile(STRUCT_PATH, 'experiment', experiment_name));    
%     experiment{end} = experiment{end}.experiment;
% end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Analyze
results_config_filename = 'ciao_2classes';
results_config_file = fullfile(CONFIG_PATH, 'results', results_config_filename);
results = {};
for ff=selected_net
    %results{ff} = analyze_experiment(fullfile(STRUCT_PATH, 'results'), results_config_filename, experiment{ff}, results_config_file);
    results{ff} = analyze_experiment(fullfile(STRUCT_PATH, 'results'), results_config_filename, experiment{ff});
end

display('done');




test_script_per_molti;


tmp_y = y(1:(idx_trial),:,:);

ymean = squeeze(mean(tmp_y,1));
ystd = squeeze(std(tmp_y,[],1));


for idx_RES = 1:numel(selected_net)
    figure;
    hold on;
    bar(ymean(:,idx_RES),'y');
    errorbar(ymean(:,idx_RES),ystd(:,idx_RES),'.');
    axis([0 size(y,2)+1 0 1]);

    if idx_trial>1
        boxplot(tmp_y(:,:,idx_RES), 'boxstyle', 'filled', 'symbol', '+', 'outliersize', 3, 'positions', 1:3);
    end
    
    ylim([0 1])
    title(network{selected_net(idx_RES)}.network_dir);
    
end    

pause(0.001);

idx_trial = idx_trial+1;

%% boxplot


%     figure,
%     boxplot(y(:,:,idx_RES), 'boxstyle', 'filled', 'symbol', '+', 'outliersize', 3, 'positions', 1:5);
%     ylim([0 1])
    
if idx_trial > ntrials
    break;
end



