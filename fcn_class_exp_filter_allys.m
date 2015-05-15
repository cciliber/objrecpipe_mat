function fcn_class_exp_filter_allys(machine, dataset_name, modality, task, classification_kind, feature_name)

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

%% FEATURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%feature_name = 'fv_d64_pyrNO';
%feature_name = 'sc_d512';
%feature_name = 'sc_d512_dictIROS';
%feature_name = 'sc_d512_dictOnTheFly';
%feature_name = 'sc_d1024_dictIROS'; 
%feature_name = 'sc_d1024_iros';
%feature_name = 'overfeat_small_default';
%feature_name = 'caffe';
%feature_name = 'caffe_prova';
%feature_name = 'caffe_centralcrop_meanimagenet2012';

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

working_folder = fullfile(root_path, [dataset_name '_experiments'], classification_kind, feature_name);
check_input_dir(working_folder);

if isempty(task) && isempty(modality)
    ys_filename = 'saved_output.mat';
elseif isempty(modality)
     ys_filename = ['saved_output_' task '.mat'];
elseif isempty(task)
     ys_filename = ['saved_output_' modality '.mat'];
else
    ys_filename = ['saved_output_' modality '_' task '.mat'];
end
ys_path = fullfile(working_folder, ys_filename);

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(task) && isempty(modality)
    filtered_ys_filename = 'saved_output_filtered.mat';
elseif isempty(modality)
     filtered_ys_filename = ['saved_output_filtered_' task '.mat'];
elseif isempty(task)
     filtered_ys_filename = ['saved_output_filtered_' modality '.mat'];
else
    filtered_ys_filename = ['saved_output_filtered_' modality '_' task '.mat'];
end
filtered_ys_path = fullfile(working_folder, filtered_ys_filename);

%% FILTERING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%windows = [1:20 24:4:50];
%fps = 7.5;
windows = [1:20 25:5:55];
fps = 11;

dt_frame = 1/fps; % sec
temporal_windows = windows*dt_frame;
nwindows = length(windows);

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load ys
input = load(ys_path);
cell_output = input.cell_output;

% filter ys
cell_output = filter_allys(cell_output, windows, 'gurls_perclass');

% save filtered ys
save(filtered_ys_path, 'cell_output');