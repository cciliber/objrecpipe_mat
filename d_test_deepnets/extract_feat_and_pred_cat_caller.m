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
mapping = '';
%mapping = 'tuning';

%% Caffe model

model = 'caffenet';
%model = 'googlenet_caffe';
oversample = true;
overscale = [];
GRID = [];

%model = 'googlenet_paper';
%oversample = true;
%overscale = true;
%GRID = '3-2';
%GRID = '1-2';
%GRID = '3-1';

%model = 'vgg16';
%oversample = true;
%overscale = true;
%GRID='1x1';
%GRID = '5x5';

caffestuff = setup_caffemodel(caffe_dir, model, oversample, overscale, GRID);

%% Whether to extract also the features
extract_features = true;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Categories
%setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
setlist.cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };

if ~isempty(mapping)
    
    %% Set up train, val and test sets
    
    % objects per category
    Ntest = 1;
    Nval = 1;
    Ntrain = dset.NobjPerCat - Ntest - Nval; 
    setlist.obj_lists_all = cell(Ntrain, 1);
    p = randperm(nset.NobjPerCat);
    for oo=1:Ntrain 
        setlist.obj_lists_all{oo} = cell(1,3);
        setlist.obj_lists_all{oo}{3} = p(1:Ntest);
        setlist.obj_lists_all{oo}{2} = p((Ntest+1):(Ntest+Nval));
        setlist.obj_lists_all{oo}{1} = p((Ntest+Nval+1):(Ntest+Nval+oo));
    end

    % transformation
    setlist.transf_lists_all = { {1:dset.Ntransfs, 1:dset.Ntransfs, 1:dset.Ntransfs}; {1, 1, 1} };

    % day
    setlist.day_mappings_all = { {1, 1, 1} };
    setlist.day_lists_all = create_day_list(setlist.day_mappings_all, dset.Days);

    % camera
    setlist.camera_lists_all = { {1, 1, 1} };
    
    % sets
    eval_set = 3;
    trainval_sets = [1 2];
    trainval_prefixes = {'train_', 'val_'};
    
else 

    %% Just set up the test set
    
    % objects per category
    setlist.obj_lists_all = { {1:dset.NobjPerCat} };
    
    % transformation
    setlist.transf_lists_all = { {1:dset.Ntransfs} };
    
    % day
    setlist.day_mappings_all = { {2} };
    setlist.day_lists_all = create_day_list(setlist.day_mappings_all, dset.Days);
    
    % camera
    setlist.camera_lists_all = { {1}, {2} };

    eval_set = 1;
    trainval_sets = [];
    trainval_prefixes = {};
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

extract_feat_and_pred_cat(DATA_DIR, dset, ...
    question_dir, ...
    dset_name, ...
    mapping, ...
    setlist, trainval_prefixes, trainval_sets, eval_set, ...
    caffestuff, extract_features);