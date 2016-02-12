
%% Input images
dset_dir = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

%% Preprocessing operations (depend on network)
network.caffestuff.preprocessing.SCALING.scales = [256 256];
network.caffestuff.preprocessing.SCALING.aspect_ratio = false;
network.caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
network.caffestuff.preprocessing.GRID.nodes = 2; 
network.caffestuff.preprocessing.GRID.resize = false;
network.caffestuff.preprocessing.GRID.mirror = true;

%% Feature extraction
extract_features = false;