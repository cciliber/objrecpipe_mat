%FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
%FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%DATA_DIR = '/media/giulia/MyPassport';
%DATA_DIR = '/Volumes/MyPassport';
%DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';
DATA_DIR = '/media/giulia/DATA';

%% Dataset info

dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat)';
%obj_names = keys(opts.Obj)';
transf_names = keys(opts.Transfs)';
day_names = keys(opts.Days)';
camera_names = keys(opts.Cameras)';

Ncat = opts.Cat.Count;
Nobj = opts.Obj.Count;
NobjPerCat = opts.ObjPerCat;
Ntransfs = opts.Transfs.Count;
Ndays = opts.Days.Count;
Ncameras = opts.Cameras.Count;

%% Choose which part of the dataset to check
% all indices are referred to the dataset infos

% Choose categories

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

% Choose objects per category

obj_list = 8:10;

% Choose transformation, day, camera

transf_list = 1:5;

day_mapping = 1;

tmp = keys(opts.Days);
day_list = [];
for dd=1:length(day_mapping)
    tmp1 = tmp(cell2mat(values(opts.Days))==day_mapping(dd))';
    tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
    day_list = [day_list tmp2];
    
end
day_list = day_names(day_list);

%% Set the IO root dirs

% Input dataset
dset_in_root = '/media/giulia/DATA/iCubWorldUltimate_finaltree';
check_input_dir(dset_in_root);

% Output dataset
dset_out_root = '/media/giulia/DATA/iCubWorldUltimate_finaltree_checked';
check_output_dir(dset_out_root);

%% Set the modality

modality = 'cc';
% modality = 'feat';

%% For each video, go!

for cc=1:length(cat_idx)
    for oo=1:length(obj_list)
        for tt=1:length(transf_list)
            
            
            cat = cat_names{cat_idx(cc)};
            obj = strcat(cat_names{cat_idx(cc)}, num2str(obj_list(oo)));
            tr = transf_names{transf_list(tt)};
            
            %% Start selecting frames
            
            start_gui(dset_in_root, dset_out_root, cat, obj, tr, day_list, modality);
            
        end
    end
end

