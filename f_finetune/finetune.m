%% Caffe - classify and extract features

addpath(genpath( '/usr/local/src/robot/caffe/matlab' ));

%% Setup

%FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
%FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));
create_lmdb_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/create_lmdb/build/create_lmdb_icubworld');
compute_mean_bin_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_subsets/compute_mean/build/compute_mean_icubworld');
template_prototxt_path = fullfile(FEATURES_DIR, 'f_finetune/prepare_prototxts/template_models');

%DATA_DIR = '/media/giulia/MyPassport';
%DATA_DIR = '/Volumes/MyPassport';
DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

%% Dataset info

dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat);
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

%% Set up the experiments

% Default sets that are searched

set_names_prefix = {'train_', 'val_'};
Nsets = length(set_names_prefix);

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Whether to use the imnet or the tuning labels

use_imnetlabels = false;

% Choose categories

cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    %obj_lists_all = { {1:7, 8:10} };
    obj_lists_all = { {1:7, 8:10} };
    %obj_lists_all = { {8:10} };
    
elseif strcmp(experiment, 'identification')
    
    id_exps = {1:3, 1:5, 1:7, 1:10};
    obj_lists_all = cell(length(id_exps), 1);
    for ii=1:length(id_exps)
        obj_lists_all{ii} = repmat(id_exps(ii), 1, Nsets);
    end
    
end

% Choose transformation, day, camera

%transf_lists_all = { {1, 1:Ntransfs} {2, 1:Ntransfs} {3, 1:Ntransfs} {4, 1:Ntransfs}};
%transf_lists_all = { {5, 1:Ntransfs} {4:5, 1:Ntransfs} {[2 4:5], 1:Ntransfs} {2:5, 1:Ntransfs} {1:Ntransfs, 1:Ntransfs} };
transf_lists_all = { {5, 5} };
%transf_lists_all = { {1:Ntransfs} };

day_mappings_all = { {1, 1} };
day_lists_all = cell(length(day_mappings_all),1);

for ee=1:length(day_mappings_all)
    
    day_mappings = day_mappings_all{ee};
    
    day_lists = cell(Nsets,1);
    tmp = keys(opts.Days);
    for ii=1:Nsets
        for dd=1:length(day_mappings{ii})
            tmp1 = tmp(cell2mat(values(opts.Days))==day_mappings{ii}(dd))';
            tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
            day_lists{ii} = [day_lists{ii} tmp2];
        end
    end
    
    day_lists_all{ee} = day_lists;
    
end

camera_lists_all = { {1, 1} };

% Choose whether to maintain the same size of 1st set for all sets

same_size = false;
%same_size = true;
%same_size = true;

if same_size == true
    %question_dir = 'frameORtransf';
    question_dir = 'frameORinst';
else
    question_dir = '';
end

%% Caffe parameters

% caffe dir
caffe_dir = '/usr/local/src/robot/caffe';
%caffe_dir = '/data/giulia/REPOS/caffe';
addpath(genpath(fullfile(caffe_dir, 'matlab')));

% use GPU or CPU
use_gpu = true;
gpu_id = 0;  % we will use the first gpu in this demo

% train or test caffe net
phase = 'train';

%% Choose caffe model

model = 'caffenet';
%model = 'googlenet';
%model = 'vgg16';

if strcmp(model, 'caffenet') && strcmp(mapping, 'none')
    
    model_dir = fullfile(caffe_dir, 'models/bvlc_reference_caffenet/');
    
    MEAN_W = 256;
    MEAN_H = 256;
    
    CROP_SIZE = 227;

    oversample = false;
    if oversample
        NCROPS=10;
    else
        NCROPS=1;
    end
    
    % remember that actual caffe batch size is max_bsize*NCROPS !!!!
    max_bsize = 512;
    
    % net definition
    caffepaths.net_model_template = fullfile(template_prototxt_path, model, 'train_val_template.prototxt');
    
    % solver definition
    caffepaths.solver_template = fullfile(template_prototxt_path, model, 'solver_template.prototxt');
    
    % net weights
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_reference_caffenet.caffemodel');
    
elseif strcmp(model, 'googlenet') && strcmp(mapping, 'none')
    
    model_dir = fullfile(caffe_dir, 'models/bvlc_googlenet/');
    
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
    
    % remember that actual caffe batch size is max_bsize*NCROPS !!!!
    max_bsize = 10;
    
    % net definition
    caffepaths.net_model = fullfile(model_dir, 'train_val.prototxt');
    
    % solver definition
    caffepaths.solver = fullfile(model_dir, 'solver.prototxt');
    
    % net weights
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_googlenet.caffemodel');

elseif strcmp(model, 'vgg16') && strcmp(mapping, 'none')
    
    model_dir = fullfile(caffe_dir, 'models/VGG/VGG_ILSVRC_16');
    
    CROP_SIZE = 224;
    
    % whether to consider multiple scales
    %SHORTER_SIDE = [256 288 320 352];
    SHORTER_SIDE = 256;
    
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
    
    % remember that actual caffe batch size is max_bsize*NCROPS !!!!
    max_bsize = 2;
    
    % net definition
    caffepaths.net_model = fullfile(model_dir, 'VGG_ILSVRC_16_layers_train_val.prototxt');
    
    % solver definition
    caffepaths.solver = fullfile(model_dir, 'solver.prototxt');
    
    % net weights
    caffepaths.net_weights = fullfile(model_dir, 'VGG_ILSVRC_16_layers.caffemodel');
    
end

%% Caffe inizialization

% Set caffe mode
if use_gpu
    caffe.set_mode_gpu();
    caffe.set_device(gpu_id);
else
    caffe.set_mode_cpu();
end

%% Input images

%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

%% Input registries

input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt_root);

%% Output models

exp_dir = fullfile([dset_dir '_experiments'], 'tuning');

output_dir_root = fullfile(exp_dir, 'models', model, experiment);
check_output_dir(output_dir_root);

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        for itransf=1:length(transf_lists_all)
            
            transf_lists = transf_lists_all{itransf};
            
            for iday=1:length(day_lists_all)
                
                day_lists = day_lists_all{iday};
                day_mappings = day_mappings_all{iday};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_lists = camera_lists_all{icam};
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    if strcmp(experiment, 'identification')
                        dir_regtxt_relative = fullfile(dir_regtxt_relative, strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-'));
                    end
                    
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir = fullfile(output_dir_root, dir_regtxt_relative);
                    check_output_dir(output_dir);
                    
                    %% Create set names
                    
                    for iset=1:Nsets
                        set_names{iset} = [set_names_prefix{iset} strrep(strrep(num2str(obj_lists{iset}), '   ', '-'), '  ', '-')];
                        set_names{iset} = [set_names{iset} '_tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-')];
                        set_names{iset} = [set_names{iset} '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                        set_names{iset} = [set_names{iset} '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-')];
                    end

                    for iset=1:Nsets
                        
                        %% Create train and val lmdb
                        
                        if use_imnetlabels
                            dbname = [set_names{iset} '_Yimnet_lmdb'];
                        else
                            dbname = [set_names{iset} '_Y_lmdb'];
                        end                        
                        filelist = fullfile(input_dir_regtxt, [dbname '.txt']);
                        
                        dbpath = fullfile(output_dir, dbname);

                        command = sprintf('%s --resize_width=%d --resize_height=%d --shuffle %s %s %s', create_lmdb_bin_path, MEAN_W, MEAN_H, dset_dir, filelist, dbpath);
                        [status, cmdout] = system(command);
                        if status~=0
                            error(cmdout);
                        end
                        
                        %% Compute mean image (binaryproto)
                        
                        meanpath = [dbname '_mean.binaryproto'];
                        
                        command = sprintf('%s --resize_width=%d --resize_height=%d --shuffle %s %s %s', compute_mean_bin_path, dbpath, meanpath);
                        [status, cmdout] = system(command);
                        if status~=0
                            error(cmdout);
                        end
  
                        %% Modify net definition with path to created lmdb + mean
                    
                        caffepaths.net_model = fullfile(output_dir, '');
                        net_params = create_struct_from_txt(caffepaths.net_model_default_values, ': ');
                        net_params. = a;
                        net_params. = b;
                        net_params. = c;
                        customize_prototxt(caffepaths.net_model_template, net_params, caffepaths.net_model);
                        
                        caffepaths.net_weights = fullfile(output_dir, '');
                        solver_params = create_struct_from_txt(caffepaths.solver_default_values, ': ');
                        solver_params. = a;
                        solver_params. = b;
                        solver_params. = c;
                        customize_prototxt(caffepaths.solver_template, solver_params, caffepaths.solver);
                        
                    
                        %% Train
                    
                        % Init net
                    
                        net = caffe.Net(caffepaths.net_model, caffepaths.net_weights, phase);
                    
                    % Set batch size
                    
                    inputshape = net.blobs('data').shape();
                    bsize_net = inputshape(4);
                    if max_bsize*NCROPS ~= bsize_net
                        net.blobs('data').reshape([CROP_SIZE CROP_SIZE 3 max_bsize*NCROPS])
                        net.reshape() % optional: the net reshapes automatically before a call to forward()
                    end
                    
                    
                    %% Choose epoch
                    
                    %% Save chosen model
                    
                    %% Delete train and val lmdb
                    
                    
                    % Initialize a network



                    
                    
                    
                    
                   
                        
                       
                        
                        %% Extract scores (+ features) and compute predictions
                        
                        Ypred = cell(Ncat,1);
                        NframesPerCat = cell(Ncat, 1);
                        
                        for cc=cat_idx
                            
                            NframesPerCat{opts.Cat(cat_names{cc})} = length(REG{opts.Cat(cat_names{cc})});
                            Ypred{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, 1);
                            
                            bsize = min(max_bsize, NframesPerCat{opts.Cat(cat_names{cc})});
                            Nbatches = ceil(NframesPerCat{opts.Cat(cat_names{cc})}/bsize);
                            
                            for bidx=1:Nbatches
                                
                                %tic
                                
                                bstart = (bidx-1)*bsize+1;
                                bend = min(bidx*bsize, NframesPerCat{opts.Cat(cat_names{cc})});
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
                                    im = imread(fullfile(dset_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{bstart+imidx-1}(1:(end-4)) '.jpg']));
                                    
                                    if strcmp(model, 'caffenet') && strcmp(mapping, 'none')
                                        input_data(:,:,:,((imidx-1)*NCROPS+1):(imidx*NCROPS)) = prepare_image_caffenet(im, mean_data, oversample);
                                    elseif ( strcmp(model, 'googlenet') || strcmp(model, 'vgg16') ) && strcmp(mapping, 'none')
                                        input_data(:,:,:,((imidx-1)*NCROPS+1):(imidx*NCROPS)) = prepare_image_multiscalecrop(im, mean_data, CROP_SIZE, SHORTER_SIDE, GRID);
                                    end
                                    
                                end
                                
                                % extract scores in batches
                                scores = net.forward({input_data});
                                scores = scores{1};
                                % eventually select scores
                                if strcmp(mapping, 'select')
                                    scores = scores(sel_idxs, :);
                                end
                                
                                % extract features in batches
                                if extract_features
                                    feat = cell(nFeat,1);
                                    for ff=1:nFeat
                                        feat{ff} = net.blobs(feat_names{ff}).get_data();
                                    end
                                end
                                
                                % reshape, dividing features and scores per image
                                scores = reshape(scores, [], NCROPS, bsize_curr);
                                if extract_features
                                    for ff=1:nFeat
                                        feat{ff} = reshape(feat{ff}, [], NCROPS, bsize_curr);
                                    end
                                end
                                
                                % take average scores over crops
                                scores = squeeze(mean(scores, 2));
                                
                                % compute max score per image
                                [~, maxlabel] = max(scores);
                                maxlabel = maxlabel - 1;
                                
                                % save extracted features
                                if extract_features
                                    for imidx=1:bsize_curr
                                        for ff=1:nFeat
                                            fc = squeeze(feat{ff}(:,:,imidx));
                                            outpath = fullfile(output_dir_root_fc, feat_names{ff}, cat_names{cc}, fileparts(REG{opts.Cat(cat_names{cc})}{bstart+imidx-1}));
                                            check_output_dir(outpath);
                                            save(fullfile(output_dir_root_fc, feat_names{ff}, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{bstart+imidx-1}(1:(end-4)) '.mat']), 'fc');
                                        end
                                    end
                                end
                                
                                % store all predictions in Y
                                Ypred{opts.Cat(cat_names{cc})}(bstart:bend) = maxlabel;
                                
                                %toc
                                fprintf('%s: batch %d out of %d \n', cat_names{cc}, bidx, Nbatches);
                            end
                            
                        end
                        
                        % compute accuracy
                        [acc, C] = trace_confusion(cell2mat(Y), cell2mat(Ypred));
                        
                        if strcmp(mapping, 'tuned')                         
                            save(fullfile(output_dir, ['Y_' mapping '_' set_names_prefix{iset} cell2mat(strcat('_', set_names(:))') '.mat'] ), 'Ypred', 'acc', 'C', '-v7.3');
                        elseif strcmp(mapping, 'none') || strcmp(mapping, 'select')
                            save(fullfile(output_dir, ['Y_' mapping '_' set_names{iset}((length(set_names_prefix{iset})+1):end) '.mat'] ), 'Ypred', 'acc', 'C', '-v7.3');
                        end
                        
                    end
                
            end
        end
    end
end

% call caffe.reset_all() to reset caffe
caffe.reset_all();

