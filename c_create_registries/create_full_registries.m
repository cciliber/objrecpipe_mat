%% Setup 

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% ImageNet synsets

imnet_1000synsets_path = '/usr/local/src/robot/caffe/data/ilsvrc12/synsets.txt';
fid = fopen(imnet_1000synsets_path);
imnet_1000synsets = textscan(fid, '%s');
imnet_1000synsets = imnet_1000synsets{1};
fclose(fid);

%% Dataset

dset_path = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree';
dset_info = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries/info/iCubWorldUltimate.txt';
dset_name = 'iCubWorldUltimate';

ICUBWORLDopts = ICUBWORLDinit(dset_info);

cat_names = keys(ICUBWORLDopts.Cat)';

obj_names = keys(ICUBWORLDopts.Obj)';

Ncat = ICUBWORLDopts.Cat.Count;
Nobj = ICUBWORLDopts.Obj.Count;
NobjPerCat = ICUBWORLDopts.ObjPerCat;

%% Output

out_dir = fullfile('/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries/full_registries');

out_ext = '.jpg';

%% Go!

cat_list = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

for cc=cat_list
    
    out_path = fullfile(out_dir, [cat_names{cc} '.txt']);
    fid = fopen(out_path,'w');
    if (fid==-1)
        fprintf(2, 'Cannot open file: %s', out_path);
    end
    
    registry = registry_from_folder(dset_path, cat_names{cc}, [], [], []);
    
    [fpaths, fnames, fexts] = cellfun(@fileparts, registry, 'UniformOutput', false);
    
    registry(strcmp(fexts, '.txt')) = [];
    
    cat_synset = ICUBWORLDopts.Cat_ImnetWNIDs(cat_names{cc});
    if ~isempty(cat_synset)
        Ytrue = strcmp(imnet_1000synsets, cat_synset);
        Ylabel = find(Ytrue)-1;
    else
        Ylabel = -1;
    end
    
    for line_idx=1:length(registry)
        fprintf(fid, '%s\n', [registry{line_idx}(1:(end-4)) out_ext  ' ' num2str(Ylabel)]);
    end
    
    fclose(fid);
end
