%% MACHINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%machine = 'server';
%machine = 'laptop_giulia_win';
machine = 'laptop_giulia_lin';
    
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

train_list_filename = 'objlist_categorization_train.mat';
test_list_filename = 'objlist_categorization_test.mat';
cat_list_filename = 'catlist_categorization.mat';

experiments_path = fullfile(root_path, [dataset_name '_experiments']);
check_output_dir(experiments_path);

objlist_train_path = fullfile(experiments_path, train_list_filename);
objlist_test_path = fullfile(experiments_path, test_list_filename);
catlist_path = fullfile(experiments_path, cat_list_filename);

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% categorizarion experiment:
% consider nc categories with nc=2:Ncat
%   fix nc and consider all possible n-uples nuples_cat = combnk(1:Ncat, nc)
%   for each n-upla nu_cat in nuples_cat
%       for each object o belonging to nu_cat
%           --> subtract it from the training set and categorize it 

% initialization 

nuples_cat = cell(Ncat-1,1);
Nnuples_cat = zeros(Ncat-1,1);

objlist_train = cell(Ncat-1,1);
objlist_test = cell(Ncat-1,1);
catlist = cell(Ncat-1,1);

for nc=2:Ncat
    
    nuples_cat{nc-1,1} = my_combnk(1:Ncat,nc);
    Nnuples_cat(nc-1,1) = size(nuples_cat{nc-1,1},1);
    
    objlist_train{nc-1,1} = cell(Nnuples_cat(nc-1,1),NobjPerCat);
    objlist_test{nc-1,1} = cell(Nnuples_cat(nc-1,1),NobjPerCat);
    catlist{nc-1,1} = cell(Nnuples_cat(nc-1,1),1);
end

% computation

for nc=2:Ncat
    
    onumbers = repmat((1:NobjPerCat)',nc,1);
    
    for nu_cat=1:Nnuples_cat(nc-1,1)
        
        catlist{nc-1}{nu_cat} = cat_names(nuples_cat{nc-1,1}(nu_cat,:));
        
        olist = repmat(catlist{nc-1}{nu_cat}, NobjPerCat, 1);
        olist = olist(:);
        olist = strcat(olist, cellstr(num2str(onumbers(:))));
        
        for o=1:NobjPerCat
            
            objlist_test{nc-1}{nu_cat,o} = olist(o:4:end);
            objlist_train{nc-1}{nu_cat,o} = olist;
            objlist_train{nc-1}{nu_cat,o}(o:4:end) = [];
           
        end
    end
end
            
% save
save(objlist_train_path, 'objlist_train');
save(objlist_test_path, 'objlist_test');
save(catlist_path, 'catlist');
