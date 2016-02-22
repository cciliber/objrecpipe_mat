function new_create_sets(DATA_DIR, dset, question_dir, setlist)

if strncmp(question_dir, 'cat', 3)
    exp_id = false;
elseif strncmp(question_dir, 'id', 2)
    exp_id = true;
else
    error('Unsupported exp_kind in the question config file!');
end
    
if exp_id
    if isfield(setlist, 'divide_trainval_perc')
        divide_trainval_perc = setlist.divide_trainval_perc;
    else
        divide_trainval_perc = false;
    end
end
    
if exp_id && divide_trainval_perc
    warning('Going to divide set 1 and 2 according to divide_trainval_perc settings!');
    
    set_prefixes = setlist.set_prefixes;

    validation_perc = setlist.validation_perc;
    validation_split = setlist.validation_split; % 'step' 'block' 'random'

end

num_eval_sets = numel(setlist.set_prefixes);


if isfield(setlist,'same_size')
    same_size = setlist.same_size;
else
    same_size = zeros(1,num_eval_sets);
end


if ~exp_id
    if isfield(question.setlist, 'create_imnetlabels')
        create_imnetlabels = question.setlist.create_imnetlabels;
    else
        create_imnetlabels = false;
    end
end


cat_idx_all = setlist.cat_idx_all;
obj_lists_all = setlist.obj_lists_all;
transf_lists_all = setlist.transf_lists_all;
day_mappings_all = setlist.day_mappings_all;
day_lists_all = setlist.day_lists_all;
camera_lists_all = setlist.camera_lists_all;


cat_names = dset.cat_names;
transf_names = dset.transf_names;
day_names = dset.day_names;
camera_names = dset.camera_names;


%% Setup the IO root directories

% input registries from which to select the subsets
reg_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/full_registries');
check_input_dir(reg_dir);

% output root dir for registries of the subsets
output_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries');

%% For each experiment, go!
for eval_set = 1:num_eval_sets
    
    
    
    for icat=1:length(cat_idx_all)
        cat_idx = cat_idx_all{icat};
        
        % Assign the first part of relative output dir
        output_dir_regtxt_relative_cat = strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-');
        
        if ~exp_id
            
            % Assign output dir
            output_dir_regtxt = fullfile(output_dir_regtxt_root, ...
                output_dir_regtxt_relative_cat, ...
                question_dir);
            check_output_dir(output_dir_regtxt);
            
            % Assign the labels
            fid_labels = fopen(fullfile(output_dir_regtxt, 'labels.txt'), 'w');
            Y_digits = containers.Map (cat_names(cat_idx), 0:(length(cat_idx)-1));
            for line=cat_idx
                fprintf(fid_labels, '%s %d\n', cat_names{line}, Y_digits(cat_names{line}));
            end
            fclose(fid_labels);
            
        end
        
        % Files to be created
        fcreated = zeros(length(obj_lists_all), length(transf_lists_all), length(day_lists_all), length(camera_lists_all));

        if same_size(eval_set)
            NsamplesReference = zeros(length(cat_idx),1);
        end
        
        for cc=cat_idx
            
            % create flist_splitted
            reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
            
            fid = fopen(reg_path);
            loader = textscan(fid, '%s %d');
            flist_splitted = regexp(loader{1}, '/', 'split');
            clear loader;
            fclose(fid);
            flist_splitted = vertcat(flist_splitted{:});
            flist_splitted(:,1) = [];
            
            for iobj=1:length(obj_lists_all)
                obj_list = obj_lists_all{iobj}{eval_set};
                
                if ~isempty(obj_list)
                    
                    if exp_id
                        
                        % Assign the output dir
                        output_dir_regtxt_relative_obj = strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-');
                        
                        output_dir_regtxt = fullfile(output_dir_regtxt_root, ...
                            output_dir_regtxt_relative_cat, ...
                            question_dir, ...
                            output_dir_regtxt_relative_obj);
                        check_output_dir(output_dir_regtxt);
                        
                        % Assign the labels
                        % if we want to do identification then
                        % all objects are in the train val and test sets
                        % (obj_list should be the same for every eval_set)
                        obj_names = repmat(cat_names(cat_idx)', length(obj_list),1);
                        obj_names = obj_names(:);
                        tmp = repmat(obj_list', length(cat_idx),1);
                        obj_names = strcat(obj_names, strrep(mat2cell(num2str(tmp), ones(length(tmp),1)), ' ', ''));
                        
                        fid_labels = fopen(fullfile(output_dir_regtxt, 'labels.txt'), 'w');
                        Y_digits = containers.Map (obj_names, 0:(length(obj_names)-1));
                        for line=1:length(obj_names)
                            fprintf(fid_labels, '%s %d\n', obj_names{line}, Y_digits(obj_names{line}));
                        end
                        fclose(fid_labels);
                        
                    end
                    
                    oo_tobeloaded = ismember(flist_splitted(:,1), strrep(cellstr(strcat(cat_names{cc}, num2str(obj_list'))), ' ', '') );
                    
                    for itransf=1:length(transf_lists_all)
                        transf_list = transf_lists_all{itransf}{eval_set};
                        
                        if ~isempty(transf_list)
                            
                            tt_tobeloaded = ismember(flist_splitted(:,2), transf_names(transf_list));
                            
                            for iday=1:length(day_lists_all)
                                day_list = day_lists_all{iday}{eval_set};
                                day_mapping = day_mappings_all{iday}{eval_set};
                                
                                if ~isempty(day_list)
                                    
                                    dd_tobeloaded = ismember(flist_splitted(:,3), day_names(day_list));
                                    
                                    for icam=1:length(camera_lists_all)
                                        camera_list = camera_lists_all{icam}{eval_set};
                                        
                                        if ~isempty(camera_list)
                                            
                                            ee_tobeloaded = ismember(flist_splitted(:,4), camera_names(camera_list));
                                            
                                            % Create the set name
                                            if exp_id                                               
                                                if divide_trainval_perc
                                                    set_name = set_prefixes{eval_set};
                                                else
                                                    set_name = '';
                                                end                                             
                                            else                                              
                                                set_name = [strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-') '_'];                                           
                                            end                                            
                                            set_name = [set_name ...
                                                    'tr_' strrep(strrep(num2str(transf_list), '   ', '-'), '  ', '-') ...
                                                    '_day_' strrep(strrep(num2str(day_mapping), '   ', '-'), '  ', '-') ...
                                                    '_cam_' strrep(strrep(num2str(camera_list), '   ', '-'), '  ', '-')];   
                                                
                                            % Create fids or open them
                                            if ~fcreated(iobj, itransf, iday, icam)
                                                fcreated(iobj, itransf, iday, icam) = 1;
                                                writemodality = 'w';
                                            else
                                                writemodality = 'a';
                                            end
                                            fid_Y = fopen(fullfile(output_dir_regtxt, [set_name '_Y.txt']), writemodality);
                                            if ~exp_id && create_imnetlabels
                                                fid_Yimnet = fopen(fullfile(output_dir_regtxt, [set_name '_Yimnet.txt']), writemodality);
                                            end
                                            
                                            
                                            % Select!
                                            tobeloaded = oo_tobeloaded & tt_tobeloaded & dd_tobeloaded & ee_tobeloaded;
                                            flist_splitted_tobeloaded = flist_splitted(tobeloaded==1, :);
                                            
                                            % Eventually divide train val
                                            if exp_id && divide_trainval_perc
                                                
                                                if strcmp(validation_split, 'step')
                                                    
                                                    validation_step = 1/validation_perc;
                                                    
                                                    if strncmp(set_name, 'train', 5)
                                                        flist_splitted_tobeloaded(1:validation_step:end,:) = [];
                                                    elseif strncmp(set_name, 'val', 3)
                                                        flist_splitted_tobeloaded = flist_splitted_tobeloaded(1:validation_step:end,:);
                                                    end
                                                    
                                                elseif strcmp(validation_split, 'block')
                                                    error('Not supported yet!');
                                                    
                                                elseif strcmp(validation_split, 'random')
                                                    
                                                    fidxs = randperm(length(flist_splitted_tobeloaded));
                                                    split_idx = floor(validation_perc*length(flist_splitted_tobeloaded));
                                                    
                                                    if strncmp(set_name, 'train', 5)
                                                        flist_splitted_tobeloaded = flist_splitted_tobeloaded(fidxs(1:split_idx),:);
                                                    elseif strncmp(set_name, 'val', 3)
                                                        flist_splitted_tobeloaded = flist_splitted_tobeloaded(fidxs(split_idx+1:end),:);
                                                    end
                                                    
                                                end
                                                
                                            end
                                            
                                            % Eventually reduce samples
                                            if same_size(eval_set)
                                                if icat==1 && iobj==1 && itransf==1 && iday==1 && icam==1
                                                    NsamplesReference(cc) = length(flist_splitted_tobeloaded);
                                                else
                                                    subs_idxs = round(linspace(1, length(flist_splitted_tobeloaded), NsamplesReference(cc)));
                                                    subs_idxs = unique(subs_idxs);
                                                    
                                                    flist_splitted_tobeloaded = flist_splitted_tobeloaded(subs_idxs, :);
                                                end
                                            end
                                            nsmpl_xcat = length(flist_splitted_tobeloaded);
                                            
                                            % Assign REG
                                            REG = fullfile(flist_splitted_tobeloaded(:,1), flist_splitted_tobeloaded(:,2), flist_splitted_tobeloaded(:,3), flist_splitted_tobeloaded(:,4), flist_splitted_tobeloaded(:,5));
                                            
                                            % Assign Y and Yimnet
                                            if exp_id
                                                Y = cell2mat(values(Y_digits, flist_splitted_tobeloaded(:,1)));
                                            else
                                                Y = ones(nsmpl_xcat, 1)*Y_digits(cat_names{cc});
                                                if create_imnetlabels
                                                    Yimnet = ones(nsmpl_xcat, 1)*double(dset.Cat_ImnetLabels(cat_names{cc}));
                                                end
                                            end     
                                            
                                            % Write output
                                            for line=1:nsmpl_xcat
                                                
                                                fprintf(fid_Y, '%s/%s %d\n', cat_names{cc}, REG{line}, Y(line));
                                                if ~exp_id && create_imnetlabels
                                                    fprintf(fid_Yimnet, '%s/%s %d\n', cat_names{cc}, REG{line}, Yimnet(line));
                                                end
                                                
                                            end
                                            
                                            fprintf('%s: %s\n', set_name, cat_names{cc});
                                            
                                            fclose(fid_Y);
                                            if ~exp_id && create_imnetlabels
                                                fclose(fid_Yimnet);
                                            end
                                            
                                        end
                                        
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
end


end