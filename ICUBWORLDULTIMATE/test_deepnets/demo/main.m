%% Caffe dir

caffe_dir = '/usr/local/src/robot/caffe';
%caffe_dir = '/data/giulia/REPOS/caffe';

%% Add caffe/matlab to you Matlab search PATH to use matcaffe

addpath(genpath(fullfile(caffe_dir, 'matlab')));

%% Initialize the network using BVLC CaffeNet for image classification

model_dir = fullfile(caffe_dir, 'models/bvlc_reference_caffenet/');

caffepaths.net_model = [model_dir 'deploy.prototxt'];
caffepaths.net_weights = [model_dir 'bvlc_reference_caffenet.caffemodel'];

%% Contains mean_data that is already in W x H x C with BGR channels

caffepaths.mean_path = fullfile(caffe_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');

%% Images

folder_path = '/usr/local/src/robot/caffe/matlab/demo/mug';
list_dirs = dir(folder_path);

%% Categories

categories_struct = struct;
categories_struct.category_names = {'cellphone', ...
    'mouse', ...
    'mug', ...
    'pencilcase', ...
    'perfume', ...
    'remote', ...
    'ringbinder', ...
    'soapdispenser', ...
    'sunglasses', ...
    'wallet'};
categories_struct.predictions_selector = [487 673 504 709 711 761 446 804 837 893];

%% Go!

for idx_dirs = 1:numel(list_dirs)
    
    curr_folder = list_dirs(idx_dirs).name;
    if curr_folder(1) ~= '.' && isdir(curr_folder)
        caffe_coder(caffepaths, fullfile(folder_path,curr_folder), curr_folder, categories_struct, 'jpg');
    end
    
end