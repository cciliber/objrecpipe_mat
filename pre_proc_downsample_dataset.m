%% MACHINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%machine_tag = 'server';
%machine_tag = 'laptop_giulia_win';
machine_tag = 'laptop_giulia_lin';
    
root_path = init_machine(machine_tag);

%% DATASET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%dataset_name = 'Groceries_4Tasks';
%dataset_name = 'Groceries';
%dataset_name = 'Groceries_SingleInstance';
%dataset_name = 'iCubWorld0';
%dataset_name = 'iCubWorld20';
dataset_name = 'iCubWorld30';
%dataset_name = 'prova';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ICUBWORLDopts = ICUBWORLDinit(dataset_name);

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

% %% MODALITY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %modality = 'carlo_household_right';
% %modality = 'human';
% %modality = 'robot';
% %modality = 'lunedi22';
% %modality = 'martedi23';
% %modality = 'mercoledi24';
% %modality = 'venerdi26';
% modality = '';
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% if ~isempty(modality) && sum(strcmp(modality, modalities))==0
%     error('Modality does not match any existing modality.');
% end
% 
% %% TASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %task = 'background';
% %task = 'categorization';
% %task = 'demonstrator';
% %task = 'robot';
% task = '';
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% if ~isempty(task) && sum(strcmp(task, tasks))==0
%     error('Task does not match any existing task.');
% end
%
%% FOLDERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%objlist = obj_names;
%objlist = cat_names;
objlist = [];

%% DOWNSAMPLING PARAMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

downsample_factor = 3; 

%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
in_dataset_path = fullfile(root_path, [dataset_name '_nocrop']);
check_input_dir(in_dataset_path);

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

out_dataset_path = fullfile(root_path, [dataset_name '_nocrop_downsampled']);
check_output_dir(out_dataset_path);

%% REGISTRIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

registries_dir = fullfile(out_dataset_path, 'registries');
check_output_dir(registries_dir);

% INPUT 

in_registry_file = [];

in_registry_path = [];

% OUTPUT 

out_registry_file = [];

out_registry_path = [];
    
%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataset = Features.MyDataset('.ppm');

dataset.downsample(in_dataset_path, in_registry_path, objlist, out_registry_path, downsample_factor, out_dataset_path);
