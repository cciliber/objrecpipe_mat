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

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid384_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb60_disp_finaltree';
dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid256_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb30_disp_finaltree';

reg_dir = '/data/giulia/DATASETS/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

input_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'scores', model);
check_input_dir(input_dir);

output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model);
check_output_dir(output_dir);

%% Build sets (e.g. even & odd days) & compute native predictions

set_names = {'even', 'odd'};
day_lists = {4:2:Ndays, 3:2:Ndays};
obj_lists = {1:NobjPerCat, 1:NobjPerCat};
transf_lists = {1:Ntransfs, 1:Ntransfs};
camera_lists = {[1 2], [1 2]};

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    day_list = day_lists{sidx};
    obj_list = obj_lists{sidx};
    transf_list = transf_lists{sidx};
    camera_list = camera_lists{sidx};
    
    %% Build sets
    
    X = cell(Ncat, 1);
    Y = cell(Ncat, 1);
    REG = cell(Ncat, 1);
    
    for cc=cat_idx
        
        reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
        
        loader = Features.GenericFeature();
        loader.assign_registry_and_tree_from_file(reg_path, [], []);
        
        fdirs = regexp(loader.Registry, '/', 'split');
        clear loader;
        fdirs = vertcat(fdirs{:});
        fdirs(:,1) = [];
        
        tobeloaded = zeros(length(fdirs), 1);
        
        for oo=obj_list
            
            oo_tobeloaded = strcmp(fdirs(:,1), strcat(cat_names{cc}, num2str(oo)));
            
            for tt=transf_list
                
                tt_tobeloaded = oo_tobeloaded & strcmp(fdirs(:,2), transf_names(tt));
                
                for dd=day_list
                    
                    dd_tobeloaded = tt_tobeloaded & strcmp(fdirs(:,3), day_names(dd));
                    
                    for ee=camera_list
                        
                        ee_tobeloaded = dd_tobeloaded & strcmp(fdirs(:,4), camera_names(ee));
                        
                        tobeloaded = tobeloaded + ee_tobeloaded;
                        
                    end
                end
            end
        end
        
        REG{opts.Cat(cat_names{cc})} = fullfile(fdirs(tobeloaded==1,1), fdirs(tobeloaded==1,2), fdirs(tobeloaded==1,3), fdirs(tobeloaded==1,4), fdirs(tobeloaded==1,5));
        Y{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
        X{opts.Cat(cat_names{cc})} = zeros(length(REG{opts.Cat(cat_names{cc})}), 1000);
        for ff=1:length(REG{opts.Cat(cat_names{cc})})
            fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
            X{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
            fclose(fid);
        end
        
        disp([set_name ': ' cat_names(cc)]);
        
    end
    
    save(fullfile(output_dir, ['REG_' set_name '.mat']), 'REG', '-v7.3');
    save(fullfile(output_dir, ['X_' set_name '.mat']), 'X', '-v7.3');
    save(fullfile(output_dir, ['Y_' set_name '.mat']), 'Y', '-v7.3');
    
    %% Compute native predictions
    
    Ypred = cell(Ncat,1);
    batch_size = 10000;
    
    for cc=cat_idx
        
        N = size(X{opts.Cat(cat_names{cc})},1);
        Ypred{opts.Cat(cat_names{cc})} = zeros(N, 1);
        Nbatches = ceil(N/batch_size);
        
        for idx=1:Nbatches
            [~, I] = max(X{opts.Cat(cat_names{cc})}(((idx-1)*batch_size+1):min(idx*batch_size, N),:), [], 2);
            Ypred{opts.Cat(cat_names{cc})}((((idx-1)*batch_size+1):min(idx*batch_size, N))) = I-1;
        end
    end
    
    save(fullfile(output_dir, ['Y_none_' set_name '.mat']), 'Ypred', '-v7.3');
    
end

clear tobeloaded oo_tobeloaded tt_tobeloaded dd_tobeloaded ee_tobeloaded

%% Compute kNN predictions on one set, keeping the other as training set

k = 1;

XX = cell(length(set_names),1);
YY = cell(length(set_names),1);

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    load(fullfile(output_dir, ['X_' set_name '.mat']));
    load(fullfile(output_dir, ['Y_' set_name '.mat']));
    XX{sidx} = X;
    YY{sidx} = Y;
    
end

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    other_sidx = -sidx + 3;
    
    Ypred = cell(Ncat, 1);
    batch_size = 10000;
    
    for cc=cat_idx
    
        N = size(XX{sidx}{opts.Cat(cat_names{cc})},1);
        Ypred{opts.Cat(cat_names{cc})} = zeros(N, 1);
        Nbatches = ceil(N/batch_size);

        for idx=1:Nbatches 
            Ypred{opts.Cat(cat_names{cc})}((((idx-1)*batch_size+1):min(idx*batch_size, N))) = kNNClassify_multiclass(cell2mat(XX{other_sidx}), cell2mat(YY{other_sidx}), k, XX{sidx}{opts.Cat(cat_names{cc})}(((idx-1)*batch_size+1):min(idx*batch_size, N),:));
            disp([set_name ': ' num2str(cc) ' ' num2str(idx)]);
        end
    end
    
    save(fullfile(output_dir, ['Y_kNN_' set_name '.mat']), 'Ypred', '-v7.3');
    
end