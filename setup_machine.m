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


    %% CAFFE Binaries 
    caffe_bin_path = fullfile(caffe_dir, 'build/install/bin/caffe');
    create_lmdb_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/create_lmdb/build/create_lmdb_icubworld');
    compute_mean_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/compute_mean/build/compute_mean_icubworld');
    parse_log_path = fullfile(FEATURES_DIR, 'f_finetune/parse_caffe_log.sh');

    template_prototxts_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_prototxts/template_models');
    
    %% Global data dir
    DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

    %% Dataset info
    dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
    dset = ICUBWORLDinit(dset_info);

    
    setup_data.caffe_dir    = caffe_dir;
    setup_data.dset         = dset;
    setup_data.DATA_DIR     = DATA_DIR;
    
    
    setup_data.caffe_bin_path           = caffe_bin_path;
    setup_data.create_lmdb_bin_path     = create_lmdb_bin_path;
    setup_data.compute_mean_bin_path    = compute_mean_bin_path;
    setup_data.parse_log_path           = parse_log_path;
    setup_data.template_prototxts_path  = template_prototxts_path;
end


