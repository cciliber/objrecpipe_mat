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

model = 'googlenet';
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

experiment = 'kNN-categorization-corrected';
%experiment = 'kNN-identification';

dset_dirs = {'/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb60_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid256_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree'};

%% Sets (e.g. even & odd days)

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

set_names = {'train', 'val', 'test'};
day_lists = {3:2:Ndays, 3:2:Ndays, 3:Ndays};

obj_lists = {1:3, 4:6, 7:10};
transf_lists = {1:Ntransfs, 1:Ntransfs, 1:Ntransfs};

camera_lists = {[1 2], [1 2], [1 2]};

%% Go!

for dset_idx=1:length(dset_dirs)
    
    tic
    
    dset_dir = dset_dirs{dset_idx};
    
    input_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'scores', model);
    check_input_dir(input_dir);
    
    output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model, experiment);
    check_output_dir(output_dir);
    
    
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
            
            flist_splitted = regexp(loader.Registry, '/', 'split');
            clear loader;
            flist_splitted = vertcat(flist_splitted{:});
            flist_splitted(:,1) = [];
            
            tobeloaded = zeros(length(flist_splitted), 1);
            
            for oo=obj_list
                
                oo_tobeloaded = strcmp(flist_splitted(:,1), strcat(cat_names{cc}, num2str(oo)));
                
                for tt=transf_list
                    
                    tt_tobeloaded = oo_tobeloaded & strcmp(flist_splitted(:,2), transf_names(tt));
                    
                    for dd=day_list
                        
                        dd_tobeloaded = tt_tobeloaded & strcmp(flist_splitted(:,3), day_names(dd));
                        
                        for ee=camera_list
                            
                            ee_tobeloaded = dd_tobeloaded & strcmp(flist_splitted(:,4), camera_names(ee));
                            
                            tobeloaded = tobeloaded + ee_tobeloaded;
                            
                        end
                    end
                end
            end
            
            REG{opts.Cat(cat_names{cc})} = fullfile(flist_splitted(tobeloaded==1,1), flist_splitted(tobeloaded==1,2), flist_splitted(tobeloaded==1,3), flist_splitted(tobeloaded==1,4), flist_splitted(tobeloaded==1,5));
            Y{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
            X{opts.Cat(cat_names{cc})} = zeros(length(REG{opts.Cat(cat_names{cc})}), 1000);
            for ff=1:length(REG{opts.Cat(cat_names{cc})})
                fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
                X{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
                fclose(fid);
            end
            
            disp([set_name ': ' cat_names(cc)]);
            
        end
        
        save(fullfile(output_dir, ['X_' set_name '.mat']), 'X', '-v7.3');
        save(fullfile(output_dir, ['REG_' set_name '.mat']), 'REG', '-v7.3');
        save(fullfile(output_dir, ['Y_' set_name '.mat']), 'Y', '-v7.3');
        
        %% Compute native predictions
        
        Ypred = cell(Ncat,1);
        batch_size = 10000;
        
        for cc=cat_idx
            
            N = size(X{opts.Cat(cat_names{cc})},1);
            Ypred{opts.Cat(cat_names{cc})} = zeros(N, 1);
            Nbatches = ceil(N/batch_size);
            
            for bidx=1:Nbatches
                [~, I] = max(X{opts.Cat(cat_names{cc})}(((bidx-1)*batch_size+1):min(bidx*batch_size, N),:), [], 2);
                Ypred{opts.Cat(cat_names{cc})}((((bidx-1)*batch_size+1):min(bidx*batch_size, N))) = I-1;
            end
        end
        
        save(fullfile(output_dir, ['Y_none_' set_name '.mat'] ), 'Ypred', '-v7.3');
        
    end
    
    toc
    
end