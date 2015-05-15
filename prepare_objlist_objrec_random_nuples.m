%% MACHINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%machine = 'server';
machine = 'laptop_giulia_win';
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
dataset_name = 'Groceries_SingleInstance';
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

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%list_filename = 'objlist_30_ICRA15.mat';
list_filename = 'objlist_si.mat';

experiments_path = fullfile(root_path, [dataset_name '_experiments']);
check_output_dir(experiments_path);

objlist_path = fullfile(experiments_path, list_filename);

%% PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% divisive factor to reduce the number of all possible nuples
factor = 5;

% function to be used to compute the number of nuples from Nobj to 1
%trend_function = 'constant'; 
%trend_function = 'linear';
trend_function = 'parabola';

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute
[nuples, objlist] = compute_random_nuples(Nobj, factor, trend_function, obj_names);

% save
save(objlist_path, 'objlist');
