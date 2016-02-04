clear all;

%%

create_fullpath = false;
setup_code_and_data(create_fullpath);


%% Setup the question

% experiment kind
experiment = 'categorization';
%experiment = 'identification';

% question
same_size = true;
if same_size == true
    %question_dir = 'frameORtransf';
    question_dir = 'frameORinst';
    
end

%% Setup the IO root directories

% input registries from which to select the subsets
reg_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/full_registries');
check_input_dir(reg_dir);

% output root dir for registries of the subsets
output_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
if create_fullpath
    output_dir_regtxt_root_fullpath = fullfile([dset_dir '_experiments'], 'registries', experiment);
end

%% Set up the trials

% Default sets that are created

set_names_prefix = {'train_', 'val_', 'test_'};
Nsets = length(set_names_prefix);

% Whether to create the ImageNet labels

if strcmp(experiment, 'categorization')
    create_imnetlabels = true;
else
    create_imnetlabels = [];
end

% Choose categories

cat_idx_all = {[2 3 4 5 6 7 8 9 11 12 13 14 15 19 20]};

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    Ntest = 1;
    Nval = 1;
    Ntrain = NobjPerCat - Ntest - Nval;
    
    obj_lists_all = cell(Ntrain, 1);
    
    p = randperm(NobjPerCat);

    for oo=1:Ntrain
        
        obj_lists_all{oo} = cell(Nsets,1);
        
        obj_lists_all{oo}{3} = p(1:Ntest);
        obj_lists_all{oo}{2} = p((Ntest+1):(Ntest+Nval));
        
        obj_lists_all{oo}{1} = p((Ntest+Nval+1):(Ntest+Nval+oo));
        
    end
    
elseif strcmp(experiment, 'identification')
    
    id_exps = {1:3, 1:5, 1:7, 1:10};
    obj_lists_all = cell(length(id_exps), 1);
    for ii=1:length(id_exps)
        obj_lists_all{ii} = repmat(id_exps(ii), 1, Nsets);
    end
    
end

% Choose transformation

transf_lists_all = { {1:5, 1:5, 1:5} };

% Choose day

day_mappings_all = { {1, 1, 1:2} };
day_lists_all = cell(length(day_mappings_all),1);

for ee=1:length(day_mappings_all)
    
    day_mappings = day_mappings_all{ee};
    
    day_lists = cell(1,Nsets);
    tmp = keys(opts.Days);
    for ii=1:Nsets
        for dd=1:length(day_mappings{ii})
            tmp1 = tmp(cell2mat(values(opts.Days))==day_mappings{ii}(dd))';
            tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
            day_lists{ii} = [day_lists{ii} tmp2];
        end
    end
    
    day_lists_all{ee} = day_lists;
    
end

% Choose camera

camera_lists_all = { {1, 1, 1:2} };

% Choose validation percentage

% You can set it to true in the 'identification' experiment
% e.g. if the train and val sets are coincident
% (same transformation+day, the camera is not to be considered)
if strcmp(experiment, 'identification')
    divide_trainval_perc = true;
else
    divide_trainval_perc = [];
end

if strcmp(experiment, 'identification') && divide_trainval_perc==true
    validation_perc = 0.5;
    validation_step = 1/validation_perc;
else
    validation_perc = [];
    validation_step = [];
end

%% Save metadata of this experiment

trial.cat_idx_all = cat_idx_all;
trial.obj_lists_all = obj_lists_all;
trial.transf_lists_all = transf_lists_all;
trial.day_mappings_all = day_mappings_all;
trial.camera_lists_all = camera_lists_all;

save(fullpath(output_dir_regtxt_root_fullpath, 'trial.mat'), 'trial', '-v7.3');

%% For each experiment, go!

if same_size
    NsamplesReference = cell(Ncat, 1);
end

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        for itransf=1:length(transf_lists_all)
            
            transf_lists = transf_lists_all{itransf};
            
            for iday=1:length(day_lists_all)
                
                day_lists = day_lists_all{iday};
                day_mappings = day_mappings_all{iday};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_lists = camera_lists_all{icam};
                    
                    % Assign the proper output directory
                    
                    output_dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    if strcmp(experiment, 'identification')
                        output_dir_regtxt_relative = fullfile(output_dir_regtxt_relative, strrep(strrep(num2str(obj_lists), '   ', '-'), '  ', '-'));
                    end
                    
                    if same_size==true
                        output_dir_regtxt_relative = fullfile(output_dir_regtxt_relative, question_dir);
                    end
                    
                    output_dir_regtxt = fullfile(output_dir_regtxt_root, output_dir_regtxt_relative);
                    check_output_dir(output_dir_regtxt);
                    
                    if create_fullpath
                        output_dir_regtxt_fullpath = fullfile(output_dir_regtxt_root_fullpath, output_dir_regtxt_relative);
                        check_output_dir(output_dir_regtxt_fullpath);
                    end
                    
                    % Assign the Y labels
                    
                    fid_labels = fopen(fullfile(output_dir_regtxt, 'labels.txt'), 'w');
                    
                    if strcmp(experiment, 'categorization')
                        
                        Y_digits = containers.Map (cat_names(cat_idx), 0:(length(cat_idx)-1));
                        for line=cat_idx
                            fprintf(fid_labels, '%s %d\n', cat_names{line}, Y_digits(cat_names{line}));
                        end
                        
                    elseif strcmp(experiment, 'identification')
                        
                        % if we want to do identification then all objects are both in the
                        % 'trainval' and in the 'test' sets (obj_lists{1}==obj_lists{2})
                        obj_names = repmat(cat_names(cat_idx)', length(obj_lists{1}),1);
                        obj_names = obj_names(:);
                        tmp = repmat(obj_lists{1}', length(cat_idx),1);
                        obj_names = strcat(obj_names, strrep(mat2cell(num2str(tmp), ones(length(tmp),1)), ' ', ''));
                        Y_digits = containers.Map (obj_names, 0:(length(obj_names)-1));
                        for line=1:length(obj_names)
                            fprintf(fid_labels, '%s %d\n', obj_names{line}, Y_digits(obj_names{line}));
                        end
                    end
                    
                    fclose(fid_labels);
                    
                    % Create the set names
                    
                    for ii=1:Nsets
                        set_names{ii} = [set_names_prefix{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
                    end
                    
                    % Create the registries REG and the labels Yimnet (ImageNet labels), Y
                    
                    for sidx=1:Nsets
                        
                        set_name = set_names{sidx};
                        
                        day_list = day_lists{sidx};
                        obj_list = obj_lists{sidx};
                        transf_list = transf_lists{sidx};
                        camera_list = camera_lists{sidx};
                        
                        REG = cell(Ncat, 1);
                        
                        Y = cell(Ncat, 1);
                        fid_Y = fopen(fullfile(output_dir_regtxt, [set_name '_Y.txt']), 'w');
                        
                        if strcmp(experiment, 'categorization') && create_imnetlabels
                            Yimnet = cell(Ncat, 1);
                            fid_Yimnet = fopen(fullfile(output_dir_regtxt, [set_name '_Yimnet.txt']), 'w');
                        end
                        
                        if create_fullpath
                            if strcmp(experiment, 'categorization') && create_imnetlabels
                                fid_Yimnet_fullpath = fopen(fullfile(output_dir_regtxt_fullpath, [set_name '_fullpath_Yimnet.txt']), 'w');
                            end
                            fid_Y_fullpath = fopen(fullfile(output_dir_regtxt_fullpath, [set_name '_fullpath_Y.txt']), 'w');
                        end
                        
                        for cc=cat_idx
                            
                            reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
                            
                            loader = Features.GenericFeature();
                            loader.assign_registry_and_tree_from_file(reg_path, [], []);
                            
                            flist_splitted = regexp(loader.Registry, '/', 'split');
                            clear loader;
                            flist_splitted = vertcat(flist_splitted{:});
                            flist_splitted(:,1) = [];
                            
                            tobeloaded = zeros(length(flist_splitted), 1);
                            
                            for oo=obj_list
                                
                                oo_tobeloaded = strcmp(flist_splitted(:,1), strcat(cat_names{cc}, num2str(oo)));
                                
                                for tt=transf_list
                                    
                                    tt_tobeloaded = oo_tobeloaded & strcmp(flist_splitted(:,2), transf_names(tt));
                                    
                                    for dd=day_list
                                        
                                        dd_tobeloaded = tt_tobeloaded & strcmp(flist_splitted(:,3), day_names(dd));
                                        
                                        for ee=camera_list
                                            
                                            ee_tobeloaded = dd_tobeloaded & strcmp(flist_splitted(:,4), camera_names(ee));
                                            
                                            tobeloaded = tobeloaded + ee_tobeloaded;
                                            
                                        end
                                    end
                                end
                            end
                            
                            flist_splitted = flist_splitted(tobeloaded==1, :);
                            
                            if strcmp(experiment, 'identification') && divide_trainval_perc==true
                                if strncmp(set_name, 'tra', 3)
                                    flist_splitted(1:validation_step:end,:) = [];
                                elseif strncmp(set_name, 'val', 3)
                                    flist_splitted = flist_splitted(1:validation_step:end,:);
                                end
                            end
                            
                            if same_size==true && strncmp(set_name, 'tra', 3)
                                if icat==1 && iobj==1 && itransf==1 && iday==1 && icam==1
                                    NsamplesReference{opts.Cat(cat_names{cc})} = length(flist_splitted);
                                else
                                    subs_idxs =  round(linspace(1, length(flist_splitted), NsamplesReference{opts.Cat(cat_names{cc})}));
                                    subs_idxs = unique(subs_idxs);
                                    
                                    flist_splitted = flist_splitted(subs_idxs, :);
                                end
                            end
                            
                            nsmpl_xcat = length(flist_splitted);
                            
                            REG{opts.Cat(cat_names{cc})} = fullfile(flist_splitted(:,1), flist_splitted(:,2), flist_splitted(:,3), flist_splitted(:,4), flist_splitted(:,5));
                            
                            if strcmp(experiment, 'categorization')
                                if create_imnetlabels
                                    Yimnet{opts.Cat(cat_names{cc})} = ones(nsmpl_xcat, 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
                                end
                                Y{opts.Cat(cat_names{cc})} = ones(nsmpl_xcat, 1)*Y_digits(cat_names{cc});
                            elseif strcmp(experiment, 'identification')
                                Y{opts.Cat(cat_names{cc})} = cell2mat(values(Y_digits, flist_splitted(:,1)));
                            end
                            
                            for line=1:nsmpl_xcat
                                
                                fprintf(fid_Y, '%s/%s %d\n', cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Y{opts.Cat(cat_names{cc})}(line));
                                if strcmp(experiment, 'categorization') && create_imnetlabels
                                    fprintf(fid_Yimnet, '%s/%s %d\n', cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Yimnet{opts.Cat(cat_names{cc})}(line));
                                end
                                if create_fullpath
                                    fprintf(fid_Y_fullpath, '%s/%s/%s %d\n', dset_dir, cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Y{opts.Cat(cat_names{cc})}(line));
                                    if strcmp(experiment, 'categorization') && create_imnetlabels
                                        fprintf(fid_Yimnet_fullpath, '%s/%s/%s %d\n', dset_dir, cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Yimnet{opts.Cat(cat_names{cc})}(line));
                                    end
                                end
                            end
                            
                            disp([set_name ': ' cat_names(cc)]);
                            
                        end
                        
                        save(fullfile(output_dir_regtxt, ['REG_' set_name '.mat']), 'REG', '-v7.3');
                        
                        save(fullfile(output_dir_regtxt, ['Y_' set_name '.mat']), 'Y', '-v7.3');
                        fclose(fid_Y);
                        
                        if strcmp(experiment, 'categorization') && create_imnetlabels
                            Y = Yimnet;
                            save(fullfile(output_dir_regtxt, ['Yimnet_' set_name '.mat']), 'Y', '-v7.3');
                            fclose(fid_Yimnet);
                        end
                        
                        if create_fullpath
                            if strcmp(experiment, 'categorizaion') && create_imnetlabels
                                fclose(fid_Yimnet_fullpath);
                            end
                            fclose(fid_Y_fullpath);
                        end
                        
                    end
                    
                end
            end 
        end
    end
end
