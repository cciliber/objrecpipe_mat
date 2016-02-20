function RES = new_analyze_predictions(setup_data, experiment, results)

%% Load linked information

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
global_RES_dir = [experiment.experiment_struct_path '_RES'];
check_output_dir(global_RES_dir);
check_output_dir(fullfile(global_RES_dir, 'figs/fig'));
check_output_dir(fullfile(global_RES_dir, 'figs/png'));


%% Allocate memory to contain resuls for all the trained models in setlist
RES = struct([]);

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
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
                    
                    if isfield(network, 'network_dir')
                        output_dir = fullfile(exp_dir, network.caffestuff.net_name, dir_regtxt_relative, trainval_dir, network.mapping, network.network_dir);
                    else
                        output_dir = fullfile(exp_dir, network.caffestuff.net_name, dir_regtxt_relative, trainval_dir, network.mapping);
                    end
                    check_output_dir(output_dir);
                    
                    
                    %% Load the registry REG and the true labels Y
                    
                    fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                    input_registry = textscan(fid, '%s %d');
                    fclose(fid);
                    Y = input_registry{2};
                    REG = input_registry{1};
                    if isempty(network.mapping)% && question.create_imnetlabels
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Yimnet.txt']));
                        input_registry = textscan(fid, '%s %d');
                        fclose(fid);
                        Yimnet = input_registry{2};
                    end
                    clear input_registry;
                    
                    %% Load the predictions Ypred
                    
                    Y_avg_struct = load(fullfile(output_dir, ['Yavg_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    if isempty(network.mapping)
                        Y_avg_sel_struct = load(fullfile(output_dir, ['Yavg_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    end
                    
                    if experiment.prep.NCROPS>1
                        Y_central_struct = load(fullfile(output_dir, ['Ycentral_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        if isempty(network.mapping)
                            Y_central_sel_struct = load(fullfile(output_dir, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
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
                    nclasses = size(Y_avg_struct.C,2);
                    [Y_avg_struct.acc_new, Y_avg_struct.acc_xclass_new, Y_avg_struct.C_new] = ...
                        computeAcc(Y_avg_struct.Y, Y_avg_struct.Ypred, nclasses, cells_sel, acc_dimensions);
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
                            computeAcc(Y_central_struct.Y, Y_central_struct.Ypred, nclasses, cells_sel, acc_dimensions);
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

save(global_RES_dir, 'RES');

%% Plot RES!

% here we suppose that the training set changes (elements of the struct)
% but that the test set is the same for all trained models

% these results are for one network kind, trained on different subsets
% --> they can be compared with the same results for other network kinds

end



