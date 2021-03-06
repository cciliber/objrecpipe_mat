



%% Caffe model

caffestuff.net_name = 'caffenet';

%%%%% WARNING!!!!!
caffestuff.original_net_weights = '/data/giulia/REPOS/caffe/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';
caffestuff.MEAN_W = 256;
caffestuff.MEAN_H = 256;
%%%%%%%%%%%%%%%%%%%%%%%%%%


%%
mapping = 'tuning';


%%
base_lr = 1e-3;
fc8_name = 'fc8-N';
fc7_name = 'fc7';
fc6_name = 'fc6';
fc8_final_W = 10*base_lr;
fc7_final_W = base_lr;
fc6_final_W = base_lr;
fc8_final_b = 2*fc8_final_W;
fc7_final_b = 2*fc7_final_W;
fc6_final_b = 2*fc6_final_W;

drop6_dropout_ratio = 0.5;
drop7_dropout_ratio = 0.5;

% base_lr = 1e-5;
% fc8_name = 'fc8-N';
% fc7_name = 'fc7-N';
% fc6_name = 'fc6-N';
% fc8_final_W = 10*base_lr;
% fc7_final_W = 10*base_lr;
% fc6_final_W = 10*base_lr;
% fc8_final_b = 2*fc8_final_W;
% fc7_final_b = 2*fc7_final_W;
% fc6_final_b = 2*fc6_final_W;






