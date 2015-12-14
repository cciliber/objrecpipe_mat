%% Setup

%FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
%FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%DATA_DIR = '/media/giulia/MyPassport';
%DATA_DIR = '/Volumes/MyPassport';
DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

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

%% Set up the experiments

% Default sets that are searched

set_names_prefix = {'train_', 'val_', 'test_'};
Nsets = length(set_names_prefix);
loaded_set = 3;

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Mapping (used only to name the resulting predictions)

if strcmp(experiment, 'categorization')
    mapping = 'tuned';
    %mapping = 'none';
elseif strcmp(experiment, 'identification')
    mapping = 'tuned';
else
    mapping = [];
end

% Whether to use the imnet or the tuning labels

if strcmp(experiment, 'categorization') && strcmp(mapping, 'none')
    use_imnetlabels = true;
elseif strcmp(experiment, 'categorization') && strcmp(mapping, 'tuned')
    use_imnetlabels = false;
elseif strcmp(experiment, 'identification')
    use_imnetlabels = false;
else
    use_imnetlabels = [];
end

% Choose categories

cat_idx_all = { [9 13], ...
    [8 9 13 14 15], ...
    [3 8 9 11 12 13 14 15 19 20], ...
    [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20]};

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    obj_lists_all = { {1, 5, [2 3 4 6 7 8 9 10]}, ...
        {1:2, 5, [3 4 6 7 8 9 10]}, ...
        {1:4, 5:7, 8:10}, ...
        {[1:4 6 7], 5, 8:10}, ...
        {[1:4 6:9], 5, 10}};
    
elseif strcmp(experiment, 'identification')
    
    id_exps = {1:3, 1:5, 1:7, 1:10};
    obj_lists_all = cell(length(id_exps), 1);
    for ii=1:length(id_exps)
        obj_lists_all{ii} = repmat(id_exps(ii), 1, Nsets);
    end
    
end

% Choose transformation, day, camera

%transf_lists = {1:Ntransfs, 1:Ntransfs, 1:Ntransfs};
%transf_lists = {[2 3], [2 3], [2 3]};
transf_lists = {2, 2, 1:Ntransfs};

day_mappings = {1, 1, 1:2};
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
camera_lists = {1, 1, 1:2};

%% Set the IO root directories

% Location of the scores

dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

%exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');
exp_dir = fullfile([dset_dir '_experiments'], 'tuning');

model = 'googlenet';
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

input_dir = fullfile(exp_dir, 'scores', model);
if strcmp(mapping, 'tuned')
    input_dir = fullfile(input_dir, experiment);
end
check_input_dir(input_dir);

output_dir = fullfile(exp_dir, 'predictions', model, experiment);
check_output_dir(output_dir);

input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt_root);

%% Prediction parameters

max_batch_size = 10000;

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        % Assign the proper IO directories
        
        dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
        if strcmp(experiment, 'identification')
            dir_regtxt_relative = fullfile(dir_regtxt_relative, strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-'));
        end
        
        if strcmp(mapping, 'tuned')
            input_dir = fullfile(input_dir, dir_regtxt_relative);
            check_input_dir(input_dir);
        end
        
        input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
        check_input_dir(input_dir_regtxt);
        
        output_dir_regtxt = fullfile(output_dir, dir_regtxt_relative);
        check_output_dir(output_dir_regtxt);
        
        % Create set names
        
        for ii=1:Nsets
            set_names{ii} = [set_names_prefix{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
        end
        
        %% Load Y and create X for train, val and test sets to compute native Ypred
        
        % load Y
        if use_imnetlabels
            load(fullfile(input_dir_regtxt, ['Yimnet_' set_names{loaded_set} '.mat']));
        else
            load(fullfile(input_dir_regtxt, ['Y_' set_names{loaded_set} '.mat']));
        end
        
        % load REG and create X
        load(fullfile(input_dir_regtxt, ['REG_' set_names{loaded_set} '.mat']));
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
        
        % compute predictions
        Ypred = cell(Ncat,1);
        for cc=cat_idx
            
            Ypred{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, 1);
            
            batch_size = min(max_batch_size, NframesPerCat{opts.Cat(cat_names{cc})});
            Nbatches = ceil(NframesPerCat{opts.Cat(cat_names{cc})}/batch_size);
            for bidx=1:Nbatches
                [~, I] = max(X{opts.Cat(cat_names{cc})}(((bidx-1)*batch_size+1):min(bidx*batch_size, NframesPerCat{opts.Cat(cat_names{cc})}),:), [], 2);
                Ypred{opts.Cat(cat_names{cc})}((((bidx-1)*batch_size+1):min(bidx*batch_size, NframesPerCat{opts.Cat(cat_names{cc})}))) = I-1;
            end
            
        end
        
        acc = compute_accuracy(cell2mat(Y), cell2mat(Ypred), 'gurls');
        
        if strcmp(mapping, 'tuned')
            save(fullfile(output_dir_regtxt, ['Y_' mapping '_' set_names{1} '_' set_names{2} '_' set_names{3} '.mat'] ), 'Ypred', 'acc', '-v7.3');
        elseif strcmp(mapping, 'tuned')
            save(fullfile(output_dir_regtxt, ['Y_' mapping '_' set_names{loaded_set}((length(set_names_prefix{loaded_set})+1):end) '.mat'] ), 'Ypred', 'acc', '-v7.3');
        end
       
        
    end
    
end
