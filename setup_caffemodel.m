function caffestuff = setup_caffemodel(caffe_dir, model, oversample, overscale, GRID)

caffestuff.model = model;
caffestuff.oversample = oversample;
caffestuff.overscale = overscale;

if strcmp(model, 'caffenet')
    
    % model dir
    caffestuff.model_dir = fullfile(caffe_dir, 'models/bvlc_reference_caffenet/');
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.model_dir, 'bvlc_reference_caffenet.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.model_dir, 'deploy.prototxt');
    
    % features to extract
    caffestuff.feat_names = {'fc6', 'fc7'};
    
    % mean data: mat file already in W x H x C with BGR channels
    caffestuff.mean_path = fullfile(caffe_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
    d = load(caffestuff.mean_path);
    caffestuff.mean_data = d.mean_data;
    caffestuff.MEAN_W = size(caffestuff.mean_data, 1);
    caffestuff.MEAN_H = size(caffestuff.mean_data, 2);
    
    % net input 
    caffestuff.CROP_SIZE = 227;
    
    % scales
    caffestuff.SHORTER_SIDE = [];
    
    % crops
    if oversample
        caffestuff.NCROPS = 10;
    else
        caffestuff.NCROPS = 1;
    end
    caffestuff.GRID = [];
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);

elseif strcmp(model, 'googlenet_caffe')
    
    % model dir
    caffestuff.model_dir = fullfile(caffe_dir, 'models/bvlc_googlenet/');
    
    % net weights
    caffepaths.net_weights = fullfile(caffestuff.model_dir, 'bvlc_googlenet.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.model_dir, 'deploy.prototxt');
    
    % features to extract
    caffestuff.feat_names = [];
    
    % mean data
    caffestuff.mean_data = [104 117 123];
    
    % net input
    caffestuff.CROP_SIZE = 224;
    
    % scales
    caffestuff.SHORTER_SIDE = [];
    
    % crops
    if oversample
        caffestuff.NCROPS = 10;
    else
        caffestuff.NCROPS = 1;
    end
    caffestuff.GRID = [];
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);
 
elseif strcmp(model, 'googlenet_paper')
    
    % model dir
    caffestuff.model_dir = fullfile(caffe_dir, 'models/bvlc_googlenet/');
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.model_dir, 'bvlc_googlenet.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.model_dir, 'deploy.prototxt');
    
    % features to extract
     caffestuff.feat_names = [];
     
    % mean data
    caffestuff.mean_data = [104 117 123];
    
    % net input
    caffestuff.CROP_SIZE = 224;
    
    % scales
    if oversample && overscale   
        caffestuff.SHORTER_SIDE = [256 288 320 352];
    else
        caffestuff.SHORTER_SIDE = 256;
    end
    
    % crops
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            caffestuff.NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
        else
            caffestuff.NCROPS = grid_side;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        if grid_side>1
            caffestuff.NCROPS = grid_side*grid_side*2;
        else
            caffestuff.NCROPS = 1;
        end
    end
    caffestuff.GRID = GRID;
    caffestuff.NCROPS = caffestuff.NCROPS*length(caffestuff.SHORTER_SIDE);
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);
  
elseif strcmp(model, 'vgg16')
    
    % model dir
    caffestuff.model_dir = fullfile(caffe_dir, 'models/VGG/VGG_ILSVRC_16');
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.model_dir, 'VGG_ILSVRC_16_layers.caffemodel');
    
    % net definition
    caffepaths.net_model = fullfile(caffestuff.model_dir, 'VGG_ILSVRC_16_layers_deploy.prototxt');
    
    % features to extract
    caffestuff.feat_names = {'fc6', 'fc7'};
    
    % mean data
    caffestuff.mean_data = [103.939 116.779 123.68];
     
    % net input
    caffestuff.CROP_SIZE = 224;
    
    % scales
    if oversample && overscale 
        caffestuff.SHORTER_SIDE = [256 384 512];
    else
        caffestuff.SHORTER_SIDE = 384;
    end
    
    % crops
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            caffestuff.NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
        else
            caffestuff.NCROPS = grid_side;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        caffestuff.NCROPS = grid_side*grid_side*2;
    end
    caffestuff.GRID = GRID;
    caffestuff.NCROPS = caffestuff.NCROPS*length(caffestuff.SHORTER_SIDE);
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);

end