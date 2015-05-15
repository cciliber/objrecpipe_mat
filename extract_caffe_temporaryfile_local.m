%% MACHINE

machine_tag = 'laptop_giulia_lin';
root_path = init_machine(machine_tag);

%% CAFFE

properties = struct('feat_type', [], ...
    'install_dir', [], 'mode', [], ...
    'path_dataset_mean', [], 'model_def_file', [], 'model_file', [], 'oversample', []);

properties.feat_type = 'MyCaffe';

% root of Caffe dir
properties.install_dir = getenv('Caffe_ROOT');
% 'gpu' or 'cpu'
properties.mode = 'gpu';

% path to .binaryproto mean file
properties.path_dataset_mean = [];
%properties.path_dataset_mean = fullfile(root_path, dataset_name, 'iCubWorld30_train_mean.mat');
% path to .prototxt def file
properties.model_def_file = [];
% path to .caffemodel file
properties.model_file = [];
% if 1, extract 10 crops, if 0, extract central crop
properties.oversample = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

input_extension = '.ppm';
% image extension or .txt if the features must be converted in .mat/bin
output_extension = '.mat';
% either .bin or .mat

input_dirname = 'cfr_caffe_cpp_matlab_experiments';

output_dirname = fullfile('cfr_caffe_cpp_matlab_experiments', 'caffe_mat');

dataset_name = 'iCubWorld30';
modality = '';
task = '';

% CALL TO FCN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fcn_extract_feat(root_path, dataset_name, ...
    modality, task, ...
    properties, ...
    input_dirname, ...
    output_dirname, ...
    input_extension, ...
    output_extension);