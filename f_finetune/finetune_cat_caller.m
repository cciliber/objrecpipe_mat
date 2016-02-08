clear all;

%% Code dir
FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% VL FEAT
vl_feat_setup();

%% GURLS
gurls_setup();

%% MATLAB CAFFE
%caffe_dir = '/usr/local/src/robot/caffe';
caffe_dir = '/data/giulia/REPOS/caffe';
addpath(genpath(fullfile(caffe_dir, 'matlab')));

%% Global data dir
DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

%% Dataset info
dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';
dset = ICUBWORLDinit(dset_info);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup the question
%question_dir = 'frameORtransf';
%question_dir = 'frameORinst';
question_dir = '';

%% Input images
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

%% Binaries 
caffe_bin_path = fullfile(caffe_dir, 'build/install/bin/caffe');
create_lmdb_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/create_lmdb/build/create_lmdb_icubworld');
compute_mean_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/compute_mean/build/compute_mean_icubworld');
parse_log_path = fullfile(FEATURES_DIR, 'f_finetune/parse_caffe_log.sh');

%% Caffe model

%model = 'caffenet';
%model = 'googlenet_caffe';
oversample = true;

%model = 'googlenet_paper';
oversample = true;
overscale = true;
%GRID = '3-2';
%GRID = '1-2';
%GRID = '3-1';

%model = 'vgg16';
oversample = true;
overscale = true;
%GRID='1x1';
%GRID = '5x5';

caffestuff = setup_caffemodel(caffe_dir, model, oversample, overscale, GRID);

template_prototxts_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_prototxts/template_models');

if strcmp(model, 'caffenet')

    % net definition
    caffestuff.net_model_template = fullfile(template_prototxts_path, model, 'train_val_template.prototxt');
    caffestuff.net_model_struct_types = fullfile(template_prototxts_path, model, 'train_val_struct_types.txt');
    caffestuff.net_model_struct_values = fullfile(template_prototxts_path, model, 'train_val_struct_values.txt');
    
    % net initialization 
    % suypposing that the fine-tuning is the same for all experiments
    net_params = create_struct_from_txt(caffestuff.net_model_struct_types, caffestuff.net_model_struct_values);              
    net_params.fc8_name = 'fc8_icub';
    net_params.fc8_top = 'fc8_icub';
    net_params.fc8_lr_mult_W = 10;
    net_params.fc8_lr_mult_b = 20;
    net_params.accuracy_bottom = 'fc8_icub';
    net_params.loss_bottom = 'fc8_icub';
  
    % solver definition
    caffestuff.solver_template = fullfile(template_prototxts_path, model, 'solver_template.prototxt');
    caffestuff.solver_struct_types = fullfile(template_prototxts_path, model, 'solver_struct_types.txt');
    caffestuff.solver_struct_values = fullfile(template_prototxts_path, model, 'solver_struct_values.txt');
    
    % solver initialization
    % suypposing that the fine-tuning is the same for all experiments
    solver_params = create_struct_from_txt(caffestuff.solver_struct_types, caffestuff.solver_struct_values);         
    solver_params.base_lr = 0.001;

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Categories
%setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
setlist.cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };

% objects
setlist.obj_lists_all = { {1:NobjPerCat, 1:NobjPerCat} };

% transformation
setlist.transf_lists_all = { {1:5, 1:5} };

% day
setlist.day_mappings_all = { {1, 1} };
setlist.day_lists_all = create_day_list(day_mappings_all, opts.Days);

% camera
setlist.camera_lists_all = { {1, 1} };

trainval_prefixes = {'train_', 'val_'};
trainval_sets = [1 2];
tr_set = trainval_sets(1);
val_set = trainval_sets(2);
                    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finetune_cat(question_dir, ...
    dset_dir, ...
    setlist, trainval_prefixes, trainval_sets, tr_set, val_set, ...
    caffestuff, net_params, solver_params, ...
    caffe_bin_path, create_lmdb_bin_path, compute_mean_bin_path, parse_log_path);