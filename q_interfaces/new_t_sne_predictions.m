function [RES,feature_matrix,labels_matrix] = new_t_sne_predictions(setup_data, experiment, results)

%% Load linked information

if isfield(question.setlist,'cat_idx_all_trainval')
    cat_idx_all_trainval = question.setlist.cat_idx_all_trainval;
else
    cat_idx_all_trainval = question.setlist.cat_idx_all;
end


% about the network tested (network)
load(experiment.network_struct_path);

% abut the subset of the dset considered (question)
load(experiment.question_struct_path);

cat_idx_all = question.setlist.cat_idx_all;
obj_lists_all = question.setlist.obj_lists_all;
transf_lists_all = question.setlist.transf_lists_all;
day_mappings_all = question.setlist.day_mappings_all;
day_lists_all = question.setlist.day_lists_all;
camera_lists_all = question.setlist.camera_lists_all;


acc_dimensions = results.acc_dimensions;

% temporary ?
trainval_prefixes = {'train_','val_'};
trainval_sets = [1, 2];
eval_set = numel(question.setlist.obj_lists_all{1});

%% Setup the IO root directories

% input registries
input_dir_regtxt_root = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% root location of the predictions (and of the output)
[~,dset_name] = fileparts(experiment.dset_dir);
exp_dir = fullfile(setup_data.DATA_DIR, [dset_name '_experiments'], 'categorization');
check_input_dir(exp_dir);

%global_RES_dir = experiment.experiment_struct_path;
global_RES_dir = experiment.experiment_struct_path;
check_output_dir(global_RES_dir);
check_output_dir(fullfile(global_RES_dir, 'figs/fig'));
check_output_dir(fullfile(global_RES_dir, 'figs/png'));


%% Allocate memory to contain resuls for all the trained models in setlist
RES = struct([]);

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    cat_idx_trainval = cat_idx_all{icat};
    
    cells_sel{1} = cell2mat(values(setup_data.dset.Cat, setup_data.dset.cat_names(cat_idx)));
    
    for iobj=1:length(obj_lists_all)
        
        obj_list = obj_lists_all{iobj}{eval_set};
        if isempty(obj_list)
            obj_list = obj_lists_all{1}{eval_set};
        end
            
        cells_sel{2} = obj_list;
        
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
                    set_name = [strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-') ...
                        '_tr_' strrep(strrep(num2str(transf_list), '   ', '-'), '  ', '-') ...
                        '_day_' strrep(strrep(num2str(day_mapping), '   ', '-'), '  ', '-') ...
                        '_cam_' strrep(strrep(num2str(camera_list), '   ', '-'), '  ', '-')];
                    
                    if ~isempty(network.mapping)
                        
                        %% Create the train val folder name
                        set_names = cell(length(trainval_sets),1);
                        for iset=trainval_sets
                            
                            set_names{iset} = [strrep(strrep(num2str(obj_lists_all{iobj}{iset}), '   ', '-'), '  ', '-') ...
                                '_tr_' strrep(strrep(num2str(transf_lists_all{itransf}{iset}), '   ', '-'), '  ', '-') ...
                                '_day_' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', '-'), '  ', '-') ...
                                '_cam_' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', '-'), '  ', '-')];
                            
                            set_names_4figs{iset} = [trainval_prefixes{iset}(1:(end-1)) ': ' ...
                                strrep(strrep(num2str(obj_lists_all{iobj}{iset}), '   ', ', '), '  ', ', ')];
                            tmp = setup_data.dset.transf_names(transf_lists_all{itransf}{iset});
                            tmp = cell2mat(strcat(tmp(:), ' ')');
                            set_names_4figs{iset} = [set_names_4figs{iset} ...
                                ', tr ' tmp ...
                                ', day ' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', ', '), '  ', ', ') ...
                                ', cam ' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', ', '), '  ', ', ')];
                        end
                        trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                        trainval_dir = trainval_dir(1:end-1);
                        
                    else
                        trainval_dir = '';
                    end
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question.question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);

                    dir_regtxt_relative_trainval = fullfile(['Ncat_' num2str(length(cat_idx_trainval))], strrep(strrep(num2str(cat_idx_trainval), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative_trainval = fullfile(dir_regtxt_relative_trainval, question.question_dir);
                    
                    input_dir_regtxt_trainval = fullfile(input_dir_regtxt_root, dir_regtxt_relative_trainval);
                    check_input_dir(input_dir_regtxt_trainval);
                    
                    
                    % Assign the labels
                    fid_labels_trainval = fopen(fullfile(input_dir_regtxt_trainval, 'labels.txt'), 'r');
                    Y_digits_trainval = textscan(fid_labels_trainval,'%s %d');
                    Y_digits_trainval = Y_digits_trainval{1};
                    fclose(fid_labels_trainval);

                    % Assign the labels
                    fid_labels = fopen(fullfile(input_dir_regtxt, 'labels.txt'), 'r');
                    Y_digits = textscan(fid_labels,'%s %d');
                    Y_digits = Y_digits{1};
                    fclose(fid_labels);

                    % create mapping from Y_digits to Y_digits_trainval
                    Y_digits_mapping = zeros(numel(Y_digits),1);
                    last_idx = numel(Y_digits_trainval)+1;
                    for idx_y_digits = 1:numel(Y_digits)

                        for idx_y_digits_trainval = 1:numel(Y_digits_trainval)
                            if strcmp(Y_digits{idx_y_digits},Y_digits_trainval{idx_y_digits_trainval})
                                Y_digits_mapping(idx_y_digits) = idx_y_digits_trainval;
                                break;
                            end
                        end
                        
                        if Y_digits_mapping(idx_y_digits) == 0
                            Y_digits_mapping(idx_y_digits) = last_idx;
                            last_idx = last_idx + 1;
                        end
                    end

                    
                    
                    if isfield(network, 'network_dir')
                        input_dir = fullfile(exp_dir, network.caffestuff.net_name, dir_regtxt_relative, trainval_dir, network.mapping, network.network_dir);
                    else
                        input_dir = fullfile(exp_dir, network.caffestuff.net_name, dir_regtxt_relative, trainval_dir, network.mapping);
                    end
                    check_output_dir(input_dir);
                    
                    
                    
                    if isempty(network.mapping)
                        input_dir_fc = fullfile(exp_dir, network.caffestuff.net_name, 'scores');                  
                    else
                        input_dir_fc = fullfile(input_dir, 'scores');
                    end
                    
                    input_dir_list = dir(input_dir_fc);
                    found_dir = false;
                    for idx_list = 1:numel(input_dir_list)
                        if findstr(results.feat_name,input_dir_list(idx_list).name)>0
                            input_dir_fc = fullfile(input_dir_fc,input_dir_list(idx_list).name);
                            found_dir = true;
                            break;
                        end
                    end
                    
                    if ~found_dir
                        error('Feature directory "%s" not found!',results.feat_name);
                    end
                    
                    
                    %% Load the registry REG and the true labels Y
                    
                    fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                    input_registry = textscan(fid, '%s %d');
                    fclose(fid);
                    Y = input_registry{2};
                    
                    % map and eliminate unknonw classes
                    Y = Y_digits_mapping(Y + 1) - 1;
                    idx_to_keep = Y<=numel(Y_digits_trainval);                   
                    
                    
                    REG = input_registry{1};
                    if isempty(network.mapping)% && question.setlist.create_imnetlabels
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Yimnet.txt']));
                        input_registry = textscan(fid, '%s %d');
                        fclose(fid);
                        Yimnet = input_registry{2};
                    end
                    clear input_registry;
                    
                    %% Load the predictions Ypred
                    
                    Y_avg_struct = load(fullfile(input_dir, ['Yavg_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    if isempty(network.mapping)
                        Y_avg_sel_struct = load(fullfile(input_dir, ['Yavg_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    end
                    
                    if experiment.prep.NCROPS>1
                        Y_central_struct = load(fullfile(input_dir, ['Ycentral_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        if isempty(network.mapping)
                            Y_central_sel_struct = load(fullfile(input_dir, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        end
                    end
                    
                    
                    
                    %% Load Features!
                    
                    
                    
                    tmp_fc = load(fullfile(input_dir_fc,[REG{1}(1:(end-4)) '.mat']));
                    feature_matrix = zeros(numel(REG),size(tmp_fc.fc,1));
                    labels_matrix = zeros(numel(REG),4);
                    
                    dirlist = cellfun(@fileparts, REG, 'UniformOutput', false);
                    dirlist_splitted = regexp(dirlist, '/', 'split');
                    dirlist_splitted = vertcat(dirlist_splitted{:});
                    
                    for idx_REG = 1:numel(REG)
                    
                        tmp_fc = load(fullfile(input_dir_fc,[REG{idx_REG}(1:(end-4)) '.mat']));
%                         results.feature_matrix(idx_REG,:) = tmp_fc.fc(:,experiment.prep.central_score_idx)';
                        feature_matrix(idx_REG,:) = tmp_fc.fc(:,1)';
   
                        obj = str2double(dirlist_splitted{idx_REG,2}(regexp(dirlist_splitted{idx_REG,2}, '\d'):end));
                        labels_matrix(idx_REG,:) = [Y(idx_REG)+1, obj, setup_data.dset.Transfs(dirlist_splitted{idx_REG,3}), setup_data.dset.Days(dirlist_splitted{idx_REG,4})];
                        
                    end


                    
                    
                    
                    
                    
                    
                    Y_avg_struct = load(fullfile(input_dir, ['Yavg_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    if isempty(network.mapping)
                        Y_avg_sel_struct = load(fullfile(input_dir, ['Yavg_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    end
                    
                    if experiment.prep.NCROPS>1
                        Y_central_struct = load(fullfile(input_dir, ['Ycentral_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        if isempty(network.mapping)
                            Y_central_sel_struct = load(fullfile(input_dir, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        end
                    end
                    
                    
                    
                    
                    
                    
                    %% Organize Y and Ypred in cell arrays and compute accuracies
                    
                    if isempty(network.mapping)
%                         if question.setlist.create_imnetlabels
                            Y_avg_struct.Y = Yimnet;
%                         else
%                             warning('mapping is empty but Yimnet not found: skipping accuracy for Ypred_avg...');
%                         end
                    else
                        Y_avg_struct.Y = Y;
                    end
                    Y_avg_struct = putYinCell(setup_data.dset, REG, Y_avg_struct);
                    nclasses = numel(unique(Y_avg_struct.Y));%size(Y_avg_struct.C,2);
                    [Y_avg_struct.acc_new, Y_avg_struct.acc_xclass_new, Y_avg_struct.C_new] = ...
                        computeAcc(Y_avg_struct.Y(idx_to_keep,:), Y_avg_struct.Ypred(idx_to_keep,:), nclasses, cells_sel, acc_dimensions);
                    % Store
                    RES(icat, iobj, itransf, iday, icam).Y_avg_struct = Y_avg_struct;
                    
                    if isempty(network.mapping)
                        Y_avg_sel_struct.Y = Y;
                        Y_avg_sel_struct = putYinCell(setup_data.dset, REG, Y_avg_sel_struct);
                        nclasses = size(Y_avg_sel_struct.C,2);
                        
                        [Y_avg_sel_struct.acc_new, Y_avg_sel_struct.acc_xclass_new, Y_avg_sel_struct.C_new] = ...
                            computeAcc(Y_avg_sel_struct.Y, Y_avg_sel_struct.Ypred, nclasses, cells_sel, acc_dimensions);
                        % Store
                        RES(icat, iobj, itransf, iday, icam).Y_avg_sel_struct = Y_avg_sel_struct;
                    end
                    
                    if experiment.prep.NCROPS>1
                        
                        if isempty(network.mapping)
%                             if question.setlist.create_imnetlabels
                                Y_central_struct.Y = Yimnet;
%                             else
%                                 warning('... and for Ypred_central...');
%                             end
                        else
                            Y_central_struct.Y = Y;
                            
                        end
                        Y_central_struct = putYinCell(setup_data.dset, REG, Y_central_struct);
                        nclasses = size(Y_central_struct.C,2);
                        [Y_central_struct.acc_new, Y_central_struct.acc_xclass_new, Y_central_struct.C_new] = ...
                            computeAcc(Y_central_struct.Y(idx_to_keep,:), Y_central_struct.Ypred(idx_to_keep,:), nclasses, cells_sel, acc_dimensions);
                        % Store
                        RES(icat, iobj, itransf, iday, icam).Y_central_struct = Y_central_struct;
                        if isempty(network.mapping)
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

%% Save RES!

% save(global_RES_dir, 'RES');

%% Plot RES!

% here we suppose that the training set changes (elements of the struct)
% but that the test set is the same for all trained models

% these results are for one network kind, trained on different subsets
% --> they can be compared with the same results for other network kinds

end



