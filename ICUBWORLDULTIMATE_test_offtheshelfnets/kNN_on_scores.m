%% Setup 

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% Dataset info

dset_info = fullfile(FEATURES_DIR, 'ICUBWORLDULTIMATE_test_offtheshelfnets', 'iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

ICUBWORLDopts = ICUBWORLDinit(dset_info);

cat_names = keys(ICUBWORLDopts.Cat)';
obj_names = keys(ICUBWORLDopts.Obj)';

Ncat = ICUBWORLDopts.Cat.Count;
Nobj = ICUBWORLDopts.Obj.Count;
NobjPerCat = ICUBWORLDopts.ObjPerCat;
Ntransfs = ICUBWORLDopts.Transfs.Count;
%Ndays = ICUBWORLDopts.Days.Count;
Ncameras = ICUBWORLDopts.Cameras.Count;

%% IO

input_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid_disp_finaltree_experiments/test_offtheshelfnets/scores';
check_input_dir(input_dir);

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';

output_dir = fullfile('/data/giulia/DATASETS/iCubWorldUltimate_centroid_disp_finaltree_experiments/test_offtheshelfnets/predictions', model, 'kNN');
check_output_dir(output_dir);

%% Load predictions

cat_list = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

DATA = load(fullfile(input_dir, model, 'all.mat'), 'prediction');
prediction = DATA.prediction;

%% Train & test sets

k = 1;

obj_train = obj_names;
obj_test = obj_names;

transf_train = keys(ICUBWORLDopts.Transfs);
transf_test = keys(ICUBWORLDopts.Transfs):

day_train = 1;
day_test = 2;

cam_train = [1 2];
cam_test = [1 2];

%% Go!

for cc=cat_list
    
    for oo=obj_test
        for tt=train_test
            for dd=day_test
                for cc=cam_test
                    
                    Ypred = kNNClassify(Xtr, Ytr, k, Xte);
                    
                    
                end
            end
        end
    end
    
end
            
            
            
            