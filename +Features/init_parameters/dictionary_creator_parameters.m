



function p=dictionary_creator_parameters(img_folder_path)

    if(nargin<1)
        img_folder_path='.';
    end
        
    p=struct;
    
    p.img_folder_path=img_folder_path;
    
    if(p.img_folder_path(1,end)~='/' && p.img_folder_path(1,end)~='\')
        p.img_folder_path(1,end+1)='/';
    end
    
    p.max_dataset_size=-1;
    
    % for the SIFT ----------------
    p.sift=struct;
    
    p.sift.feature_size=128;
    p.sift.descriptors_path=[p.img_folder_path 'sift_descriptors.txt'];
    p.sift.locations_path=[p.img_folder_path 'sift_locations.txt'];    
    p.sift.use_lowe=true;
    
    % for the BOW -----------------
    p.bow=struct;
    
    p.bow.feature_size=512;
    p.bow.dictionary_path=[p.img_folder_path 'bow_dictionary.txt'];
    
    
    % for the SC ------------------
    p.sc=struct;
    
    p.sc.feature_size=512;
    p.sc.dictionary_path=[p.img_folder_path 'sc_dictionary.txt'];
    
    p.sc.gamma=0.15;
    p.sc.beta=1e-5;
    p.sc.num_iters = 50;

    % for the HMAX ----------------
    p.hmax=struct;
    p.hmax.num_features=2048;
    p.hmax.feature_size=4096;
    
    p.hmax.NScales       = 8;
    p.hmax.ScaleFactor   = 2^0.2; 
    p.hmax.NOrientations = 8;
    p.hmax.S2RFCount     = [4 8 12];
    p.hmax.BSize         = 256;

    p.hmax.dictionary_path=[p.img_folder_path 'hmax_dictionary.txt'];
    p.hmax.mode='gpu';
    p.hmax.params = hmax_mitcub_params(p);
	
	%check the name of the machine	
	[ret, name] = system('hostname');   
	if ret ~= 0,
	   if ispc
		  name = getenv('COMPUTERNAME');
	   else      
		  name = getenv('HOSTNAME');      
	   end
	end
	name = lower(name);
    name=name(1:end-1);

    if(strcmp(name,'iitrbcsws022'))
        p.ignore_hmax=1;
    end

    if(strcmp(name,'icub-cuda'))
        p.ignore_sift=1;
        p.ignore_bow=1;
        p.ignore_sc=1;
    end


end

