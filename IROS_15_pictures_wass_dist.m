%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IROS 2015 pictures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
check_input_dir(working_dir);

%% OUTPUT

tmp=cell2mat(strcat('_', feature_names')');
figures_dir = fullfile(working_dir, 'figures', tmp(2:end));
check_output_dir(figures_dir);

%% load

day = {'lun', 'mar', 'mer', 'ven'};
ndays = length(day);

frame = [10 50 100 1000];
nframes = length(frame);

% histogram bins
binw = 0.05;
halfbinw = binw/2;
bins = 0:binw:1;
nbins = length(bins)-1;


rawdata = cell(ndays,nframes);

% load original data day by day
F = nframes;

loader = load(fullfile(working_dir, 'DATA_lun.mat'));
for f=F
    rawdata{1,f} = loader.DATA{f};
end

loader = load(fullfile(working_dir, 'DATA_mar.mat'));
for f=F
    rawdata{2,f} = loader.DATA{f};
end

loader = load(fullfile(working_dir, 'DATA_mer_1-26_100-142.mat'));
for f=F
    rawdata{3,f} = loader.DATA{f};
end

loader = load(fullfile(working_dir, 'DATA_ven_1-28_100-144.mat'));
for f=F
    rawdata{4,f} = loader.DATA{f};
end

T = length(rawdata{1,f});

%% compute histograms and wass distances

F = nframes;

mean_acc_over_nuples = zeros(ndays, T);
std_acc_over_nuples = zeros(ndays, T);

hist_acc_over_nuples_normalized = zeros(T, ndays, nbins);

hist_distances = zeros(T, ndays, ndays);

for d=1:ndays
    for t=1:T
        
        accvector = [rawdata{d,F}{t}.acc];
        
        mean_acc_over_nuples(d, t) = mean(accvector);
        std_acc_over_nuples(d, t) = std(accvector);
        
        hist_acc_over_nuples_normalized(t, d, :) = histcounts(accvector, bins, 'Normalization','probability');
        
    end
end

for t=1:T
    hist_distances(t, :, :) = wass_dist(squeeze(hist_acc_over_nuples_normalized(t, :, :)),squeeze(hist_acc_over_nuples_normalized(t, :, :)));
end

figure
for t=1:T
    
    subplot(7,4,t)
    imagesc(squeeze(hist_distances(t, :, :))), colorbar
end

figure, imagesc(squeeze(mean(hist_distances(1:26, :, :),1)));

%% compute correlations

acc_correlations = zeros(T, ndays, ndays);

nsamples = 26;
for t=1:T
    
    currn = nsamples;
    for d=1:ndays
        currn = min(currn, length([rawdata{d,F}{t}.acc]));
    end
    
    accmatrix = zeros(currn, ndays);
    for d=1:ndays
        
        accvector = [rawdata{d,F}{t}.acc];
        accmatrix(:,d) = accvector(1:currn);
    end
    
    acc_correlations(t, :, :) = corr(accmatrix);
end
