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

ICUBWORLDopts = ICUBWORLDinit('iCubWorld28');

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

%% output

input_dir = fullfile('/data/giulia/DATASETS/iCubWorld28_experiments/CaffeNet_finetuned/features');
check_input_dir(input_dir);
 
%% go!

acc_gurls = zeros(4, 4);
acc_carlo = zeros(4, 4);

for ii=1:length(modalities)
    
    true_path = fullfile('/data/giulia/DATASETS/iCubWorld28/test', modalities{ii});
     
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_folder(true_path, [], obj_names, [], []);
    
    Ytrue = loader.Y;
    
    for jj = 1:length(modalities)
        
        feat_rootpath = fullfile(input_dir, ['TRday' num2str(jj) 'TEday' num2str(ii)]);
        
        loader.load_feat(feat_rootpath, [], '.txt', [], obj_names, [], []);
    
        [~, Ypred] = max(loader.Feat', [], 2);
        
        [acc_carlo(jj,ii), C] = compute_accuracy(Ytrue, Ypred, 'carlo');
        acc_gurls(jj,ii) = compute_accuracy(Ytrue, Ypred, 'gurls');

    end
    
end

%% go!

acc_gurls_cum = zeros(6, 4);
acc_carlo_cum = zeros(6, 4);

models = {'day1day2', 'day1day2day3', 'day1day2day3day4', 'day12', 'day123', 'day1234'};

for ii=1:length(modalities)
    
    true_path = fullfile('/data/giulia/DATASETS/iCubWorld28/test', modalities{ii});
     
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_folder(true_path, [], obj_names, [], []);
    
    Ytrue = loader.Y;
    
    for jj=1:length(models)
        
        feat_rootpath = fullfile(input_dir, ['TR' models{jj} 'TEday' num2str(ii)]);
        loader.load_feat(feat_rootpath, [], '.txt', [], obj_names, [], []);
        [~, Ypred] = max(loader.Feat', [], 2);
        
        [acc_carlo_cum(jj, ii), C] = compute_accuracy(Ytrue, Ypred, 'carlo');
        acc_gurls_cum(jj, ii) = compute_accuracy(Ytrue, Ypred, 'gurls');
        
%      figure, imagesc(C12)
%      set(gca, 'YTickLabels', obj_names)
%      set(gca, 'XTickLabels', obj_names, 'XTickLabelRotation', 45)
%      grid on
%      colorbar

    end
end

acc_global = [acc_carlo; acc_carlo_cum];

figure
subplot(1,3,1)
plot(acc_global(1:4,:)')
ylim([0.6 1])
legend({'day1', 'day2', 'day3', 'day4'})
subplot(1,3,2)
plot(acc_global(5:7,:)')
ylim([0.6 1])
legend({'day1day2', 'day1day2day3', 'day1day2day3day4'})
subplot(1,3,3)
plot(acc_global(8:10,:)')
ylim([0.6 1])
legend({'day12', 'day123', 'day1234'})



