function fcn_extract_feat(root_path, dataset_name, modality, task, properties, input_dir, output_dir, input_extension, output_extension)

%% DATASET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ICUBWORLDopts = ICUBWORLDinit(dataset_name);

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

%% MODALITY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(modality) 
    if sum(strcmp(modality, modalities))==0
        error('Modality does not match any existing modality.');
    end
end

%% TASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(task) 
    if sum(strcmp(task, tasks))==0
        error('Task does not match any existing task.');
    end
end

%% Feature INSTANTIATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch properties.feat_type
   
    case 'MyCaffe'
        feat_train = Features.MyCaffe(properties.install_dir, properties.mode, properties.path_dataset_mean, properties.model_def_file, properties.model_file, properties.oversample);
        feat_test = Features.MyCaffe(properties.install_dir, properties.mode, properties.path_dataset_mean, properties.model_def_file, properties.model_file, properties.oversample);
    
    case 'MyOverFeat'
        feat_train = Features.MyOverFeat(properties.install_dir, properties.mode, properties.net_model, properties.out_layer);
        feat_test = Features.MyOverFeat(properties.install_dir, properties.mode, properties.net_model, properties.out_layer);
        
    case 'MyHMAX'
        feat_train = Features.MyHMAX(properties.install_dir, properties.mode, properties.NScales, properties.ScaleFactor, properties.NOrientations, properties.S2RFCount, properties.BSize);
        feat_test = Features.MyHMAX(properties.install_dir, properties.mode, properties.NScales, properties.ScaleFactor, properties.NOrientations, properties.S2RFCount, properties.BSize);
    
    case 'MySIFT'
        feat_train = Features.MySIFT(properties.step, properties.scale, properties.use_lowe, properties.dense, properties.normalize);
        feat_test =  Features.MySIFT(properties.step, properties.scale, properties.use_lowe, properties.dense, properties.normalize);
        
    case 'MyPCA'
        feat_train = Features.MyPCA();
        feat_test = Features.MyPCA();
        
    case 'MySC'
        feat_train = Features.MySC(properties.pyramid, properties.beta, properties.gamma, properties.num_iters);
        feat_test = Features.MySC(properties.pyramid, properties.beta, properties.gamma, properties.num_iters);
        
    case 'MyFV'
        feat_train = Features.MyFV(properties.pyramid);
        feat_test = Features.MyFV(properties.pyramid);
        
    otherwise
end

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
in_path = fullfile(root_path, input_dir);
check_input_dir(in_path);
        
in_train_path = fullfile(in_path, 'train', modality);
in_test_path = fullfile(in_path, 'test', modality, task);

folders_to_select = [];
%folders_to_select = cat_names;
%folders_to_select = obj_names; 
% folders_to_select = {'banana'; 'box_brown'; ...}
% folders_to_select = {'bananas', 'banana1', 'demo2'; 'lemons', 'demo1'; 'pears'}

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if modality_out is 'file'/'both' then 
% out_train/test_path and properties.output_extension are mandatory
% if modality_out is 'wspace' are ignored and can be []
modality_out = 'file'; % or 'wspace' or 'both'

out_path = fullfile(root_path, output_dir);
check_output_dir(out_path);

out_train_path = fullfile(out_path, 'train', modality);
out_test_path = fullfile(out_path, 'test', modality, task);

%% REGISTRIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

registries_dir = fullfile(root_path, fileparts(output_dir), 'registries');

switch properties.feat_type
    
    case {'MyCaffe', 'MyOverFeat', 'MyHMAX', 'MySIFT'}
        
        check_output_dir(registries_dir);
        
        % INPUT
        
        in_registry_train_file = [];
        in_registry_test_file = [];
        
        in_registry_train_path = [];
        in_registry_test_path = [];
        
        % OUTPUT
        
        if ~isempty(modality)
            out_registry_train_file = [dataset_name '_train_' modality '.txt'];
        else
            out_registry_train_file = [dataset_name '_train.txt'];
        end
        if ~isempty(modality) && ~isempty(task)
            out_registry_test_file = [dataset_name '_test_' modality '_' task '.txt'];
        elseif ~isempty(modality)
            out_registry_test_file = [dataset_name '_test_' modality '.txt'];
        elseif ~isempty(task)
            out_registry_test_file = [dataset_name '_test_' task '.txt'];
        else
            out_registry_test_file = [dataset_name '_test.txt'];
        end
        
        out_registry_train_path = fullfile(registries_dir, out_registry_train_file);
        out_registry_test_path = fullfile(registries_dir, out_registry_test_file);
        
    case {'MyPCA', 'MySC', 'MyFV'}
        
        check_input_dir(registries_dir);
        
        % INPUT
        
        if ~isempty(modality)
            in_registry_train_file = [dataset_name '_train_' modality '.txt'];
        else
            in_registry_train_file = [dataset_name '_train.txt'];
        end
        if ~isempty(modality) && ~isempty(task)
            in_registry_test_file = [dataset_name '_test_' modality '_' task '.txt'];
        elseif ~isempty(modality)
            in_registry_test_file = [dataset_name '_test_' task '.txt'];
        elseif ~isempty(task)
            in_registry_test_file = [dataset_name '_test_' modality '.txt'];
        else
            in_registry_test_file = [dataset_name '_test.txt'];
        end
        
        in_registry_train_path = fullfile(registries_dir, in_registry_train_file);
        in_registry_test_path = fullfile(registries_dir, in_registry_test_file);
        
        % OUTPUT
        
        out_registry_train_file = [];
        out_registry_test_file = [];
        
        out_registry_train_path = [];
        out_registry_test_path = [];
        
        
    otherwise
end
   
%% DICTIONARY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dictionary = []; % if it's not part of this feature

if isfield(properties, 'learn_dict')
    
    if (properties.learn_dict)
        
        if ~isempty(properties.dictionary)
            dictionary = fullfile(out_path, properties.dictionary); % either .bin or .mat or .txt
        end
        
        feat_train.dictionarize_file(in_train_path, in_registry_train_path, input_extension, folders_to_select, properties.dict_size, properties.n_randfeat, out_registry_train_path, modality_out, dictionary);
        %feat_train.dictionarize_wspace(feat_matrix, properties.dict_size, modality_out, dictionary);
        
    else
       
        if isnumeric(properties.dictionary)
            dictionary = properties.dictionary;
        else
            dictionary = fullfile(out_path, properties.dictionary); % either .bin or .mat or .txt
        end
    
    end
    
end

%% EXTRACTION! %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

feat_train.extract_file(in_train_path, in_registry_train_path, input_extension, folders_to_select, out_registry_train_path, dictionary, modality_out, out_train_path, output_extension);
%feat_train.extract_wspace(feat_matrix, featsize_matrix, grid_matrix, gridsize_matrix, imsize_matrix, dictionary, modality_out, out_train_path, output_extension);

feat_test.extract_file(in_test_path, in_registry_test_path, input_extension, folders_to_select, out_registry_test_path, dictionary, modality_out, out_test_path, output_extension);
%feat_test.extract_wspace(feat_matrix, featsize_matrix, grid_matrix, gridsize_matrix, imsize_matrix, dictionary, modality_out, out_test_path, output_extension);