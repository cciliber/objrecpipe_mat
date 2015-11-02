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

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';

output_dir = fullfile('/data/giulia/DATASETS/iCubWorldUltimate_centroid_disp_finaltree_experiments/test_offtheshelfnets/predictions', model, 'kNN');
check_output_dir(output_dir);

input_dir = fullfile('/data/giulia/DATASETS/iCubWorldUltimate_centroid_disp_finaltree_experiments/test_offtheshelfnets/scores', model);
check_input_dir(input_dir);

reg_dir = '/data/giulia/DATASETS/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

%% Train & test sets

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

obj_train = 1:NobjPerCat;
obj_test = 1:NobjPerCat;

transf_train = 1:Ntransfs;
transf_test = 1:Ntransfs;

day_train = 3:2:Ndays;
day_test = 4:2:Ndays;

camera_train = [1 2];
camera_test = [1 2];

% cat_idx = [2 3];
% 
% obj_train = 1;
% obj_test = 1;
% 
% transf_train = 1;
% transf_test = 1;
% 
% day_train = 3:2:Ndays;
% day_test = 4:2:Ndays;
% 
% camera_train = 1 ;
% camera_test = 1;

%% Build TRAIN

Xtr = cell(Ncat, 1);
Ytr = cell(Ncat, 1);

for cc=cat_idx
    
    reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
    
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_file(reg_path, [], []); 
    
    fpaths = loader.Registry;
    clear loader;
    
    fdirs = regexp(fpaths, '/', 'split');
    fdirs = vertcat(fdirs{:});
    fdirs(:,1) = [];
    clear fpaths;
    
    tobeloaded = zeros(length(fdirs), 1);
    
    for oo=obj_train
        
        oo_tobeloaded = strcmp(fdirs(:,1), strcat(cat_names{cc}, num2str(oo)));
        
        for tt=transf_train
            
            tt_tobeloaded = oo_tobeloaded & strcmp(fdirs(:,2), transf_names(tt));
            
            for dd=day_train
                
                dd_tobeloaded = tt_tobeloaded & strcmp(fdirs(:,3), day_names(dd));
                
                for ee=camera_train
                    
                    ee_tobeloaded = dd_tobeloaded & strcmp(fdirs(:,4), camera_names(ee));
                    
                    tobeloaded = tobeloaded + ee_tobeloaded;

                end
            end
        end
    end
      
    fpaths = fullfile(fdirs(tobeloaded==1,1), fdirs(tobeloaded==1,2), fdirs(tobeloaded==1,3), fdirs(tobeloaded==1,4), fdirs(tobeloaded==1,5));
                    
    Xtr{opts.Cat(cat_names{cc})} = zeros(length(fpaths), 1000);
    Ytr{opts.Cat(cat_names{cc})} = ones(length(fpaths), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
                    
    for ff=1:length(fpaths)
        fid = fopen(fullfile(input_dir, cat_names{cc}, [fpaths{ff}(1:(end-4)) '.txt']));
        Xtr{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
        fclose(fid);
    end

    disp(['TR: ' cat_names(cc)]);
    
end

Xtr = cell2mat(Xtr);
Ytr = cell2mat(Ytr);

save(fullfile(output_dir, 'Xtr.mat'), 'Xtr', '-v7.3');
save(fullfile(output_dir, 'Ytr.mat'), 'Ytr', '-v7.3');

%% Build TEST

Xte = cell(Ncat, 1);
Yte = cell(Ncat, 1);

for cc=cat_idx
    
    reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
    
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_file(reg_path, [], []); 
    
    fpaths = loader.Registry;
    clear loader;
    
    fdirs = regexp(fpaths, '/', 'split');
    fdirs = vertcat(fdirs{:});
    fdirs(:,1) = [];
    clear fpaths;
    
    tobeloaded = zeros(length(fdirs), 1);
    
    for oo=obj_test
        
        oo_tobeloaded = strcmp(fdirs(:,1), strcat(cat_names{cc}, num2str(oo)));
        
        for tt=transf_test
            
            tt_tobeloaded = oo_tobeloaded & strcmp(fdirs(:,2), transf_names(tt));
            
            for dd=day_test
                
                dd_tobeloaded = tt_tobeloaded & strcmp(fdirs(:,3), day_names(dd));
                
                for ee=camera_test
                    
                    ee_tobeloaded = dd_tobeloaded & strcmp(fdirs(:,4), camera_names(ee));
                    
                    tobeloaded = tobeloaded + ee_tobeloaded;

                end
            end
        end
    end
      
    fpaths = fullfile(fdirs(tobeloaded==1,1), fdirs(tobeloaded==1,2), fdirs(tobeloaded==1,3), fdirs(tobeloaded==1,4), fdirs(tobeloaded==1,5));
                    
    Xte{opts.Cat(cat_names{cc})} = zeros(length(fpaths), 1000);
    Yte{opts.Cat(cat_names{cc})} = ones(length(fpaths), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
                    
    for ff=1:length(fpaths)
        fid = fopen(fullfile(input_dir, cat_names{cc}, [fpaths{ff}(1:(end-4)) '.txt']));
        Xte{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
        fclose(fid);
    end

     disp(['TE: ' cat_names(cc)]);
end

Xte = cell2mat(Xte);
Yte = cell2mat(Yte);
  
save(fullfile(output_dir, 'Xte.mat'), 'Xte', '-v7.3');
save(fullfile(output_dir, 'Yte.mat'), 'Yte', '-v7.3');

clear tobeloaded oo_tobeloaded tt_tobeloaded dd_tobeloaded ee_tobeloaded

%% TEST!

k = 1;

Xtr_gpu = gpuArray(Xtr);
Ytr_gpu = gpuArray(int32(Ytr));

Ntest = size(Xte,1);

Ypred_te_gpu = zeros(Ntest, 1);
batch_size = 500;
Nbatches = ceil(Ntest/batch_size);
tic
for idx=1:Nbatches 
    Xte_gpu = gpuArray(Xte(((idx-1)*batch_size+1):min(idx*batch_size,Ntest),:));
    Ytmp_gpu = kNNClassify_multiclass_gpu(Xtr_gpu, Ytr_gpu, k, Xte_gpu);
    Ypred_te_gpu((((idx-1)*batch_size+1):min(idx*batch_size, Ntest))) = gather(Ytmp_gpu);
end
toc

save(fullfile(output_dir, 'Ypred_te_gpu.mat'), 'Ypred_te_gpu', '-v7.3');

Ypred_te_cpu = zeros(Ntest, 1);
batch_size = 10000;
Nbatches = ceil(Ntest/batch_size);
tic
for idx=1:Nbatches 
    Ypred_te_cpu((((idx-1)*batch_size+1):min(idx*batch_size, Ntest))) = kNNClassify(Xtr, Ytr, k, Xte(((idx-1)*batch_size+1):min(idx*batch_size, Ntest),:));
end
toc

save(fullfile(output_dir, 'Ypred_te_cpu.mat'), 'Ypred_te_cpu', '-v7.3');

%% Verify the correctness of the kNN algortihm on the TRAINING SET...

% Ntrain = size(Xtr,1);
% 
% Ypred_tr_cpu = zeros(Ntrain, 1);
% batch_size = 300;
% Nbatches = ceil(Ntrain/batch_size);
% tic
% for idx=1:Nbatches 
%     Ypred_tr_cpu(((idx-1)*batch_size+1):min(idx*batch_size,Ntrain)) = kNNClassify_multiclass(Xtr, Ytr, k, Xtr(((idx-1)*batch_size+1):min(idx*batch_size,Ntrain),:));
%     %Ypred_tr_cpu_ale(((idx-1)*batch_size+1):min(idx*batch_size, Ntrain)) = kNNClassify(Xtr, Ytr, k, Xtr(((idx-1)*batch_size+1):min(idx*batch_size,Ntrain),:));
% end
% toc
% 
% Ypred_tr_gpu = zeros(Ntrain, 1);
% batch_size = 300;
% Nbatches = ceil(Ntrain/batch_size);
% tic
% for idx=1:Nbatches 
%     Ytmp_gpu = kNNClassify_multiclass_gpu(Xtr_gpu, Ytr_gpu, k, Xtr_gpu(((idx-1)*batch_size+1):min(idx*batch_size,Ntrain),:));
%     Ypred_tr_gpu((((idx-1)*batch_size+1):min(idx*batch_size, Ntrain))) = gather(Ytmp_gpu);
% end
% toc

%% Put the predictions in the same cell array as the native ones

prediction = cell(Ncat,1);
more_freq_prediction = cell(Ncat,1);
prediction_yesno = cell(Ncat,1);
accuracy = cell(Ncat,1);

for cc=cat_idx

    reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
    
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_file(reg_path, [], []);
    
    if sum(loader.Y==loader.Y(1))==length(loader.Y)
        Ytrue =loader.Y(1);
    else
        disp(['Not all files in ' reg_path ' have the same label.']);
    end
        
    fpaths = loader.Registry;
    clear loader;
    
    fdirs = regexp(fpaths, '/', 'split');
    fdirs = vertcat(fdirs{:});
    fdirs(:,1) = [];
    clear fpaths;

    prediction{cc} = cell(NobjPerCat, Ntransfs, 2, Ncameras);
    prediction_yesno{cc} = cell(NobjPerCat, Ntransfs, 2, Ncameras);
    more_freq_prediction{cc} = zeros(NobjPerCat, Ntransfs, 2, Ncameras);
    accuracy{cc} = zeros(NobjPerCat, Ntransfs, 2, Ncameras);
    
    fid = fopen(fullfile(output_dir, model, [cat_names{cc} '_' num2str(Ytrue(cc)) '_pred.txt']), 'w');
    line_idx = cellfun(@fileparts, fpaths, 'UniformOutput', false);
    [~, ~, ic] = unique(line_idx, 'stable'); 
    % [C,ia,ic] = unique(A) 
    % C = A(ia)
    % A = C(ic)
    
    ff=1;
    
    prob = textread(fullfile(input_dir, model, [fpaths{ff}(1:(end-4)) '.txt']), '%f', 'delimiter', '\n');
    [dummy, y] = max(prob);
    
    Ypred = zeros(sum(ic==ic(ff)), 1);
    counter = 1;
    Ypred(counter) = y-1;
    
    counter = counter + 1;
    
    for ff=2:length(fpaths)
        
        prob = textread(fullfile(input_dir, model, [fpaths{ff}(1:(end-4)) '.txt']), '%f', 'delimiter', '\n');
        [dummy, y] = max(prob);
        
        if ic(ff)==ic(ff-1)
            
            Ypred(counter) = y-1;
          
        else
            
            prediction{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = Ypred;
            fprintf(fid, '%s\t', line_idx{ff-1});
            fprintf(fid, '%3d ', Ypred);
            fprintf(fid, '\n');

            prediction_yesno{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = (Ypred==Ytrue(cc));
        
            more_freq_prediction{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = mode(Ypred); 
        
            accuracy{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = compute_accuracy(repmat(Ytrue(cc), length(Ypred), 1), Ypred, 'gurls');
            
            Ypred = zeros(sum(ic==ic(ff)), 1);
            counter = 1;
            Ypred(counter) = y-1;
            
        end
        
        counter = counter + 1;
        
    end
    
    
    prediction{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = Ypred;
    fprintf(fid, '%s\t', line_idx{ff-1});
    fprintf(fid, '%3d ', Ypred);
    fprintf(fid, '\n');
    
    prediction_yesno{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = (Ypred==Ytrue(cc));
    
    more_freq_prediction{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = mode(Ypred);
    
    accuracy{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = compute_accuracy(repmat(Ytrue(cc), length(Ypred), 1), Ypred, 'gurls');
    
    fclose(fid);

end

save(fullfile(output_dir, model, 'all.mat'), 'prediction', 'prediction_yesno', 'accuracy', 'more_freq_prediction');