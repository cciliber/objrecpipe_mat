

% question_config_filename = 'id10obj_1trials_tune2transl';
% question_config_filename = 'id15obj_10trials_tune2transf_10Cat_trasl_one_shot';
question_config_filename = 'id15obj_10trials_all_transf_15Cat_trasl_one_shot';


% selected_net = [4,6];
% selected_net = [6];

create_new_question = false;
create_new_networks = false;

perform_experiment = false;



selected_net = [1 6 5];
selected_result = [1 6 5];


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
% 
% %% Finetune
% finetune_config_filename = 'cc256';
% finetune_config_file = fullfile(CONFIG_PATH, 'finetune', finetune_config_filename);
% % for ff=1:numel(network)
% %     network{ff} = finetune_network(question, network{ff}, finetune_config_file);
% % end
% 
% for ff=selected_net
%     figure();
%     network{ff} = finetune_network(question, network{ff}, finetune_config_file);
%     
%     title(network{ff}.network_dir);
% end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Predict and save experiment

experiment_config_filename = 'cc256_caffenet_withfeatures';
experiment = {};

if perform_experiment
    experiment_config_file = fullfile(CONFIG_PATH, 'experiment', experiment_config_filename);
    for ff=selected_net%:numel(network)
        ff
        experiment_name = [experiment_config_filename '_' question.question_dir '_' network{ff}.network_dir];
        experiment{ff} = dummy_experiment_network(fullfile(STRUCT_PATH, 'experiment'), experiment_name, question, network{ff}, experiment_config_file);
        close;
    end
end

%% Load experiment
for ff=selected_net%:numel(network)
    experiment_name = [experiment_config_filename '_' question.question_dir '_' network{ff}.network_dir];
    experiment{ff} = load(fullfile(STRUCT_PATH, 'experiment', experiment_name));    
    experiment{ff} = experiment{ff}.experiment;
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Analyze
results_config_filename = 't_sne_test';
results_config_file = fullfile(OBJREC_DIR, 'default_t_sne_config_script');
results = {};
for ff=selected_net
    %results{ff} = analyze_experiment(fullfile(STRUCT_PATH, 'results'), results_config_filename, experiment{ff}, results_config_file);
    results{ff} = t_sne_experiment(fullfile(STRUCT_PATH, 'results'), results_config_filename, experiment{ff});
end
display('done');


%%

TSNE_PATH = '/data/giulia/REPOS/t_sne';
addpath(genpath(TSNE_PATH));


   
colorVec = [131,0,35;
            94,174,238;
            107,162,4;
            45,89,180;
            189,63,0;
            219,166,0;
            255,199,228;
            57,85,47;
            253,242,62;
            18,19,16;
            205,211,233;
            231,63,63;
            129,59,129;
            23,167,104;
            97,97,97];
        
        
colorVec = colorVec/255.0;


marker_transformation = {'o','x','d','s','*'};

selected_day = 1;

% Set parameters
no_dims = 2;
initial_dims = 100;
perplexity = 30;
% Run t−SNE

selected_transformation = setup_data.dset.Transfs('TRANSL');


scores = [];
scores_big = [];
for idx_result = selected_result

    mappedX = fast_tsne(results{idx_result}.feature_matrix, no_dims, initial_dims, perplexity);
    % Plot results

    ncats = numel(unique(results{idx_result}.labels_matrix(:,1)));

    figure;
    hold on;
    
    Xselected = [];
    Yselected = [];
    Xts_selected = [];
    Yts_selected = [];
    for idx_cat = 1:ncats

        select_idx_cat = results{idx_result}.labels_matrix(:,1)==idx_cat;

        for idx_transf = 1:5

            select_idx_transf = results{idx_result}.labels_matrix(:,3)==idx_transf;

            select_idx_joint = (select_idx_transf.*select_idx_cat);

            scatter(mappedX(select_idx_joint==1,1),mappedX(select_idx_joint==1,2),100,colorVec(idx_cat,:),marker_transformation{idx_transf});
            
            if idx_transf == selected_transformation
                        
                Xselected = [Xselected; mappedX(select_idx_joint==1,:)];
                Yselected = [Yselected; idx_cat * ones( size(mappedX(select_idx_joint==1,1),1),1 )];
            else
                Xts_selected = [Xts_selected; mappedX(select_idx_joint==1,:)];
                Yts_selected = [Yts_selected; idx_cat * ones( size(mappedX(select_idx_joint==1,1),1),1 )];
            end

        end 
    end
    hold off;
    
    pause(0.001);

    


    mdl = fitcknn(Xselected,Yselected);
    mdl.NumNeighbors = 5;

    
    
    nplot = 100;
    wmin = min(mappedX(:,1));
    wmax = max(mappedX(:,1));
    hmin = min(mappedX(:,2));
    hmax = max(mappedX(:,2));
    Wplot = linspace(wmin,wmax,nplot)'*ones(1,nplot);
    Hplot = ones(nplot,1)*linspace(hmin,hmax,nplot);
    Xplot = [Wplot(:),Hplot(:)];
    
    YpredTSNE = predict(mdl,Xplot);
    
    colorVecWhitened = colorVec*255 + 40;
    colorVecWhitened(colorVecWhitened>255) = 255;
    colorVecWhitened = colorVecWhitened/255;

    figure; 
    hold on;
%     s_handle = scatter(Xplot(:,1),Xplot(:,2),100,colorVecWhitened(YpredTSNE,:),'filled');
    
    
    legend_str = {};


    first_time_cat = true;
    for idx_transf = 1:5
        
        for idx_cat = 1:ncats

            select_idx_cat = results{idx_result}.labels_matrix(:,1)==idx_cat;


            select_idx_transf = results{idx_result}.labels_matrix(:,3)==idx_transf;

            select_idx_joint = (select_idx_transf.*select_idx_cat);

% 
%             if idx_transf == selected_transformation
%                 
%                 select_idx_day = results{idx_result}.labels_matrix(:,4)==selected_day;
%                 select_idx_joint = (select_idx_joint.*select_idx_day);
%                 
%                 scatter(mappedX(select_idx_joint==1,1),mappedX(select_idx_joint==1,2),100,'g',marker_transformation{idx_transf});
%             else
                scatter(mappedX(select_idx_joint==1,1),mappedX(select_idx_joint==1,2),100,colorVec(idx_cat,:),marker_transformation{idx_transf});
% %             end            

            if first_time_cat
                legend_str{end+1} = setup_data.dset.cat_names{idx_cat+1};
            end
            
        end
        
        first_time_cat = false;
        
    end
    hold off;
    
    legend(legend_str,'Location','eastoutside');
    
    title(network{idx_result}.network_dir);
   	
    axis([wmin wmax hmin hmax]);
    
    pause(0.001);
    
    
    
    
    YpredTSNE = predict(mdl,Xts_selected);

    C = confusionmat(Yts_selected,YpredTSNE);

    C = C./repmat(sum(C,2),1,size(C,2));

    scores(end+1) = trace(C)/size(C,1)
    
   
    
    
   
end

display(scores);




%%




selected_day = 1;


selected_transformation = setup_data.dset.Transfs('TRANSL');


ntr = 20;

scores = [];
scores_big = [];
for idx_result = selected_result
    % Plot results

    ncats = numel(unique(results{idx_result}.labels_matrix(:,1)));
    
    Xtr = [];
    Ytr = [];
    Xts = [];
    Yts = [];
    for idx_cat = 1:ncats

        select_idx_cat = results{idx_result}.labels_matrix(:,1)==idx_cat;

        for idx_transf = 1:5

            select_idx_transf = results{idx_result}.labels_matrix(:,3)==idx_transf;

            select_idx_joint = (select_idx_transf.*select_idx_cat);

  
            if idx_transf == selected_transformation
                
                
                tmpXtr = results{idx_result}.feature_matrix(select_idx_joint==1,:);
                if ntr>0 && size(tmpXtr,1)>0
%                     tmpXtr = tmpXtr(1:ntr,:);
                    tmpXtr = tmpXtr(randperm(size(tmpXtr,1),ntr),:);
                end
                
                Xtr = [Xtr; tmpXtr];
                Ytr = [Ytr; idx_cat * ones( size(tmpXtr,1) , 1 )];

                
%                 Xtr = [Xtr; results{idx_result}.feature_matrix(select_idx_joint==1,:)];
%                 Ytr = [Ytr; idx_cat * ones( sum(select_idx_joint) , 1 )];
                
                
            else
                Xts = [Xts; results{idx_result}.feature_matrix(select_idx_joint==1,:)];
                Yts = [Yts; idx_cat * ones( sum(select_idx_joint) , 1 )];
            end

        end 
    end
    
    
    

    % learn and predict
    model = gurls_train(Xtr,Ytr);
    YpredRLS = gurls_test(model,Xts);
    
    [~,YpredRLS_class] = max(YpredRLS,[],2);  
    
    C = confusionmat(Yts,YpredRLS_class);

    C = C./repmat(sum(C,2),1,size(C,2));

    scores(end+1) = trace(C)/size(C,1)
    
end



