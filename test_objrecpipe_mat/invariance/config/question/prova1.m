
%% Experiment kind
% Will be the prefix of question_dir
exp_kind = 'cat';

% use set_prefixes to indicate which sets are train, val and test:
%   'train' for training set (one)
%   'val' for validation set (one)
%   '' for test set (can be multiple)
% set_prefixes must have same size as your number of sets in setlist
% train and val sets are used to create the trainval folder
%
% if divide_trainval_perc == true 'train' and 'val' are  splitted
% and saved with their prefix 
% those sets which are empty are left as they are
% and saved without prefix
% 
setlist.set_prefixes = {'train_', 'val_', ''};


%% Whether to create fullpath registries
create_fullpath = false;

%% Whether to create also the ImageNet labels
setlist.create_imnetlabels = true;



%% Categories
setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };



%% Objects per category
Ntrials = 2;
setlist.obj_lists_all = cell(Ntrials,1);
for oo = 1:Ntrials
    setlist.obj_lists_all{oo} = {oo:oo+3, oo+4, oo+5};
end

%% Transformation
setlist.transf_lists_all = { 
    {1 1 1:setup_data.dset.Ntransfs} ...
    {2 2 []} ...
    {3 3 []} ...
    {4 4 []} ...
    {5 5 []} ...
    };

%% Day
setlist.day_mappings_all = { {1 1 2} };
setlist.day_lists_all = create_day_list(setlist.day_mappings_all, setup_data.dset.Days);

%% Camera
setlist.camera_lists_all = { {1 1 1} };



%% Keep the same #examples across datasets training | val | test
setlist.same_size = [0 0 0];



