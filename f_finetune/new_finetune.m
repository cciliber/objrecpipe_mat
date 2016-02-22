function network = new_finetune(setup_data, question, network, dset_dir, output_dir_root, Ntrials)


if strncmp(question.question_dir, 'cat', 3)
    exp_id = false;
elseif strncmp(question.question_dir, 'id', 2)
    exp_id = true;
else
    error('Unsupported exp_kind in the question config file!');
end

if exp_id
    if isfield(question.setlist, 'divide_trainval_perc')
        divide_trainval_perc = question.setlist.divide_trainval_perc;
    else
        divide_trainval_perc = false;
    end
end

set_prefixes = question.setlist.set_prefixes;
tr_set = find(~cellfun(@isempty, regexp(set_prefixes, 'train')));
val_set = find(~cellfun(@isempty, regexp(set_prefixes, 'val')));

if exp_id && divide_trainval_perc
    validation_split = question.setlist.validation_split; % 'step' 'block' 'random'
    validation_perc = int32(question.setlist.validation_perc*100);
end


cat_idx_all = question.setlist.cat_idx_all;
obj_lists_all = question.setlist.obj_lists_all;
transf_lists_all = question.setlist.transf_lists_all;
day_mappings_all = question.setlist.day_mappings_all;
day_lists_all = question.setlist.day_lists_all;
camera_lists_all = question.setlist.camera_lists_all;


MEAN_W = network.caffestuff.MEAN_W;
MEAN_H = network.caffestuff.MEAN_H;


%% Set up the IO root directories

% input registries
input_dir_regtxt_root = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_registries');
check_input_dir(input_dir_regtxt_root);

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        dir_regtxt_relative_cat = strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-');
        dir_regtxt_relative = fullfile(dir_regtxt_relative_cat, question.question_dir);
    
        num_output = length(cat_idx);
        
        if exp_id
            
            dir_regtxt_relative_obj = strrep(strrep(num2str(obj_lists{tr_set}), '   ', '-'), '  ', '-');
            dir_regtxt_relative = fullfile(dir_regtxt_relative, dir_regtxt_relative_obj);
             
            num_output = num_output*length(obj_lists{tr_set});
            
        end

        input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
        check_input_dir(input_dir_regtxt);
        
        for itransf=1:length(transf_lists_all)
            
            transf_lists = transf_lists_all{itransf};
            
            for iday=1:length(day_lists_all)
                    
                day_mappings = day_mappings_all{iday};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_lists = camera_lists_all{icam};
                    
                    %% Create the train val folder name 
                    
                    set_names = cell(2,1);
                    
                    if exp_id 
                        if divide_trainval_perc 
                            for iset=[tr_set val_set]
                                set_names{iset} = [set_prefixes{iset} ...
                                    'tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-') ...
                                    '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-') ...
                                    '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                            end
                            trainval_dir = [set_prefixes{tr_set}(1:end-1) set_names{val_set} '_' validation_split num2str(validation_perc)];
                        else
                            for iset=[tr_set val_set]
                                set_names{iset} = ['tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-') ...
                                    '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-') ...
                                    '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                            end
                            trainval_prefixes = set_prefixes([tr_set val_set]);
                            trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                            trainval_dir = trainval_dir(1:end-1);
                        end
                    else
                        for iset=[tr_set val_set]
                            set_names{iset} = [strrep(strrep(num2str(obj_lists{iset}), '   ', '-'), '  ', '-') ...
                                '_tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-') ...
                                '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-') ...
                                '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                        end
                        trainval_prefixes = set_prefixes([tr_set val_set]);
                        trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                        trainval_dir = trainval_dir(1:end-1);                      
                    end

                    %% Assign O directory 
                    output_dir = fullfile(output_dir_root, dir_regtxt_relative, trainval_dir, 'tuning', network.network_dir, 'model');
                    check_output_dir(output_dir);
                    
                    %% Create lmdbs
                    
                    dbname = cell(2,1);
                    dbpath = cell(2,1);
                    Nsamples = zeros(2, 1);
                    for iset=[tr_set val_set]
                        
                        % create lmdb         
                        filelist = fullfile(input_dir_regtxt, [set_names{iset} '_Y.txt']);
                        
                        dbname{iset} = [set_prefixes{iset} 'Y_lmdb'];   
                        dbpath{iset} = fullfile(output_dir, dbname{iset});

                        if exist(dbpath{iset}, 'dir')
                            warning('Going to remove and recreate the db: %s', dbpath{iset});
                            rmdir(dbpath{iset}, 's');
                        end
                        command = sprintf('%s --resize_width=%d --resize_height=%d --shuffle %s %s %s', setup_data.create_lmdb_bin_path, ...
                            MEAN_W, MEAN_H, [dset_dir '/'], filelist, dbpath{iset});
                        [status, cmdout] = system(command);
                        if status~=0
                           error(cmdout);
                        end
                        
                        % get number of samples
                        Nsamples(iset) = get_linecount(filelist); 
                        
                    end
                    
                    %% Compute train mean image (binaryproto)

                    mean_name = [set_prefixes{tr_set} 'mean.binaryproto'];                   
                    mean_path = fullfile(output_dir, mean_name);
                        
                    command = sprintf('%s %s %s', setup_data.compute_mean_bin_path, dbpath{tr_set}, mean_path);
                    [status, cmdout] = system(command);
                    if status~=0
                      error(cmdout);
                    end
 
                    %% Modify net definition
                    
                    net_model_name = 'train_val.prototxt';
                    deploy_model_name = 'deploy.prototxt';
                    network.caffestuff.net_model = fullfile(output_dir, net_model_name);
                    network.caffestuff.deploy_model = fullfile(output_dir, deploy_model_name);
                    
                    network.trainval_params.fc8_num_output = num_output;
                    network.deploy_params.fc8_num_output = num_output;
                    
                    network.trainval_params.train_mean_file = mean_name;
                    network.trainval_params.train_source = dbname{tr_set};
                    network.trainval_params.val_source = dbname{val_set};
                    network.trainval_params.val_mean_file = mean_name;
                      
                    network.trainval_params.train_batch_size = min(network.trainval_params.train_batch_size, Nsamples(tr_set)); % check train batch size 
                    network.trainval_params.val_batch_size = min(network.trainval_params.val_batch_size, Nsamples(val_set)); % check test batch size
    
                    customize_prototxt(network.caffestuff.net_model_template, struct2cell(network.trainval_params), network.caffestuff.net_model);   
                    customize_prototxt(network.caffestuff.deploy_model_template, struct2cell(network.deploy_params), network.caffestuff.deploy_model);
                    
                    %% Modify solver definition 
                    
                    network.caffestuff.solver = fullfile(output_dir, 'solver.prototxt');
                    
                    network.solver_params.net = net_model_name;
                    network.solver_params.snapshot_prefix = 'snap';
                    
                    % num iters to perform one epoch
                    epoch_train = ceil(Nsamples(tr_set) / double(network.trainval_params.train_batch_size));
                    epoch_val = ceil(Nsamples(val_set) / double(network.trainval_params.val_batch_size));
                    
                    % in epochs
                    test_iter = 1;
                    test_interval = 1;
                    display = 1;
                    snapshot = 1;
                    
                    max_iter = 6;
                    stepsize = max_iter/3;
                    
                    network.solver_params.test_iter = test_iter*epoch_val;
                    network.solver_params.test_interval = test_interval*epoch_train;
                    network.solver_params.display = display*epoch_train;
                    
                    network.solver_params.max_iter = max_iter*epoch_train;
                    network.solver_params.stepsize = stepsize*epoch_train;                 
                    network.solver_params.snapshot = snapshot*epoch_train;
                    
                    customize_prototxt(network.caffestuff.solver_template, struct2cell(network.solver_params), network.caffestuff.solver);
                        
                    %% Train
                    
                    % cd because the paths are relative to 'output_dir'
                    curr_dir = cd(output_dir);
                    
                    gpu_id = 0;
                   
                    divergence_count = 0;
                    
                    good_acc = zeros(Ntrials,1);
                    epoch_idx = zeros(Ntrials,1);
                    for idx_trial=1:Ntrials
                    
                        %% Train
                        command = sprintf('%s train -solver %s -weights %s -gpu %d --log_dir=%s', ...
                            setup_data.caffe_bin_path, network.caffestuff.solver, network.caffestuff.net_weights, gpu_id, output_dir);
                            [status, cmdout] = system(command);
                        if status~=0
                            error(cmdout);
                        end

                        %% Parse the logs
                        command = sprintf('%s %s %s %s', setup_data.parse_log_path, fullfile(output_dir, 'caffe.INFO'), ...
                            ['caffe_INFO_' num2str(idx_trial) '_train.txt'], ...
                            ['caffe_INFO_' num2str(idx_trial) '_test.txt']);
                        [status, cmdout] = system(command);
                        if status~=0
                        error(cmdout);
                        end
 
                        %% Maximize val accuracy
                        T = readtable(fullfile(output_dir, ['caffe_INFO_' num2str(idx_trial) '_test.txt']), 'Delimiter', ',');
                        val_acc = T.acc;
                        [good_acc(idx_trial), epoch_idx(idx_trial)] = max(val_acc);
                    
                        %% Plot
%                         Ttr = readtable(fullfile(output_dir, 'caffe.INFO.train.txt'), 'Delimiter', ',');
%                         figure;
%                         hold on;
%                         plot(Ttr.acc);
%                         plot(T.acc);
%                         plot(Ttr.loss);
%                         plot(T.loss);
%                         legend({'Acc tr','Acc va','Loss tr','Loss va'});
%                         title(network.network_dir);
%                         hold off;
%                         pause(0.001);
 
                        if epoch_idx(idx_trial) == 1
                            
                            %% Skip trial
                            warning('Your loss diverged.');
                            divergence_count = divergence_count+1;
                        else
                            
                            %% Find correspondent model and rename it
                            epoch = num2str(T.iter(epoch_idx(idx_trial)));
                            modelname = [network.solver_params.snapshot_prefix '_iter_' epoch '.caffemodel'];
                            solverstatename = [network.solver_params.snapshot_prefix '_iter_' epoch '.solverstate'];
                            movefile(modelname,['good_model_' num2str(idx_trial) '.caffemodel']);
                            movefile(solverstatename,['good_model_' num2str(idx_trial) '.solverstate']);
                        end
                    
                        %% Clear others
                        delete('snap_*.caffemodel');
                        delete('snap_*.solverstate');
                    
                    end
                    
                    %% Choose best model across trials and rename it
                    [~, trial_idx] = max(good_acc); 
                    movefile(['good_model_' num2str(trial_idx) '.caffemodel'], 'best_model.caffemodel');
                    movefile(['good_model_' num2str(trial_idx) '.solverstate'], 'best_model.solverstate');
                    
                    %% Clear others
                    delete('good_model_*.caffemodel');
                    delete('good_model_*.solverstate');
                    
                    %% Update network fields
                    network.caffestuff.net_weights = fullfile(output_dir, 'best_model.caffemodel');
                    % mean data: mat file already in W x H x C with BGR channels
                    caffestuff.mean_path = fullfile(output_dir, 'train_mean.binaryproto');
                    caffestuff.mean_data = caffe.io.read_mean(caffestuff.mean_path);
                    caffestuff.MEAN_W = size(caffestuff.mean_data,1);
                    caffestuff.mean_H = size(caffestuff.mean_data, 2);
                    
                    %% Delete train/val lmdbs (but leave the mean)
                    rmdir(dbpath{tr_set}, 's');
                    rmdir(dbpath{val_set}, 's');

                    cd(curr_dir);
                        
                end
            end
        end
    end
end
