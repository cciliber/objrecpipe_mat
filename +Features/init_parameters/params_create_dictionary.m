function p=params_create_dictionary(path,feature_size)

    p=struct;
    
    p.ext='.ppm';

    p.hier=struct;
    
    % for the SIFT ----------------
    p.sift=struct;
    
    p.sift.feature_size=128;
    p.sift.use_lowe=false;

    p.sift.dense=true;
    p.sift.normalize=true;

    p.sift.step=8;
    p.sift.scale=16;

    
    % for BOW -----------------
    p.bow=struct;
    
    p.bow.feature_size=feature_size;
    p.bow.dictionary_path='???';
    
    
    % for SC ------------------
    p.sc=struct;
    
    p.sc.feature_size=sc_feature_size;
    p.sc.dictionary_path='???';
    
    p.sc.gamma=0.15;
    p.sc.beta=1e-5;
    p.sc.num_iters = 20;

    % for HMAX ----------------
    p.hmax=struct;
    p.hmax.feature_size=feature_size;
    p.hmax.num_features=uint32(p.hmax.feature_size/2);
    
    p.hmax.NScales       = 8;
    p.hmax.ScaleFactor   = 2^0.2; 
    p.hmax.NOrientations = 8;
    p.hmax.S2RFCount     = [4 8 12];
    p.hmax.BSize         = 256;

    p.hmax.dictionary_path='???';
    p.hmax.mode='cpu';
    p.hmax.params = hmax_params(p);
	
end