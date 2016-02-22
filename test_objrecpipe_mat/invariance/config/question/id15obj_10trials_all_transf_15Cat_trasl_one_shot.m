
%% Whether to create fullpath registries
create_fullpath = false;

%% Whether to create also the ImageNet labels
setlist.create_imnetlabels = true;



%% Categories
setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
% setlist.cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };
% setlist.cat_idx_all = { [3 8] };



%% Objects per category
setlist.obj_lists_all = {{1:7 8:9 10}};


%% Transformation
setlist.transf_lists_all = { 
    {1:5 1:5 [2 4 5]} ...
    };

%% Day
setlist.day_mappings_all = { {1 1 1:2} };
setlist.day_lists_all = create_day_list(setlist.day_mappings_all, setup_data.dset.Days);

%% Camera
setlist.camera_lists_all = { {1 1 1} };



%% Keep the same #examples across datasets training | val | test
setlist.same_size = [0 0 0];



