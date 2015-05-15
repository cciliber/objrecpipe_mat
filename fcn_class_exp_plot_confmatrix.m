function fcn_class_exp_plot_confmatrix(machine, dataset_name, modality, task, classification_kind, feature_names)

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
% classification_kind = 'obj_rec_inter_class';
% classification_kind = 'obj_rec_intra_class';
% classification_kind = 'categorization';

%% FEATURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%feature_names = {'sc_d1024_iros', 'overfeat_small_default'};
%feature_names = {'sc_d512', 'overfeat_small_default'};
%feature_names = {'sc_d1024_iros'};
%feature_names = {'sc_d512'};
%feature_names = {'overfeat_small_default'};
%feature_names = {'caffe'};

feature_number = length(feature_names);

%% MAIL SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run('setup_mail_matlab.m');

mail_recipient = {'cciliber@gmail.com', 'giu.pasquale@gmail.com'};
mail_object = [mfilename '_' dataset_name];
mail_message = 'Successfully executed.';

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

working_folder = fullfile(root_path, [dataset_name '_experiments'], classification_kind);
check_input_dir(working_folder);

if isempty(task) && isempty(modality)
    filtered_ys_filename = 'saved_output_filtered.mat';
elseif isempty(modality)
     filtered_ys_filename = ['saved_output_filtered_' task '.mat'];
elseif isempty(task)
     filtered_ys_filename = ['saved_output_filtered_' modality '.mat'];
else
    filtered_ys_filename = ['saved_output_filtered_' modality '_' task '.mat'];
end

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figures_dir = fullfile(working_folder, 'figures');
check_output_dir(figures_dir);

figure_name_prefix = cell2mat(strcat(feature_names', '_')');
if ~isempty(modality) && ~isempty(task)
    figure_name_prefix = [figure_name_prefix modality '_' task '_'];
elseif isempty(modality)
    figure_name_prefix = [figure_name_prefix task '_'];
elseif isempty(task)
    figure_name_prefix = [figure_name_prefix modality '_'];
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

%n1_tobeplotted = [2 7 14 28];
%n1_tobeplotted = [2 7 14];
n1_tobeplotted = Nobj;

n2_tobeplotted = 1;
n3_tobeplotted = 1; % set to 1 if exp_folder = 'obj_rec_random_nuples'
% either n2 or n3 to be plotted must be a scalar

w_tobeplotted = windows([1 end]);

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute confusion matrices

conf_matrices = cell(feature_number, 1);
    
for feat_idx=1:length(feature_names)


    loaded_ys = load(fullfile(working_folder, feature_names{feat_idx}, filtered_ys_filename));
    cell_output = loaded_ys.cell_output;

    N1 = length(cell_output);
    if sum(n1_tobeplotted>N1+1)
        error('Invalid value/s for n1_tobeplotted.');
    end
    
    conf_matrices{feat_idx} = cell(N1,1);

    for n1=1:N1
        
        [N2, N3] = size(cell_output{n1});   
        % nwindows = length(cell_output{n1}{1, 1}.y_mode);
        
        conf_matrices{feat_idx, n1} = zeros(N2, N3, nwindows, n1+1, n1+1);
        
        for n2=1:N2
            for n3=1:N3
                for w=1:nwindows
                    y = cell_output{n1}{n2, n3}.y_mode{w};
                    ypred = cell_output{n1}{n2, n3}.ypred_mode{w};
                   % delete the zero padding
                    y(y==0) = [];
                    ypred(ypred==0) = [];
                    conf_matrices{feat_idx, n1}(n2, n3, w, :, :) = compute_confusion_matrix(y, ypred);
                end
            end
        end  
           
    end
    
end

% plot

figure_counter = 1;

for feat_idx=1:length(feature_names)
    % figure_counter = 1;
    for n1=n1_tobeplotted
        for n2=n2_tobeplotted
            for n3=n3_tobeplotted
                for w=w_tobeplotted
                    
                    figure(figure_counter)
                    set(gcf,'units','normalized','outerposition',[0 0 1 1])
                    % subplot(1,2,feat_idx)
                    
                    [~, w_idx] = find(windows==w);
                    imagesc(squeeze(conf_matrices{feat_idx, n1-1}(n2, n3, w_idx, :, :)));
                    title(sprintf('Feat: %s, %d cat, nupla (%d,%d), w=%d', strrep(feature_names{feat_idx}, '_', ' ' ), n1, n2, n3, w));
                    ylabel('true cat');
                    xlabel('predicted cat');
                    % '.experiment' should be equal for all features
                    set(gca, 'XTick', 1:n1);
                    set(gca, 'YTick', 1:n1);
                    set(gca, 'XTickLabel', cell_output{n1-1}{n2, n3}.experiment, 'FontSize', 8);
                    set(gca, 'YTickLabel', cell_output{n1-1}{n2, n3}.experiment, 'FontSize', 8);
                    colorbar 
                    grid on
                    rotateXLabels(gca(), 45 );
                    
                    figure_counter = figure_counter + 1;
                    
                    saveas(gcf, fullfile(figures_dir, [sprintf('%sconf_matrix_n1_%d_n2_%d_n3_%d_w_%d', figure_name_prefix, n1, n2, n3, w) '.fig']));
                    %h = gcf;
                    %set(h,'PaperOrientation','landscape');
                    %set(h,'PaperUnits','normalized');
                    %set(h,'PaperPosition', [0 0 1 1]);
                    % set(gca,'InvertHardcopy','off')
                    %print(h, '-dpdf', fullfile(figures_dir, [sprintf('%sconf_matrix_n1_%d_n2_%d_n3_%d_w_%d', figure_name_prefix, n1, n2, n3, w) '.pdf']));
                    %print(h, '-dpng', fullfile(figures_dir, [sprintf('%sconf_matrix_n1_%d_n2_%d_n3_%d_w_%d', figure_name_prefix, n1, n2, n3, w) '.png']));
                end
            end
        end
    end
end