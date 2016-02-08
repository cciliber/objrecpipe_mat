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
same_size = false;
if same_size == true
    %question_dir = 'frameORtransf';
    question_dir = 'frameORinst';
else
    question_dir = '';
end

%% Whether to create fullpath registries
create_fullpath = false;
if create_fullpath
    dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');
else dset_dir = [];
end

%% Whether to create also the ImageNet labels
create_imnetlabels = true;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Categories
%setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
setlist.cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };

%% Set up the trials

% objects per category
setlist.obj_lists_all = { {1:dset.ObjPerCat} };

% transformation
setlist.transf_lists_all = { {1:dset.Ntransfs} };

% day
setlist.day_mappings_all = { {1:2} };
setlist.day_lists_all = create_day_list(setlist.day_mappings_all, dset.Days);

% camera
setlist.camera_lists_all = { {1}, {2} };

eval_set = 1;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_sets_cat(DATA_DIR, dset, ...
    same_size, question_dir, ...
    create_fullpath, dset_name, ...
    create_imnetlabels, ...
    setlist, eval_set);
