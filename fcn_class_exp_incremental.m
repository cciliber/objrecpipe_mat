function fcn_class_exp_incremental(machine, dataset_name, modality, task, feature_name)

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
classification_kind = 'incremental';

%% FEATURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%feature_name = 'fv_d64_pyrNO';
%feature_name = 'sc_d512';
%feature_name = 'sc_d512_dictIROS';
%feature_name = 'sc_d512_dictOnTheFly';
%feature_name = 'sc_d1024_dictIROS'; 
%feature_name = 'sc_d1024_iros';
%feature_name = 'overfeat_small_default';
%feature_name = 'caffe_centralcrop_meanimagenet2012';

%% MAIL SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run('setup_mail_matlab.m');

mail_recipient = {'giu.pasquale@gmail.com'};
mail_object = [mfilename '_' dataset_name];
mail_message = 'Successfully executed.';

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

experiments_path = fullfile(root_path, [dataset_name '_experiments']);
check_output_dir(experiments_path);

output_path = fullfile(experiments_path, classification_kind, feature_name);
check_output_dir(output_path);
  
if ~isempty(task)
    acc_filename = ['saved_output_' task '.mat'];
else
    acc_filename = 'saved_output.mat';
end
acc_path = fullfile(output_path, acc_filename);

% temporary structure for GURLS
opt_path = fullfile(output_path, 'opt');

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

experiments_path = fullfile(root_path, [dataset_name '_experiments']);
check_output_dir(experiments_path);

feature_path = fullfile(experiments_path, feature_name);
check_output_dir(feature_path);

%% REGISTRIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

registries_dir = fullfile(experiments_path, 'registries');
check_input_dir(registries_dir);

%% FOLDERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

objlist = obj_names;
%objlist = cat_names;
%objlist = [];

dayslist = modalities;
Ndays = numel(dayslist);

%% FILTERING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%windows = [1:20 24:4:50];
%fps = 7.5;
windows = [1:20 25:5:55];
fps = 11;

dt_frame = 1/fps; % sec
temporal_windows = windows*dt_frame;
nwindows = length(windows);

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% we are assuming the train/test data matrices to be cell arrays where
% each element contains the data for a day.

cellXtr = cell(Ndays,1);
cellXts = cell(Ndays,1);

cellYtr = cell(Ndays,1);
cellYts = cell(Ndays,1);

% load the data

for idx_day=1:Ndays
    
    feature_train_path = fullfile(feature_path, 'train', dayslist{idx_day});
    feature_test_path = fullfile(feature_path, 'test', dayslist{idx_day}, task);

    if ~isempty(modality)
        train_reg_file = [dataset_name '_train_' dayslist{idx_day} '_' modality '.txt'];
    else
        train_reg_file = [dataset_name '_train_' dayslist{idx_day} '.txt'];
    end
    if ~isempty(modality) && ~isempty(task)
        test_reg_file = [dataset_name '_test_' dayslist{idx_day} '_' modality '_' task '.txt'];
    elseif ~isempty(modality)
        test_reg_file = [dataset_name '_test_' dayslist{idx_day} '_' task '.txt'];
    elseif ~isempty(task)
        test_reg_file = [dataset_name '_test_' dayslist{idx_day} '_' modality '.txt'];
    else
        test_reg_file = [dataset_name '_test_' dayslist{idx_day} '.txt'];
    end
    
    train_reg_path = fullfile(registries_dir, train_reg_file);
    test_reg_path = fullfile(registries_dir, test_reg_file);
    
    [cellXtr{idx_day},cellYtr{idx_day},cellXts{idx_day},cellYts{idx_day}] = load_selectedXY(feature_train_path, train_reg_path, feature_test_path, test_reg_path, objlist, '.mat');
end

% create a single matrix containing all the tests

Xts = cell2mat(cellXts);
Yts = cell2mat(cellYts);

% find the indices at which split the matrix

start_indices = cell(Ndays,1);
end_indices = cell(Ndays,1);

curr_idx = 1;
for idx_day=1:Ndays
    start_indices{idx_day}=curr_idx;
    end_indices{idx_day}=curr_idx+size(cellXts{idx_day},1)-1;
    curr_idx = end_indices{idx_day}+1;
end
start_indices{end+1}=end_indices{end}+1;

% train and test

% the results structure contains 7 fields
% each field is a Ndays cell structure containing the system performance
% trained, incrementally, on subsequent days 
% (i.e. day 1 in cell element 1, day 1 + day 2 in cell element 2, and so on...)
% in particular they contain the average accuracy on:
% - present: the current day test set (e.g. train day 1+2+3 -> test on day 3)
% - past: all (and only) the test sets from previous days (e.g. train day 1+2+3 -> test on days 1+2)
% - future: all (and only) the test sets from future days (e.g. train day 1+2+3 -> test on days 4+5+...)
% - immediate_future: only the test set from the following day (e.g. train day 1+2+3 -> test on day 4)
% - immediate_past: only the test set from the past day (e.g. train day 1+2+3 -> test on day 2)
% - causal: all the test sets up to the current day (e.g. train day 1+2+3 -> test on days 1+2+3)
% - all: all the test sets (e.g. train day 1+2+3 -> test on days 1+2+3+4+5+...)

results = struct;
results.present = cell(Ndays,1);
results.past = cell(Ndays,1);
results.future = cell(Ndays,1);
results.immediate_past = cell(Ndays,1);
results.immediate_future = cell(Ndays,1);
results.causal = cell(Ndays,1);
results.all = cell(Ndays,1);

for idx_day=1:Ndays
    
    % create the train matrices
    
    Xtr = cell2mat(cellXtr(1:idx_day));
    Ytr = cell2mat(cellYtr(1:idx_day));
    
    Ypred = train_and_predict(Xtr, Ytr, Xts, opt_path);
    
    % accuracy on all test sets
    [~,~,results.all{idx_day}] = filter_y(Yts,Ypred,windows, 'gurls');
    
    % accuracy on current test set
    [~,~,results.present{idx_day}] = filter_y(...
        Yts(start_indices{idx_day}:end_indices{idx_day},:),...
        Ypred(start_indices{idx_day}:end_indices{idx_day},:),...
        windows,...
        'gurls');
   
    % accuracy on past test sets
    if idx_day>1
        [~,~,results.past{idx_day}] = filter_y(...
            Yts(1:end_indices{idx_day-1},:),...
            Ypred(1:end_indices{idx_day-1},:),...
            windows,...
            'gurls');
    else
        results.past{idx_day} = [];
    end
    
    % accuracy on future test sets
    if idx_day<Ndays
        [~,~,results.future{idx_day}] = filter_y(...
            Yts(start_indices{idx_day+1}:end,:),...
            Ypred(start_indices{idx_day+1}:end,:),...
            windows,...
            'gurls');
    else
        results.future{idx_day} = [];
    end
    
    % accuracy on immediate past test sets
    if idx_day>1
        [~,~,results.immediate_past{idx_day}] = filter_y(...
            Yts(start_indices{idx_day-1}:end_indices{idx_day-1},:),...
            Ypred(start_indices{idx_day-1}:end_indices{idx_day-1},:),...
            windows,...
            'gurls');
    else
        results.immediate_past{idx_day} = [];
    end
    
    % accuracy on the immediate future test set
    if idx_day<Ndays
        [~,~,results.immediate_future{idx_day}] = filter_y(...
            Yts(start_indices{idx_day+1}:end_indices{idx_day+1},:),...
            Ypred(start_indices{idx_day+1}:end_indices{idx_day+1},:),...
            windows,...
            'gurls');
    else
        results.immediate_future{idx_day} = [];
    end
    
    % accuracy on past and current test sets
    [~,~,results.causal{idx_day}] = filter_y(...
        Yts(1:end_indices{idx_day},:),...
        Ypred(1:end_indices{idx_day},:),...
        windows,...
        'gurls');

    save(acc_path,'results');
    
%     % send e-mail
%     try
%         
%         mail_object = ['Incremental learning on ' dataset_name ' - Day ' num2str(idx_day)];
%         mail_message = [...
%             'I have successfully trained and tested on the dataset' 10 ...
%             'Results have been saved on ' acc_path 10 ...
%             'Accuracies are:' 10 ...
%             'Present: ' num2str(cell2mat(results.present{idx_day})) 10 ...
%             'Past: ' num2str(cell2mat(results.past{idx_day})) 10 ...
%             'Future: ' num2str(cell2mat(results.future{idx_day})) 10 ...
%             'Immediate Past: ' num2str(cell2mat(results.immediate_past{idx_day})) 10 ...
%             'Immediate Future: ' num2str(cell2mat(results.immediate_future{idx_day})) 10 ...
%             'Causal: ' num2str(cell2mat(results.causal{idx_day})) 10 ...
%             'All: ' num2str(cell2mat(results.all{idx_day})) 10 ...
%         ]; 
%         
%         fprintf(mail_message);
%         
%         sendmail(mail_recipient,mail_object,mail_message);
%         
%     catch err
%         display(err);
%     end

end