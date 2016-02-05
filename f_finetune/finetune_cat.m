
clear all;

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%caffe_dir = '/usr/local/src/robot/caffe/';
caffe_dir = '/data/giulia/REPOS/caffe';

matlab_interface = false;
if matlab_interface
    % if using the Matlab interface to perform the training
    addpath(genpath(fullfile(caffe_dir, 'matlab')));
else
    % if using the command line interface to perform the training
    caffe_bin_path = fullfile(caffe_dir, 'build/install/bin/caffe');
end

gpu_id = 0;
phase = 'train';

%% This code setup

create_lmdb_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/create_lmdb/build/create_lmdb_icubworld');
compute_mean_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/compute_mean/build/compute_mean_icubworld');
template_prototxt_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_prototxts/template_models');
parse_log_path = fullfile(FEATURES_DIR, 'f_finetune/parse_caffe_log.sh');

%% Global data dir
DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

%% Dataset info

dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat);
%obj_names = keys(opts.Obj)';
transf_names = keys(opts.Transfs)';
day_names = keys(opts.Days)';
camera_names = keys(opts.Cameras)';

Ncat = opts.Cat.Count;
Nobj = opts.Obj.Count;
NobjPerCat = opts.ObjPerCat;
Ntransfs = opts.Transfs.Count;
Ndays = opts.Days.Count;
Ncameras = opts.Cameras.Count;

%% Where to put the models
mapping = 'tuning';

%% Setup the question
same_size = false;
if same_size == true
    %question_dir = 'frameORtransf';
    question_dir = 'frameORinst';
end

%% Set up the IO root directories

% input images
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

% input registries
input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% output root
exp_dir = fullfile([dset_dir '_experiments'], 'categorization');
check_output_dir(exp_dir);

%% Categories
%cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };

%% Set up train and val test sets

% objects per category
Ntest = 1;
Nval = 1;
Ntrain = NobjPerCat - Ntest - Nval;
obj_lists_all = cell(Ntrain, 1);
p = randperm(NobjPerCat);
for oo=1:Ntrain
    obj_lists_all{oo} = cell(1,3);
    obj_lists_all{oo}{3} = p(1:Ntest);
    obj_lists_all{oo}{2} = p((Ntest+1):(Ntest+Nval));
    obj_lists_all{oo}{1} = p((Ntest+Nval+1):(Ntest+Nval+oo));
end

% transformation
%transf_lists_all = { {1, 1:Ntransfs}; {2, 1:Ntransfs}; {3, 1:Ntransfs}; {4, 1:Ntransfs}};
%transf_lists_all = { {5, 1:Ntransfs}; {4:5, 1:Ntransfs}; {[2 4:5], 1:Ntransfs}; {2:5, 1:Ntransfs}; {1:Ntransfs, 1:Ntransfs} };
transf_lists_all = { {5, 2} };
%transf_lists_all = { {1:Ntransfs} };

% day
day_mappings_all = { {1, 1} };
day_lists_all = create_day_list(day_mappings_all, opts.Days);

% camera
camera_lists_all = { {1, 1} };

set_name_prefixes = {'train_', 'val_'};
Nsets = length(set_name_prefixes);

%% Caffe model

model = 'caffenet';

if strcmp(model, 'caffenet')
    
    % model dir
    model_dir = fullfile(caffe_dir, 'models/bvlc_reference_caffenet/');
    
    % net weights
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_reference_caffenet.caffemodel');
    
    MEAN_W = 256;
    MEAN_H = 256;
    
    CROP_SIZE = 227;

    oversample = false;
    if oversample
        NCROPS=10;
    else
        NCROPS=1;
    end
    
    % remember that actual caffe batch size is max_bsize*NCROPS !!!!
    max_bsize = 512;
    
    % net definition
    caffepaths.net_model_template = fullfile(template_prototxt_path, model, 'train_val_template.prototxt');
    caffepaths.net_model_struct_types = fullfile(template_prototxt_path, model, 'train_val_struct_types.txt');
    caffepaths.net_model_struct_values = fullfile(template_prototxt_path, model, 'train_val_struct_values.txt');
    
    % net initialization 
    % suypposing that the fine-tuning is the same for all experiments
    net_params = create_struct_from_txt(caffepaths.net_model_struct_types, caffepaths.net_model_struct_values);              
    net_params.fc8_name = 'fc8_icub';
    net_params.fc8_top = 'fc8_icub';
    net_params.fc8_lr_mult_W = 10;
    net_params.fc8_lr_mult_b = 20;
    net_params.accuracy_bottom = 'fc8_icub';
    net_params.loss_bottom = 'fc8_icub';
  
    % solver definition
    caffepaths.solver_template = fullfile(template_prototxt_path, model, 'solver_template.prototxt');
    caffepaths.solver_struct_types = fullfile(template_prototxt_path, model, 'solver_struct_types.txt');
    caffepaths.solver_struct_values = fullfile(template_prototxt_path, model, 'solver_struct_values.txt');
    
    % solver initialization
    % suypposing that the fine-tuning is the same for all experiments
    solver_params = create_struct_from_txt(caffepaths.solver_struct_types, caffepaths.solver_struct_values);         
    solver_params.base_lr = 0.001;
    
elseif strcmp(model, 'googlenet')
    
    model_dir = fullfile(caffe_dir, 'models/bvlc_googlenet/');
    
    CROP_SIZE = 224;
    
    % whether to consider multiple scales
    %SHORTER_SIDE = [256 288 320 352];
    SHORTER_SIDE = 256;
    
    % whether to consider multiple crops
    %GRID = '3-2';
    %GRID = '1-2';
    %GRID = '3-1';
    GRID='1x1';
    %GRID = '5x5';
    
    %% assign number of total crops per image
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
        else
            NCROPS = grid_side;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        if grid_side>1
            NCROPS = grid_side*grid_side*2;
        else
            NCROPS = 1;
        end
    end
    NCROPS=NCROPS*length(SHORTER_SIDE);
    
    % remember that actual caffe batch size is max_bsize*NCROPS !!!!
    max_bsize = 10;
    
    % net definition
    caffepaths.net_model = fullfile(model_dir, 'train_val.prototxt');
    
    % solver definition
    caffepaths.solver = fullfile(model_dir, 'solver.prototxt');
    
    % net weights
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_googlenet.caffemodel');

elseif strcmp(model, 'vgg16')
    
    model_dir = fullfile(caffe_dir, 'models/VGG/VGG_ILSVRC_16');
    
    CROP_SIZE = 224;
    
    % whether to consider multiple scales
    %SHORTER_SIDE = [256 288 320 352];
    SHORTER_SIDE = 256;
    
    % whether to consider multiple crops
    %GRID = '3-2';
    %GRID = '1-2';
    %GRID = '3-1';
    %GRID='1x1';
    GRID = '5x5';
    
    %% assign number of total crops per image
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
        else
            NCROPS = grid_side;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        NCROPS = grid_side*grid_side*2;
    end
    NCROPS=NCROPS*length(SHORTER_SIDE);
    
    % remember that actual caffe batch size is max_bsize*NCROPS !!!!
    max_bsize = 2;
    
    % net definition
    caffepaths.net_model = fullfile(model_dir, 'VGG_ILSVRC_16_layers_train_val.prototxt');
    
    % solver definition
    caffepaths.solver = fullfile(model_dir, 'solver.prototxt');
    
    % net weights
    caffepaths.net_weights = fullfile(model_dir, 'VGG_ILSVRC_16_layers.caffemodel');
    
end

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        for itransf=1:length(transf_lists_all)
            
            transf_lists = transf_lists_all{itransf};
            
            for iday=1:length(day_lists_all)
                
                day_lists = day_lists_all{iday};
                day_mappings = day_mappings_all{iday};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_lists = camera_lists_all{icam};
                    
                    %% Create the train val folder name 
                    for iset=1:Nsets
                        set_names{iset} = [strrep(strrep(num2str(obj_lists{iset}), '   ', '-'), '  ', '-') ...
                        '_tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-') ...
                        '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-') ...
                        '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-')];
                    end
                    trainval_dir = cell2mat(strcat(set_name_prefixes(:), '_', set_names(:))');
                    
                    %% Number of classes
                    num_output = length(cat_idx);
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(num_output)], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir = fullfile(exp_dir, model, dir_regtxt_relative, trainval_dir, mapping, 'model');
                    check_output_dir(output_dir);
                    
                    %% Create lmdbs
                    
                    dbname = cell(Nsets,1);
                    dbpath = cell(Nsets,1);
                    Nsamples = zeros(Nsets, 1);
                    for iset=1:Nsets
                        
                        % create lmdb         
                        filelist = fullfile(input_dir_regtxt, [set_names{iset} '.txt']);
                        
                        dbname{iset} = [set_name_prefixes{iset} '_Y_lmdb'];   
                        dbpath{iset} = fullfile(output_dir, dbname{iset});

                        command = sprintf('%s --resize_width=%d --resize_height=%d --shuffle %s %s %s', create_lmdb_bin_path, MEAN_W, MEAN_H, [dset_dir '/'], filelist, dbpath{iset});
                        [status, cmdout] = system(command);
                        if status~=0
                            error(cmdout);
                        end
                        
                        % get number of samples
                        Nsamples(iset) = get_linecount(filelist); 
                        
                    end
                    
                    %% Compute train mean image (binaryproto)
                        
                    tr_set = find(strcmp(set_name_prefixes, 'train_')>0);
                    val_set = find(strcmp(set_name_prefixes, 'val_')>0);
                    
                    mean_name = [set_name_prefixes{tr_set} '_mean.binaryproto'];                   
                    mean_path = fullfile(output_dir, mean_name);
                        
                    command = sprintf('%s %s %s', compute_mean_bin_path, dbpath{tr_set}, mean_path);
                    [status, cmdout] = system(command);
                    if status~=0
                       error(cmdout);
                    end
 
                    %% Modify net definition
                    
                    net_model_name = 'train_val.prototxt';
                    caffepaths.net_model = fullfile(output_dir, net_model_name);
                       
                    net_params.fc8_num_output = num_output;
                    
                    net_params.train_mean_file = mean_name;
                    net_params.train_source = dbname{tr_set};
                    net_params.val_source = dbname{val_set};
                    net_params.val_mean_file = mean_name;
                      
                    min(net_params.train_batch_size, Nsamples(tr_set)); % check train batch size 
                    net_params.val_batch_size = min(net_params.val_batch_size, Nsamples(val_set)); % check test batch size
    
                    customize_prototxt(caffepaths.net_model_template, struct2cell(net_params), caffepaths.net_model);
                      
                    %% Modify solver definition 
                    
                    caffepaths.solver = fullfile(output_dir, 'solver.prototxt');
                    
                    solver_params.net = net_model_name;
                    solver_params.snapshot_prefix = 'snap';
                    
                    % num iters to perform one epoch
                    epoch_train = ceil(Nsamples(tr_set) / double(net_params.train_batch_size));
                    epoch_val = ceil(Nsamples(val_set) / double(net_params.val_batch_size));
                    
                    % in epochs
                    test_iter = 1;
                    test_interval = 1;
                    display = 1;
                    snapshot = 1;
                    
                    max_iter = 6;
                    stepsize = max_iter/3;
                    
                    solver_params.test_iter = test_iter*epoch_val;
                    solver_params.test_interval = test_interval*epoch_train;
                    solver_params.display = display*epoch_train;
                    
                    solver_params.max_iter = max_iter*epoch_train;
                    solver_params.stepsize = stepsize*epoch_train;                 
                    solver_params.snapshot = snapshot*epoch_train;
                    
                    customize_prototxt(caffepaths.solver_template, struct2cell(solver_params), caffepaths.solver);
                        
                    %% Train
                    
                    % cd because the paths are relative to 'output_dir'
                    curr_dir = cd(output_dir);
                    
                    if matlab_interface
                        % using Matlab interface
                        caffe.set_mode_gpu();
                        caffe.set_device(gpu_id);
                        solver = caffe.Solver(caffepaths.solver);
                        solver.net.copy_from(caffepaths.net_weights);
                        solver.solve();
                        caffe.reset_all(); % clear net and solver
                    else 
                        % or calling the command line interface
                        command = sprintf('%s train -solver %s -weights %s -gpu %d --log_dir=%s', ...
                            caffe_bin_path, caffepaths.solver, caffepaths.net_weights, gpu_id, output_dir);
                        [status, cmdout] = system(command);
                        if status~=0
                            error(cmdout);
                        end
                    end
                    
                    %% Choose epoch
                    
                    % parse the logs
                    command = sprintf('%s %s', parse_log_path, fullfile(output_dir, 'caffe.INFO'));
                    [status, cmdout] = system(command);
                    if status~=0
                       error(cmdout);
                    end
                    
                    cd(curr_dir);
                    
                    % maximize val accuracy
                    T = readtable(fullfile(output_dir, 'caffe.INFO.test.txt'), 'Delimiter', ',');
                    val_acc = T.acc;
                    [~, epoch_idx] = max(val_acc);
 
                    % find correspondent model
                    epoch = num2str(T.iter(epoch_idx));
                    modelname = [solver_params.snapshot_prefix '_iter_' epoch '.caffemodel'];
                    solverstatename = [solver_params.snapshot_prefix '_iter_' epoch '.solverstate'];

                    % rename it
                    movefile(modelname,'best_model.caffemodel');
                    movefile(solverstatename,'best_model.solverstate');
                    
                    % clear others
                    delete('snap_*.caffemodel');
                    delete('snap_*.solverstate');
                    
                    % delete train/val lmdbs (but leave the mean)
                    rmdir(dbpath{tr_set}, 's');
                    rmdir(dbpath{val_set}, 's');
                        
                end
            end
        end
    end
end
