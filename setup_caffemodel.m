function caffestuff = setup_caffemodel(model_dir, caffestuff)

if strcmp(caffestuff.model, 'caffenet')
    
    % model dir
    caffestuff.model_dir = fullfile(model_dir, 'models/bvlc_reference_caffenet/');
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.model_dir, 'bvlc_reference_caffenet.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.model_dir, 'deploy.prototxt');
    
    % features to extract
    caffestuff.feat_names = {'fc6', 'fc7'};
    
    % net input 
    caffestuff.CROP_SIZE = 227;
    
    % mean data: mat file already in W x H x C with BGR channels
    caffestuff.mean_path = fullfile(caffestuff.model_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
    d = load(caffestuff.mean_path);
    caffestuff.mean_data = d.mean_data;

elseif strcmp(caffestuff.model, 'googlenet_caffe')
    
    % model dir
    caffestuff.model_dir = fullfile(model_dir, 'models/bvlc_googlenet/');
    
    % net weights
    caffepaths.net_weights = fullfile(caffestuff.model_dir, 'bvlc_googlenet.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.model_dir, 'deploy.prototxt');
    
    % features to extract
    caffestuff.feat_names = [];
    
    % net input
    caffestuff.CROP_SIZE = 224;
    
    % mean data
    caffestuff.mean_data = [104 117 123];
 
elseif strcmp(caffestuff.model, 'googlenet_paper')
    
    % model dir
    caffestuff.model_dir = fullfile(model_dir, 'models/bvlc_googlenet/');
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.model_dir, 'bvlc_googlenet.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.model_dir, 'deploy.prototxt');
    
    % features to extract
     caffestuff.feat_names = [];
     
    % net input
    caffestuff.CROP_SIZE = 224;
    
    % mean data
    caffestuff.mean_data = [104 117 123];
  
elseif strcmp(caffestuff.model, 'vgg16')
    
    % model dir
    caffestuff.model_dir = fullfile(model_dir, 'models/VGG/VGG_ILSVRC_16');
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.model_dir, 'VGG_ILSVRC_16_layers.caffemodel');
    
    % net definition
    caffepaths.net_model = fullfile(caffestuff.model_dir, 'VGG_ILSVRC_16_layers_deploy.prototxt');
    
    % features to extract
    caffestuff.feat_names = {'fc6', 'fc7'};
    
    % net input
    caffestuff.CROP_SIZE = 224;
    
    % mean data
    caffestuff.mean_data = [103.939 116.779 123.68];

else 
    % model dir
    caffestuff.model_dir = model_dir;
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.model_dir, 'best_model.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.model_dir, 'deploy.prototxt');
    
    % features to extract
    caffestuff.feat_names = {'fc6', 'fc7'};
    
    % net input 
    caffestuff.CROP_SIZE = 227;
    
    % mean data: mat file already in W x H x C with BGR channels
    caffestuff.mean_path = fullfile(caffestuff.model_dir, 'train_mean.binaryproto');
    caffestuff.mean_data = caffe.io.read_mean(caffestuff.mean_path);

end