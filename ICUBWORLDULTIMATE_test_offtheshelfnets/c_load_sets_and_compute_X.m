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

experiment = 'categorization';
%experiment = 'identification';

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

%% Load the scores and create X matrices

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    % load REG
    load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
    
    for dset_idx=1:length(dset_dirs)
        
        dset_dir = dset_dirs{dset_idx};
        
        input_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'scores', model);
        check_input_dir(input_dir);
        
        output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model, experiment);
        check_output_dir(output_dir);
        
        % create X matrices
        
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
    
end