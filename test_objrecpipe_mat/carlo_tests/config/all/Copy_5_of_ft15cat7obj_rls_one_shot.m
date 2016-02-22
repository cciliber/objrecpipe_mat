


%% question


    %% Whether to create fullpath registries
    create_fullpath = false;

    %% Whether to create also the ImageNet labels
    setlist.create_imnetlabels = true;



    %% Categories
    setlist.cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
    %setlist.cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };
%     setlist.cat_idx_all = { [3 8] };
  

    %% Objects per category
    setlist.obj_lists_all = {{[1 2 3 10 5 6 7] 8:9 4}};
%     setlist.obj_lists_all = {{1:7 8:9 10}};


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





    
    
%% Finetune
    
    %% Input images
    dset_dir = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');


    
%% Experiment


    %% Input images
    
%     same as finetune

%     dset_dir = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%     dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%     dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
%     dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

    %% Preprocessing operations (depend on network)
    network.caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
    network.caffestuff.preprocessing.GRID.nodes = 2; 
    network.caffestuff.preprocessing.GRID.resize = false;
    network.caffestuff.preprocessing.GRID.mirror = true;

    %% Feature extraction
    extract_features = true;
    save_only_central_feat = true;
    feat_names = {'fc7'};
    % feat_names = {'conv3', 'conv4', 'pool5', 'fc6', 'fc7'};





%% Result

    % acc_dimensions is a 
    % cell array containing the dimensions in the data
    % that we want to average on in the computation of the accuracy
    % 1: category
    % 2: object
    % 3: transf
    % 4: day
    % 5: cam

    Ndims = 5;

    % acc_dimensions can be computed in the following way:
    % keep empty the dimensions that do not matter in the comp of the accuracy

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % accuracy
    acc_dimensions{1} = 1:Ndims;

    % accuracy xCat xObj xTr xDay xCam
    acc_dimensions{2} = [];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % accuracy xCat xObj xTr
    %acc_dimensions{end+1} = [4 5];

    % accuracy xCat xTr
    %acc_dimensions{end+1} = [2 4 5];

    % accuracy xTr xDay xCam
    %acc_dimensions{end+1} = [1 2];

    % accuracy xTr
    %acc_dimensions{end+1} = [1 2 4 5];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % accuracy xObj xTr xDay xCam
    acc_dimensions{end+1} = 1;

    % accuracy xCat xTr xDay xCam
    %acc_dimensions{end+1} = 2;

    % accuracy xCat xObj xDay xCam
    acc_dimensions{end+1} = 3;

    % accuracy xCat xObj xTr xCam
    %acc_dimensions{end+1} = 4;

    % accuracy xCat xObj xTr xDay
    %acc_dimensions{end+1} = 5;

    






