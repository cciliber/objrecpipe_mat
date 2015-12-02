%% Setup

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% Dataset info

dset_info = fullfile(FEATURES_DIR, 'ICUBWORLDULTIMATE_test_offtheshelfnets', 'iCubWorldUltimate.txt');
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

%% Location of the scores

dset_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree';
%dset_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb60_disp_finaltree';
%dset_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid256_disp_finaltree';
%dset_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree';

scores_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');

model = 'googlenet';
%model = 'caffenet';
%model = 'vgg';

%% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

%% Input root dir for registries of the subsets

input_dir_regtxt = fullfile('/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt);

%% Default sets that are searched

set_names = {'train_', 'val_', 'test_'};
Nsets = length(set_names);

%% Choose categories

%cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];
%cat_idx = [3 8 9 11 12 13 14 15 19 20];
cat_idx = [9 13];
%cat_idx = [8 9 13 14 15];

input_dir_regtxt = fullfile(input_dir_regtxt, ['Ncat_' num2str(length(cat_idx))]);
check_input_dir(input_dir_regtxt);

input_dir_regtxt = fullfile(input_dir_regtxt, strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
check_input_dir(input_dir_regtxt);

%% Choose objects per category (for each set)

if strcmp(experiment, 'categorization')
    obj_lists = {4:6, 4:6, 4:6};
elseif strcmp(experiment, 'identification')
    obj_list = 4:6;
    obj_lists = {obj_list, obj_list, obj_list};
end

%% Choose transformation, day, camera (for each set)

% you can set it to true in the identification experiment 
% e.g. if the train and val sets are coincident (same transformation+day)
% the camera is not to be considered in this division...
if strcmp(experiment, 'identification') 
    divide_trainval_perc = false;
else
    divide_trainval_perc = [];
end

%transf_lists = {1:Ntransfs, 1:Ntransfs, 1:Ntransfs};
transf_lists = {2, 1, 3};
%transf_lists = {[2 3], [2 3], [2 3]};

day_mappings = {1, 1, [1 2]};
day_lists = cell(Nsets,1);
tmp = keys(opts.Days);
for ii=1:Nsets
    for dd=1:length(day_mappings{ii})
        tmp1 = tmp(cell2mat(values(opts.Days))==day_mappings{ii}(dd))';
        tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
        day_lists{ii} = [day_lists{ii} tmp2];
    end
end

%camera_lists = {[1 2], [1 2], [1 2]};
camera_lists = {1, 1, 1};

%% Create set names

for ii=1:Nsets
    set_names{ii} = [set_names{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
    set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
    set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
    set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
end

%% Set the output

output_dir = fullfile(exp_dir, 'predictions', model, experiment);
check_output_dir(output_dir);

%% Load the scores and create X matrices

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    % load REG
    load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
    
    % where to load the scores
    input_dir = fullfile(scores_dir, 'scores', model);
    check_input_dir(input_dir);
    
    % create X
    X = cell(Ncat, 1);
    for cc=cat_idx
        X{opts.Cat(cat_names{cc})} = zeros(length(REG{opts.Cat(cat_names{cc})}), 1000);
        for ff=1:length(REG{opts.Cat(cat_names{cc})})
            fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
            X{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
            fclose(fid);
        end
        disp([set_name ': ' cat_names(cc)]);
    end
    
    save(fullfile(output_dir, ['X_' set_name '.mat']), 'X', '-v7.3');
    
end