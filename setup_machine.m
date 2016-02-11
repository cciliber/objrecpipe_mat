function setup_data = setup_machine()


    setup_data = struct;

    %% Code dir
    FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
    addpath(genpath(FEATURES_DIR));

    %% VL FEAT
    vl_feat_setup();

    %% GURLS
    gurls_setup();

    %% MATLAB CAFFE
    %caffe_dir = '/usr/local/src/robot/caffe';
    caffe_dir = '/data/giulia/REPOS/caffe';
    addpath(genpath(fullfile(caffe_dir, 'matlab')));

    %% Global data dir
    DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

    %% Dataset info
    dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
    dset = ICUBWORLDinit(dset_info);

    
    setup_data.caffe_dir    = caffe_dir;
    setup_data.dset_info    = dset;
    setup_data.DATA_DIR     = DATA_DIR;
    
    
end


