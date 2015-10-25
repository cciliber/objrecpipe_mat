%%
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

in_ext = '.png';
out_ext = '.jpg';

day = 3;
camera = 'left';

in_root_path = fullfile('/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_folderized_png',  ['day' num2str(day)], camera);
out_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg',  ['day' num2str(day)], camera);

convert_folder_tree(in_root_path, in_ext, out_root_path, out_ext);