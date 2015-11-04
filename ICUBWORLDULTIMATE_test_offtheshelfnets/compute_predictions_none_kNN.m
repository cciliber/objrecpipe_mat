%% Setup 

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

gurls_setup('/data/REPOS/GURLS/');
vl_feat_setup();

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
%model = 'vgg';

dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid256_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb30_disp_finaltree';

reg_dir = '/data/giulia/DATASETS/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

input_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'scores', model);
check_input_dir(input_dir);

output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model);
check_output_dir(output_dir);

%% Divide into 2 sets (e.g. tr & te)

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

obj_train = 1:NobjPerCat;
obj_test = 1:NobjPerCat;

transf_train = 1:Ntransfs;
transf_test = 1:Ntransfs;

day_train = 3:2:Ndays;
day_test = 4:2:Ndays;

camera_train = [1 2];
camera_test = [1 2];

%% Build TRAIN (e.g. odd days)

Xodd = cell(Ncat, 1);
Yodd = cell(Ncat, 1);
REGodd = cell(Ncat, 1);

for cc=cat_idx
    
    reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
    
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_file(reg_path, [], []); 
    
    fdirs = regexp(loader.Registry, '/', 'split');
    clear loader;
    fdirs = vertcat(fdirs{:});
    fdirs(:,1) = [];
    
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
        
    REGodd{opts.Cat(cat_names{cc})} = fullfile(fdirs(tobeloaded==1,1), fdirs(tobeloaded==1,2), fdirs(tobeloaded==1,3), fdirs(tobeloaded==1,4), fdirs(tobeloaded==1,5));
    Xodd{opts.Cat(cat_names{cc})} = zeros(length(REGodd{opts.Cat(cat_names{cc})}), 1000);
    Yodd{opts.Cat(cat_names{cc})} = ones(length(REGodd{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
    
    for ff=1:length(REGodd{opts.Cat(cat_names{cc})})
        fid = fopen(fullfile(input_dir, cat_names{cc}, [REGodd{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
        Xodd{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
        fclose(fid);
    end

    disp(['TR: ' cat_names(cc)]);
    
end

save(fullfile(output_dir, 'REGodd.mat'), 'REGodd', '-v7.3');
save(fullfile(output_dir, 'Xodd.mat'), 'Xodd', '-v7.3');
save(fullfile(output_dir, 'Yodd.mat'), 'Yodd', '-v7.3');

load(fullfile(output_dir, 'Yodd.mat'));

%% Build TEST

Xeven = cell(Ncat, 1);
Yeven = cell(Ncat, 1);
REGeven = cell(Ncat, 1);

for cc=cat_idx
    
    reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
    
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_file(reg_path, [], []); 
    
    fdirs = regexp(loader.Registry, '/', 'split');
    clear loader;
    fdirs = vertcat(fdirs{:});
    fdirs(:,1) = [];
    
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
                     
    REGeven{opts.Cat(cat_names{cc})} = fullfile(fdirs(tobeloaded==1,1), fdirs(tobeloaded==1,2), fdirs(tobeloaded==1,3), fdirs(tobeloaded==1,4), fdirs(tobeloaded==1,5));
    Xeven{opts.Cat(cat_names{cc})} = zeros(length(REGodd{opts.Cat(cat_names{cc})}), 1000);
    Yeven{opts.Cat(cat_names{cc})} = ones(length(REGodd{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
    
    for ff=1:length(REGeven{opts.Cat(cat_names{cc})})
        fid = fopen(fullfile(input_dir, cat_names{cc}, [REGeven{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
        Xeven{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
        fclose(fid);
    end

     disp(['TE: ' cat_names(cc)]);
end

save(fullfile(output_dir, 'REGeven.mat'), 'REGeven', '-v7.3');
save(fullfile(output_dir, 'Xeven.mat'), 'Xeven', '-v7.3');
save(fullfile(output_dir, 'Yeven.mat'), 'Yeven', '-v7.3');
  
clear tobeloaded oo_tobeloaded tt_tobeloaded dd_tobeloaded ee_tobeloaded

%% Compute native predictions on even set

Ypred = cell(Ncat,1);
batch_size = 10000;

for cc=cat_idx

    Neven = size(Xeven{opts.Cat(cat_names{cc})},1);
    Ypred{opts.Cat(cat_names{cc})} = zeros(Neven, 1);
    Nbatches = ceil(Neven/batch_size);

    for idx=1:Nbatches
        [~, I] = max(Xeven{opts.Cat(cat_names{cc})}(((idx-1)*batch_size+1):min(idx*batch_size, Neven),:), [], 2);
        Ypred{opts.Cat(cat_names{cc})}((((idx-1)*batch_size+1):min(idx*batch_size, Neven))) = I-1;
    end
end

save(fullfile(output_dir, 'Yeven_none.mat'), 'Ypred', '-v7.3');

%% Compute native predictions on odd set

Ypred = cell(Ncat,1);
batch_size = 10000;

for cc=cat_idx
    Nodd = size(Xodd{opts.Cat(cat_names{cc})},1);
    Ypred{opts.Cat(cat_names{cc})} = zeros(Nodd, 1);
    Nbatches = ceil(Nodd/batch_size);

    for idx=1:Nbatches
        [~, I] = max(Xodd{opts.Cat(cat_names{cc})}(((idx-1)*batch_size+1):min(idx*batch_size, Nodd),:), [], 2);
        Ypred{opts.Cat(cat_names{cc})}((((idx-1)*batch_size+1):min(idx*batch_size, Nodd))) = I-1;
    end
end

save(fullfile(output_dir, 'Yodd_none.mat'), 'Ypred', '-v7.3');

%% Compute kNN predictions on even set, keeping odd as training set

k = 1;

Ypred = cell(Ncat, 1);
batch_size = 10000;

for cc=cat_idx
    
    Neven = size(Xeven{opts.Cat(cat_names{cc})},1);
    Ypred{opts.Cat(cat_names{cc})} = zeros(Neven, 1);
    Nbatches = ceil(Neven/batch_size);

    for idx=1:Nbatches 
        Ypred{opts.Cat(cat_names{cc})}((((idx-1)*batch_size+1):min(idx*batch_size, Neven))) = kNNClassify_multiclass(cell2mat(Xodd), cell2mat(Yodd), k, Xeven{opts.Cat(cat_names{cc})}(((idx-1)*batch_size+1):min(idx*batch_size, Neven),:));
        disp(['EVEN: ' num2str(cc) ' ' num2str(idx)]);
    end
    
end

save(fullfile(output_dir, 'Yeven_kNN.mat'), 'Ypred', '-v7.3');

%% Compute kNN predictions on odd set, keeping even as training set

k = 1;

Ypred = cell(Ncat, 1);
batch_size = 10000;

for cc=cat_idx 
    
    Nodd = size(Xodd{opts.Cat(cat_names{cc})},1);
    Ypred{opts.Cat(cat_names{cc})} = zeros(Nodd, 1);
    Nbatches = ceil(Nodd/batch_size);

    for idx=1:Nbatches 
        Ypred{opts.Cat(cat_names{cc})}(((idx-1)*batch_size+1):min(idx*batch_size,Nodd)) = kNNClassify_multiclass(cell2mat(Xeven), cell2mat(Yeven), k, Xodd{opts.Cat(cat_names{cc})}(((idx-1)*batch_size+1):min(idx*batch_size,Nodd),:));
        disp(['ODD: ' num2str(cc) ' ' num2str(idx)]);
    end
end

save(fullfile(output_dir, 'Yodd_kNN.mat'), 'Ypred', '-v7.3');
