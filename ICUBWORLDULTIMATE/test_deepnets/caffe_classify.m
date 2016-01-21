%% Caffe - classify

addpath(genpath( '/usr/local/src/robot/caffe/matlab' ));

%% Setup

%FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
%FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

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

set_names_prefix = {'test_'};
Nsets = length(set_names_prefix);
loaded_set = Nsets;

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Mapping (used only to name the resulting predictions)

if strcmp(experiment, 'categorization')
    %mapping = 'tuned';
    mapping = 'none';
    %mapping = 'select';
elseif strcmp(experiment, 'identification')
    mapping = 'tuned';
else
    mapping = [];
end

% Whether to use the imnet or the tuning labels

if strcmp(experiment, 'categorization') && strcmp(mapping, 'none')
    use_imnetlabels = true;
elseif strcmp(experiment, 'categorization') && (strcmp(mapping, 'tuned') || strcmp(mapping, 'select'))
    use_imnetlabels = false;
elseif strcmp(experiment, 'identification')
    use_imnetlabels = false;
else
    use_imnetlabels = [];
end

% Choose categories

cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    %obj_lists_all = { {1:7, 8:10} };
    %obj_lists_all = { {1:7, 8:10} };
    obj_lists_all = { {8:10} };
    
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
%transf_lists_all = { {5, 5} };
transf_lists_all = { {1:Ntransfs} };

day_mappings_all = { {1:2} };
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

camera_lists_all = { {1} };

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
phase = 'test'; % run with phase test (so that dropout isn't applied)
   
%% Choose caffe model

model = 'caffenet';

if strcmp(model, 'caffenet') && strcmp(mapping, 'none')
    
    % net weights
    model_dir = fullfile(caffe_dir, 'models/bvlc_reference_caffenet/');
    caffepaths.net_weights = fullfile(model_dir, 'bvlc_reference_caffenet.caffemodel');
   
    % mean_data: mat file already in W x H x C with BGR channels
    caffepaths.mean_path = fullfile(caffe_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
   
    CROP_SIZE = 227;
    MEAN_SIZE = 256;
    NCROPS = 10;
    
    % remember that actual caffe batch size is max_batch_size*NCROPS !!!!
    max_bsize = 50; 
    
    % net definition
    oversample = true;
    caffepaths.net_model = fullfile(model_dir, 'deploy.prototxt');
    
end

%% Caffe inizialization

% Set caffe mode
if use_gpu
    caffe.set_mode_gpu();
    caffe.set_device(gpu_id);
else
    caffe.set_mode_cpu();
end

% Initialize a network
net = caffe.Net(caffepaths.net_model, caffepaths.net_weights, phase);

inputshape = net.blobs('data').shape();
bsize_net = inputshape(4);
if max_bsize*NCROPS ~= bsize_net
    net.blobs('data').reshape([CROP_SIZE CROP_SIZE 3 max_bsize*NCROPS])
    net.reshape() % optional: the net reshapes automatically before a call to forward()
end
                            
% Load mean
d = load(caffepaths.mean_path);
mean_data = d.mean_data;

%% Input images

%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

%% Input registries

input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt_root);

%% Output predictions

exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');
%exp_dir = fullfile([dset_dir '_experiments'], 'tuning');

output_dir_root = fullfile(exp_dir, 'predictions', model, experiment);
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
                    
                    for ii=1:Nsets
                        set_names{ii} = [set_names_prefix{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
                    end
                    
                    %% Load Y (true labels)
                    
                    if use_imnetlabels
                        load(fullfile(input_dir_regtxt, ['Yimnet_' set_names{loaded_set} '.mat']));
                    else
                        load(fullfile(input_dir_regtxt, ['Y_' set_names{loaded_set} '.mat']));
                    end
                    
                    %% Eventually set scores to be selected 
                    
                    if strcmp(mapping, 'select')
                        
                        %sel_idxs = cell(Ncat, 1);
                        %sel_idxs(cell2mat(values(opts.Cat, cat_names(cat_idx)))) = values( opts.Cat_ImnetLabels, cat_names(cat_idx));
                        %sel_idxs = cell2mat(sel_idxs(~cellfun(@isempty, sel_idxs)));
                        
                        sel_idxs = cell2mat(values(opts.Cat_ImnetLabels));
                        sel_idxs = sel_idxs(cat_idx)+1;
                        
                        if sum(sel_idxs>1000)
                            error('You are selecting scores > 1000!');
                        end
                    end
                    
                    %% Load REG
                    
                    load(fullfile(input_dir_regtxt, ['REG_' set_names{loaded_set} '.mat']));
                    
                    %% Extract scores and compute predictions
                    
                    X = cell(Ncat, 1);
                    Ypred = cell(Ncat,1);
                    
                    NframesPerCat = cell(Ncat, 1);
                    
                    for cc=cat_idx
                        
                        NframesPerCat{opts.Cat(cat_names{cc})} = length(REG{opts.Cat(cat_names{cc})});
                        if (strcmp(mapping, 'select') || strcmp(mapping, 'tuned')) && strcmp(experiment, 'categorization')
                            score_length = length(cat_idx);
                        elseif strcmp(mapping, 'tuned') && strcmp(experiment, 'identification')
                            score_length = length(obj_lists{loaded_set});
                        elseif strcmp(mapping, 'none')
                            score_length = 1000;
                        end
                        
                        X{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, score_length);
                        Ypred{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, 1);
                        
                        bsize = min(max_bsize, NframesPerCat{opts.Cat(cat_names{cc})});
                        Nbatches = ceil(NframesPerCat{opts.Cat(cat_names{cc})}/bsize);
                        
                        for bidx=1:Nbatches
                            
                            tic 
                            
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
                                input_data(:,:,:,((imidx-1)*NCROPS+1):(imidx*NCROPS)) = prepare_image_caffenet(im, mean_data, oversample);
                            end
                            
                            % extract scores in batches
                            scores = net.forward({input_data});    
                            scores = scores{1};
                            
                            % reshape, dividing scores per image
                            scores = reshape(scores, score_length, NCROPS, bsize_curr);
                            
                            if strcmp(mapping, 'select')                                
                                scores = scores(sel_idxs, :, :);
                            end
                            
                            % take average scores over 10 crops
                            scores = squeeze(mean(scores, 2)); 
                            
                            % compute max score per image
                            [~, maxlabel] = max(scores);
                            maxlabel = maxlabel - 1;

                            Ypred{opts.Cat(cat_names{cc})}(bstart:bend) = maxlabel;
                            
                            toc
                            fprintf('%s: batch %d out of %d \n', cat_names{cc}, bidx, Nbatches);
                        end
                        
                    end
                    
                    % compute accuracy
                    acc = compute_accuracy(cell2mat(Y), cell2mat(Ypred), 'gurls');
                    
                    if strcmp(mapping, 'tuned')
                        save(fullfile(output_dir, ['Y_' mapping '_' set_names{1} '_' set_names{2} '.mat'] ), 'Ypred', 'acc', '-v7.3');
                    elseif strcmp(mapping, 'none') || strcmp(mapping, 'select')
                        save(fullfile(output_dir, ['Y_' mapping '_' set_names{loaded_set}((length(set_names_prefix{loaded_set})+1):end) '.mat'] ), 'Ypred', 'acc', '-v7.3');
                    end
                    
                    
                end
            end
        end
    end
end

% call caffe.reset_all() to reset caffe
caffe.reset_all();

