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
%dataset_name = 'Groceries_SingleInstance';
%dataset_name = 'iCubWorld0';
%dataset_name = 'iCubWorld20';
dataset_name = 'iCubWorld30';
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

obj_list_filename = 'objlist_objrec_intra_cat.mat';

experiments_path = fullfile(root_path, [dataset_name '_experiments']);
check_output_dir(experiments_path);

objlist_path = fullfile(experiments_path, obj_list_filename);

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% object recognition intra class
% for no = 2:NobjPerCat
%   fix no and consider all possible nuples_obj = combnk(1:NobjPerCat,no)  
%   for each nupla nu_obj in nuples_obj
%       for each class c=1:Ncat
%           --> object recognition

% initialization 

nuples_obj = cell(NobjPerCat-1,1);
Nnuples_obj = zeros(NobjPerCat-1,1);

objlist = cell(NobjPerCat-1,1);

for no=2:NobjPerCat
    
    nuples_obj{no-1,1} = my_combnk(1:NobjPerCat,no);
    Nnuples_obj(no-1,1) = size(nuples_obj{no-1,1},1);
    
    objlist{no-1,1} = cell(Nnuples_obj(no-1,1),Ncat);
end

% computation

for no=2:NobjPerCat
    for nu_obj=1:Nnuples_obj(no-1,1)
        
        onumbers = cellstr(num2str(nuples_obj{no-1,1}(nu_obj,:)'));
    
        for c=1:Ncat
            objlist{no-1}{nu_obj,c} = strcat(repmat(cat_names{c}, no, 1), onumbers);
        end
    end
end
            
% save
save(objlist_path, 'objlist');
