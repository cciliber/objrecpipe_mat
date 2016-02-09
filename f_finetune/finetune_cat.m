function finetune_cat(question_dir, dset_dir, setlist, trainval_prefixes, trainval_sets, tr_set, val_set, caffestuff, net_params, deploy_params, solver_params, ...
    caffe_bin_path, create_lmdb_bin_path, compute_mean_bin_path, parse_log_path)

cat_idx_all = setlist.cat_idx_all;
obj_lists_all = setlist.obj_lists_all;
transf_lists_all = setlist.transf_lists_all;
day_mappings_all = setlist.day_mappings_all;
day_lists_all = setlist.day_lists_all;
camera_lists_all = setlist.camera_lists_all;

%% Set up the IO root directories

% input registries
input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% output root
exp_dir = fullfile([dset_dir '_experiments'], 'categorization');
check_output_dir(exp_dir);
                
%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        for itransf=1:length(transf_lists_all)
            
            transf_lists = transf_lists_all{itransf};
            
            for iday=1:length(day_lists_all)
                    
                day_mappings = day_mappings_all{iday};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_lists = camera_lists_all{icam};
                    
                    %% Create the train val folder name 
                    set_names = cell(length(trainval_sets),1);
                    for iset=trainval_sets
                        set_names{iset} = [strrep(strrep(num2str(obj_lists{iset}), '   ', '-'), '  ', '-') ...
                        '_tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-') ...
                        '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-') ...
                        '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                    end
                    trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                    trainval_dir = trainval_dir(1:end-1);
                    
                    %% Number of classes
                    num_output = length(cat_idx);
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(num_output)], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir = fullfile(exp_dir, model, dir_regtxt_relative, trainval_dir, 'tuning', 'model');
                    check_output_dir(output_dir);
                    
                    %% Create lmdbs
                    
                    dbname = cell(length(trainval_sets),1);
                    dbpath = cell(length(trainval_sets),1);
                    Nsamples = zeros(length(trainval_sets), 1);
                    for iset=trainval_sets
                        
                        % create lmdb         
                        filelist = fullfile(input_dir_regtxt, [set_names{iset} '_Y.txt']);
                        
                        dbname{iset} = [trainval_prefixes{iset} '_Y_lmdb'];   
                        dbpath{iset} = fullfile(output_dir, dbname{iset});

                        command = sprintf('%s --resize_width=%d --resize_height=%d --shuffle %s %s %s', create_lmdb_bin_path, MEAN_W, MEAN_H, [dset_dir '/'], filelist, dbpath{iset});
                        [status, cmdout] = system(command);
                        if status~=0
                            error(cmdout);
                        end
                        
                        % get number of samples
                        Nsamples(iset) = get_linecount(filelist); 
                        
                    end
                    
                    %% Compute train mean image (binaryproto)

                    mean_name = [trainval_prefixes{tr_set} '_mean.binaryproto'];                   
                    mean_path = fullfile(output_dir, mean_name);
                        
                    command = sprintf('%s %s %s', compute_mean_bin_path, dbpath{tr_set}, mean_path);
                    [status, cmdout] = system(command);
                    if status~=0
                       error(cmdout);
                    end
 
                    %% Modify net definition
                    
                    net_model_name = 'train_val.prototxt';
                    deploy_model_name = 'deploy.prototxt';
                    caffestuff.net_model = fullfile(output_dir, net_model_name);
                    caffestuff.deploy_model = fullfile(output_dir, deploy_model_name);
                    
                    net_params.fc8_num_output = num_output;
                    deploy_params.fc8_num_output = num_output;
                    
                    net_params.train_mean_file = mean_name;
                    net_params.train_source = dbname{tr_set};
                    net_params.val_source = dbname{val_set};
                    net_params.val_mean_file = mean_name;
                      
                    net_params.train_batch_size = min(net_params.train_batch_size, Nsamples(tr_set)); % check train batch size 
                    net_params.val_batch_size = min(net_params.val_batch_size, Nsamples(val_set)); % check test batch size
    
                    customize_prototxt(caffestuff.net_model_template, struct2cell(net_params), caffestuff.net_model);   
                    customize_prototxt(caffestuff.deploy_model_template, struct2cell(deploy_params), caffestuff.deploy_model);
                    
                    %% Modify solver definition 
                    
                    caffestuff.solver = fullfile(output_dir, 'solver.prototxt');
                    
                    solver_params.net = net_model_name;
                    solver_params.snapshot_prefix = 'snap';
                    
                    % num iters to perform one epoch
                    epoch_train = ceil(Nsamples(tr_set) / double(net_params.train_batch_size));
                    epoch_val = ceil(Nsamples(val_set) / double(net_params.val_batch_size));
                    
                    % in epochs
                    test_iter = 1;
                    test_interval = 1;
                    display = 1;
                    snapshot = 1;
                    
                    max_iter = 6;
                    stepsize = max_iter/3;
                    
                    solver_params.test_iter = test_iter*epoch_val;
                    solver_params.test_interval = test_interval*epoch_train;
                    solver_params.display = display*epoch_train;
                    
                    solver_params.max_iter = max_iter*epoch_train;
                    solver_params.stepsize = stepsize*epoch_train;                 
                    solver_params.snapshot = snapshot*epoch_train;
                    
                    customize_prototxt(caffestuff.solver_template, struct2cell(solver_params), caffestuff.solver);
                        
                    %% Train
                    
                    % cd because the paths are relative to 'output_dir'
                    curr_dir = cd(output_dir);
                    
                    gpu_id = 0;
                    
                    if matlab_interface
                        % using Matlab interface
                        caffe.set_mode_gpu(); 
                        caffe.set_device(gpu_id);
                        solver = caffe.Solver(caffestuff.solver);
                        solver.net.copy_from(caffestuff.net_weights);
                        solver.solve();
                        caffe.reset_all(); % clear net and solver
                    else 
                        % or calling the command line interface
                        command = sprintf('%s train -solver %s -weights %s -gpu %d --log_dir=%s', ...
                            caffe_bin_path, caffestuff.solver, caffestuff.net_weights, gpu_id, output_dir);
                        [status, cmdout] = system(command);
                        if status~=0
                            error(cmdout);
                        end
                    end
                    
                    %% Choose epoch
                    
                    % parse the logs
                    command = sprintf('%s %s', parse_log_path, fullfile(output_dir, 'caffe.INFO'));
                    [status, cmdout] = system(command);
                    if status~=0
                       error(cmdout);
                    end
                    
                    cd(curr_dir);
                    
                    % maximize val accuracy
                    T = readtable(fullfile(output_dir, 'caffe.INFO.test.txt'), 'Delimiter', ',');
                    val_acc = T.acc;
                    [~, epoch_idx] = max(val_acc);
 
                    % find correspondent model
                    epoch = num2str(T.iter(epoch_idx));
                    modelname = [solver_params.snapshot_prefix '_iter_' epoch '.caffemodel'];
                    solverstatename = [solver_params.snapshot_prefix '_iter_' epoch '.solverstate'];

                    % rename it
                    movefile(modelname,'best_model.caffemodel');
                    movefile(solverstatename,'best_model.solverstate');
                    
                    % clear others
                    delete('snap_*.caffemodel');
                    delete('snap_*.solverstate');
                    
                    % delete train/val lmdbs (but leave the mean)
                    rmdir(dbpath{tr_set}, 's');
                    rmdir(dbpath{val_set}, 's');
                        
                end
            end
        end
    end
end
