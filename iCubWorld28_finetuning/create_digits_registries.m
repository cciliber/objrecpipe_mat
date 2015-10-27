%% setup 

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';

run('/data/REPOS/GURLS/gurls/utils/gurls_install.m');

curr_dir = pwd;
cd('/data/REPOS/vlfeat-0.9.20/toolbox');
vl_setup;
cd(curr_dir);
clear curr_dir;

addpath(genpath(FEATURES_DIR));

%% dataset

dset_path = '/data/giulia/DATASETS/iCubWorld28_jpg';

ICUBWORLDopts = ICUBWORLDinit('iCubWorld28');

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

%% output

output_dir = fullfile('/data/giulia/DATASETS/iCubWorld28_digit_registries');
check_output_dir(output_dir);
 
out_ext = '.jpg';

val_frac = 0.25;

%% go!

% compute
for ii=2:length(modalities)
    
    loaderTRVAL = Features.GenericFeature();
    loaderTE = Features.GenericFeature();
    
    % split validation/train
    
    in_path = fullfile(dset_path, 'train');
    loaderTRVAL.assign_registry_and_tree_from_folder(in_path, modalities(1:ii)', obj_names, [], []);
    
    val_registry = loaderTRVAL.Registry(1:(1/val_frac):end);
    tr_registry = loaderTRVAL.Registry;
    tr_registry(1:(1/val_frac):end) = [];
    
    val_path = fullfile(output_dir, ['VAL' [modalities{1:ii}] '.txt']);
    tr_path = fullfile(output_dir, ['TR' [modalities{1:ii}] '.txt']);
    
    y_val = create_y(val_registry, obj_names, []);
    [~, y_val] = max(y_val, [], 2);
    y_tr = create_y(tr_registry, obj_names, []);
    [~, y_tr] = max(y_tr, [], 2);
    
    [reg_dir, ~, ~] = fileparts(val_path);
    check_output_dir(reg_dir);
    fid = fopen(val_path,'w');
    if (fid==-1)
        fprintf(2, 'Cannot open file: %s', val_path);
    end
    for line_idx=1:length(y_val)
        fprintf(fid, '%s\n', [val_registry{line_idx} out_ext  ' ' num2str(y_val(line_idx)-1)]);
    end
    fclose(fid);
    
    [reg_dir, ~, ~] = fileparts(tr_path);
    check_output_dir(reg_dir);
    fid = fopen(tr_path,'w');
    if (fid==-1)
        fprintf(2, 'Cannot open file: %s', tr_path);
    end
    for line_idx=1:length(y_tr)
        fprintf(fid, '%s\n', [tr_registry{line_idx} out_ext  ' ' num2str(y_tr(line_idx)-1)]);
    end
    fclose(fid);
    
    % test 
    
    out_path = fullfile(output_dir, ['TE' [modalities{1:ii}] '.txt']);
    in_path = fullfile(dset_path, 'test');
    loaderTE.assign_registry_and_tree_from_folder(in_path, modalities(1:ii)', obj_names, out_path, out_ext);
    
end

for ii=1:length(modalities)
    
    loaderTRVAL = Features.GenericFeature();
    loaderTE = Features.GenericFeature();

    % split validation/train
    
    in_path = fullfile(dset_path, 'train', modalities{ii});
    loaderTRVAL.assign_registry_and_tree_from_folder(in_path, [], obj_names, [], []);
    
    val_registry = loaderTRVAL.Registry(1:(1/val_frac):end);
    tr_registry = loaderTRVAL.Registry;
    tr_registry(1:(1/val_frac):end) = [];
    
    val_path = fullfile(output_dir, ['VAL' modalities{ii} '.txt']);
    tr_path = fullfile(output_dir, ['TR' modalities{ii} '.txt']);
    
    y_val = create_y(val_registry, obj_names, []);
    [~, y_val] = max(y_val, [], 2);
    y_tr = create_y(tr_registry, obj_names, []);
    [~, y_tr] = max(y_tr, [], 2);
    
    [reg_dir, ~, ~] = fileparts(val_path);
    check_output_dir(reg_dir);
    fid = fopen(val_path,'w');
    if (fid==-1)
        fprintf(2, 'Cannot open file: %s', val_path);
    end
    for line_idx=1:length(y_val)
        fprintf(fid, '%s\n', [val_registry{line_idx} out_ext  ' ' num2str(y_val(line_idx)-1)]);
    end
    fclose(fid);
    
    [reg_dir, ~, ~] = fileparts(tr_path);
    check_output_dir(reg_dir);
    fid = fopen(tr_path,'w');
    if (fid==-1)
        fprintf(2, 'Cannot open file: %s', tr_path);
    end
    for line_idx=1:length(y_tr)
        fprintf(fid, '%s\n', [tr_registry{line_idx} out_ext  ' ' num2str(y_tr(line_idx)-1)]);
    end
    fclose(fid);
    
    % test
    
    out_path = fullfile(output_dir, ['TE' modalities{ii} '.txt']);
    in_path = fullfile(dset_path, 'test', modalities{ii});
    loaderTE.assign_registry_and_tree_from_folder(in_path, [], obj_names, out_path, out_ext);
    
end