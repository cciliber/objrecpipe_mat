%% MATLAB path update

% add the folder containing the '+Features' package to the path
FEATURES_DIR = 'C:\Users\Giulia\REPOS\objrecpipe_mat';
addpath(FEATURES_DIR);

% add the current working directory to the path
addpath(genpath('.'));

% common root path
root_path = 'D:\IIT';

datasets_folder = fullfile(root_path, 'DATASETS');

%% iCubWorld2.0 source folder

version = 2;
%modality = 'carlo_household_left';
modality = 'carlo_household_right';

% set dataset directory
dataset_path = fullfile(datasets_folder, 'iCubWorld2.0');

dataset_raw_images_path = fullfile(dataset_path, 'PPMImages_raw', modality);
dataset_images_path = fullfile(dataset_path, 'PPMImages', modality);

% choose a name for output files
time_img = 'icub20_time_img.txt';
time_blob = 'icub20_time_blob.txt';
blob_img_auto = 'icub20_blob_img_auto.txt';
blob_img_manual = 'icub20_blob_img_manual.txt';
blob_img_autoandmanual = 'icub20_blob_img_autoandmanual.txt';

% assign image format
dataset_extension = [];

% initialize VOC options
addpath(dataset_code_path);
ICUBWORLDopts = ICUBWORLDinit(datasets_folder, version, modality);

%% Dataset initialization

time_img_path = fullfile(dataset_path, time_img);
time_blob_path = fullfile(dataset_path, time_blob);
blob_img_auto_path = fullfile(dataset_path, blob_img_auto);
blob_img_manual_path = fullfile(dataset_path, blob_img_manual);
blob_img_autoandmanual_path = fullfile(dataset_path, blob_img_autoandmanual);

dataset_raw = Features.MyDataset(dataset_extension);

dataset_raw.init_raw(dataset_raw_images_path, time_img_path, time_blob_path);

%% Pipeline initialization

dataset = Features.MyDataset(dataset_extension);

% set the window of the vector of blob timestamps where to look for the
% nearest timestamp
time_window = 30; % number of elements
box_size = 127; % half side of the bounding box
% e.g. 127 to crop 2x127+1+1 = 256 squared images

%% Automatic bounding box (motion CUT) 

eye = 'left';
dataset.segment_dataset('auto', time_window, box_size, eye, dataset_images_path, blob_img_auto_path, dataset_raw);

eye = 'right';
dataset.segment_dataset('auto', time_window, box_size, eye, dataset_images_path, blob_img_auto_path, dataset_raw);

%% Automatic bounding box (motion CUT) + possibility of correction and creation of folders

eye = 'left';
dataset.segment_dataset('auto+manual', time_window, box_size, eye, dataset_images_path, blob_img_autoandmanual_path, dataset_raw);

eye = 'right';
dataset.segment_dataset('auto+manual', time_window, box_size, eye, dataset_images_path, blob_img_autoandmanual_path, dataset_raw);

%% Manual bounding box and creation of folders

eye = 'left';
dataset.segment_dataset('manual', time_window, box_size, eye, dataset_images_path, blob_img_manual_path, dataset_raw);

eye = 'right';
dataset.segment_dataset('manual', time_window, box_size, eye, dataset_images_path, blob_img_manual_path, dataset_raw);

%% Delete spurious images and organize dataset into folders (aka label it)

eye = 'left';
% reads images from dataset.RootPath (= dataset_images_path)
dataset.RootPath = dataset_images_path;
dataset.clean_and_label_dataset(eye, dataset_raw);

eye = 'right';
% reads images from dataset.RootPath (= dataset_images_path)
dataset.clean_and_label_dataset(eye, dataset_raw);