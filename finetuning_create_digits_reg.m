%% setup 

FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';

run('/Users/giulia/LIBRARIES/GURLS/gurls/utils/gurls_install.m');

curr_dir = pwd;
cd('/Users/giulia/LIBRARIES/vlfeat-0.9.20/toolbox');
vl_setup;
cd(curr_dir);
clear curr_dir;

addpath(genpath(FEATURES_DIR));

check_input_dir(root_path);

%% dataset

dset_path = '/Users/giulia/DATASETS/iCubWorld28';

ICUBWORLDopts = ICUBWORLDinit('iCubWorld28');

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

%% output

output_dir = fullfile('/Users/giulia/DATASETS/iCubWorld28_digit_registries');
check_output_dir(output_dir);
 
%% go!

% compute
for ii=1:length(modalities)
    
    loaderTR = Features.GenericFeature();
    loaderTE = Features.GenericFeature();

    out_path = fullfile(output_dir, ['TR' modalities{ii} '.txt']);
    in_path = fullfile(dset_path, 'train', modalities{ii});
    loaderTR.assign_registry_and_tree_from_folder(in_path, [], out_path);

    out_path = fullfile(output_dir, ['TE' modalities{ii} '.txt']);
    in_path = fullfile(dset_path, 'test', modalities{ii});
    loaderTE.assign_registry_and_tree_from_folder(in_path, [], out_path);
    
end
