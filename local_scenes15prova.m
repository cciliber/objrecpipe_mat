%% MACHINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%machine = 'server';
%machine = 'laptop_giulia_win';
machine = 'laptop_giulia_lin';
    
if strcmp(machine, 'server')
    
    FEATURES_DIR = '/home/icub/GiuliaP/objrecpipe_mat';
    root_path = '/DATA/DATASETS';
    
    run('/home/icub/Dev/GURLS/gurls/utils/gurls_install.m');
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
    
elseif strcmp (machine, 'laptop_giulia_win')
    
    FEATURES_DIR = 'C:\Users\Giulia\REPOS\objrecpipe_mat';
    root_path = 'D:\DATASETS';
    
elseif strcmp (machine, 'laptop_giulia_lin')
    
    FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
    root_path = '/media/giulia/DATA/DATASETS';
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
end

addpath(genpath(FEATURES_DIR));

check_input_dir(root_path);

%% PIPELINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CAFFE
oversample = 0;
caffe_install_dir = getenv('caffe_ROOT');
%path_dataset_mean = fullfile(root_path, dataset_name, 'iCubWorld30_train_mean.mat');
path_dataset_mean = [];
use_gpu = 1;

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
dataset_path = fullfile(root_path, 'ALOT');
check_input_dir(dataset_path);

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

caffe_path = fullfile(root_path, 'ALOT_experiments', 'caffe');
check_output_dir(caffe_path);

%% REGISTRIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

registries_dir = fullfile(root_path, 'ALOT_experiments', 'registries');
check_output_dir(registries_dir);

% INPUT 

in_registry_file = [];

in_registry_path = [];

% OUTPUT 

out_registry_file = 'registry.txt';

out_registry_path = fullfile(registries_dir, out_registry_file);
    
%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%try   
  
    caffe = Features.MyCaffe(oversample, caffe_install_dir, path_dataset_mean, [], [], use_gpu);

    % ARGUMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % MANDATORY 
    input_rootpath = dataset_path;
    
    input_extension = '.png'; 
    % image extension or .txt if the features must be converted in .mat/bin
    
    modality_out = 'file'; % or 'wspace' or 'both' 
    
    % if modality_out is 'file'/'both' then the following 2 are mandatory
    % (if modality_out is 'wspace' are ignored and can be [])
    
    output_rootpath = caffe_path;
    
    output_extension = '.mat'; 
    % either .bin or .mat
 
    % OPTIONAL
    
    %input_registry = in_registry_train_path; % will be used
    input_registry = []; % input_rootpath will be explored
    
    folders_to_select = [];
    %folders_to_select = objlist; 
    % examples:
    % objlist = {'banana'; 'box_brown'; ...}
    % objlist = {'bananas', 'banana1', 'demo2'; 'lemons', 'demo1'; 'pears'}

    output_registry = out_registry_path;
    %output_registry = []; % won't be created
    
    dictionary = []; % if it's not necessary
    %dictionary = dictionary_path; % either .bin or .mat or .txt
    %dictionary = dict_matrix;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    caffe.extract_file(input_rootpath, input_registry, input_extension, folders_to_select, output_registry, dictionary, modality_out, output_rootpath, output_extension);
    %caffe_train.extract_wspace(feat_matrix, featsize_matrix, grid_matrix, gridsize_matrix, imsize_matrix, dictionary, modality_out, output_rootpath, output_extension);
        
    disp('CAFFE');