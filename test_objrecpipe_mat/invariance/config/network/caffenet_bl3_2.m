



%% Whether this will be a net to fine-tune or just ready to be tested
mapping = 'tuning';

%% Caffe model 
% original from which to start tuning, or definitive, depending on 'mapping'
caffestuff.net_name = 'caffenet';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WARNING!!!!! 
caffestuff.original_net_weights = '/data/giulia/REPOS/caffe/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';
caffestuff.MEAN_W = 256;
caffestuff.MEAN_H = 256;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Tuning params 
% Neded only in case of tuning
% Those that are not listed here will be the default
% See templates for the list of settable params
base_lr = 1e-3;
fc8_name = 'fc8-N';
fc8_final_W = 10*base_lr;
fc8_final_b = 2*fc8_final_W;