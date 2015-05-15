

function p=set_folder_parameters(p,img_folder_path,prefix,dictionaries_folder_path)

   
    if(nargin<2)
        error('Error! Not enough parameters!');
    end
    
    if(nargin<3 || numel(prefix)==0)
        prefix='';
    else
        if(prefix(end)~='_')
            prefix(end+1)='_';
        end    
    end
        
     
    
    p.img_folder_path=img_folder_path;

    if(p.img_folder_path(1,end)~='/' && p.img_folder_path(1,end)~='\')
        p.img_folder_path(1,end+1)='/';
    end    
    
    % for the SIFT ---------------
    p.sift.descriptors_path=[p.img_folder_path 'sift_descriptors.txt'];    
    p.sift.locations_path=[p.img_folder_path 'sift_locations.txt'];    
    
    % for the BOW -----------------
    p.bow.hist_path=[p.img_folder_path prefix 'bow_histograms.txt'];
        
    % for the SC ------------------
    p.sc.hist_path=[p.img_folder_path prefix 'sc_histograms.txt'];
    %p.sc.descriptors_path=[p.img_folder_path prefix 'sc_descriptors.txt'];
    
    % for the HMAX ----------------
    p.hmax.hist_path=[p.img_folder_path prefix 'hmax_histograms.txt'];

    if(nargin>=4)
        p=set_dictionary_folder_parameters(p,dictionaries_folder_path);
    end
    
end

