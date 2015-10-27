%% setup 

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';

run('/data/REPOS/GURLS/gurls/utils/gurls_install.m');

curr_dir = pwd;
cd('/data/REPOS/vlfeat-0.9.20/toolbox');
vl_setup;
cd(curr_dir);
clear curr_dir;

addpath(genpath(FEATURES_DIR));

%% dataset

dset_path = '/data/giulia/DATASETS/iCubWorld28';

ICUBWORLDopts = ICUBWORLDinit('iCubWorld28');

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

in_ext = '.ppm';
out_ext = '.jpg';

%% output

output_dir = fullfile('/data/giulia/DATASETS/iCubWorld28_experiments');
check_output_dir(output_dir);

%% go!
    
loader = Features.GenericFeature();
loader.assign_registry_and_tree_from_folder(dset_path, [], [], [], []);
    
loader.reproduce_tree(output_dir);

for idx=1:loader.ExampleCount
    
    I = imread(fullfile(dset_path, [loader.Registry{idx} in_ext]));
    imwrite(I, fullfile(output_dir, [loader.Registry{idx} out_ext]));
    
end