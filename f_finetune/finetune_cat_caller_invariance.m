
in = input('clear all? [0/1] ');
if in
    clear all;
end

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

caffestuff.net_name = 'caffenet';
caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
caffestuff.preprocessing.GRID.nodes = 2; 
caffestuff.preprocessing.GRID.resize = false;
caffestuff.preprocessing.GRID.mirror = true;
caffestuff.feat_names = {'fc6', 'fc7'};
extract_features = true;

%%%%% WARNING!!!!!
caffestuff.net_weights = '/data/giulia/REPOS/caffe/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';
caffestuff.MEAN_W = 256;
caffestuff.MEAN_H = 256;
%%%%%%%%%%%%%%%%%%%%%%%%%%


template_prototxts_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_prototxts/template_models');

human_readable_name = 'aggressive';
base_lr = 1e-3;
fc8_name = 'fc8-N';
fc7_name = 'fc7';
fc6_name = 'fc6';
fc8_final_W = 10*base_lr;
fc7_final_W = base_lr;
fc6_final_W = base_lr;
fc8_final_b = 2*fc8_final_W;
fc7_final_b = 2*fc7_final_W;
fc6_final_b = 2*fc6_final_W;

% human_readable_name = 'conservative';
% base_lr = 1e-5;
% fc8_name = 'fc8-N';
% fc7_name = 'fc7-N';
% fc6_name = 'fc6-N';
% fc8_final_W = 10*base_lr;
% fc7_final_W = 10*base_lr;
% fc6_final_W = 10*base_lr;
% fc8_final_b = 2*fc8_final_W;
% fc7_final_b = 2*fc7_final_W;
% fc6_final_b = 2*fc6_final_W;

model_dirname = sprintf('model_%s_bl_%.2d_%s_%.2d_%s_%.2d_%s_%.2d', human_readable_name, ...
    floor(log10(base_lr)), ...
    fc8_name, floor(log10(fc8_final_W/base_lr)), ...
    fc7_name,floor(log10(fc7_final_W/base_lr)), ...
    fc6_name,floor(log10(fc6_final_W/base_lr)));


if strcmp(caffestuff.net_name, 'caffenet')

    % net definition
    caffestuff.net_model_template = fullfile(template_prototxts_path, caffestuff.net_name, 'train_val_template.prototxt');
    caffestuff.net_model_struct_types = fullfile(template_prototxts_path, caffestuff.net_name, 'train_val_struct_types.txt');
    caffestuff.net_model_struct_values = fullfile(template_prototxts_path, caffestuff.net_name, 'train_val_struct_values.txt');
    
    % net initialization 
    % suypposing that the fine-tuning is the same for all experiments
    net_params = create_struct_from_txt(caffestuff.net_model_struct_types, caffestuff.net_model_struct_values);        
    
    net_params.fc8_lr_mult_W = fc8_final_W/base_lr;
    net_params.fc8_lr_mult_b = fc8_final_b/base_lr;
    
    net_params.fc7_lr_mult_W = fc7_final_W/base_lr;
    net_params.fc7_lr_mult_b = fc7_final_b/base_lr;
    
    net_params.fc6_lr_mult_W = fc6_final_W/base_lr;
    net_params.fc6_lr_mult_b = fc6_final_b/base_lr;
    
    %net_params.drop6_dropout_ratio = 0.5000;
    %net_params.drop7_dropout_ratio = 0.5000;
    
    net_params.fc8_name = fc8_name;
    net_params.fc8_top = fc8_name;
    net_params.accuracy_bottom = fc8_name;
    net_params.loss_bottom = fc8_name;
    
    net_params.fc6_name = fc6_name;
    net_params.fc6_top = fc6_name;
    net_params.relu6_bottom = fc6_name;
    net_params.relu6_top = fc6_name;
    net_params.drop6_bottom = fc6_name;
    net_params.drop6_top = fc6_name;
    net_params.fc7_bottom = fc6_name;
   
    net_params.fc7_name = fc7_name;
    net_params.fc7_top = fc7_name;
    net_params.relu7_bottom = fc7_name;
    net_params.relu7_top = fc7_name;
    net_params.drop7_bottom = fc7_name;
    net_params.drop7_top = fc7_name;
    net_params.fc8_bottom = fc7_name;
  
    % deploy definition
    caffestuff.deploy_model_template = fullfile(template_prototxts_path, caffestuff.net_name, 'deploy_template.prototxt');
    caffestuff.deploy_model_struct_types = fullfile(template_prototxts_path, caffestuff.net_name, 'deploy_struct_types.txt');
    caffestuff.deploy_model_struct_values = fullfile(template_prototxts_path, caffestuff.net_name, 'deploy_struct_values.txt');
    
    % deploy initialization 
    % suypposing that the fine-tuning is the same for all experiments
    deploy_params = create_struct_from_txt(caffestuff.deploy_model_struct_types, caffestuff.deploy_model_struct_values);              
    
    fnames = fieldnames(deploy_params);
    for ii=1:length(fnames)
        if isfield(net_params, fnames{ii})
            deploy_params.(fnames{ii}) = net_params.(fnames{ii});
        else
            warning('Field not present in trainval: %s. Are you assigning it separately?', fnames{ii});
        end
    end
    deploy_params.prob_bottom = deploy_params.fc8_top;
     
    % solver definition
    caffestuff.solver_template = fullfile(template_prototxts_path, caffestuff.net_name, 'solver_template.prototxt');
    caffestuff.solver_struct_types = fullfile(template_prototxts_path, caffestuff.net_name, 'solver_struct_types.txt');
    caffestuff.solver_struct_values = fullfile(template_prototxts_path, caffestuff.net_name, 'solver_struct_values.txt');
    
    % solver initialization
    % suypposing that the fine-tuning is the same for all experiments
    solver_params = create_struct_from_txt(caffestuff.solver_struct_types, caffestuff.solver_struct_values);         
    solver_params.base_lr = base_lr;

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


load('/data/giulia/ICUBWORLD_ULTIMATE/stuff/setlist_invariance_1');


trainval_prefixes = {'train_', 'val_'};
trainval_sets = [1 2];
tr_set = trainval_sets(1);
val_set = trainval_sets(2);
                    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finetune_cat(DATA_DIR, question_dir, model_dirname, ...
    dset_dir, ...
    setlist, trainval_prefixes, trainval_sets, tr_set, val_set, ...
    caffestuff, net_params, deploy_params, solver_params, ...
    caffe_bin_path, create_lmdb_bin_path, compute_mean_bin_path, parse_log_path);



