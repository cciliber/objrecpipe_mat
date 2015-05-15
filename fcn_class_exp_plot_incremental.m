function fcn_class_exp_plot_incremental(machine, dataset_name, modality, task, classification_kind, feature_names)

%% MACHINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%machine = 'server';
%machine = 'laptop_giulia_win';
%machine = 'laptop_giulia_lin';
    
if strcmp(machine, 'server')
    
    FEATURES_DIR = '/home/icub/GiuliaP/objrecpipe_mat';
    root_path = '/DATA/DATASETS';
    
    run('/home/icub/Dev/GURLS/gurls/utils/gurls_install.m');
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
    
elseif strcmp (machine, 'laptop_giulia_win')
    
    FEATURES_DIR = 'C:\Users\Giulia\REPOS\objrecpipe_mat';
    root_path = 'D:\DATASETS';
    
elseif strcmp (machine, 'laptop_giulia_lin')
    
    FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
    root_path = '/media/giulia/DATA/DATASETS';
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
end

addpath(genpath(FEATURES_DIR));

check_input_dir(root_path);

%% DATASET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%dataset_name = 'Groceries_4Tasks';
%dataset_name = 'Groceries';
%dataset_name = 'Groceries_SingleInstance';
%dataset_name = 'iCubWorld0';
%dataset_name = 'iCubWorld20';
%dataset_name = 'iCubWorld30';
%dataset_name = 'prova';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ICUBWORLDopts = ICUBWORLDinit(dataset_name);

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

%% MODALITY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%modality = 'carlo_household_right';
%modality = 'human';
%modality = 'robot';
%modality = 'lunedi22';
%modality = 'martedi23';
%modality = 'mercoledi24';
%modality = 'venerdi26';
%modality = '';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(modality) && sum(strcmp(modality, modalities))==0
    error('Modality does not match any existing modality.');
end

%% TASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%task = 'background';
%task = 'categorization';
%task = 'demonstrator';
%task = 'robot';
%task = '';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(task) && sum(strcmp(task, tasks))==0
    error('Task does not match any existing task.');
end

%% CLASSIFICATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%classification_kind = 'obj_rec_random_nuples';
%classification_kind = 'obj_rec_inter_class';
%classification_kind = 'obj_rec_intra_class';
%classification_kind = 'categorization';
%classification_kind = 'incremental';

%% FEATURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%feature_names = {'sc_d1024_iros', 'overfeat_small_default'};
%feature_names = {'sc_d1024_iros'};
%feature_names = {'sc_d512'};
%feature_names = {'overfeat_small_default'};
%feature_names = {'caffe','overfeat_small_default'};
%feature_names = {'caffe'};

feature_number = length(feature_names);

%% MAIL SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run('setup_mail_matlab.m');

mail_recipient = {'cciliber@gmail.com', 'giu.pasquale@gmail.com'};
mail_object = [mfilename '_' dataset_name];
mail_message = 'Successfully executed.';

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

working_dir = fullfile(root_path, [dataset_name '_experiments'], classification_kind);
check_input_dir(working_dir);

if ~isempty(task)
    acc_filename = ['saved_output_' task '.mat'];
else
    acc_filename = 'saved_output.mat';
end

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figures_dir = fullfile(working_dir, 'figures');
check_output_dir(figures_dir);

figure_name_prefix = cell2mat(strcat(feature_names', '_')');
if ~isempty(task)
    figure_name_prefix = [figure_name_prefix '_' task '_'];
end

%% FILTERING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%windows = [1:20 24:4:50];
%fps = 7.5;
windows = [1:20 25:5:55];
fps = 11;

dt_frame = 1/fps; % sec
temporal_windows = windows*dt_frame;
nwindows = length(windows);

%% PLOTTING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

markers = {'o', '*'};
cmap = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1];

w_tbp_sizes = [1,11,27];

mail_attachments = {};

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% conversion from cell array to matrices

results = cell(feature_number,7);

for feat_idx=1:feature_number
    
    acc_path = fullfile(working_dir, feature_names{feat_idx}, acc_filename);
    loaded_res = load(acc_path);
    cell_results = loaded_res.results;

results{feat_idx,1} = cell2mat(cell_results.present);

results{feat_idx,2} = [NaN*ones(1,nwindows); cell2mat(cell_results.past)];

results{feat_idx,3}  = [cell2mat(cell_results.future); NaN*ones(1,nwindows)];

results{feat_idx,4} = [NaN*ones(1,nwindows); cell2mat(cell_results.immediate_past)];

results{feat_idx,5} = [cell2mat(cell_results.immediate_future); NaN*ones(1,nwindows)];

results{feat_idx,6} = cell2mat(cell_results.causal);

results{feat_idx,7} = cell2mat(cell_results.all);
    
end 

for w_tobeplotted = w_tbp_sizes
    
    % plot
    
    figure
    hold on
    for idx=1:7
        plot(1:4, results{1,idx}(:,w_tobeplotted), ['-' markers{1}], 'Color', cmap(idx,:), 'LineWidth', 1.2, 'MarkerSize', 6);
    end

    legend({'CAFFE present', 'CAFFE past', 'CAFFE future', 'CAFFE immediate past', 'CAFFE immediate future', 'CAFFE causal' 'CAFFE all'}, 'Location', 'Best');
    grid on, box on
    xlabel('day');
    set(gca, 'XTick', 1:4);
    ylabel('accuracy (mean over classes)');
    xlim([1 4]);

    % save 

    fig_name = [figure_name_prefix 'filtered_acc_w_' num2str(w_tobeplotted)];

    saveas(gcf, fullfile(figures_dir, [fig_name '.fig']));
    h = gcf;
    set(h,'PaperOrientation','landscape');
    set(h,'PaperUnits','normalized');
    set(h,'PaperPosition', [0 0 0.8 1]);
    % set(gca,'InvertHardcopy','off')
    print(h, '-dpdf', fullfile(figures_dir, [fig_name  '.pdf']));
    print(h, '-dpng', fullfile(figures_dir, [fig_name  '.png']));

    % mail_attachments{end+1} = fullfile(figures_dir, [fig_name  '.png']);
    % mail_attachments{end+1} = fullfile(figures_dir, [fig_name  '.pdf']);
    % mail_attachments{end+1} = fullfile(figures_dir, [fig_name  '.fig']);
        
end

% send mail

%  try
%     
%     mail_object = ['Incremental learning on ' dataset_name ' - Figures Wrap-up'];
%     mail_message = ['See attachment'];
%     
%     fprintf(mail_message);
% 
%     sendmail(mail_recipient,mail_object,mail_message,mail_attachments);
%     
% catch err
%     display(err);
%  end


