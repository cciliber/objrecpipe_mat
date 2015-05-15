feat = Features.GenericFeature();

in_rootpath = '/media/giulia/DATA/DATASETS/iCubWorld30';
out_registry_path = '/media/giulia/DATA/DATASETS/iCubWorld30_experiments/registries/iCubWorld30.txt';
feat.assign_registry_and_tree_from_folder(in_rootpath, [], out_registry_path);

out_rootpath = '/media/giulia/DATA/DATASETS/iCubWorld30_nocrop_downsampled';
feat.reproduce_tree(out_rootpath);

in_rootpath = '/media/giulia/DATA/DATASETS/iCubWorld30_nocrop';
for im=1:feat.ExampleCount
    
    copyfile(fullfile(in_rootpath, [feat.Registry{im} '.ppm']), fullfile(out_rootpath, [feat.Registry{im} '.ppm']));
    
end