function extract_feat_and_pred_cat(DATA_DIR, dset, question_dir, dset_name, mapping, setlist, trainval_prefixes, trainval_sets, eval_set, caffestuff, extract_features)

cat_idx_all = setlist.cat_idx_all;
obj_lists_all = setlist.obj_lists_all;
transf_lists_all = setlist.transf_lists_all;
day_mappings_all = setlist.day_mappings_all;
day_lists_all = setlist.day_lists_all;
camera_lists_all = setlist.camera_lists_all;

%% Setup the IO root directories

% input registries
input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% output root
dset_dir = fullfile(DATA_DIR, dset_name);
exp_dir = fullfile(DATA_DIR, [dset_name '_experiments'], 'categorization');
check_output_dir(exp_dir);

%% Caffe init
caffe.set_mode_gpu();
gpu_id = 0;
caffe.set_device(gpu_id);

%% Caffe preprocesing initialization

prep = caffestuff.preprocessing;
NCROPS_grid = (prep.GRID*prep.GRID+even(prep.GRID)+prep.GRID.resize)*(prep.GRID.mirror+1);

if ~isempty(prep.OUTER_GRID)
    NCROPS_scale = NCROPS_grid*prep.OUTER_GRID; 
else
    NCROPS_scale = NCROPS_grid;
end

NCROPS = NCROPS_scale*NSCALES; 

if ~isfield(caffestuff.preprocessing, 'SCALING') 
    centralscale = 1;
elseif size(caffestuff.preprocessing.SCALING,1)==1
    centralscale = 1;
else
    centralscale = prep.SCALING.centralscale;
end

central_score_idx = (centralscale-1)*NCROPS_scale;

if ~isempty(prep.OUTER_GRID)
    central_score_idx = central_score_idx + NCROPS_grid*(prep.OUTER_GRID-1)/2;
end

if odd(prep.GRID)
    central_score_idx = central_score_idx + ceil(prep.GRID*prep.GRID/2);
else
    central_score_idx = central_score_idx + prep.GRID*prep.GRID+1;
end

max_bsize = round(500/NCROPS);

if isempty(mapping)
    
    %% Setup caffe model
    caffe_model_name = caffestuff.net_name;
    caffestuff = setup_caffemodel(caffe_dir, caffestuff, mapping);
    net = caffe.Net(caffestuff.net_model, caffestuff.net_weights, 'test');
    % reshape according to batch size
    inputshape = net.blobs('data').shape();
    CROP_SIZE = inputshape(1);
    bsize_net = inputshape(4);
    if max_bsize*NCROPS ~= bsize_net
        net.blobs('data').reshape([CROP_SIZE CROP_SIZE 3 max_bsize*NCROPS])
        net.reshape() % optional: the net reshapes automatically before a call to forward()
    end   
    % features to extract
    if any(~ismember(blob_names, caffestuff.feat_names))
        error('Blob not present!');
    end
    feat_names = caffestuff.feat_names;
    nFeat = length(feat_names);

end

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_list = obj_lists_all{iobj}{eval_set};
        
        for itransf=1:length(transf_lists_all)
            
            transf_list = transf_lists_all{itransf}{eval_set};
            
            for iday=1:length(day_lists_all)
                
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
                        set_names = cell(length(trainval_sets),1);
                        for iset=trainval_sets
                            set_names{iset} = [strrep(strrep(num2str(obj_lists_all{iobj}{iset}), '   ', '-'), '  ', '-') ...
                            '_tr_' strrep(strrep(num2str(transf_lists_all{itransf}{iset}), '   ', '-'), '  ', '-') ...
                            '_day_' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', '-'), '  ', '-') ...
                            '_cam_' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', '-'), '  ', '-')];
                        end
                        trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                        trainval_dir = trainval_dir(1:end-1);
                        
                        %% Setup caffe model
                        caffe_model_name = caffestuff.net_name;  
                        caffestuff = setup_caffemodel(trainval_dir, caffestuff, mapping);
                        net = caffe.Net(caffestuff.net_model, caffestuff.net_weights, 'test');
                        % reshape according to batch size
                        inputshape = net.blobs('data').shape();
                        CROP_SIZE = inputshape(1);
                        bsize_net = inputshape(4);
                        if max_bsize*NCROPS ~= bsize_net
                            net.blobs('data').reshape([CROP_SIZE CROP_SIZE 3 max_bsize*NCROPS])
                            net.reshape() % optional: the net reshapes automatically before a call to forward()
                        end   
                        % features to extract
                        if any(~ismember(blob_names, caffestuff.feat_names))
                            error('Blob not present!');
                        end
                        feat_names = caffestuff.feat_names;
                        nFeat = length(feat_names);
                        
                    else
                        
                        trainval_dir = '';
                        
                    end
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir_y = fullfile(exp_dir, caffe_model_name, dir_regtxt_relative, trainval_dir, mapping);
                    check_output_dir(output_dir_y);

                    if isempty(mapping)
                        output_dir_fc = fullfile(exp_dir, caffe_model_name, 'scores');                  
                    else
                        output_dir_fc = fullfile(output_dir_y, 'scores');
                    end
                    check_output_dir(output_dir_fc);
                    
                    %% Eventually set scores to be selected
                    if isempty(mapping)
                        sel_idxs = cell2mat(values(dset.Cat_ImnetLabels));
                        sel_idxs = sel_idxs(cat_idx)+1;
                        % check against number of output units
                        score_length = net.blobs('prob').shape();
                        score_length = score_length(1);
                        if sum(sel_idxs>score_length)
                            error('You are selecting scores out of net range!');
                        end
                    end
                    
                    %% Load the registry and Y (true labels)
                    fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                    input_registry = textscan(fid, '%s %d'); 
                    fclose(fid);
                    Y = input_registry{2};
                    REG = input_registry{1};  
                    if isempty(mapping)
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
                    if NCROPS>1
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
                            
                            if isempty(mapping)  
                                input_data(:,:,:,((imidx-1)*NCROPS+1):(imidx*NCROPS)) = prepare_image_caffe(im, caffestuff.preprocessing, caffestuff.mean_data, caffestuff.CROP_SIZE);
                            else
                                error('Specify how to init model for tuned models...');
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
                        [~, maxlabel_avg] = max(avg_scores);
                        maxlabel_avg = maxlabel_avg - 1;
                        Ypred_avg(bstart:bend) = maxlabel_avg;
                        if isempty(mapping)
                            % select
                            avg_scores_sel = avg_scores(sel_idxs, :);
                            [~, maxlabel_avg_sel] = max(avg_scores_sel);
                            maxlabel_avg_sel = maxlabel_avg_sel - 1;
                            Ypred_avg_sel(bstart:bend) = maxlabel_avg_sel;
                        end
                        
                        if NCROPS>1
                            % take central score over crops
                            central_scores = squeeze(scores(:,central_score_idx,:));  
                            [~, maxlabel_central] = max(central_scores);
                            maxlabel_central = maxlabel_central - 1;
                            Ypred_central(bstart:bend) = maxlabel_central;
                            if isempty(mapping)
                                % select
                                central_scores_sel = central_scores(sel_idxs, :);
                                [~, maxlabel_central_sel] = max(central_scores_sel);
                                maxlabel_central_sel = maxlabel_central_sel - 1;
                                Ypred_central_sel(bstart:bend) = maxlabel_central_sel;
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

                        fprintf('batch %d out of %d \n', bidx, Nbatches);
                    end

                    % compute accuracy and save everything             
                    if isempty(mapping)
                        [acc, acc_xclass, C] = trace_confusion(Yimnet+1, Ypred_avg+1, score_length);
                    else
                        [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_avg+1, score_length);
                    end   
                    %save(fullfile(output_dir_y, ['Yavg_' set_name '.mat'] ), 'Ypred_avg', 'acc', 'acc_xclass', 'C', '-v7.3');
                    
                    if isempty(mapping)
                        [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_avg_sel+1, length(cat_idx));
                        %save(fullfile(output_dir_y, ['Yavg_sel_' set_name '.mat'] ), 'Ypred_avg_sel', 'acc', 'acc_xclass', 'C', '-v7.3');  
                    end
                    
                    if NCROPS>1
                        if isempty(mapping)
                            [acc, acc_xclass, C] = trace_confusion(Yimnet+1, Ypred_central+1, score_length);
                        else
                            [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_central+1, score_length);
                        end
                        %save(fullfile(output_dir_y, ['Ycentral_' set_name '.mat'] ), 'Ypred_central', 'acc', 'acc_xclass', 'C', '-v7.3');
                        
                        if isempty(mapping)
                            [acc, acc_xclass, C] = trace_confusion(Y+1, Ypred_central_sel+1, length(cat_idx));
                            %save(fullfile(output_dir_y, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred_central_sel', 'acc', 'acc_xclass', 'C', '-v7.3');
                        end
                    end                       

                end
            end
        end
    end
end

caffe.reset_all();