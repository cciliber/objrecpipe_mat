% Process the mean obtained from caffe's script
% $caffe_ROOT/tools/compute_image_mean.cpp 
% and converted from .binaryproto to .mat with the script
% $caffe_ROOT/pithon/convert_mean.py

% The mean produced and here imported is:
% - Num(=1) x Channels x Height x Width
% - BGR

mean_path = '/home/giulia/REPOS/caffe/python/iCubWorld30_train_mean.mat';

image_mean = load(mean_path);
image_mean = single(image_mean.out);
channels = size(image_mean,1);
height = size(image_mean, 2);
width = size(image_mean, 3);

% In order to be compatible with ilsvrc_2012_mean.mat,
% and thus use the same matlab scripts
% flip the dimensions to Height x Width x Channels (but leave BGR)
image_mean = permute(image_mean, [2 3 1]);

save(mean_path, 'image_mean')