
clear all;

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

vl_feat_setup();

%caffe_dir = '/usr/local/src/robot/caffe';
caffe_dir = '/data/giulia/REPOS/caffe';
addpath(genpath(fullfile(caffe_dir, 'matlab')));

caffe.set_mode_gpu();
gpu_id = 0;
caffe.set_device(gpu_id);

phase = 'test';

%% Global data dir
DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

%% Dataset info

dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
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

%% Whether the net is finetuned or not
mapping = '';
%mapping = 'tuning';

%% Setup the question
question_dir = '';
%question_dir = 'frameORtransf';
%question_dir = 'frameORinst';

%% Whether to use also the ImageNet labels
if isempty(mapping)
    use_imnetlabels = true;
else
    use_imnetlabels = false;
end

%% Setup the IO root directories

% input images
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

% input registries
input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% output root
exp_dir = fullfile([dset_dir '_experiments'], 'categorization');
check_output_dir(exp_dir);

%% Categories
%cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };

if ~isempty(mapping)
    
    %% Set up train, val and test sets
    
    % objects per category
    Ntest = 1;
    Nval = 1;
    Ntrain = NobjPerCat - Ntest - Nval; 
    obj_lists_all = cell(Ntrain, 1);
    p = randperm(NobjPerCat);
    for oo=1:Ntrain 
        obj_lists_all{oo} = cell(1,3);
        obj_lists_all{oo}{3} = p(1:Ntest);
        obj_lists_all{oo}{2} = p((Ntest+1):(Ntest+Nval));
        obj_lists_all{oo}{1} = p((Ntest+Nval+1):(Ntest+Nval+oo));
    end

    % transformation
    transf_lists_all = { {1:Ntransfs, 1:Ntransfs, 1:Ntransfs}; {1, 1, 1} };

    % day
    day_mappings_all = { {1, 1, 1} };
    day_lists_all = create_day_list(day_mappings_all, opts.Days);

    % camera
    camera_lists_all = { {1, 1, 1} };
    
    % sets
    eval_set = 3;
    tr_set = 1;
    val_set = 2;
    
    set_name_prefixes = {'train_', 'val_'};
    
else 

    %% Just set up the test set
    
    % objects per category
    obj_lists_all = { {1:NobjPerCat} };
    
    % transformation
    transf_lists_all = { {1:Ntransfs} };
    
    % day
    day_mappings_all = { {1} };
    day_lists_all = create_day_list(day_mappings_all, opts.Days);
    
    % camera
    camera_lists_all = { {1} };

    eval_set = 1;
    
end

%% Caffe model

model = 'caffenet';
%model = 'googlenet_paper';
%model = 'googlenet_caffe';
%model = 'vgg16';

if strcmp(model, 'caffenet')
    
    % model dir
    model_dir = fullfile(caffe_dir, 'models/bvlc_reference_caffenet/');
    
    % net weights
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_reference_caffenet.caffemodel');
    
    % mean_data: mat file already in W x H x C with BGR channels
    caffepaths.mean_path = fullfile(caffe_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
    
    CROP_SIZE = 227;
    
    % remember that actual caffe batch size is max_bsize*NCROPS !!!!
    max_bsize = 50;
    
    % net definition
    oversample = true;
    if oversample
        NCROPS = 10;
    else
        NCROPS=1;
    end
    caffepaths.net_model = fullfile(model_dir, 'deploy.prototxt');
    
    % features to extract
    extract_features = true;
    if extract_features
        feat_names = {'fc6', 'fc7'};
        nFeat = length(feat_names);
    end
    
elseif strcmp(model, 'googlenet_caffe')
    
    % net weights
    model_dir = fullfile(caffe_dir, 'models/bvlc_googlenet/');
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_googlenet.caffemodel');
    
    CROP_SIZE = 224;
    
    % remember that actual caffe batch size is max_batch_size*NCROPS !!!!
    max_bsize = 512;
    
    % net definition
    oversample = true;
    if oversample
        NCROPS = 10;
    else
        NCROPS=1;
    end
    caffepaths.net_model = fullfile(model_dir, 'deploy.prototxt');
    
    % features to extract
    extract_features = false;
    if extract_features
        feat_names = [];
        nFeat = length(feat_names);
    end
    
elseif strcmp(model, 'googlenet_paper')
    
    % net weights
    model_dir = fullfile(caffe_dir, 'models/bvlc_googlenet/');
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_googlenet.caffemodel');
    
    CROP_SIZE = 224;
    
    % whether to consider multiple scales
    %SHORTER_SIDE = [256 288 320 352];
    SHORTER_SIDE = 256;
    
    % whether to consider multiple crops
    %GRID = '3-2';
    %GRID = '1-2';
    %GRID = '3-1';
    GRID='1x1';
    %GRID = '5x5';
    
    %% assign number of total crops per image
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
        else
            NCROPS = grid_side;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        if grid_side>1
            NCROPS = grid_side*grid_side*2;
        else
            NCROPS = 1;
        end
    end
    NCROPS=NCROPS*length(SHORTER_SIDE);
    
    % remember that actual caffe batch size is max_batch_size*NCROPS !!!!
    max_bsize = 2;
    
    caffepaths.net_model = fullfile(model_dir, 'deploy.prototxt');
    
    % features to extract
    extract_features = false;
    if extract_features
        feat_names = [];
        nFeat = length(feat_names);
    end
    
elseif strcmp(model, 'vgg16')
    
    % net weights
    model_dir = fullfile(caffe_dir, 'models/VGG/VGG_ILSVRC_16');
    caffepaths.net_weights = fullfile(model_dir, 'VGG_ILSVRC_16_layers.caffemodel');
    
    CROP_SIZE = 224;
    
    % whether to consider multiple scales
    %SHORTER_SIDE = [256 384 512];
    SHORTER_SIDE = 384;
    
    % whether to consider multiple crops
    %GRID = '3-2';
    %GRID = '1-2';
    %GRID = '3-1';
    %GRID='1x1';
    GRID = '5x5';
    
    %% assign number of total crops per image
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
        else
            NCROPS = grid_side;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        NCROPS = grid_side*grid_side*2;
    end
    NCROPS=NCROPS*length(SHORTER_SIDE);
    
    % remember that actual caffe batch size is max_batch_size*NCROPS !!!!
    max_bsize = 2;
    
    caffepaths.net_model = fullfile(model_dir, 'VGG_ILSVRC_16_layers_deploy.prototxt');
    
    % features to extract
    extract_features = true;
    if extract_features
        feat_names = {'fc6', 'fc7'};
        nFeat = length(feat_names);
    end
    
end

%% Caffe net init

% init network
net = caffe.Net(caffepaths.net_model, caffepaths.net_weights, phase);

% reshape according to batch size
inputshape = net.blobs('data').shape();
bsize_net = inputshape(4);
if max_bsize*NCROPS ~= bsize_net
    net.blobs('data').reshape([CROP_SIZE CROP_SIZE 3 max_bsize*NCROPS])
    net.reshape() % optional: the net reshapes automatically before a call to forward()
end

% load mean
if strcmp(model, 'caffenet') && isempty(mapping)
    d = load(caffepaths.mean_path);
    mean_data = d.mean_data;
elseif strncmp(model, 'googlenet', length('googlenet')) && isempty(mapping)
    mean_data = [104 117 123];
elseif strcmp(model, 'vgg16') && isempty(mapping)
    mean_data = [103.939 116.779 123.68];
end

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_list = obj_lists_all{iobj}{eval_set};
        
        for itransf=1:length(transf_lists_all)
            
            transf_list = transf_lists_all{itransf}{eval_set};
            
            for iday=1:length(day_lists_all)
                
                day_list = day_lists_all{iday}{eval_set};
                day_mapping = day_mappings_all{iday}{eval_set};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_list = camera_lists_all{icam}{eval_set};
                    
                    %% Create the test set name
                    set_name = [strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-') ...
                        '_tr_' strrep(strrep(num2str(transf_list), '   ', '-'), '  ', '-') ...
                        '_day_' strrep(strrep(num2str(day_mapping), '   ', '-'), '  ', '-') ...
                        '_cam_' strrep(strrep(num2str(camera_list), '   ', '-'), '  ', '-')];
                    
                    if ~isempty(mapping)
                        %% Create the train val folder name
                        for iset=1:length(set_name_prefixes) 
                            set_names{iset} = [strrep(strrep(num2str(obj_lists_all{iobj}{iset}), '   ', '-'), '  ', '-') ...
                            '_tr_' strrep(strrep(num2str(transf_lists_all{itransf}{iset}), '   ', '-'), '  ', '-') ...
                            '_day_' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', '-'), '  ', '-') ...
                            '_cam_' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', '-'), '  ', '-')];
                        end
                        trainval_dir = cell2mat(strcat(set_name_prefixes(:), '_', set_names(:))');
                    else
                        trainval_dir = '';
                    end
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir_y = fullfile(exp_dir, model, dir_regtxt_relative, trainval_dir, mapping);
                    check_output_dir(output_dir_y);

                    if isempty(mapping)
                        output_dir_fc = fullfile(exp_dir, model, 'scores');                  
                    else
                        output_dir_fc = fullfile(output_dir_y, 'scores');
                    end
                    check_output_dir(output_dir_y);
                    
                    %% Set scores to be selected
                    
                    sel_idxs = cell2mat(values(opts.Cat_ImnetLabels));
                    sel_idxs = sel_idxs(cat_idx)+1;
                    % check against number of output units
                    score_length = net.blobs('prob').shape();
                    score_length = score_length(1);
                    if sum(sel_idxs>score_length)
                        error('You are selecting scores out of net range!');
                    end
 
                    %% Load the registry and Y (true labels)
                    fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                    input_registry = textscan(fid, '%s %d'); 
                    fclose(fid);
                    Y = input_registry{2};
                    REG = input_registry{1};  
                    if use_imnetlabels
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Yimnet.txt']));
                        input_registry = textscan(fid, '%s %d'); 
                        fclose(fid);
                        Yimnet = input_registry{2};
                    end
                    clear input_registry;
                    
                    %% Extract scores (+ features) and compute predictions
              
                    % get number of samples
                    Nsamples = length(Y);
                    
                    % allocate memory for all predictions
                    Ypred_avg = zeros(Nsamples,1);
                    if isempty(mapping)
                        Ypred_avg_sel = zeros(Nsamples,1);
                    end
                    if strcmp(model, 'caffenet') && isempty(mapping) && oversample
                        Ypred_central = zeros(Nsamples,1);
                        if isempty(mapping)
                            Ypred_central_sel = zeros(Nsamples,1);
                        end
                    end
                      
                    bsize = min(max_bsize, Nsamples);
                    Nbatches = ceil(Nsamples/bsize);
                    
                    for bidx=1:Nbatches
                        
                        bstart = (bidx-1)*bsize+1;
                        bend = min(bidx*bsize, Nsamples);
                        bsize_curr = bend-bstart+1;
                        
                        inputshape = net.blobs('data').shape();
                        bsize_net = inputshape(4);
                        if bsize_curr*NCROPS ~= bsize_net
                            net.blobs('data').reshape([CROP_SIZE CROP_SIZE 3 bsize_curr*NCROPS])
                            net.reshape() % optional: the net reshapes automatically before a call to forward()
                        end
                        
                        % load images and preprocess one by one
                        input_data = zeros(CROP_SIZE,CROP_SIZE,3,bsize_curr*NCROPS, 'single');
                        for imidx=1:bsize_curr
                            im = imread(fullfile(dset_dir, [REG{bstart+imidx-1}(1:(end-4)) '.jpg']));
                            
                            if (strcmp(model, 'caffenet') || strcmp(model, 'googlenet')) && isempty(mapping)
                                input_data(:,:,:,((imidx-1)*NCROPS+1):(imidx*NCROPS)) = prepare_image_caffe(im, mean_data, CROP_SIZE, oversample);
                            elseif strcmp(model, 'vgg16') && isempty(mapping)
                                input_data(:,:,:,((imidx-1)*NCROPS+1):(imidx*NCROPS)) = prepare_image_multiscalecrop(im, mean_data, CROP_SIZE, SHORTER_SIDE, GRID);
                            end
                            
                        end
                        
                        % extract scores in batches
                        scores = net.forward({input_data});
                        scores = scores{1};
                        
                        % extract features in batches
                        if extract_features
                            feat = cell(nFeat,1);
                            for ff=1:nFeat
                                feat{ff} = net.blobs(feat_names{ff}).get_data();
                            end
                        end
                        
                        % reshape, dividing scores per image
                        scores = reshape(scores, [], NCROPS, bsize_curr);
                        
                        % reshape, dividing features per image
                        if extract_features
                            for ff=1:nFeat
                                feat{ff} = reshape(feat{ff}, [], NCROPS, bsize_curr);
                            end
                        end
                        
                        % take average score over crops
                        % if single crop, avg_scores == scores
                        avg_scores = squeeze(mean(scores, 2));
                        if isempty(mapping)
                            % select
                            avg_scores_sel = avg_scores(sel_idxs, :);
                        end
                        
                        if strcmp(model, 'caffenet') && isempty(mapping) && oversample
                            % take central score over crops
                            central_scores = squeeze(scores(:,5,:));
                        end
                        if isempty(mapping)
                            % select
                            central_scores_sel = central_scores(sel_idxs, :);
                        end
                        
                        % max
                        [~, maxlabel_avg] = max(avg_scores);
                        maxlabel_avg = maxlabel_avg - 1;
                        
                        if isempty(mapping)
                            % max
                            [~, maxlabel_avg_sel] = max(avg_scores_sel);
                            maxlabel_avg_sel = maxlabel_avg_sel - 1;
                        end
                        
                        if strcmp(model, 'caffenet') && isempty(mapping) && oversample
                            % max
                            [~, maxlabel_central] = max(central_scores);
                            maxlabel_central = maxlabel_central - 1;
                            if isempty(mapping)
                                % max
                                [~, maxlabel_central_sel] = max(central_scores_sel);
                                maxlabel_central_sel = maxlabel_central_sel - 1;
                            end
                        end
                        
                        % save extracted features
                        if extract_features
                            for imidx=1:bsize_curr
                                for ff=1:nFeat
                                    fc = squeeze(feat{ff}(:,:,imidx));
                                    outpath = fullfile(output_dir_fc, feat_names{ff}, fileparts(REG{bstart+imidx-1}));
                                    check_output_dir(outpath);
                                    save(fullfile(output_dir_fc, feat_names{ff}, [REG{bstart+imidx-1}(1:(end-4)) '.mat']), 'fc');
                                end
                            end
                        end
                        
                        % store all predictions in Y
                        Ypred_avg(bstart:bend) = maxlabel_avg;
                        if isempty(mapping)
                            Ypred_avg_sel(bstart:bend) = maxlabel_avg_sel;
                        end
                        if strcmp(model, 'caffenet') && isempty(mapping) && oversample
                            Ypred_central(bstart:bend) = maxlabel_central;
                            if isempty(mapping)
                                Ypred_central_sel(bstart:bend) = maxlabel_central_sel;
                            end
                        end

                        fprintf('batch %d out of %d \n', bidx, Nbatches);
                    end

                    % compute accuracy and save everything             
                    if isempty(mapping)
                        [acc, acc_xclass, C] = trace_confusion(Yimnet+1, Ypred_avg+1, score_length);
                    else
                        [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_avg+1, score_length);
                    end   
                    save(fullfile(output_dir_y, ['Yavg_' set_name '.mat'] ), 'Ypred_avg', 'acc', 'acc_xclass', 'C', '-v7.3');
                    
                    if isempty(mapping)
                        [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_avg_sel+1, length(cat_idx));
                        save(fullfile(output_dir_y, ['Yavg_sel_' set_name '.mat'] ), 'Ypred_avg_sel', 'acc', 'acc_xclass', 'C', '-v7.3');  
                    end
                    
                    if oversample
                        if isempty(mapping)
                            [acc, acc_xclass, C] = trace_confusion(Yimnet+1, Ypred_central+1, score_length);
                        else
                            [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_central+1, score_length);
                        end
                        save(fullfile(output_dir_y, ['Ycentral_' set_name '.mat'] ), 'Ypred_central', 'acc', 'acc_xclass', 'C', '-v7.3');
                        
                        if isempty(mapping)
                            [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_central_sel+1, length(cat_idx));
                            save(fullfile(output_dir_y, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred_central_sel', 'acc', 'acc_xclass', 'C', '-v7.3');
                        end
                    end                       

                end
            end
        end
    end
end

caffe.reset_all();

