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

exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');

model = 'googlenet';
%model = 'caffenet';
%model = 'vgg';

%% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

%% Set the IO

input_dir = fullfile(exp_dir, 'scores', model);
check_input_dir(input_dir);
    
save_I = true;

output_dir = fullfile(exp_dir, 'predictions', model, experiment);
check_output_dir(output_dir);

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

%% Load Y and create X for train and val sets
disp('Loading Y and creating X for train and val...');

XX = cell(2, 1);
XX2 = cell(2, 1);

YY = cell(3, 1);

N = zeros(3, 1);
NframesPerCat = cell(3, 1);

for sidx=1:2
    
    set_name = set_names{sidx};
    
    % load Y
    load(fullfile(input_dir_regtxt, ['Y_' set_name '.mat']));
    YY{sidx} = cell2mat(Y);
    clear Y
        
    % load scores and create X
    load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
    X = cell(Ncat, 1);
    NframesPerCat{sidx} = cell(Ncat, 1);
    for cc=values(opts.Cat, cat_names(cat_idx))
        NframesPerCat{sidx}{cc} = length(REG{cc});
        X{cc} = zeros(NframesPerCat{sidx}{cc}, 1000);
        for ff=1:NframesPerCat{sidx}{cc}
            fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{cc}{ff}(1:(end-4)) '.txt']));
            X{cc}(ff,:) = cell2mat(textscan(fid, '%f'))';
            fclose(fid);
        end
    end
    
    XX{sidx} = cell2mat(X);
    XX2{sidx} = sum(XX{sidx}.*XX{sidx},2);
    
    N(sidx) = size(XX{sidx},1);
    
    clear REG X
  
end

%% kNN parameters

max_batch_size = 5000;

max_Icols = 50000;

max_k = 5000;
num_k = 10;

%% Train and cross-validate 

Kvalues = round(linspace(1, min(max_k, N(1)), num_k));
acc_crossval = zeros(3, length(Kvalues));

% Prepare scores and compute I for set 1-2 (val),
% then predict on set 2 (train) for different Ks

disp('Preparing scores to compute I for sets 1-2 (validation)...');

batch_size = min(max_batch_size, N(2));
Nbatches = ceil(N(2)/batch_size);

x1 = XX{1};
xx1 = XX2{1};

x2 = cell(Nbatches, 1);
xx2 = cell(Nbatches, 1);
for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(2));
    
    x2{bidx} = XX{2}(start_idx:end_idx, :)';
    xx2{bidx} = XX2{2}(start_idx:end_idx)';
end

clear XX XX2;

disp('Computing I for sets 1-2 (validation)...');

m = matfile(fullfile(output_dir, ['I_' set_name{1} '_' set_name{2} '.mat']), 'Writable', true);
m.I = zeros(min(max_Icols, N(2)), 1);

for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(2));
    Dbatch = bsxfun( @plus, xx1, xx2{bidx} ) - 2*x1*x2{bidx};
    
    [~, I] = sort(Dbatch, 1);
    
    m.I(:, start_idx:end_idx) = I(1:max_k, :);
    
    disp(num2str(bidx));
    
end

clear x2 xx2

disp('Predict on set 2 (validation) for different Ks...');

for k=1:length(Kvalues)
    
    Ypred = zeros(N(2), 1);
    
    Kcurrent = min(Kvalues(k), N(1));
    
    for bidx=1:Nbatches
        
        start_idx = (bidx-1)*batch_size+1;
        end_idx = min(bidx*batch_size, N(2));
        
        if Kcurrent==1
            Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
        else
            Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
        end
        
    end
    
    % store the accuracy for current K 
    acc_crossval(1, k) = compute_accuracy(Ypred, YY{2}, 'gurls');
    
end

% Remove intermediate I matrices if requested

if save_I==false
    rmfile(fullfile(output_dir, ['I_' set_name{1} '_' set_name{1s} '.mat']));
end

% Prepare scores and compute I for sets 1-1 (train),
% then predict on set 1 (train) for different Ks

disp('Preparing scores to compute I for sets 1-1 (train)...');

batch_size = min(max_batch_size, N(1));
Nbatches = ceil(N(1)/batch_size);

x1cell = cell(Nbatches, 1);
xx1cell = cell(Nbatches, 1);
for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(1));
    
    x1cell{bidx} = x1(start_idx:end_idx, :)';
    xx1cell{bidx} = xx1(start_idx:end_idx)';
end

disp('Compute I for sets 1-1 (train)...');

m = matfile(fullfile(output_dir, ['I_' set_name{1} '_' set_name{1} '.mat']), 'Writable', true);
m.I = zeros(min(max_Icols, N(1)), 1);

for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(1));
    Dbatch = bsxfun( @plus, xx1, xx1cell{bidx} ) - 2*x1*x1cell{bidx};
    
    [~, I] = sort(Dbatch, 1);
    
    m.I(:, start_idx:end_idx) = I(1:max_k, :);
    
    disp(num2str(bidx));
    
end

clear x1cell xx1cell

disp('Predict on set 1 (train) for different Ks...');

for k=1:length(Kvalues)
    
    Ypred = zeros(N(1), 1);
    
    Kcurrent = min(k, N(1));
    
    for bidx=1:Nbatches
        
        start_idx = (bidx-1)*batch_size+1;
        end_idx = min(bidx*batch_size, N(1));
        
        if Kcurrent==1
            Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
        else
            Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
        end
        
    end
    
    % store the accuracy for current K 
    acc_crossval(2, k) = compute_accuracy(Ypred, YY{1}, 'gurls');
    
end

% Remove intermediate I matrices if requested

if save_I==false
    rmfile(fullfile(output_dir, ['I_' set_name{1} '_' set_name{2} '.mat']));
end

%% Test

% Load Y and create X for test set
disp('Loading Y and creating X for test...');

sidx=3;
set_name = set_names{sidx};
    
% load Y
load(fullfile(input_dir_regtxt, ['Y_' set_name '.mat']));
YY{3} = cell2mat(Y);
clear Y

% load scores and create X
load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
X = cell(Ncat, 1);
NframesPerCat{sidx} = cell(Ncat, 1);
for cc=values(opts.Cat, cat_names(cat_idx))
    NframesPerCat{sidx}{cc} = length(REG{cc});
    X{cc} = zeros(NframesPerCat{sidx}{cc}, 1000);
    for ff=1:NframesPerCat{sidx}{cc}
        fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{cc}{ff}(1:(end-4)) '.txt']));
        X{cc}(ff,:) = cell2mat(textscan(fid, '%f'))';
        fclose(fid);
    end
end

XX = cell2mat(X);
XX2 = sum(XX{sidx}.*XX{sidx},2);

N(sidx) = size(XX,1);

clear REG X

% Prepare scores and compute I for sets 1-3 (test),
% then predict on set 3 (test) for the best K

disp('Preparing scores to compute I for sets 1-3 (test)...');

batch_size = min(max_batch_size, N(3));
Nbatches = ceil(N(3)/batch_size);

x3 = cell(Nbatches, 1);
xx3 = cell(Nbatches, 1);
for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(2));
    
    x3{bidx} = XX(start_idx:end_idx, :)';
    xx3{bidx} = XX2(start_idx:end_idx)';
end

clear XX XX2;

disp('Computing I for sets 1-3 (test)...');

m = matfile(fullfile(output_dir, ['I_' set_name{1} '_' set_name{3} '.mat']), 'Writable', true);
m.I = zeros(min(max_Icols, N(3)), 1);

for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(2));
    Dbatch = bsxfun( @plus, xx1, xx3{bidx} ) - 2*x1*x3{bidx};
    
    [~, I] = sort(Dbatch, 1);
    
    m.I(:, start_idx:end_idx) = I(1:max_k, :);
    
    disp(num2str(bidx));
    
end

clear x3 xx3

disp('Predict on set 3 (test) for the best K...');

% Choose best K on validation

[v, best_k_idx] = min(acc_crossval(2,:));
best_k = Kvalues(best_k_idx);

%for k=1:length(Kvalues)
for k=best_k_idx
    
    Ypred = zeros(N(3), 1);
    
    Kcurrent = min(Kvalues(k), N(3));
    
    for bidx=1:Nbatches
        
        start_idx = (bidx-1)*batch_size+1;
        end_idx = min(bidx*batch_size, N(3));
        
        if Kcurrent==1
            Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
        else
            Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
        end
        
    end
    
    % store the accuracy for current K 
    acc_crossval(3, k) = compute_accuracy(Ypred, YY{3}, 'gurls');
    
    Ypred = mat2cell(Ypred, cell2mat(NframesPerCat{3}));
    save(fullfile(output_dir, ['Y_' num2str(Kcurrent) 'NN_' set_name{3} '.mat']), 'Ypred', '-v7.3'); 

end

% Remove intermediate I matrix if requested

if save_I==false
    rmfile(fullfile(output_dir, ['I_' set_name{1} '_' set_name{3} '.mat']));
end