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
%model = 'vgg';

%experiment = 'test_offtheshelf';
experiment = 'kNN-categorization-corrected';
%experiment = 'kNN-categorization';
%experiment = 'kNN-identification';
%experiment = 'fine_tuning_compare2kNN';

dset_dirs = {'/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb60_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid256_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree'};

reg_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries';
check_input_dir(reg_dir);

input_dir_regtxt = fullfile(reg_dir, experiment);
check_input_dir(input_dir_regtxt);

%% Sets

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

set_names = {'train', 'val', 'test'};

%% Load X matrices and compute native predictions

for dset_idx=1:length(dset_dirs)
    
    dset_dir = dset_dirs{dset_idx};
    
    io_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model, experiment);
    check_input_dir(io_dir);
    
    for sidx=1:length(set_names)
        
        set_name = set_names{sidx};

        % load X
        load(fullfile(io_dir, ['X_' set_name '.mat']));
        
        % compute native predictions
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
        save(fullfile(io_dir, ['Y_none_' set_name '.mat'] ), 'Ypred', '-v7.3'); 
    end
   
end