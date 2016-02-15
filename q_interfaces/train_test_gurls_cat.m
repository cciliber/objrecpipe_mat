function new_finetune_gurls_cat(setup_data,question,gurls_model,network,dset_dir)



cat_idx_all = question.setlist.cat_idx_all;
obj_lists_all = question.setlist.obj_lists_all;
transf_lists_all = question.setlist.transf_lists_all;
day_mappings_all = question.setlist.day_mappings_all;
day_lists_all = question.setlist.day_lists_all;
camera_lists_all = question.setlist.camera_lists_all;

cat_names = setup_data.dset.cat_names;



% temporary ?
min_eval_set = min(3,numel(question.setlist.obj_lists_all{1}));
eval_set = min_eval_set:numel(question.setlist.obj_lists_all{1});


if min_eval_set > 2
    trainval_prefixes = {'train_', 'val_'};
    trainval_sets = [1 2];
    tr_set = trainval_sets(1);
    val_set = trainval_sets(2);
end


caffe_model_name = network.caffestuff.net_name;




%% Caffe init
caffe.set_mode_gpu();
gpu_id = 0;
caffe.set_device(gpu_id);


% check that this machine is using the correct features




%% Setup the IO root directories

% input registries
input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% IO root
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
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question.question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir_y = fullfile(exp_dir, caffe_model_name, dir_regtxt_relative, trainval_dir, 'rls');
                    check_output_dir(output_dir_y);
                    
                    if isempty(network.mapping)
                       
                        network.caffestuff = network.setup_caffemodel(fullfile(exp_dir, caffe_model_name, dir_regtxt_relative, trainval_dir), network.caffestuff, network.mapping, network.network_dir);
                        net = caffe.Net(network.caffestuff.net_model, network.caffestuff.net_weights, 'test');
                        

                        input_selected_feature = gurls_model.selected_feature;
                        for idx_blob_name = 1:numel(net.blob_names)
                            if numel(findstr(gurls_model.selected_feature,net.blob_names{idx_blob_name}))>0 
                                input_selected_feature = net.blob_names{idx_blob_name};
                                name_found = true;
                                break;
                            end

                            if ~name_found
                               error(sprintf('Blob "%s" not present!',gurls_model.selected_feature));
                            end
                        end

                        
                        
                        input_dir_fc = fullfile(exp_dir, caffe_model_name, 'scores', input_selected_feature);                  
                    else
                       
                        net = caffe.Net(network.caffestuff.net_model, network.caffestuff.net_weights, 'test');

                        input_selected_feature = gurls_model.selected_feature;
                        for idx_blob_name = 1:numel(net.blob_names)
                            if numel(findstr(gurls_model.selected_feature,net.blob_names{idx_blob_name}))>0 
                                input_selected_feature = net.blob_names{idx_blob_name};
                                name_found = true;
                                break;
                            end

                            if ~name_found
                               error(sprintf('Blob "%s" not present!',gurls_model.selected_feature));
                            end
                        end
                        
                        input_dir_fc = fullfile(output_dir_y, 'scores', input_selected_feature);
                    end
                    check_input_dir(input_dir_fc);
                    
                    if strcmp(gurls_model.mode, 'compute')
                        
                        % load true Y and create X for train and val sets
                        
                        X = cell(length(trainval_sets),1);
                        Y = cell(length(trainval_sets),1);
                        first_loaded = false;
                        for iset=trainval_sets
                            
                            fid = fopen(fullfile(input_dir_regtxt, [set_names{iset} '_Y.txt']));
                            input_registry = textscan(fid, '%s %d');
                            fclose(fid);
                            Y{iset} = input_registry{2};
                            REG = input_registry{1};
                            clear input_registry;
                            
                            if ~first_loaded
                                fcstruct = load(fullfile(input_dir_fc, cat_names{cc}, [REG{1}(1:(end-4)) '.mat']));
                                feat_length = size(fcstruct.fc,1);
                                first_loaded = true;
                                clear fcstruct;
                            end
                            
                            X{iset} = zeros(length(REG),feat_length);
                            for ff=1:length(REG)
                                fcstruct = load(fullfile(input_dir_fc, cat_names{cc}, [REG{ff}(1:(end-4)) '.mat']));
                                %X(ff,:) = max(fcstruct.fc, [], 2);
                                X(ff,:) = mean(fcstruct.fc, 2);
                            end
                            clear fcstruct REG
                            
                        end
                        
                        % train the model
                        % convert Y to 1-base indexing for GURLS!
                        model = gurls_train(X{tr_set}, Y{tr_set}+1, 'Xval', X{val_set}, 'yval', Y{val_set}+1, gurls_model.gurls_options);
                        
                        % save the model
                        save(fullfile(output_dir_y, ['gurls_model_' gurls_model.selected_feature '.mat']), 'model', '-v7.3');
                        
                    elseif strcmp(gurls_model.model, 'load')
    
                        % load the model                           
                        modelstruct = load(fullfile(output_dir_y, ['gurls_model_' gurls_model.selected_feature '.mat']));
                        model = modelstruct.model;
                      
                    end

                    for iset=eval_set
                        
                        % load true Y and create X for test set
                        set_name = [strrep(strrep(num2str(obj_lists{iset}), '   ', '-'), '  ', '-') ...
                            '_tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-') ...
                            '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-') ...
                            '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                        
                        
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                        input_registry = textscan(fid, '%s %d');
                        fclose(fid);
                        Y = input_registry{2}; 
                        REG = input_registry{1};
                        clear input_registry;
                            
                        if ~first_loaded
                            fcstruct = load(fullfile(input_dir, cat_names{cc}, [REG{1}(1:(end-4)) '.mat']));
                            feat_length = size(fcstruct.fc,1);
                            first_loaded = true;
                            clear fcstruct;
                        end
                            
                        X = zeros(length(REG),feat_length);
                        for ff=1:length(REG)
                            fcstruct = load(fullfile(input_dir, cat_names{cc}, [REG{ff}(1:(end-4)) '.mat']));
                            %X(ff,:) = max(fcstruct.fc, [], 2);;
                            X(ff,:) = mean(fcstruct.fc, 2);
                        end
                        clear fcstruct REG
                        
                        % test the model 
                        Ypred = gurls_test(model,X);
                        [~, Ypred] = max(Ypred, [], 2);
                        % back to 0-base indexing
                        Ypred = Ypred-1;
                            
                        % compute accuracy
                        % again convert to 1-base indexing
                        [acc, acc_xclass, C] = trace_confusion(Y+1,Ypred+1, num_output);
                            
                        % store results 
                        save(fullfile(output_dir_y, ['Y_' set_name '_' gurls_model.selected_feature '.mat']), 'Ypred', 'acc', 'acc_xclass', 'C', '-v7.3');
                    end
                    
                end
            end
        end
    end
end


