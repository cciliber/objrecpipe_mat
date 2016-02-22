function RES = new_analyze_predictions(setup_data, experiment, results)

%% Determine if it's categorization or identification

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
eval_sets = find(cellfun(@isempty, set_prefixes));

if exp_id && divide_trainval_perc
    validation_split = question.setlist.validation_split; % 'step' 'block' 'random'
    validation_perc = int32(question.setlist.validation_perc*100);
end


%% Load linked information

% abut the subset of the dset considered (question)
question = load(experiment.question_struct_path);
question = question.question;

cat_idx_all = question.setlist.cat_idx_all;
obj_lists_all = question.setlist.obj_lists_all;
transf_lists_all = question.setlist.transf_lists_all;
day_mappings_all = question.setlist.day_mappings_all;
day_lists_all = question.setlist.day_lists_all;
camera_lists_all = question.setlist.camera_lists_all;

if ~exp_id
    if isfield(question.setlist, 'create_imnetlabels')
        create_imnetlabels = question.setlist.create_imnetlabels;
    else
        create_imnetlabels = false;
    end
end

% about the network tested (network)
network = load(experiment.network_struct_path);
network = network.network;

% about the analysis
acc_dimensions = results.acc_dimensions;


%% Setup the I directories

% input registries
input_dir_regtxt_root = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_registries');
check_input_dir(input_dir_regtxt_root);

% root location of the predictions (and of the output)
input_dir_root = experiment.output_dir_root;


%% Allocate memory to contain resuls for all the trained models in setlist
RES = struct([]);

%% For each experiment, go!

for eval_set=eval_sets
    
    
    for icat=1:length(cat_idx_all)
        
        cat_idx = cat_idx_all{icat};
        
        cells_sel{1} = cell2mat(values(setup_data.dset.Cat, setup_data.dset.cat_names(cat_idx)));
        
        for iobj=1:length(obj_lists_all)
            
            obj_list = obj_lists_all{iobj}{eval_set};
            if isempty(obj_list)
                obj_list = obj_lists_all{1}{eval_set};
            end
            
            cells_sel{2} = obj_list;
            
            %% Assign the IO directories
            
            dir_regtxt_relative_cat = strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-');
            dir_regtxt_relative = fullfile(dir_regtxt_relative_cat, question.question_dir);
            if exp_id
                dir_regtxt_relative_obj = strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-');
                dir_regtxt_relative = fullfile(dir_regtxt_relative, dir_regtxt_relative_obj);
            end
            input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
            check_input_dir(input_dir_regtxt);
            
            for itransf=1:length(transf_lists_all)
                
                transf_list = transf_lists_all{itransf}{eval_set};
                if isempty(transf_list)
                    transf_list = transf_lists_all{1}{eval_set};
                end
                
                cells_sel{3} = cell2mat(values(setup_data.dset.Transfs, setup_data.dset.transf_names(transf_list)));
                
                for iday=1:length(day_lists_all)
                    
                    day_mapping = day_mappings_all{iday}{eval_set};
                    if isempty(day_mapping)
                        day_mapping = day_mappings_all{1}{eval_set};
                    end
                    
                    cells_sel{4} = day_mapping;
                    
                    for icam=1:length(camera_lists_all)
                        
                        camera_list = camera_lists_all{icam}{eval_set};
                        if isempty(camera_list)
                            camera_list = camera_lists_all{1}{eval_set};
                        end
                        
                        cells_sel{5} = cell2mat(values(setup_data.dset.Cameras, setup_data.dset.camera_names(camera_list)));
                        
                        %% Create the test set name
                        set_name = ['_tr_' strrep(strrep(num2str(transf_list), '   ', '-'), '  ', '-') ...
                            '_day_' strrep(strrep(num2str(day_mapping), '   ', '-'), '  ', '-') ...
                            '_cam_' strrep(strrep(num2str(camera_list), '   ', '-'), '  ', '-')];
                        if ~obj_id
                            set_name = [strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-') set_name];
                        end
                        
                        if ~exp_id && isempty(network.network_dir)
                            
                             trainval_dir = '';
                             
                        else
                                                      
                            %% Create the trainval folder name
                            
                            set_names = cell(2,1);
                            
                            if exp_id
                                if divide_trainval_perc
                                    for iset=[tr_set val_set]
                                        set_names{iset} = [set_prefixes{iset} ...
                                            'tr_' strrep(strrep(num2str(transf_lists_all{itransf}{iset}), '   ', '-'), '  ', '-') ...
                                            '_day_' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', '-'), '  ', '-') ...
                                            '_cam_' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', '-'), '  ', '-')];
                                    end
                                    trainval_dir = [set_prefixes{tr_set}(1:end-1) set_names{val_set} '_' validation_split num2str(validation_perc)];
                                else
                                    for iset=[tr_set val_set]
                                        set_names{iset} = ['tr_' strrep(strrep(num2str(transf_lists_all{itransf}{iset}), '   ', '-'), '  ', '-') ...
                                            '_day_' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', '-'), '  ', '-') ...
                                            '_cam_' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', '-'), '  ', '-')];
                                    end
                                    trainval_prefixes = set_prefixes([tr_set val_set]);
                                    trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                                    trainval_dir = trainval_dir(1:end-1);
                                end
                            else
                                for iset=[tr_set val_set]
                                    set_names{iset} = [strrep(strrep(num2str(obj_lists_all{iobj}{iset}), '   ', '-'), '  ', '-') ...
                                        '_tr_' strrep(strrep(num2str(transf_lists_all{itransf}{iset}), '   ', '-'), '  ', '-') ...
                                        '_day_' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', '-'), '  ', '-') ...
                                        '_cam_' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', '-'), '  ', '-')];
                                end
                                trainval_prefixes = set_prefixes([tr_set val_set]);
                                trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                                trainval_dir = trainval_dir(1:end-1);
                            end
                            
                        end
                        
                        %% Assign IO directories
                       
                        if ~isempty(network.network_dir)
                            input_dir = fullfile(input_dir_root, dir_regtxt_relative, trainval_dir, 'tuning', network.network_dir);
                        else
                            input_dir = fullfile(input_dir_root, dir_regtxt_relative);
                        end
                        check_input_dir(input_dir);
                        
                        %% Load the registry and Y (true labels)
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                        input_registry = textscan(fid, '%s %d');
                        fclose(fid);
                        Y = input_registry{2};
                        REG = input_registry{1};
                        if ~exp_id && isempty(network.network_dir) && create_imnetlabels
                            fid = fopen(fullfile(input_dir_regtxt, [set_name '_Yimnet.txt']));
                            input_registry = textscan(fid, '%s %d');
                            fclose(fid);
                            Yimnet = input_registry{2};
                        end
                        clear input_registry;
                        
                        %% Load the predictions Ypred
                        
                        Y_avg_struct = load(fullfile(input_dir, ['Yavg_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        if ~exp_id && isempty(network.network_dir)
                            Y_avg_sel_struct = load(fullfile(input_dir, ['Yavg_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        end
                        
                        if experiment.prep.NCROPS>1
                            Y_central_struct = load(fullfile(input_dir, ['Ycentral_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                            if ~exp_id && isempty(network.network_dir)
                                Y_central_sel_struct = load(fullfile(input_dir, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                            end
                        end
                        
                        %% Organize Y and Ypred in cell arrays and compute accuracies
                        
                        if ~exp_id && isempty(network.network_dir)
                            if create_imnetlabels
                                Y_avg_struct.Y = Yimnet;
                            else
                            	warning('mapping is empty but Yimnet not found: skipping accuracy for Ypred_avg...');
                            end
                        else
                            Y_avg_struct.Y = Y;
                        end
                        Y_avg_struct = putYinCell(setup_data.dset, REG, Y_avg_struct);
                        nclasses = size(Y_avg_struct.C,2);
                        [Y_avg_struct.acc_new, Y_avg_struct.acc_xclass_new, Y_avg_struct.C_new] = ...
                            computeAcc(Y_avg_struct.Y, Y_avg_struct.Ypred, nclasses, cells_sel, acc_dimensions);
                        % Store
                        RES(icat, iobj, itransf, iday, icam).Y_avg_struct = Y_avg_struct;
                        
                        if ~exp_id && isempty(network.network_dir)
                            Y_avg_sel_struct.Y = Y;
                            Y_avg_sel_struct = putYinCell(setup_data.dset, REG, Y_avg_sel_struct);
                            nclasses = size(Y_avg_sel_struct.C,2);
                            
                            [Y_avg_sel_struct.acc_new, Y_avg_sel_struct.acc_xclass_new, Y_avg_sel_struct.C_new] = ...
                                computeAcc(Y_avg_sel_struct.Y, Y_avg_sel_struct.Ypred, nclasses, cells_sel, acc_dimensions);
                            % Store
                            RES(icat, iobj, itransf, iday, icam).Y_avg_sel_struct = Y_avg_sel_struct;
                        end
                        
                        if experiment.prep.NCROPS>1
                            
                            if ~exp_id && isempty(network.network_dir)
                                if create_imnetlabels
                                    Y_central_struct.Y = Yimnet;
                                else
                                    warning('... and for Ypred_central...');
                                end
                            else
                                Y_central_struct.Y = Y;
                            end
                            Y_central_struct = putYinCell(setup_data.dset, REG, Y_central_struct);
                            nclasses = size(Y_central_struct.C,2);
                            [Y_central_struct.acc_new, Y_central_struct.acc_xclass_new, Y_central_struct.C_new] = ...
                                computeAcc(Y_central_struct.Y, Y_central_struct.Ypred, nclasses, cells_sel, acc_dimensions);
                            % Store
                            RES(icat, iobj, itransf, iday, icam).Y_central_struct = Y_central_struct;
                            if ~exp_id && isempty(network.network_dir)
                                Y_central_sel_struct.Y = Y;
                                Y_central_sel_struct = putYinCell(setup_data.dset, REG, Y_central_sel_struct);
                                nclasses = size(Y_central_sel_struct.C,2);
                                [Y_central_sel_struct.acc_new, Y_central_sel_struct.acc_xclass_new, Y_central_sel_struct.C_new] = ...
                                    computeAcc(Y_central_sel_struct.Y, Y_central_sel_struct.Ypred, nclasses, cells_sel, acc_dimensions);
                                % Store
                                RES(icat, iobj, itransf, iday, icam).Y_central_sel_struct = Y_central_sel_struct;
                            end
                            
                        end
                        
                    end
                end
            end
        end
    end
    
end

end
