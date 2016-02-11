%clear all;

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
dset = ICUBWORLDinit(dset_info);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup the question
%question_dir = 'frameORtransf';
%question_dir = 'frameORinst';
question_dir = '';

%% Input images
%dset_name = 'iCubWorldUltimate_centroid384_disp_finaltree';
%dset_name = 'iCubWorldUltimate_bb60_disp_finaltree';
dset_name = 'iCubWorldUltimate_centroid256_disp_finaltree';
%dset_name = 'iCubWorldUltimate_bb30_disp_finaltree';

%% Whether the model is finetuned or not
%mapping = '';
caffestuff.caffe_dir = caffe_dir;
mapping = 'tuning';

%% Caffe model

caffestuff.net_name = 'caffenet';
caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
caffestuff.preprocessing.GRID.nodes = 2; 
caffestuff.preprocessing.GRID.resize = false;
caffestuff.preprocessing.GRID.mirror = true;


model_dirname = 'model_conservative_bl_-05_fc8-N_01_fc7-N_01_fc6-N_01';

model_dirname = 'model_aggressive_bl_-03_fc8-N_01_fc7_00_fc6_00';

extract_features = true;
caffestuff.feat_names = {'pool5', 'fc7'};
%caffestuff.feat_names = {'conv3', 'conv4', 'pool5', 'fc6', 'fc7'};

% caffestuff.net_name = 'googlenet_caffe';
% caffestuff.preprocessing.SCALING.scales = [256 256];
% caffestuff.preprocessing.SCALING.aspect_ratio = false;
% caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
% caffestuff.preprocessing.GRID.nodes = 2; 
% caffestuff.preprocessing.GRID.resize = false;
% caffestuff.preprocessing.GRID.mirror = true;
% extract_features = false;

% caffestuff.net_name = 'googlenet_paper';
% caffestuff.preprocessing.SCALING.scales = [256; 288; 320; 352];
% caffestuff.preprocessing.SCALING.aspect_ratio = true;
% caffestuff.preprocessing.SCALING.central_scale = 1;
% caffestuff.preprocessing.OUTER_GRID = 3; % 1 or 3 or []
% caffestuff.preprocessing.GRID.nodes = 2; 
% caffestuff.preprocessing.GRID.resize = true;
% caffestuff.preprocessing.GRID.mirror = true;
% extract_features = false;

% caffestuff.net_name = 'vgg16';
% caffestuff.preprocessing.SCALING.scales = [256; 384; 512];
% caffestuff.preprocessing.SCALING.aspect_ratio = true;
% caffestuff.preprocessing.SCALING.central_scale = 2;
% caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
% caffestuff.preprocessing.GRID.nodes = 5; 
% caffestuff.preprocessing.GRID.resize = false;
% caffestuff.preprocessing.GRID.mirror = true;
% caffestuff.feat_names = {'fc6', 'fc7'};
% extract_features = true;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Categories
load('/data/giulia/ICUBWORLD_ULTIMATE/stuff/setlist_invariance_1');

trainval_prefixes = {'train_','val_'};

trainval_sets = [1,2];

eval_set = 3;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

extract_feat_and_pred_cat(DATA_DIR, dset, ...
    question_dir, model_dirname, ...
    dset_name, ...
    mapping, ...
    setlist, trainval_prefixes, trainval_sets, eval_set, ...
    caffestuff, extract_features);




