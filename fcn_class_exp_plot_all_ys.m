function fcn_class_exp_plot_all_ys(machine, dataset_name, modality, task, classification_kind, feature_names)

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
N3 = ICUBWORLDopts.objects.Count;
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
% classification_kind = 'obj_rec_inter_class';
% classification_kind = 'obj_rec_intra_class';
% classification_kind = 'categorization';

%% FEATURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%feature_names = {'sc_d1024_iros', 'overfeat_small_default'};
%feature_names = {'sc_d1024_iros'};
%feature_names = {'sc_d512'};
%feature_names = {'overfeat_small_default'};
%feature_names = {'sc_d512','overfeat_small_default','caffe_centralcrop_meanimagenet2012'};

feature_number = length(feature_names);

%% MAIL SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run('setup_mail_matlab.m');

mail_recipient = {'giu.pasquale@gmail.com'};
mail_object = [mfilename '_' dataset_name];
mail_message = 'Successfully executed.';

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

working_folder = fullfile(root_path, [dataset_name '_experiments'], classification_kind);
check_input_dir(working_folder);

if isempty(task)
    ys_filenames = strcat('saved_output_filtered_', modalities, '.mat');
else
    ys_filenames = strcat('saved_output_filtered', modalities, ['_' task], '.mat');
end

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figures_dir = fullfile(working_folder, 'figures');
check_output_dir(figures_dir);

figure_name_prefix = cell2mat(strcat(feature_names', '_')');
if ~isempty(modality) && ~isempty(task)
    figure_name_prefix = [figure_name_prefix '_' modality '_' task '_'];
elseif ~isempty(modality)
    figure_name_prefix = [figure_name_prefix '_' modality '_'];
elseif ~isempty(task)
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

methods = {'giulia', 'carlo', 'gurls'};
method_tobeplotted = 3; % accuracy method: 1-giulia, 2-carlo, or 3-gurls

windows_leg = [round(1/33*100)/100; round(temporal_windows(:)*10)/10];

w_tobeplotted = 1;

markers = {'o', '*', 's'};

cmap = [0 0 0; 1 0 0; 0 1 0; 0 0 1];

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute

mean_accuracy_over_classes = cell(feature_number, length(modalities));
mean_accuracy_over_nuples = cell(feature_number, length(modalities));
var_accuracy_over_nuples = cell(feature_number, length(modalities));

for feat_idx=1:length(feature_names)

    for mod_idx = 1:length(modalities)
    
        load(fullfile(working_folder, feature_names{feat_idx}, ys_filenames{mod_idx}));
        
        N1 = size(cell_output, 1);
    
        mean_accuracy_over_classes{feat_idx, mod_idx} = cell(N1,1);
        mean_accuracy_over_nuples{feat_idx, mod_idx} = zeros(N1, nwindows+1);
        var_accuracy_over_nuples{feat_idx, mod_idx} = zeros(N1, nwindows+1);
        
        % extract accuracy information from cell array of results
        for n1=1:N1
            
            [N2, N3] = size(cell_output{n1});
            
            mean_accuracy_over_classes{feat_idx, mod_idx, n1} = zeros(N2, N3, nwindows+1);
            
            for n2=1:N2
                for n3=1:N3
                    if strcmp(feature_names{feat_idx},'caffe_centralcrop_meanimagenet2012')
                        mean_accuracy_over_classes{feat_idx, mod_idx, n1}(n2, n3, :) = [mean(cell_output{n1}{n2, n3}.accuracy); cell_output{n1}{n2, n3}.accuracy_mode'];
                    else
                        mean_accuracy_over_classes{feat_idx, mod_idx, n1}(n2, n3, :) = [mean(cell_output{n1}{n2, n3}.accuracy); cell2mat(cell_output{n1}{n2, n3}.accuracy_mode(method_tobeplotted,:))'];
                    end
                end
            end
            
            for w=1:nwindows+1
                mean_accuracy_over_nuples{feat_idx, mod_idx}(n1, w) = mean2(squeeze(mean_accuracy_over_classes{feat_idx, mod_idx, n1}(:,:,w)));
                var_accuracy_over_nuples{feat_idx, mod_idx}(n1, w) = std2(squeeze(mean_accuracy_over_classes{feat_idx, mod_idx, n1}(:,:,w)));
            end
            
        end
        
    end
end

% plot

for feat_idx=1:length(feature_names)

    for mod_idx = 1:length(modalities)
    
        figure(1)
        hold on
        plot(2:N1+1, mean_accuracy_over_nuples{feat_idx, mod_idx}(:, w_tobeplotted), ['-' markers{feat_idx}], 'Color', cmap(mod_idx, :), 'LineWidth', 2, 'MarkerSize', 8);
        
    end
end

legend({'SC day1', 'SC day2', 'SC day3', 'SC day4', 'OF day1', 'OF day2', 'OF day3', 'OF day4'}, 'Location', 'Best');

grid on
xlabel('# classes', 'FontSize', 15);
set(gca, 'XTick', 2:N1+1);
set(gca, 'FontSize', 15)
ylabel('accuracy (mean over classes)', 'FontSize', 15);
xlim([2 N1+1]);
ylim([0.2 1]);

% save 

saveas(figure(1), fullfile(figures_dir, [figure_name_prefix 'acc.fig']));
h = figure(1);
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
% set(gca,'InvertHardcopy','off')
print(h, '-dpdf', fullfile(figures_dir, [figure_name_prefix 'acc.pdf']));
print(h, '-dpng', fullfile(figures_dir, [figure_name_prefix 'acc.png']));
