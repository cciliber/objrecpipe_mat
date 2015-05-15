function fcn_class_exp_objrec_inter_cat(machine, dataset_name, modality, task, feature_name)

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
    
    % points to build dir inside GURLS dir usually
    GURLS_DIR = getenv('GURLS_DIR');
    GURLS_DIR = GURLS_DIR(1:(end-6));
    run(fullfile(GURLS_DIR, 'gurls/utils/gurls_install.m'));
    
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
classification_kind = 'obj_rec_inter_class';
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

%% MAIL SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run('setup_mail_matlab.m');

mail_recipient = {'giu.pasquale@gmail.com'};
mail_object = [mfilename '_' dataset_name];
mail_message = 'Successfully executed.';

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

experiments_path = fullfile(root_path, [dataset_name '_experiments']);
check_output_dir(experiments_path);

feature_path = fullfile(experiments_path, feature_name);
check_output_dir(feature_path);

feature_train_path = fullfile(feature_path, 'train', modality);
feature_test_path = fullfile(feature_path, 'test', modality, task);

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

output_path = fullfile(experiments_path, classification_kind, feature_name);
check_output_dir(output_path);

if isempty(task) && isempty(modality)
    ys_filename = 'saved_output.mat';
elseif isempty(modality)
     ys_filename = ['saved_output_' task '.mat'];
elseif isempty(task)
     ys_filename = ['saved_output_' modality '.mat'];
else
    ys_filename = ['saved_output_' modality '_' task '.mat'];
end
ys_path = fullfile(output_path, ys_filename);

% temporary structure for GURLS
opt_path = fullfile(output_path, ['opt_' modality]);

%% REGISTRIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
registries_dir = fullfile(experiments_path, 'registries');
check_input_dir(registries_dir);

% INPUT

if ~isempty(modality)
    in_registry_train_file = [dataset_name '_train_' modality '.txt'];
else
    in_registry_train_file = [dataset_name '_train.txt'];
end
if ~isempty(modality) && ~isempty(task) 
    in_registry_test_file = [dataset_name '_test_' modality '_' task '.txt'];
elseif ~isempty(modality)
    in_registry_test_file = [dataset_name '_test_' modality '.txt'];
elseif ~isempty(task)
    in_registry_test_file = [dataset_name '_test_' task '.txt'];
else
    in_registry_test_file = [dataset_name '_test.txt'];
end
    
in_registry_train_path = fullfile(registries_dir, in_registry_train_file);
in_registry_test_path = fullfile(registries_dir, in_registry_test_file);

% OUTPUT 

out_registry_train_file = [];
out_registry_test_file = [];

out_registry_train_path = [];
out_registry_test_path = [];

%% FOLDERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

objlist_filename = 'objlist_objrec_inter_cat.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

loaded_list = load(fullfile(experiments_path, objlist_filename));
objlist = loaded_list.objlist;

Nnuples = zeros(1, Ncat-1);
for no=1:Ncat-1
    Nnuples(no) = size(objlist{no},1);
end

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% generic object creation 

feat_train = Features.GenericFeature();
feat_test = Features.GenericFeature();

% output cell array initialization

cell_output = cell(Ncat-1,1);
for no=1:Ncat-1
    cell_output{no} = cell(Nnuples(no),NobjPerCat);
end
save(ys_path, 'cell_output');

% classifcation of specified nuples

for nc=2:Ncat
    
    for nu_cat=1:Nnuples(nc-1)
        
        for o=1:NobjPerCat
              
            % X and y preparation
            
            % ARGUMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % common
            
            feat_ext = '.mat';
            selected_folders = objlist{nc-1}{nu_cat,o};
            out_registry_path = [];
            
            y_path = [];
            labels_list = selected_folders;
        
            % train 
        
            feat_rootpath = feature_train_path;
            in_registry_path = in_registry_train_path;
        
            feat_train.load_feat(feat_rootpath, in_registry_path, feat_ext, selected_folders, out_registry_path);
            ytr = create_y(feat_train.Registry, labels_list, y_path);

            % test
            
            feat_rootpath = feature_test_path;
            in_registry_path = in_registry_test_path;
            
            feat_test.load_feat(feat_rootpath, in_registry_path, feat_ext, selected_folders, out_registry_path);
            yte = create_y(feat_test.Registry, labels_list, y_path);
            
            % GURLS initialization
            
            opt = defopt(opt_path);
            
            opt.hoproportion = 0.5;
            opt.nlambda = 20;
            opt.kernel.type = 'linear';
            opt.paramsel.hoperf = @perf_macroavg;
            opt.seq = {'kernel:linear','split:ho', 'paramsel:hodual', 'rls:dual', 'pred:dual', 'perf:macroavg'};
            
            opt.process{1} = [2,2,2,2,0,0];
            opt.process{2} = [3,3,3,3,2,2];
            
            % train
            
            Xtr = feat_train.Feat';
            Xm = mean(Xtr,1);
            Xtr = Xtr - ones(size(Xtr,1),1)*Xm;
            
            gurls (Xtr, ytr, opt, 1);
            clear Xtr sc_train.Feat;
            
            % test
            
            Xte = feat_test.Feat';
            Xte = Xte - ones(size(Xte,1),1)*Xm;
            
            gurls (Xte, yte, opt, 2);
            clear Xte sc_test.Feat;
            
            % store results
         
            result = load(opt.savefile);
            load(ys_path);
            
            cell_output{nc-1}{nu_cat, o}.accuracy = result.opt.perf.acc;
            cell_output{nc-1}{nu_cat, o}.ypred_double = result.opt.pred;
            [~, yte_class] = max(yte, [], 2);
            cell_output{nc-1}{nu_cat, o}.y = yte_class;
            cell_output{nc-1}{nu_cat, o}.experiment = selected_folders;

            save(ys_path, 'cell_output');
            delete(result.opt.savefile);

            disp(['nc = ' num2str(nc) ' nu_cat = ' num2str(nu_cat) ' o = ' num2str(o)]);
        end
    end
end

% try
%     sendmail(mail_recipient,mail_object,mail_message);
% catch err
%     display(err);
% end