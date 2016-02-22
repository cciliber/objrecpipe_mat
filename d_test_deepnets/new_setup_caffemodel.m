function caffestuff = new_setup_caffemodel(net_dir, network_kind)

caffestuff = struct;

% it is the kind of net (e.g. caffenet/googlenet/vgg)
caffestuff.network_kind = network_kind;

if strcmp(caffestuff.network_kind, 'caffenet')
    
    net_dir = fullfile(net_dir, 'models/bvlc_reference_caffenet/');
    
    
    % net weights
    caffestuff.net_weights = fullfile(net_dir, 'bvlc_reference_caffenet.caffemodel');
    
    % net definition
    caffestuff.deploy_model = fullfile(net_dir, 'deploy.prototxt');
    
    % mean data: mat file already in W x H x C with BGR channels
    caffestuff.mean_path = fullfile(net_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
    
    
    d = load(caffestuff.mean_path);
    caffestuff.mean_data = d.mean_data;
    
    caffestuff.MEAN_W = size(caffestuff.mean_data,1);
    caffestuff.MEAN_H = size(caffestuff.mean_data,2);
    
elseif strcmp(caffestuff.network_kind, 'googlenet_caffe')
    
    % model dir
    net_dir = fullfile(net_dir, 'models/bvlc_googlenet/');
    
    % net weights
    caffestuff.net_weights = fullfile(net_dir, 'bvlc_googlenet.caffemodel');
    
    % net definition
    caffestuff.deploy_model = fullfile(net_dir, 'deploy.prototxt');
    
    % mean data
    caffestuff.mean_data = [104 117 123];
    
elseif strcmp(caffestuff.network_kind, 'googlenet_paper')
    
    % model dir
    net_dir = fullfile(net_dir, 'models/bvlc_googlenet/');
    
    % net weights
    caffestuff.net_weights = fullfile(net_dir, 'bvlc_googlenet.caffemodel');
    
    % net definition
    caffestuff.deploy_model = fullfile(net_dir, 'deploy.prototxt');
    
    % mean data
    caffestuff.mean_data = [104 117 123];
    
elseif strcmp(caffestuff.network_kind, 'vgg16')
    
    % model dir
    net_dir = fullfile(net_dir, 'models/VGG/VGG_ILSVRC_16');
    
    % net weights
    caffestuff.net_weights = fullfile(net_dir, 'VGG_ILSVRC_16_layers.caffemodel');
    
    % net definition
    caffestuff.deploy_model = fullfile(net_dir, 'VGG_ILSVRC_16_layers_deploy.prototxt');
    
    % mean data
    caffestuff.mean_data = [103.939 116.779 123.68];
    
else
    
    error('network_kind unknown!');
    
end

end