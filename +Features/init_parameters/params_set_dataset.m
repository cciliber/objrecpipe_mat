function    p=params_set_dataset(p,path,prefix)

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
        
    p.img_folder_path=path;

    if(p.img_folder_path(1,end)~='/' && p.img_folder_path(1,end)~='\')
        p.img_folder_path(1,end+1)='/';
    end    
    
    % for the SIFT ---------------
    p.sift.descriptors_path=[p.img_folder_path 'sift_descriptors.txt'];    
    p.sift.locations_path=[p.img_folder_path 'sift_locations.txt'];    
    
    % for the BOW -----------------
    p.bow.hist_path=[p.img_folder_path prefix 'bow_' p.bow.feature_size '_histograms.txt'];
        
    % for the SC ------------------
    p.sc.hist_path=[p.img_folder_path prefix 'sc_' p.sc.feature_size '_histograms.txt'];
    %p.sc.descriptors_path=[p.img_folder_path prefix 'sc_' p.sc.feature_size '_descriptors.txt'];
    
% feaSet        -structure defining the feature set of an image   
%                   .feaArr     local feature array extracted from the
%                               image, column-wise
%                   .x          x locations of each local feature, 2nd
%                               dimension of the matrix
%                   .y          y locations of each local feature, 1st
%                               dimension of the matrix
%                   .width      width of the image
%                   .height     height of the image
            

    
    % for the HMAX ----------------
    p.hmax.hist_path=[p.img_folder_path prefix 'hmax_' p.hmax_feature_size '_histograms.txt'];
    
end



end