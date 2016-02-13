function results = new_analyze_predictions(setup_data, experiment)

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

check_output_dir(fullfile(exp_dir, 'figs/fig'));
check_output_dir(fullfile(exp_dir, 'figs/png'));
                    
%% Load linked information 

% about the network tested (network)
load(experiment.network_struct_path);

if isfield(network, 'network_dir')
    network.network_dir;
end

% abut the subset of the dset considered (question)
load(experiment.question_struct_path);

cat_idx_all = question.setlist.cat_idx_all;
obj_lists_all = question.setlist.obj_lists_all;
transf_lists_all = question.setlist.transf_lists_all;
day_mappings_all = question.setlist.day_mappings_all;
day_lists_all = question.setlist.day_lists_all;
camera_lists_all = question.setlist.camera_lists_all;

%% Allocate memory for the accuracy

acc_global = -ones(length(cat_idx_all), length(obj_lists_all));
acc_all = cell(length(cat_idx_all), length(obj_lists_all), length(transf_lists_all), length(day_lists_all), length(camera_lists_all));

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
                                tmp = transf_names(transf_lists_all{itransf}{iset});
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
                        output_dir = fullfile(exp_dir, caffe_model_name, dir_regtxt_relative, trainval_dir, network.mapping, network.network_dir);
                    else
                        output_dir = fullfile(exp_dir, caffe_model_name, dir_regtxt_relative, trainval_dir, network.mapping);
                    end
                    check_output_dir(output_dir);

                    check_output_dir(fullfile(output_dir, 'figs/fig'));
                    check_output_dir(fullfile(output_dir, 'figs/png'));
                    
                    %% Load the registry REG and the true labels Y
                     
                    fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                    input_registry = textscan(fid, '%s %d'); 
                    fclose(fid);
                    Y = input_registry{2};
                    REG = input_registry{1}; 
                    if isempty(network.mapping) && question.create_imnetlabels
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Yimnet.txt']));
                        input_registry = textscan(fid, '%s %d'); 
                        fclose(fid);
                        Yimnet = input_registry{2};
                    end
                    clear input_registry;

                    %% Load the predictions Ypred
                    
                    Y_avg_struct = load(fullfile(output_dir_y, ['Yavg_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    if isempty(network.mapping) 
                        Y_avg_sel_struct = load(fullfile(output_dir_y, ['Yavg_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C'); 
                    end
                    
                    if NCROPS>1
                       Y_central_struct = load(fullfile(output_dir_y, ['Ycentral_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        if isempty(network.mapping) 
                            Y_central_sel_struct = load(fullfile(output_dir_y, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        end
                    end

                    %% Organize Y and Ypred in cell arrays ready to be analyzed
                    
                    if isempty(network.mapping) 
                        if question.setlist.create_imnetlabels
                            Y_avg_struct.Y = Yimnet;
                        else
                            warning('mapping is empty but Yimnet not found: skipping accuracy for Ypred_avg...');
                        end
                    else
                        Y_avg_struct.Y = Y; 
                    end 
                    Y_avg_struct = putYinCell(setup_data.dset, REG, Y_avg_struct);
                    
                    if isempty(network.mapping)
                        Y_avg_sel_struct.Y = Y;
                        Y_avg_sel_struct = putYinCell(setup_data.dset, REG, Y_avg_sel_struct);
                    end    
                    
                    if NCROPS>1
                        
                        if isempty(network.mapping)
                            if question.setlist.create_imnetlabels
                                Y_central_struct.Y = Yimnet;
                            else
                                warning('... and for Ypred_central...');
                            end
                        else
                            Y_central_struct.Y = Y;
                        end   
                        Y_central_struct = putYinCell(setup_data.dset, REG, Y_central_struct);
                        
                        if isempty(network.mapping) 
                            Y_central_sel_struct.Y = Y;
                            Y_central_sel_struct = putYinCell(setup_data.dset, REG, Y_central_sel_struct);
                        end
                        
                    end                       
                    
                    %% Compute the accuracies (frame-based / filtered)
                    
                    Nplots = 3;
                    Ncols = 3;
                    Nrows =  ceil(Nplots/Ncols);
                    
                    AA = cell(Nplots,1);
                    for ii=1:Nplots
                        AA{ii} = zeros(length(cat_idx)*length(obj_list), length(transf_list)*length(camera_list)*length(day_mapping));
                    end
                    
                    % accuracy xCat xObj xTr xDay xCam
                    for cc=1:length(cat_idx)
                        for idxo=1:length(obj_list)
                            
                            for idxt =1:length(transf_list)
                                for idxd=1:length(day_mapping)
                                    for idxe=1:length(camera_list)
                                        
                                        io = obj_list(idxo);
                                        it = opts.Transfs(transf_names{transf_list(idxt)});
                                        ie = opts.Cameras(camera_names{camera_list(idxe)});
                                        id = opts.Days(day_names{day_mapping(idxd)});
                                        
                                        if strcmp(accum_method, 'none')
                                            ypred = Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}{io, it, id ,ie};
                                        elseif strcmp(accum_method, 'mode')
                                            ypred = Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}{io, it, id ,ie};
                                        elseif compute_avg && strcmp(accum_method, 'avg')
                                            ypred = Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}{io, it, id ,ie};
                                        end
                                        ytrue = Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id ,ie);
                                        ytrue = repmat(ytrue, length(ypred), 1);
                                        
                                        AA{1}((cc-1)*length(obj_list)+idxo,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = compute_accuracy(ytrue, ypred, 'gurls');
                                        
                                    end
                                end
                            end
                            
                        end
                    end
                    
%                     % accuracy frame-based xCat xObj xTr xDay
%                     for cc=1:length(cat_idx)
%                         for idxo=1:length(obj_list)
%                             for idxt =1:length(transf_list)
%                                 for idxd=1:length(day_mapping)
%                                     
%                                     io = obj_list(idxo);
%                                     it = opts.Transfs(transf_names{transf_list(idxt)});
%                                     id = opts.Days(day_names{day_mapping(idxd)});
%                                     
%                                     if strcmp(accum_method, 'none')
%                                         ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
%                                     elseif strcmp(accum_method, 'mode')
%                                         ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
%                                     elseif compute_avg && strcmp(accum_method, 'avg')
%                                         ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
%                                     end
%                                     ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :));
%                                     foo = ones(size(ytrue));
%                                     nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
%                                     ytrue = cellfun(@repmat, mat2cell(ytrue, foo), nfrxdir, mat2cell(foo, foo), 'UniformOutput', 0);
%                                     
%                                     ypred = cell2mat(ypred(:));
%                                     ytrue = cell2mat(ytrue(:));
%                                     
%                                     rowidx = (cc-1)*length(obj_list)+idxo;
%                                     colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+1;
%                                     colidx2 = colidx1+(length(camera_list)-1);
%                                     colidx = colidx1:colidx2;
%                                     a = compute_accuracy(ytrue, ypred, 'gurls');
%                                     AA{2}(rowidx,colidx) = repmat(a, 1, length(camera_list));
%                                     
%                                     
%                                 end
%                             end
%                         end
%                     end
%                     
%                     % accuracy frame-based xCat xObj xTr
%                     for cc=1:length(cat_idx)
%                         for idxo=1:length(obj_list)
%                             for idxt =1:length(transf_list)
%                                 
%                                 io = obj_list(idxo);
%                                 it = opts.Transfs(transf_names{transf_list(idxt)});
%                                 
%                                 if strcmp(accum_method, 'none')
%                                     ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
%                                 elseif strcmp(accum_method, 'mode')
%                                     ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
%                                 elseif compute_avg && strcmp(accum_method, 'avg')
%                                     ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
%                                 end
%                                 ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, : , :));
%                                 
%                                 foo = ones(size(ytrue));
%                                 foo1 = ones(size(ytrue,1),1);
%                                 foo2 = ones(size(ytrue,2),1);
%                                 nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
%                                 ytrue = cellfun(@repmat, mat2cell(ytrue, foo1, foo2), nfrxdir, mat2cell(foo, foo1, foo2), 'UniformOutput', 0);
%                                 
%                                 ypred = cell2mat(ypred(:));
%                                 ytrue = cell2mat(ytrue(:));
%                                 
%                                 rowidx = (cc-1)*length(obj_list)+idxo;
%                                 colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
%                                 colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
%                                 colidx = colidx1:colidx2;
%                                 a = compute_accuracy(ytrue, ypred, 'gurls');
%                                 AA{3}(rowidx,colidx) = repmat(a, 1, length(camera_list)*length(day_mapping));
%                                 
%                             end
%                         end
%                     end
%                     
%                     % accuracy frame-based xCat xTr
%                     for cc=1:length(cat_idx)
%                         for idxt =1:length(transf_list)
%                             
%                             it = opts.Transfs(transf_names{transf_list(idxt)});
%                             
%                             if strcmp(accum_method, 'none')
%                                 ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             elseif strcmp(accum_method, 'mode')
%                                 ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             elseif compute_avg && strcmp(accum_method, 'avg')
%                                 ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             end
%                             
%                             ytrue = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             
%                             foo = ones(size(ytrue));
%                             foo1 = ones(size(ytrue,1),1);
%                             foo2 = ones(size(ytrue,2),1);
%                             foo3 = ones(size(ytrue,3),1);
%                             nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
%                             ytrue = cellfun(@repmat, mat2cell(ytrue, foo1, foo2, foo3), nfrxdir, mat2cell(foo, foo1, foo2, foo3), 'UniformOutput', 0);
%                             
%                             ypred = cell2mat(ypred(:));
%                             ytrue = cell2mat(ytrue(:));
%                             
%                             rowidx1 = (cc-1)*length(obj_list)+1;
%                             rowidx2 = rowidx1+length(obj_list)-1;
%                             rowidx = rowidx1:rowidx2;
%                             colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
%                             colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
%                             colidx = colidx1:colidx2;
%                             a = compute_accuracy(ytrue, ypred, 'gurls');
%                             AA{4}(rowidx,colidx) = repmat(a, length(obj_list), length(camera_list)*length(day_mapping));
%                             
%                         end
%                     end
                    
                    % accuracy frame-based xCat xTr xDay xCam
                    for cc=1:length(cat_idx)
                        for idxt =1:length(transf_list)
                            for idxd=1:length(day_mapping)
                                for idxe=1:length(camera_list)
                                    
                                    it = opts.Transfs(transf_names{transf_list(idxt)});
                                    ie = opts.Cameras(camera_names{camera_list(idxe)});
                                    id = opts.Days(day_names{day_mapping(idxd)});
                                    
                                    if strcmp(accum_method, 'none')
                                        ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
                                    elseif strcmp(accum_method, 'mode')
                                        ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
                                    elseif compute_avg && strcmp(accum_method, 'avg')
                                        ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
                                    end
                                    
                                    ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie));
                                    
                                    foo = ones(size(ytrue));
                                    nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
                                    ytrue = cellfun(@repmat, mat2cell(ytrue, foo), nfrxdir, mat2cell(foo, foo), 'UniformOutput', 0);
                                    
                                    ypred = cell2mat(ypred(:));
                                    ytrue = cell2mat(ytrue(:));
                                    
                                    rowidx1 = (cc-1)*length(obj_list)+1;
                                    rowidx2 = rowidx1+length(obj_list)-1;
                                    rowidx = rowidx1:rowidx2;
                                    a = compute_accuracy(ytrue, ypred, 'gurls');
                                    AA{2}(rowidx,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = repmat(a, length(obj_list), 1);
                                    
                                end
                            end
                        end
                    end
                    
                    % accuracy frame-based xTr xDay xCam   
                    for idxt =1:length(transf_list)
                        for idxd=1:length(day_mapping)
                            for idxe=1:length(camera_list)
                                
                                it = opts.Transfs(transf_names{transf_list(idxt)});
                                ie = opts.Cameras(camera_names{camera_list(idxe)});
                                id = opts.Days(day_names{day_mapping(idxd)});
                                
                                ypred = cell(length(cat_idx),1);
                                ytrue = cell(length(cat_idx),1); 
                                for cc=1:length(cat_idx)
                                    
                                    if strcmp(accum_method, 'none')
                                        ypred{cc} = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
                                    elseif strcmp(accum_method, 'mode')
                                        ypred{cc} = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
                                    elseif compute_avg && strcmp(accum_method, 'avg')
                                        ypred{cc} = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
                                    end
                                    
                                    ytrue{cc} = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id, ie))];
                                    
                                    foo = ones(size(ytrue{cc}));
                                    nfrxdir = cellfun(@length, ypred{cc}, 'UniformOutput', 0);
                                    ytrue{cc} = cellfun(@repmat, mat2cell(ytrue{cc}, foo), nfrxdir, mat2cell(foo, foo), 'UniformOutput', 0);
                                    
                                    ypred{cc} = cell2mat(ypred{cc}(:));
                                    ytrue{cc} = cell2mat(ytrue{cc}(:));
                                end
                                
                                ypred = cell2mat(ypred);
                                ytrue = cell2mat(ytrue);
                        
                                rowidx1 = 1;
                                rowidx2 = rowidx1+length(obj_list)*length(cat_idx)-1;
                                rowidx = rowidx1:rowidx2;
                                a = compute_accuracy(ytrue, ypred, 'gurls');
                                AA{3}(rowidx,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = repmat(a, length(obj_list)*length(cat_idx), 1);
                                
                            end
                        end
                    end
                    
%                     % accuracy frame-based xTr
%                     for idxt =1:length(transf_list)
%                         
%                         it = opts.Transfs(transf_names{transf_list(idxt)});
%                         
%                         ypred = cell(length(cat_idx),1);
%                         ytrue = cell(length(cat_idx),1);
%                         for cc=1:length(cat_idx)
%                             
%                             if strcmp(accum_method, 'none')
%                                 ypred{cc} = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             elseif strcmp(accum_method, 'mode')
%                                 ypred{cc} = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             elseif compute_avg && strcmp(accum_method, 'avg')
%                                 ypred{cc} = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             end
%                             ytrue{cc} = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             
%                             foo = ones(size(ytrue{cc}));
%                             foo1 = ones(size(ytrue{cc},1),1);
%                             foo2 = ones(size(ytrue{cc},2),1);
%                             foo3 = ones(size(ytrue{cc},3),1);
%                             nfrxdir = cellfun(@length, ypred{cc}, 'UniformOutput', 0);
%                             ytrue{cc} = cellfun(@repmat, mat2cell(ytrue{cc}, foo1, foo2, foo3), nfrxdir, mat2cell(foo, foo1, foo2, foo3), 'UniformOutput', 0);
%                             
%                             ypred{cc} = cell2mat(ypred{cc}(:));
%                             ytrue{cc} = cell2mat(ytrue{cc}(:));
%                             
%                         end
%                         
%                         ypred = cell2mat(ypred);
%                         ytrue = cell2mat(ytrue);
%                         
%                         rowidx1 = 1;
%                         rowidx2 = rowidx1+length(obj_list)*length(cat_idx)-1;
%                         rowidx = rowidx1:rowidx2;
%                         colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
%                         colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
%                         colidx = colidx1:colidx2;
%                         a = compute_accuracy(ytrue, ypred, 'gurls');
%                         AA{7}(rowidx,colidx) = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping));
%                         
%                     end
%                          
%                     % accuracy frame-based
%                     
%                     if strcmp(accum_method, 'none')
%                         a = compute_accuracy(cell2mat(Y), cell2mat(Ypred), 'gurls');
%                     elseif strcmp(accum_method, 'mode')
%                         
%                     elseif compute_avg && strcmp(accum_method, 'avg')
%                         
%                     end
%                     
%                     AA{8} = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping)*length(transf_list));
                    
                    % plot and save
                    bottom = 1;
                    top = 0;
                    for ii=1:Nplots
                        bottom = min(bottom, min(min(AA{ii})));
                        top = max(top, max(max(AA{ii})));
                    end
                    
                    figure
                    scrsz = get(groot,'ScreenSize');
                    set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
                    
                    for ii=1:Nplots
                        subplot(Nrows, Ncols, ii)
                        imagesc(AA{ii}, [bottom top]);
                        %imagesc(AA{ii});
                        
                        set(gca, 'YTick', 1:length(cat_idx)*length(obj_list));
                        ytl = cat_names(cat_idx);
                        ytl = ytl(:)';
                        ytl = repmat(ytl, length(obj_list), 1);
                        ytl = strcat(ytl(:), repmat(strrep(cellstr(num2str(obj_list(:))), ' ' , ''), length(cat_idx), 1));
                        set(gca, 'YTickLabel', ytl);
                        set(gca, 'XTick', 1:length(camera_list)*length(day_mapping):length(transf_list)*length(camera_list)*length(day_mapping));
                        set(gca, 'XTickLabel', transf_names(transf_list));
                        
                    end
                    colormap(jet);
                    colorbar
                    
                    stringtitle = {['categorization' ', ' mapping ', ' accum_method]};
                    if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
                        %stringtitle{end+1} = [set_names_4figs{1} ' - ' set_names_4figs{2}];
                        stringtitle{end+1} = set_names_4figs{1};
                    end
                    if strcmp(mapping, 'NN')
                        stringtitle{end} = [stringtitle{end} ' - K = ' num2str(K(icat, iobj))];
                    end
                    
                    suptitle(stringtitle);
                    
                    figname = ['acc_' mapping '_' accum_method '_'];
                    figname = [figname strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-')];
                    if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
                        figname = [figname '_' trainval_prefixes{eval_set}];
                        figname = [figname set_names{1} '_' set_names{2}];
                    end
                    
                    saveas(gcf, fullfile(output_dir, 'figs/fig', [figname '.fig']));
                    set(gcf,'PaperPositionMode','auto')
                    print(fullfile(output_dir, 'figs/png', [figname '.png']),'-dpng','-r0')
                    
                    acc_all{icat, iobj, itransf, iday, icam} = AA;
                    
                end
            end
        end
    end
end

%% frameORinst

tobeplotted = [acc_all{1, :, 1, 1, 1}];
tobeplotted = tobeplotted(3,:)';

d1 = zeros(length(tobeplotted),1);
d2 = zeros(length(tobeplotted),1);
cmap = jet(length(tobeplotted));

for itrain=1:length(tobeplotted) 
    d1(itrain, :) = tobeplotted{itrain}(1, 1:2:end);
    d2(itrain, :) = tobeplotted{itrain}(1, 2:2:end);
end

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(2, d1(itrain, :), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
    
    title('day 1')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 3]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);
    h = gca;
    h.XTick = 2;
    
    h.XTickLabel = 'TRANSL';
    
    subplot(1,2,2)
    hold on
    grid on
    
    plot(2, d2(itrain,:), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
   
    title('day 2')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 3]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 2;
    
    h.XTickLabel = 'TRANSL';
    
end

legend({'1:3', '1:7 (same dim)'});

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_1';
%figname = 'framesORtransf_1';
figname = 'framesORinst_1';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')
                    
figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:1
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:length(tobeplotted), d1(:, 1), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
    
    title('day 1')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 2]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:2;
    
    h.XTickLabel = {'1:3', '1:7 (same)'};
    h.XTickLabelRotation = 45; 
    
    subplot(1,2,2)
    hold on
    grid on
   
    plot(1:length(tobeplotted), d2(:, 1), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
    
    title('day 2')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 2]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:2;
    
    h.XTickLabel = {'1:3', '1:7 (same)'};
    h.XTickLabelRotation = 45;
    
end

legend('TRANSL');

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_2';
%figname = 'framesORtransf_2';
figname = 'framesORinst_2';

saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

subplot(1,2,1)
imagesc(d1, [min(min([d1 d2])) max(max([d1 d2]))]);
title('day 1')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1;
h.XTickLabel = {'TRANSL'};
h.YTick = 1:2;
h.YTickLabel = {'1:3', '1:7 (same)'};
colormap(jet);

subplot(1,2,2)
imagesc(d2, [min(min(d2)) max(max(d1))]);
title('day 2')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1;
h.XTickLabel = {'TRANSL'};
h.YTick = 1:2;
h.YTickLabel = {'1:3', '1:7 (same)'};
colormap(jet);
colorbar

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_3';
%figname = 'framesORtransf_3';
figname = 'framesORinst_3';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

%% frameORtransf

tobeplotted = [acc_all{1, 1, :, 1, 1}];
tobeplotted = tobeplotted(3,:)';

d1 = zeros(length(tobeplotted),Ntransfs);
d2 = zeros(length(tobeplotted),Ntransfs);
cmap = jet(length(tobeplotted));

for itrain=1:length(tobeplotted) 
    d1(itrain, :) = tobeplotted{itrain}(1, 1:2:end);
    d2(itrain, :) = tobeplotted{itrain}(1, 2:2:end);
end

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(itrain, :), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);
    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
    subplot(1,2,2)
    hold on
    grid on
    
    plot(1:Ntransfs, d2(itrain,:), 'Color', cmap(itrain,:), 'LineWidth', 2);
   
    title('day 2')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
end

legend({'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'});

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_1';
figname = 'framesORtransf_1';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')
                    
figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
    h.XTickLabelRotation = 45; 
    
    subplot(1,2,2)
    hold on
    grid on
   
    plot(1:Ntransfs, d2(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 2')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
    h.XTickLabelRotation = 45;
    
end

legend(transf_names);

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_2';
figname = 'framesORtransf_2';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

subplot(1,2,1)
imagesc(d1, [min(min([d1 d2])) max(max([d1 d2]))]);
title('day 1')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
colormap(jet);

subplot(1,2,2)
imagesc(d2, [min(min(d2)) max(max(d1))]);
title('day 2')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
colormap(jet);
colorbar

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_3';
figname = 'framesORtransf_3';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

%% Generalization across transformations

tobeplotted = [acc_all{1, 1, :, 1, 1}];
tobeplotted = tobeplotted(3,:)';

d1 = zeros(length(tobeplotted),Ntransfs);
d2 = zeros(length(tobeplotted),Ntransfs);
cmap = jet(length(tobeplotted));

for itrain=1:length(tobeplotted) 
    d1(itrain, :) = tobeplotted{itrain}(1, 1:2:end);
    d2(itrain, :) = tobeplotted{itrain}(1, 2:2:end);
end


figure
bar(d2');

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(itrain, :), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);
    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
    subplot(1,2,2)
    hold on
    grid on
    
    plot(1:Ntransfs, d2(itrain,:), 'Color', cmap(itrain,:), 'LineWidth', 2);
   
    title('day 2')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
end

legend(transf_names);

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
figname = 'generalization_transf_1';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')
                    
figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
    subplot(1,2,2)
    hold on
    grid on
   
    plot(1:Ntransfs, d2(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 2')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
end

legend(transf_names);

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
figname = 'generalization_transf_2';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

subplot(1,2,1)
imagesc(d1, [min(min([d1 d2])) max(max([d1 d2]))]);
title('day 1')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = transf_names;
colormap(jet);

subplot(1,2,2)
imagesc(d2, [min(min(d2)) max(max(d1))]);
title('day 2')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = transf_names;
colormap(jet);
colorbar

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
figname = 'generalization_transf_3';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

% tobeplotted = zeros(length(cat_idx_all), length(obj_lists_all), length(transf_lists{3}));
% for icat=1:length(cat_idx_all)
%     for iobj=1:length(obj_lists_all)
%         for idxt=1:length(transf_lists{3})
%             
%             tobeplotted(icat, iobj, idxt) = acc_all{icat, iobj}{5}(1, (idxt-1)*length(day_mappings{3})*length(camera_lists{3})+1);
%             
%         end
%     end
% end
% 
% top = max(max(max(tobeplotted))) ;
% bottom = min(min(min(tobeplotted))) ;
% 
% cmap = jet(length(obj_lists_all));
% figure
% scrsz = get(groot,'ScreenSize');
% set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
% 
% for idxt=1:length(transf_lists{3})
%     
%     subplot(1, length(transf_lists{3}), idxt)
%     hold on
%     for iobj=1:length(obj_lists_all)
%         plot(cellfun(@length, cat_idx_all), squeeze(tobeplotted(:, iobj, idxt)) , '-o', 'Color', cmap(iobj, :), 'MarkerEdgeColor', cmap(iobj, :), 'MarkerFaceColor', cmap(iobj, :));
%     end
%     ylim([bottom top])
%     title(transf_names(transf_lists{3}(idxt)))
%     set(gca, 'XTick', cellfun(@length, cat_idx_all));
% end
% 
% lgnd = cell(length(obj_lists_all), 1);
% for iobj=1:length(obj_lists_all)
%     
%     obj_lists = obj_lists_all{iobj};
%     
%     if strcmp(mapping, 'none') || strcmp(mapping, 'select')
%         lgnd{iobj} = strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-');
%     else
%         lgnd{iobj} = '';
%         for sidx=1:Nsets
%             lgnd{iobj} = [lgnd{iobj} ' ' strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
%         end
%     end
% end
% 
% legend(lgnd);
% 
% stringtitle = {[experiment ', ' mapping ', ' accum_method]};
% 
% suptitle(stringtitle);
% 
% figname = ['acc1_' mapping '_' accum_method];
% 
% saveas(gcf, fullfile(output_dir_root, 'figs/fig', [figname '.fig']));
% set(gcf,'PaperPositionMode','auto')
% print(fullfile(output_dir_root, 'figs/png', [figname '.png']),'-dpng','-r0')
% 
% 
% 
% 
% 
% 
% %% Plot all experiments together
% 
% tobeplotted = zeros(length(cat_idx_all), length(obj_lists_all), length(transf_lists{3}));
% for icat=1:length(cat_idx_all)
%     for iobj=1:length(obj_lists_all)
%         for idxt=1:length(transf_lists{3})
%             
%             tobeplotted(icat, iobj, idxt) = acc_all{icat, iobj}{5}(1, (idxt-1)*length(day_mappings{3})*length(camera_lists{3})+1);
%             
%         end
%     end
% end
% 
% top = max(max(max(tobeplotted))) ;
% bottom = min(min(min(tobeplotted))) ;
% 
% cmap = jet(length(obj_lists_all));
% figure
% scrsz = get(groot,'ScreenSize');
% set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
% 
% for idxt=1:length(transf_lists{3})
%     
%     subplot(1, length(transf_lists{3}), idxt)
%     hold on
%     for iobj=1:length(obj_lists_all)
%         plot(cellfun(@length, cat_idx_all), squeeze(tobeplotted(:, iobj, idxt)) , '-o', 'Color', cmap(iobj, :), 'MarkerEdgeColor', cmap(iobj, :), 'MarkerFaceColor', cmap(iobj, :));
%     end
%     ylim([bottom top])
%     title(transf_names(transf_lists{3}(idxt)))
%     set(gca, 'XTick', cellfun(@length, cat_idx_all));
% end
% 
% lgnd = cell(length(obj_lists_all), 1);
% for iobj=1:length(obj_lists_all)
%     
%     obj_lists = obj_lists_all{iobj};
%     
%     if strcmp(mapping, 'none') || strcmp(mapping, 'select')
%         lgnd{iobj} = strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-');
%     else
%         lgnd{iobj} = '';
%         for sidx=1:Nsets
%             lgnd{iobj} = [lgnd{iobj} ' ' strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
%         end
%     end
% end
% 
% legend(lgnd);
% 
% stringtitle = {[experiment ', ' mapping ', ' accum_method]};
% 
% suptitle(stringtitle);
% 
% figname = ['acc1_' mapping '_' accum_method];
% 
% saveas(gcf, fullfile(output_dir_root, 'figs/fig', [figname '.fig']));
% set(gcf,'PaperPositionMode','auto')
% print(fullfile(output_dir_root, 'figs/png', [figname '.png']),'-dpng','-r0')






end