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

%% Input scores
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

%% Whether the scores are from a finetuned model or not
mapping = '';

%% Caffe model
%model = 'googlenet_caffe';
%model = 'googlenet_paper';
caffe_model = 'caffenet';
%model = 'vgg16';

%% Caffe features
feature = 'fc6';

%% Whether to train a model or load a model and test it
gurls_model = 'compute'; % 'compute' or 'load'

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Categories
%setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
setlist.cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };

% objects
setlist.obj_lists_all = { {1:NobjPerCat, 1:NobjPerCat, 1:NobjPerCat} };

% transformation
%setlist.transf_lists_all = { {1, 1:Ntransfs}; {2, 1:Ntransfs}; {3, 1:Ntransfs}; {4, 1:Ntransfs}};
setlist.transf_lists_all = { {5, 1:Ntransfs}; {4:5, 1:Ntransfs}; {[2 4:5], 1:Ntransfs}; {2:5, 1:Ntransfs}; {1:Ntransfs, 1:Ntransfs} };

% day
setlist.day_mappings_all = { {1, 1, 1} };
setlist.day_lists_all = create_day_list(day_mappings_all, opts.Days);

% camera
setlist.camera_lists_all = { {1, 1, 1} };

trainval_prefixes = {'train_', 'val_'};
trainval_sets = [1 2];
tr_set = trainval_sets(1);
val_set = trainval_sets(2);
eval_set = 3;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

compute_RLS_pred(dset, ...
    question_dir, ...
    dset_dir, ...
    mapping, ...
    setlist, trainval_prefixes, trainval_sets, train_set, val_set, eval_set, gurls_model, ...
    caffe_model, feature);
