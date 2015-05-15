%% merge results

%% MACHINE

%machine_tag = 'server';
machine_tag = 'laptop_giulia_win';
%machine_tag = 'laptop_giulia_lin';

root_path = init_machine(machine_tag);

%% DATASET NAME

dataset_name = 'iCubWorld30';

%% MODALITY

%modality = 'lunedi22';
%modality = 'martedi23';
%modality = 'mercoledi24';
%modality = 'venerdi26';
modality = '';

%% TASK

task = '';

%% FEATURES

%feature_names = {'sc_d1024_iros', 'overfeat_small_default'};
%feature_names = {'sc_d512', 'overfeat_small_default'};
%feature_names = {'sc_d1024_iros'};
%feature_names = {'sc_d512'};
%feature_names = {'overfeat_small_default'};
%feature_names = {'caffe_prova', 'overfeat_small_default', 'sc_d512'};
%feature_names = {'caffe_centralcrop_meanimagenet2012', 'overfeat_small_default', 'sc_d512'};
feature_names = {'caffe_centralcrop_meanimagenet2012'};

feature_number = length(feature_names);

%% INPUT 

working_dir = fullfile(root_path, [dataset_name '_experiments'], 'IROS_2015');

%% OUTPUT

tmp=cell2mat(strcat('_', feature_names')');
figures_dir = fullfile(working_dir, 'figures', tmp(2:end));

%% load

day = {'lun', 'mar', 'mer', 'ven'};
ndays = length(day);

frame = [10 50 100 1000];
nframes = length(frame);

% ven

loader1 = load(fullfile(working_dir, 'definitivi', 'srv_DATA_mer.mat'));
loader2 = load(fullfile(working_dir, 'definitivi', 'ws_DATA_mer.mat'));

DATA = cell(nframes,1);

T = 27;

for f=1:nframes
    
    DATA{f} = cell(T,1);
    for t=1:T
        
        DATA{f}{t} = [loader1.DATA{f}{t}, loader2.DATA{f}{t}];
      
    end
end

save(fullfile(working_dir, 'definitivi', 'DATA_mer.mat'), 'DATA');
