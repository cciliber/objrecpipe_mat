
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

in_registry_path = '/data/DATASETS/iCubWorld30.txt';

in_root_path = '/data/DATASETS/iCubWorld30/';
out_root_path = '/data/DATASETS/iCubWorld30_jpg/';

feat = Features.GenericFeature();

feat.assign_registry_and_tree_from_file(in_registry_path, [], []);
feat.reproduce_tree(out_root_path);

for ii=1:length(feat.Registry)
    
    I = imread([fullfile(in_root_path, feat.Registry{ii}) '.ppm']);
    imwrite(I, [fullfile(out_root_path, feat.Registry{ii}) '.jpg']);
end