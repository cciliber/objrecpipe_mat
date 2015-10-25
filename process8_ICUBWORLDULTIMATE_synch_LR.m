
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

day = 4;
camera = 'right';

in_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized', ['day' num2str(day)], camera);
out_root_path = fullfile('/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_folderized_png', ['day' num2str(day)], camera);

out_registry_path = ['/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_folderized_png/day' num2str(day) '_' camera '.txt'];

in_ext = '.ppm';
out_ext = '.png';

feat = Features.GenericFeature();

feat.assign_registry_and_tree_from_folder(in_root_path, [], [], out_registry_path, out_ext);

feat.reproduce_tree(out_root_path);

for ii=1:length(feat.Registry)
    
    I = imread([fullfile(in_root_path, feat.Registry{ii}) in_ext]);
    imwrite(I, [fullfile(out_root_path, feat.Registry{ii}) out_ext]);
    
    disp([num2str(ii) '/' num2str(length(feat.Registry))]);
end