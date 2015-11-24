%% Setup

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% Dataset info

dset_info = fullfile(FEATURES_DIR, 'ICUBWORLDULTIMATE_test_offtheshelfnets', 'iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat)';
obj_names = keys(opts.Obj)';
transf_names = keys(opts.Transfs)';
day_names = keys(opts.Days)';
camera_names = keys(opts.Cameras)';

Ncat = opts.Cat.Count;
Nobj = opts.Obj.Count;
NobjPerCat = opts.ObjPerCat;
Ntransfs = opts.Transfs.Count;
Ndays = opts.Days.Count;
Ncameras = opts.Cameras.Count;

%% IO

reg_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

out_dir = fullfile('/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_digit_registries/fine_tuning');
check_output_dir(output_dir);

out_ext = '.jpg';

out_path_TR = fullfile(out_dir, 'TR.txt');
fid = fopen(out_path,'w');
if (fid==-1)
    fprintf(2, 'Cannot open file: %s', out_path);
end

out_path_VAL = fullfile(out_dir, 'VAL.txt');
fid = fopen(out_path,'w');
if (fid==-1)
    fprintf(2, 'Cannot open file: %s', out_path);
end

out_path_TE = fullfile(out_dir, 'TE.txt');
fid = fopen(out_path,'w');
if (fid==-1)
    fprintf(2, 'Cannot open file: %s', out_path);
end

dset_dirs = {'/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb60_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid256_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree'};

%% Sets (e.g. even & odd days)

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

set_names = {'even', 'odd'};
day_lists = {4:2:Ndays, 3:2:Ndays};

obj_lists = {1:3, 4:6};
transf_lists = {1:Ntransfs, 1:Ntransfs};

camera_lists = {[1 2], [1 2]};

%% Go!

cat_list = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

for cc=cat_list
    
    loaderTRVAL = Features.GenericFeature();
    loaderTE = Features.GenericFeature();
    
    % split validation/train
    
    loader.assign_registry_and_tree_from_folder(dset_path, cat_names{cc}, [], [], []);
    
    %scores_dir = fullfile('/data/giulia/DATASETS/iCubWorldUltimate_bb_disp_finaltree_experiments/test_offtheshelfnets/scores/googlenet');    
    %loader.reproduce_tree(scores_dir); 

    [fpaths, fnames, fexts] = cellfun(@fileparts, loader.Registry, 'UniformOutput', false);
    
    loader.Registry(strcmp(fexts, '.txt')) = [];
    
    cat_synset = ICUBWORLDopts.Cat_ImnetWNIDs(cat_names{cc});
    if ~isempty(cat_synset)
        Ytrue = strcmp(imnet_1000synsets, cat_synset);
        Ylabel = find(Ytrue)-1;
    else
        Ylabel = -1;
    end
    
    for line_idx=1:length(loader.Registry)
        fprintf(fid, '%s\n', [loader.Registry{line_idx}(1:(end-4)) out_ext  ' ' num2str(Ylabel)]);
    end
    
    fclose(fid);
end
