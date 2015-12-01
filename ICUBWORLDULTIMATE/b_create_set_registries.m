%% Setup

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% Dataset info

dset_info = fullfile('/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat)';
%obj_names = keys(opts.Obj)';
transf_names = keys(opts.Transfs)';
day_names = keys(opts.Days)';
camera_names = keys(opts.Cameras)';

Ncat = opts.Cat.Count;
Nobj = opts.Obj.Count;
NobjPerCat = opts.ObjPerCat;
Ntransfs = opts.Transfs.Count;
Ndays = opts.Days.Count;
Ncameras = opts.Cameras.Count;

%% Whether to create the full path registries (e.g. for DIGITS)

create_fullpath = false;

if create_fullpath
    dset_dirs = {'/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb60_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid256_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree'};

    choose_dset = 1;
else
    dset_dirs = [];
    choose_dset = [];
end

%% Input registries from which to select the subsets

reg_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries/full_registries';
check_input_dir(reg_dir);

%% Experiment kind

%experiment = 'categorization';
experiment = 'identification';

if strcmp(experiment, 'identification')
    % validation percentage
    validation_perc = 0.5;
    validation_step = 1/validation_perc;
else
    validation_perc = [];
    validation_step = [];
end

%% Output root dir for registries of the subsets

output_dir_regtxt = fullfile('/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries', experiment);

%% Default sets

set_names = {'train_', 'val_', 'test_'};
Nsets = length(set_names);

%% Choose categories

%cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];
%cat_idx = [3 8 9 11 12 13 14 15 19 20];
cat_idx = [9 13];
%cat_idx = [8 9 13 14 15];

output_dir_regtxt = fullfile(output_dir_regtxt, ['Ncat_' num2str(length(cat_idx))]);
check_output_dir(output_dir_regtxt);

output_dir_regtxt = fullfile(output_dir_regtxt, strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
check_output_dir(output_dir_regtxt);

%% Choose objects per category (for each set)

if strcmp(experiment, 'categorization')
    obj_lists = {4:6, 4:6, 4:6};
elseif strcmp(experiment, 'identification')
    obj_list = 4:6;
    obj_lists = {obj_list, obj_list, obj_list};
end

%% Assign labels

fid_labels = fopen(fullfile(output_dir_regtxt, 'labels.txt'), 'w');

if strcmp(experiment, 'categorization')
    
    Ynew_digit = containers.Map (cat_names(cat_idx), 0:(length(cat_idx)-1)); 
    for line=cat_idx
        fprintf(fid_labels, '%s %d\n', cat_names{line}, Ynew_digit(cat_names{line}));
    end

elseif strcmp(experiment, 'identification')
    
    % if we want to do identification then all objects are both in the
    % 'trainval' and in the 'test' sets (obj_lists{1}==obj_lists{2})
    
    obj_names = repmat(cat_names(cat_idx)', length(obj_lists{1}),1);
    obj_names = obj_names(:);
    tmp = repmat(obj_lists{1}', length(cat_idx),1);
    obj_names = strcat(obj_names, strrep(mat2cell(num2str(tmp), ones(length(tmp),1)), ' ', ''));
    
    Ynew_digit = containers.Map (obj_names, 0:(length(obj_names)-1)); 
    
    for line=1:length(obj_names)
        fprintf(fid_labels, '%s %d\n', obj_names{line}, Ynew_digit(obj_names{line}));
    end
end

fclose(fid_labels);

%% Choose transformation, day, camera (for each set)

%transf_lists = {1:Ntransfs, 1:Ntransfs, 1:Ntransfs};
transf_lists = {2, 1, 3};
%transf_lists = {[2 3], [2 3], [2 3]};

day_mappings = {1, 1, [1 2]};
day_lists = cell(Nsets,1);
tmp = keys(opts.Days);
for ii=1:Nsets
    for dd=1:length(day_mappings{ii})
        tmp1 = tmp(cell2mat(values(opts.Days))==day_mappings{ii}(dd))';
        tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
        day_lists{ii} = [day_lists{ii} tmp2];
    end
end

%camera_lists = {[1 2], [1 2], [1 2]};
camera_lists = {1, 1, 1};

%% Create set names

for ii=1:Nsets
    set_names{ii} = [set_names{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
    set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
    set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
    set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
end

%% Create the registries REG and the true labels Y (ImageNet labels), Ynew

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    day_list = day_lists{sidx};
    obj_list = obj_lists{sidx};
    transf_list = transf_lists{sidx};
    camera_list = camera_lists{sidx};
    
    REG = cell(Ncat, 1);
    
    Ynew = cell(Ncat, 1);
    fid_Ynew = fopen(fullfile(output_dir_regtxt, [set_name '_Ynew.txt']), 'w');
    
    if strcmp(experiment, 'categorization')
        Y = cell(Ncat, 1);
        fid_Y = fopen(fullfile(output_dir_regtxt, [set_name '_Y.txt']), 'w');
    end
    
    if create_fullpath
        if strcmp(experiment, 'categorizaion')
            fid_Y_fullpath = fopen(fullfile(output_dir_regtxt, [set_name '_fullpath_Y.txt']), 'w');
        end
        fid_Ynew_fullpath = fopen(fullfile(output_dir_regtxt, [set_name '_fullpath_Ynew.txt']), 'w');
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
        
        if strcmp(experiment, 'identification')
           if strncmp(set_name, 'tra', 3)
               flist_splitted(1:validation_step:end,:) = [];
           elseif strncmp(set_name, 'val', 3)
               flist_splitted = flist_splitted(1:validation_step:end,:);
           end
        end
        
        REG{opts.Cat(cat_names{cc})} = fullfile(flist_splitted(:,1), flist_splitted(:,2), flist_splitted(:,3), flist_splitted(:,4), flist_splitted(:,5));
        
        if strcmp(experiment, 'categorization')
            Y{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
            Ynew{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*Ynew_digit(cat_names{cc});
        elseif strcmp(experiment, 'identification')
            Ynew{opts.Cat(cat_names{cc})} = cell2mat(values(Ynew_digit, flist_splitted(:,1)));
        end
        
        for line=1:length(REG{opts.Cat(cat_names{cc})})
            
            fprintf(fid_Ynew, '%s/%s %d\n', cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Ynew{opts.Cat(cat_names{cc})}(line));
            if strcmp(experiment, 'categorization')
                fprintf(fid_Y, '%s/%s %d\n', cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Y{opts.Cat(cat_names{cc})}(line));
            end
            if create_fullpath
                fprintf(fid_Ynew_fullpath, '%s/%s/%s %d\n', dset_dirs{choose_dset}, cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Ynew{opts.Cat(cat_names{cc})}(line));
                if strcmp(experiment, 'categorization')
                    fprintf(fid_Y_fullpath, '%s/%s/%s %d\n', dset_dirs{choose_dset}, cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Y{opts.Cat(cat_names{cc})}(line));
                end
            end
        end
        
        disp([set_name ': ' cat_names(cc)]);
        
    end
    
    save(fullfile(output_dir_regtxt, ['REG_' set_name '.mat']), 'REG', '-v7.3');
    
    if strcmp(experiment, 'categorization')
        save(fullfile(output_dir_regtxt, ['Y_' set_name '.mat']), 'Y', '-v7.3');
        fclose(fid_Y);
    end
    
    save(fullfile(output_dir_regtxt, ['Ynew_' set_name '.mat']), 'Ynew', '-v7.3');
    fclose(fid_Ynew);
    
    if create_fullpath
        if strcmp(experiment, 'categorizaion')
            fclose(fid_Y_fullpath);
        end
        fclose(fid_Ynew_fullpath);
    end
    
end