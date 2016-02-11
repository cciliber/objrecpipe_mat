




%% Input images
dset_dir = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');

%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');



%% Caffe model

network.caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
network.caffestuff.preprocessing.GRID.nodes = 2; 
network.caffestuff.preprocessing.GRID.resize = false;
network.caffestuff.preprocessing.GRID.mirror = true;


% whether we want to extract features
extract_features = true;

% which features we want to extract
feat_names = {'pool5', 'fc7-N'};
% feat_names = {'conv3', 'conv4', 'pool5', 'fc6', 'fc7'};



% network.caffestuff.net_name = 'googlenet_caffe';
% network.caffestuff.preprocessing.SCALING.scales = [256 256];
% network.caffestuff.preprocessing.SCALING.aspect_ratio = false;
% network.caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
% network.caffestuff.preprocessing.GRID.nodes = 2; 
% network.caffestuff.preprocessing.GRID.resize = false;
% network.caffestuff.preprocessing.GRID.mirror = true;
% extract_features = false;

% network.caffestuff.net_name = 'googlenet_paper';
% network.caffestuff.preprocessing.SCALING.scales = [256; 288; 320; 352];
% network.caffestuff.preprocessing.SCALING.aspect_ratio = true;
% network.caffestuff.preprocessing.SCALING.central_scale = 1;
% network.caffestuff.preprocessing.OUTER_GRID = 3; % 1 or 3 or []
% network.caffestuff.preprocessing.GRID.nodes = 2; 
% network.caffestuff.preprocessing.GRID.resize = true;
% network.caffestuff.preprocessing.GRID.mirror = true;
% extract_features = false;

% network.caffestuff.net_name = 'vgg16';
% network.caffestuff.preprocessing.SCALING.scales = [256; 384; 512];
% network.caffestuff.preprocessing.SCALING.aspect_ratio = true;
% network.caffestuff.preprocessing.SCALING.central_scale = 2;
% network.caffestuff.preprocessing.OUTER_GRID = []; % 1 or 3 or []
% network.caffestuff.preprocessing.GRID.nodes = 5; 
% network.caffestuff.preprocessing.GRID.resize = false;
% network.caffestuff.preprocessing.GRID.mirror = true;
% network.caffestuff.feat_names = {'fc6', 'fc7'};
% extract_features = true;
