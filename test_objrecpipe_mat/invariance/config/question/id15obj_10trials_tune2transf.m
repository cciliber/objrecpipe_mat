
%% Whether to create fullpath registries
create_fullpath = false;

%% Whether to create also the ImageNet labels
setlist.create_imnetlabels = true;



%% Categories
setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };



%% Objects per category
Ntrials = setup_data.dset.NobjPerCat;
setlist.obj_lists_all = cell(Ntrials,1);
for oo = 1:Ntrials
    setlist.obj_lists_all{oo} = {oo oo oo};
end

%% Transformation
setlist.transf_lists_all = { 
    {1 1 1:setup_data.dset.Ntransfs} ...
    {2 2 1:setup_data.dset.Ntransfs} ...
    {3 3 1:setup_data.dset.Ntransfs} ...
    {4 4 1:setup_data.dset.Ntransfs} ...
    {5 5 1:setup_data.dset.Ntransfs} ...
    };

%% Day
setlist.day_mappings_all = { {1 1 2} };
setlist.day_lists_all = create_day_list(setlist.day_mappings_all, setup_data.dset.Days);

%% Camera
setlist.camera_lists_all = { {1 1 1} };



%% Keep the same #examples across datasets training | val | test
setlist.same_size = [0 0 0];



