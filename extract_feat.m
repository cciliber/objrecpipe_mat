%% MACHINE

% depending on the machine:
% GURLS and/or VL_FEAT are initialized
% FEATURES_DIR is set and added to Matlab path
% 'root_path' is set, dir containing every input/output dir from now on

%machine_tag = 'server';
%machine_tag = 'laptop_giulia_win';
%machine_tag = 'laptop_giulia_lin';
machine_tag = 'ws_vicolab';

root_path = init_machine(machine_tag);

%% MAIL 

run('setup_mail_matlab.m');

mail_recipient = {'giu.pasquale@gmail.com'};
mail_object = mfilename;
mail_message = 'Successfully executed.';

%% DATASET NAME

% name of the directory inside 'root_path' that is root of the dataset 

%dataset_name = 'Groceries_4Tasks';
%dataset_name = 'Groceries';
%dataset_name = 'Groceries_SingleInstance';
%dataset_name = 'iCubWorld0';
%dataset_name = 'iCubWorld20';
dataset_name = 'iCubWorld30';
%dataset_name = 'cfr_caffe_cpp_matlab';

%% MODALITY

% optional subfolder inside dataset

%modality = 'carlo_household_right';
%modality = 'human';
%modality = 'robot';
%modality = 'lunedi22';
%modality = 'martedi23';
%modality = 'mercoledi24';
%modality = 'venerdi26';
modality = '';

%% TASK

% optional subfolder inside modality, just for the test set

%task = 'background';
%task = 'categorization';
%task = 'demonstrator';
%task = 'robot';
task = '';

%% CAFFE

properties = struct('feat_type', [], ...
    'install_dir', [], 'mode', [], ...
    'path_dataset_mean', [], 'model_def_file', [], 'model_file', [], 'oversample', []);

properties.feat_type = 'MyCaffe';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% root of Caffe dir
properties.install_dir = getenv('Caffe_DIR');
% 'gpu' or 'cpu'
properties.mode = 'gpu';

% path to .binaryproto mean file
properties.path_dataset_mean = '/data/REPOS/caffe/matlab/caffe/ilsvrc_2012_mean';
%properties.path_dataset_mean = fullfile(root_path, dataset_name, 'iCubWorld30_train_mean.mat');
% path to .prototxt def file
properties.model_def_file = [];
% path to .caffemodel file
properties.model_file = '/data/REPOS/caffe/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';
% if 1, extract 10 crops, if 0, extract central crop
properties.oversample = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% automatically created directory in: 
% fullfile(root_path, [dataset_name '_experiments'])
input_dir = dataset_name;
output_dir = fullfile([dataset_name '_experiments'], 'caffe_fc6');

input_extension = '.ppm';
% image extension or .txt if the features must be converted in .mat/bin
output_extension = '.mat';
% either .bin or .mat

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
    
    fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dir, ...
    output_dir, ...
    input_extension, ...
    output_extension);

catch err
    mail_message = err.message;
end

sendmail(mail_recipient,mail_object,mail_message);

%% OVERFEAT

properties = struct('feat_type', [], ...
    'install_dir', [], 'mode', [], ...
    'net_model', [], 'out_layer', []);

properties.feat_type = 'MyOverFeat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

properties.install_dir = getenv('OVERFEAT_ROOT');
properties.mode = 'linux_64'; 
% either 'linux_64' or 'linux_32' or 'macos' 

properties.net_model = 'small'; 
% either 'small' or 'large'
properties.out_layer = 'default'; 
% either 'default' or an integer between 1 and the highest layer
% 'default' corresponds to layer 19 for the small and 22 for the large net

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% automatically created directory in: 
% fullfile(root_path, [dataset_name '_experiments'])
input_dir = dataset_name;
output_dir = fullfile([dataset_name '_experiments'], ['overfeat_', properties.net_model, '_', properties.out_layer]);

input_extension = '.ppm';
% image extension or .txt if the features must be converted in .mat/bin
output_extension = '.mat';
% either .bin or .mat

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

    fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dir, ...
    output_dir, ...
    input_extension, ...
    output_extension);

catch err
    mail_message = err.message;
end

sendmail(mail_recipient,mail_object,mail_message);

%% HMAX

properties = struct('feat_type', [], ...
    'install_dir', [], 'mode', [], ...
    'learn_dict', [], 'dictionary', [], 'dict_size', [], 'n_randfeat', [], ...
    'NScales', [], 'ScaleFactor', [], 'NOrientations', [], 'S2RFCount', [], 'BSize', []);

properties.feat_type = 'MyHMAX';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% root of HMAX dir
properties.install_dir = fullfile(getenv('CNS_ROOT'), 'hmax');
% 'gpu' or 'cpu'
properties.mode = 'gpu';

properties.learn_dict = 1; 
% if 1, learn dictionary and save in the filename below (if provided)
% if 0, use one provided (as a filename or dictionary itself)

% if learn_dict=1
% it is the output filename, located in output_dirname (it can be [])
% if learn dict=0
% it is the input filename, located in output_dirname, or the dictionary
% in this case the fields dict_size and n_randfeat are not considered
properties.dictionary = 'dictionary.mat'; % it must be .mat

% number of dict patches to use in S2 layer
properties.dict_size = 2048;
% number of random images from which extract dict patches
properties.n_randfeat = 1024;

properties.NScales       = 8;
properties.ScaleFactor   = 2^0.2;
properties.NOrientations = 8;
properties.S2RFCount     = [4 8 12];
properties.BSize         = 256;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% automatically created directory in: 
% fullfile(root_path, [dataset_name '_experiments'])
input_dir = dataset_name;
output_dir = fullfile([dataset_name '_experiments'], 'hmax');

input_extension = '.ppm';
% image extension or .txt if the features must be converted in .mat/bin
output_extension = '.mat'; % either .bin or .mat

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

    fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dir, ...
    output_dir, ...
    input_extension, ...
    output_extension);

catch err
    mail_message = err.message;
end

sendmail(mail_recipient,mail_object,mail_message);

%% SIFT

properties = struct('feat_type', [], ...
    'step', [], 'cale', [], 'use_lowe', [], 'dense', [], 'normalize', []);

properties.feat_type = 'MySIFT';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

properties.step = 8; % 16 
properties.scale = [8 12 16 24 32]; % 16
properties.use_lowe = 0;
properties.dense = 1;
properties.normalize = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% automatically created directory in: 
% fullfile(root_path, [dataset_name '_experiments'])
input_dir = dataset_name;
output_dir = fullfile([dataset_name '_experiments'], 'sift');

input_extension = '.ppm';
% image extension or .txt if the features must be converted in .mat/bin
output_extension = '.mat';
% either .bin or .mat

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

    fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dir, ...
    output_dir, ...
    input_extension, ...
    output_extension);

catch err
    mail_message = err.message;
end

sendmail(mail_recipient,mail_object,mail_message);

%% SC

properties = struct('feat_type', [], ...
    'learn_dict', [], 'dictionary', [], 'dict_size', [], 'n_randfeat', [], ...
    'gamma', [], 'beta', [], 'num_iters', [], 'pyramid', []);

properties.feat_type = 'MySC';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

properties.learn_dict = 1; 
% if 1, learn dictionary and save in the filename below (if provided)
% if 0, use one provided (as a filename or dictionary itself)

% if learn_dict=1
% it is the output filename, located in output_dirname (it can be [])
% if learn dict=0
% it is the input filename, located in output_dirname, or the dictionary
% in this case the fields dict_size and n_randfeat are not considered
properties.dictionary = 'dictionary_onthefly.txt'; % either .bin or .mat or .txt
%sc_properties.dictionary = 'dictionary_prova.txt';

properties.dict_size = 512;
properties.n_randfeat = 1000;

properties.gamma = 0.15;
properties.beta = 1e-5;
properties.num_iters = 20;
properties.pyramid = [1 2 4; 1 2 4];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% automatically created directory (if not existing) in: 
% fullfile(root_path, [dataset_name '_experiments'])
input_dir = fullfile([dataset_name '_experiments'], 'sift');
output_dir = fullfile([dataset_name '_experiments'], ['sc_d' num2str(properties.dict_size)]);

input_extension = '.mat'; % either .bin or .mat
output_extension = '.mat'; % either .bin or .mat

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

    fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dir, ...
    output_dir, ...
    input_extension, ...
    output_extension);

catch err
    mail_message = err.message;
end

sendmail(mail_recipient,mail_object,mail_message);

%% PCA

properties = struct('feat_type', [], ...
    'learn_dict', [], 'dictionary', [], 'dict_size', [], 'n_randfeat', []);

properties.feat_type = 'MyPCA';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

properties.learn_dict = 1; 
% if 1, learn dictionary and save in the filename below (if provided)
% if 0, use one provided (as a filename or dictionary itself)

% if learn_dict=1
% it is the output filename, located in output_dirname (it can be [])
% if learn dict=0
% it is the input filename, located in output_dirname, or the dictionary
% in this case the fields dict_size and n_randfeat are not considered
properties.dictionary = 'dictionary.txt'; % either .bin or .mat or .txt

properties.dict_size = 80;
properties.n_randfeat = 2*1e5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% automatically created directory in: 
% fullfile(root_path, [dataset_name '_experiments'])
input_dir = fullfile([dataset_name '_experiments'], 'sift');
output_dir = fullfile([dataset_name '_experiments'], ['siftpca_d' num2str(properties.dict_size)]);

input_extension = '.mat';
% .bin, .mat, or .txt if the features must be converted in .mat/bin
output_extension = '.mat';
% either .bin or .mat

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

    fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dir, ...
    output_dir, ...
    input_extension, ...
    output_extension);

catch err
    mail_message = err.message;
end

sendmail(mail_recipient,mail_object,mail_message);

%% FV

properties = struct('feat_type', [], ...
    'learn_dict', [], 'dictionary', [], 'dict_size', [], 'n_randfeat', [], ...
    'pyramid', []);

properties.feat_type = 'MyFV';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

properties.learn_dict = 1; 
% if 1, learn dictionary and save in the filename below (if provided)
% if 0, use one provided (as a filename or dictionary itself)

% if learn_dict=1
% it is the output filename, located in output_dirname (it can be [])
% if learn dict=0
% it is the input filename, located in output_dirname, or the dictionary
% in this case the fields dict_size and n_randfeat are not considered
properties.dictionary = 'dictionary.txt'; % either .bin or .mat or .txt

properties.dict_size = 64;
properties.n_randfeat = 2*1e5;

properties.pyramid = [1 2 3; 1 2 1];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% automatically created directory in: 
% fullfile(root_path, [dataset_name '_experiments'])
input_dir = fullfile([dataset_name '_experiments'], 'siftpca_d80');
output_dir = fullfile([dataset_name '_experiments'], ['fv_d' num2str(properties.dict_size)]);

input_extension = '.mat';
% .bin, .mat, or .txt if the features must be converted in .mat/bin
output_extension = '.mat';
% either .bin or .mat

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

    fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dir, ...
    output_dir, ...
    input_extension, ...
    output_extension);

catch err
    mail_message = err.message;
end

sendmail(mail_recipient,mail_object,mail_message);