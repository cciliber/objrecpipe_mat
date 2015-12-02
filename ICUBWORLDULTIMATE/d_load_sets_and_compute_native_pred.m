%% Setup

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

DATA_DIR = '/Volumes/MyPassport';

%% Dataset info

dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat);
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

% Experiment is categorization in this case
% We use the ImageNet labels

%% Location of the scores

%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');

%model = 'googlenet';
model = 'bvlc_reference_caffenet';
%model = 'vgg';

%% Set the IO

input_dir = fullfile(exp_dir, 'scores', model);
check_input_dir(input_dir);

output_dir = fullfile(exp_dir, 'predictions', model, 'categorization');
check_output_dir(output_dir);

input_dir_regtxt = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
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

output_dir_regtxt = fullfile(output_dir, ['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
check_output_dir(output_dir_regtxt);

%% Choose objects per category (for each set)

obj_lists = {4:6, 4:6, 4:6};

%% Choose transformation, day, camera (for each set)

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

%% Load Y and create X for train, val and test sets to compute native Ypred
  
max_batch_size = 10000;

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    % load Yimnet
    load(fullfile(input_dir_regtxt, ['Yimnet_' set_name '.mat']));
    
    % load scores and create X
    load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
    X = cell(Ncat, 1);
    NframesPerCat = cell(Ncat, 1);
    for cc=cat_idx
        NframesPerCat{opts.Cat(cat_names{cc})} = length(REG{opts.Cat(cat_names{cc})});
        X{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, 1000);
        for ff=1:NframesPerCat{opts.Cat(cat_names{cc})}
            fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
            X{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
            fclose(fid);
        end
    end
    
    % compute native predictions
    Ypred = cell(Ncat,1);
    for cc=cat_idx
        batch_size = min(max_batch_size, NframesPerCat{opts.Cat(cat_names{cc})});
        Ypred{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, 1);
        Nbatches = ceil(NframesPerCat{opts.Cat(cat_names{cc})}/batch_size);
        for bidx=1:Nbatches
            [~, I] = max(X{opts.Cat(cat_names{cc})}(((bidx-1)*batch_size+1):min(bidx*batch_size, NframesPerCat{opts.Cat(cat_names{cc})}),:), [], 2);
            Ypred{opts.Cat(cat_names{cc})}((((bidx-1)*batch_size+1):min(bidx*batch_size, NframesPerCat{opts.Cat(cat_names{cc})}))) = I-1;
        end
    end
    
    acc = compute_accuracy(cell2mat(Y), cell2mat(Ypred), 'gurls')
    
    % store results
    save(fullfile(output_dir_regtxt, ['Yimnet_none_' set_name '.mat'] ), 'Ypred', 'acc', '-v7.3');
    
end
  