function caffestuff = setup_caffemodel(net_dir, caffestuff, mapping)

if isempty(mapping)
    
    if strcmp(caffestuff.net_name, 'caffenet')
        
        % model dir
        caffestuff.net_dir = fullfile(net_dir, 'models/bvlc_reference_caffenet/');
        
        % net weights
        caffestuff.net_weights = fullfile(caffestuff.net_dir, 'bvlc_reference_caffenet.caffemodel');
        
        % net definition
        caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');
        
        % mean data: mat file already in W x H x C with BGR channels
        caffestuff.mean_path = fullfile(net_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
        d = load(caffestuff.mean_path);
        caffestuff.mean_data = d.mean_data;
        
    elseif strcmp(caffestuff.net_name, 'googlenet_caffe')
        
        % model dir
        caffestuff.net_dir = fullfile(net_dir, 'models/bvlc_googlenet/');
        
        % net weights
        caffepaths.net_weights = fullfile(caffestuff.net_dir, 'bvlc_googlenet.caffemodel');
        
        % net definition
        caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');
        
        % mean data
        caffestuff.mean_data = [104 117 123];
        
    elseif strcmp(caffestuff.net_name, 'googlenet_paper')
        
        % model dir
        caffestuff.net_dir = fullfile(net_dir, 'models/bvlc_googlenet/');
        
        % net weights
        caffestuff.net_weights = fullfile(caffestuff.net_dir, 'bvlc_googlenet.caffemodel');
        
        % net definition
        caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');
        
        % mean data
        caffestuff.mean_data = [104 117 123];
        
    elseif strcmp(caffestuff.net_name, 'vgg16')
        
        % model dir
        caffestuff.net_dir = fullfile(net_dir, 'models/VGG/VGG_ILSVRC_16');
        
        % net weights
        caffestuff.net_weights = fullfile(caffestuff.net_dir, 'VGG_ILSVRC_16_layers.caffemodel');
        
        % net definition
        caffepaths.net_model = fullfile(caffestuff.net_dir, 'VGG_ILSVRC_16_layers_deploy.prototxt');
        
        % mean data
        caffestuff.mean_data = [103.939 116.779 123.68];
        
    else
        
        error('Net unknown!');
        
    end
    
elseif strcmp(mapping, 'tuning')
    
    % model dir
    caffestuff.net_dir = net_dir;
    
    % net weights
    caffestuff.net_weights = fullfile(caffestuff.net_dir, 'best_model.caffemodel');
    
    % net definition
    caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');
    
    % mean data: mat file already in W x H x C with BGR channels
    caffestuff.mean_path = fullfile(caffestuff.net_dir, 'train_mean.binaryproto');
    caffestuff.mean_data = caffe.io.read_mean(caffestuff.mean_path);

else
    
    error('Mapping unknown!')
    
end