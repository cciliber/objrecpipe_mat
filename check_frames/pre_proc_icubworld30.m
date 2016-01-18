%% MACHINE

% depending on the machine:
% GURLS and/or VL_FEAT and/or CNS are initialized
% FEATURES_DIR is set and added to Matlab path
% 'root_path' is set, dir containing every input/output dir from now on

%machine_tag = 'server';
machine_tag = 'laptop_giulia_win';
%machine_tag = 'laptop_giulia_lin';

root_path = init_machine(machine_tag);



% set dataset directory
dataset_raw_path = 'G:\DATASETS\iCubWorld30_raw';

% name of input files from dumper
time_img = 'imgs.log'; % contains timestamp + img name
time_info = 'imginfos.log'; % contains timestamp + blob + class

blob_img = 'blob_img.txt';

% assign image format
dataset_extension = '.ppm';

%% Dataset initialization

% input 
time_img_path = fullfile(dataset_raw_path, time_img);
time_info_path = fullfile(dataset_raw_path, time_info);

% output
dataset_cropped_path = fullfile(root_path, 'iCubWorld30_crop256');

blob_img_path = fullfile(dataset_cropped_path, blob_img);

dset = Features.MyDataset(dataset_extension);

box_size = 127; % half side of the bounding box
% e.g. 127 to crop 2x127+1+1 = 256 squared images
% e.g. 63 to crop 2x63+1+1 = 128 squared images
% e.g. 31 to crop 2x31+1+1 = 64 squared images

dset.segment_30(dataset_raw_path, dataset_cropped_path, time_img_path, time_info_path, blob_img_path, box_size);

%dset.segment_dataset('manual', [], box_size, dataset_raw_path, dataset_cropped_path, blob_img_path)

