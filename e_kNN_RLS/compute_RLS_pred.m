function compute_RLS_pred(dset, question_dir, dset_dir, mapping, setlist, trainval_prefixes, trainval_sets, tr_set, val_set, eval_set, gurls_model, caffe_model, feature)

cat_idx_all = setlist.cat_idx_all;
obj_lists_all = setlist.obj_lists_all;
transf_lists_all = setlist.transf_lists_all;
day_mappings_all = setlist.day_mappings_all;
day_lists_all = setlist.day_lists_all;
camera_lists_all = setlist.camera_lists_all;

cat_names = dset.cat_names;

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
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir_y = fullfile(exp_dir, caffe_model, dir_regtxt_relative, trainval_dir, 'rls');
                    check_output_dir(output_dir_y);
                    
                    if isempty(mapping)
                        input_dir_fc = fullfile(exp_dir, caffe_model, 'scores', feature);                  
                    else
                        input_dir_fc = fullfile(output_dir_y, 'scores', feature);
                    end
                    check_input_dir(input_dir_fc);
                    
                    if strcmp(gurls_model, 'compute')
                        
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
                                %X(ff,:) = max(fcstruct.fc, [], 2);;
                                X(ff,:) = mean(fcstruct.fc, 2);
                            end
                            clear fcstruct REG
                            
                        end
                        
                        % train the model
                        % convert Y to 1-base indexing for GURLS!
                        model = gurls_train(X{tr_set}, Y{tr_set}+1, X{val_set}, Y{val_set}+1, ...
                            'kernelfun', 'linear', 'nlambda', 20);
                        
                        % save the model
                        save(fullfile(output_dir_y, ['gurls_model_' feature '.mat']), 'model', '-v7.3');
                        
                    elseif strcmp(gurls_model, 'load')
    
                        % load the model                           
                        modelstruct = load(fullfile(output_dir_y, ['gurls_model_' feature '.mat']));
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
                        save(fullfile(output_dir_y, ['Y_' set_name '_' feature '.mat']), 'Ypred', 'acc', 'acc_xclass', 'C', '-v7.3');
                    end
                    
                end
            end
        end
    end
end