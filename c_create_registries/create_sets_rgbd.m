%% Setup

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

DATA_DIR = '/data/giulia';

%% Whether to create the full-path registries (e.g. for DIGITS)

create_fullpath = true;

if create_fullpath
    dset_dir = fullfile(DATA_DIR, 'rgbd_dataset');
end

%% Set up the esperiments

% Default sets that are created

set_names_prefix = {'trainval_', 'test_'};
Nsets = length(set_names_prefix);

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Whether to create the ImageNet labels

if strcmp(experiment, 'categorization')
    %create_imnetlabels = true;
    create_imnetlabels = false;
else
    create_imnetlabels = [];
end

% Choose categories

reg_dir = fullfile(DATA_DIR, 'rgbd_registries');
check_input_dir(reg_dir);

fid = fopen(fullfile(reg_dir, 'rgbd.txt'));
cat_names = textscan(fid, '%s');
cat_names = cat_names{1};
fclose(fid);
Ncat = length(cat_names);

cat_idx_all = {1:Ncat};

% Assign the Y labels

fid_labels = fopen(fullfile(reg_dir, 'labels.txt'), 'w');
if strcmp(experiment, 'categorization')
    
    Y_digits = containers.Map (cat_names, 0:(Ncat-1) );
    for line=1:Ncat
        fprintf(fid_labels, '%s %d\n', cat_names{line}, Y_digits(cat_names{line}));
    end
    
end
fclose(fid_labels);

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    Ntrials = 10;
    
    obj_lists_all = cell(Ntrials,1);
    
    out_ext = '.png';
    
    dset = Features.GenericFeature();
    dset.assign_registry_and_tree_from_folder(dset_dir, [], [], [], out_ext);
    crop_idxs = ~cell2mat(cellfun(@isempty, regexp(dset.Registry, '_crop.png'), 'UniformOutput', 0));
    dset.Registry = dset.Registry(crop_idxs);
    dset.Registry = dset.Registry(5:5:end);
    flist_splitted = regexp(dset.Registry, '/', 'split');
    flist_splitted = vertcat(flist_splitted{:});
    
    for itr=1:Ntrials
        
        fid = fopen(fullfile(reg_dir, ['tr' num2str(itr) '.txt']));
        obj_names = textscan(fid, '%s');
        obj_names = obj_names{1};
        fclose(fid);
        
        in_test = zeros(length(flist_splitted),1);        
        for icat=1:length(obj_names)
            tmp = strcmp(flist_splitted(:, 2), obj_names(icat));
            in_test = in_test + tmp;
        end
        
        reg_test = dset.Registry(in_test==1);
        flist_splitted_test = flist_splitted(in_test==1, :);
        
        reg_trainval = dset.Registry(in_test==0);
        flist_splitted_trainval = flist_splitted(in_test==0, :);
        
        % create REG 
        
        [C, ia, ic] = unique(flist_splitted_test(:,1)); % [C,ia,ic] = unique(A)
        n_test = hist(ic, unique(ic));
        [C, ia, ic] = unique(flist_splitted_trainval(:,1)); % [C,ia,ic] = unique(A)
        n_trainval = hist(ic, unique(ic));
        
        REG_test = mat2cell(reg_test, n_test);
        REG_trainval = mat2cell(reg_trainval, n_trainval);
        
        % create txt registries
        
        Y_test = zeros(length(reg_test), 1);
        Y_trainval = zeros(length(reg_trainval), 1);
        
        fid = fopen(fullfile(reg_dir, ['tr' num2str(itr) '_test.txt']), 'w');
        for line=1:length(reg_test)
            Y_test(line) = Y_digits(flist_splitted_test{line, 1});
            fprintf(fid, '%s %d\n', reg_test{line}, Y_test(line));
        end
        fclose(fid);
        
        fid = fopen(fullfile(reg_dir, ['tr' num2str(itr) '_trainval.txt']), 'w');
        for line=1:length(reg_trainval)
            Y_trainval(line) = Y_digits(flist_splitted_trainval{line, 1});
            fprintf(fid, '%s %d\n', reg_trainval{line}, Y_trainval(line));
        end
        fclose(fid);
        
        % create Y
        
        Y_test = mat2cell(Y_test, n_test);
        Y_trainval = mat2cell(Y_trainval, n_trainval);
        
        % save REG and Y
        
        REG = REG_test;
        Y = Y_test;
        save(fullfile(reg_dir, ['tr' num2str(itr) '_REG_test.mat']), 'REG', '-v7.3');
        save(fullfile(reg_dir, ['tr' num2str(itr) '_Y_test.mat']), 'Y', '-v7.3');

        REG = REG_trainval;
        Y = Y_trainval;
        save(fullfile(reg_dir, ['tr' num2str(itr) '_REG_trainval.mat']), 'REG', '-v7.3');
        save(fullfile(reg_dir, ['tr' num2str(itr) '_Y_trainval.mat']), 'Y', '-v7.3');
        
    end
    
end

% %% For each experiment, go!
%
%         % Create the registries REG and the labels Yimnet (ImageNet labels), Y
%
%         for sidx=1:Nsets
%
%             set_name = set_names{sidx};
%
%             day_list = day_lists{sidx};
%             obj_list = obj_lists{sidx};
%             transf_list = transf_lists{sidx};
%             camera_list = camera_lists{sidx};
%
%             REG = cell(Ncat, 1);
%
%             Y = cell(Ncat, 1);
%             fid_Y = fopen(fullfile(output_dir_regtxt, [set_name '_Y.txt']), 'w');
%
%             if strcmp(experiment, 'categorization') && create_imnetlabels
%                 Yimnet = cell(Ncat, 1);
%                 fid_Yimnet = fopen(fullfile(output_dir_regtxt, [set_name '_Yimnet.txt']), 'w');
%             end
%
%             if create_fullpath
%                 if strcmp(experiment, 'categorization') && create_imnetlabels
%                     fid_Yimnet_fullpath = fopen(fullfile(output_dir_regtxt_fullpath, [set_name '_fullpath_Yimnet.txt']), 'w');
%                 end
%                 fid_Y_fullpath = fopen(fullfile(output_dir_regtxt_fullpath, [set_name '_fullpath_Y.txt']), 'w');
%             end
%
%             for cc=cat_idx
%
%                 reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
%
%                 loader = Features.GenericFeature();
%                 loader.assign_registry_and_tree_from_file(reg_path, [], []);
%
%                 flist_splitted = regexp(loader.Registry, '/', 'split');
%                 clear loader;
%                 flist_splitted = vertcat(flist_splitted{:});
%                 flist_splitted(:,1) = [];
%
%                 tobeloaded = zeros(length(flist_splitted), 1);
%
%                 for oo=obj_list
%
%                     oo_tobeloaded = strcmp(flist_splitted(:,1), strcat(cat_names{cc}, num2str(oo)));
%
%                     for tt=transf_list
%
%                         tt_tobeloaded = oo_tobeloaded & strcmp(flist_splitted(:,2), transf_names(tt));
%
%                         for dd=day_list
%
%                             dd_tobeloaded = tt_tobeloaded & strcmp(flist_splitted(:,3), day_names(dd));
%
%                             for ee=camera_list
%
%                                 ee_tobeloaded = dd_tobeloaded & strcmp(flist_splitted(:,4), camera_names(ee));
%
%                                 tobeloaded = tobeloaded + ee_tobeloaded;
%
%                             end
%                         end
%                     end
%                 end
%
%                 flist_splitted = flist_splitted(tobeloaded==1, :);
%
%                 if strcmp(experiment, 'identification') && divide_trainval_perc==true
%                     if strncmp(set_name, 'tra', 3)
%                         flist_splitted(1:validation_step:end,:) = [];
%                     elseif strncmp(set_name, 'val', 3)
%                         flist_splitted = flist_splitted(1:validation_step:end,:);
%                     end
%                 end
%
%                 REG{opts.Cat(cat_names{cc})} = fullfile(flist_splitted(:,1), flist_splitted(:,2), flist_splitted(:,3), flist_splitted(:,4), flist_splitted(:,5));
%
%                 if strcmp(experiment, 'categorization')
%                     if create_imnetlabels
%                         Yimnet{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
%                     end
%                     Y{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*Y_digits(cat_names{cc});
%                 elseif strcmp(experiment, 'identification')
%                     Y{opts.Cat(cat_names{cc})} = cell2mat(values(Y_digits, flist_splitted(:,1)));
%                 end
%
%                 for line=1:length(REG{opts.Cat(cat_names{cc})})
%
%                     fprintf(fid_Y, '%s/%s %d\n', cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Y{opts.Cat(cat_names{cc})}(line));
%                     if strcmp(experiment, 'categorization') && create_imnetlabels
%                         fprintf(fid_Yimnet, '%s/%s %d\n', cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Yimnet{opts.Cat(cat_names{cc})}(line));
%                     end
%                     if create_fullpath
%                         fprintf(fid_Y_fullpath, '%s/%s/%s %d\n', dset_dir, cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Y{opts.Cat(cat_names{cc})}(line));
%                         if strcmp(experiment, 'categorization') && create_imnetlabels
%                             fprintf(fid_Yimnet_fullpath, '%s/%s/%s %d\n', dset_dir, cat_names{cc}, REG{opts.Cat(cat_names{cc})}{line}, Yimnet{opts.Cat(cat_names{cc})}(line));
%                         end
%                     end
%                 end
%
%                 disp([set_name ': ' cat_names(cc)]);
%
%             end
%
%             save(fullfile(output_dir_regtxt, ['REG_' set_name '.mat']), 'REG', '-v7.3');
%
%             save(fullfile(output_dir_regtxt, ['Y_' set_name '.mat']), 'Y', '-v7.3');
%             fclose(fid_Y);
%
%             if strcmp(experiment, 'categorization') && create_imnetlabels
%                 Y = Yimnet;
%                 save(fullfile(output_dir_regtxt, ['Yimnet_' set_name '.mat']), 'Y', '-v7.3');
%                 fclose(fid_Yimnet);
%             end
%
%             if create_fullpath
%                 if strcmp(experiment, 'categorizaion') && create_imnetlabels
%                     fclose(fid_Yimnet_fullpath);
%                 end
%                 fclose(fid_Y_fullpath);
%             end
%
%         end
%
%     end
% end
