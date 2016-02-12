
%% Input images
dset_dir = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

%% Preprocessing operations (depend on network)
network.caffestuff.preprocessing.SCALING.scales = [256; 288; 320; 352];
network.caffestuff.preprocessing.SCALING.aspect_ratio = true;
network.caffestuff.preprocessing.SCALING.central_scale = 1;
network.caffestuff.preprocessing.OUTER_GRID = 3; % 1 or 3 or []
network.caffestuff.preprocessing.GRID.nodes = 2; 
network.caffestuff.preprocessing.GRID.resize = true;
network.caffestuff.preprocessing.GRID.mirror = true;

%% Feature extraction
extract_features = false;