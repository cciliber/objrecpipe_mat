classdef MyPCA < Features.GenericFeature
   
    properties
        DictionaryDim
    end
    
    methods
        function obj = MyPCA()
            
            obj = obj@Features.GenericFeature();

        end
        
        function [feat, grid, im_size] = extract_image(obj, src, src_grid, im_size, mod_out, dst)
            
            if isempty(obj.Dictionary)
                error('Error! Missing Dictionary in calling object.');
            end
            
            if ischar(src)
               
                im_size = [];
                grid = [];
                
                [~, ~, src_ext] = fileparts(src);
                
                if strcmp(src_ext,'.bin')
                    
                    fid = fopen(src, 'r', 'L');
                    if (fid==-1)
                       fprintf(2, 'Cannot open file: %s', src);
                    end
                    % column major order (transpose before writing)
                    % format for Unix systems (i.e., L, big endian)
                    src_feat_size = fread(fid, [2 1], 'double');
                    src_feat = fread(fid, src_feat_size', 'double');
                    if ~feof(fid)
                        grid_size = fread(fid, [2 1], 'double');
                        grid = fread(fid, grid_size', 'double');
                    end
                    if ~feof(fid)
                        im_size = fread(fid, [2 1], 'double');
                    end
                    fclose(fid);
                    
                elseif strcmp(src_ext,'.mat')
                    
                    input = load(src, '-mat');
                    src_feat = input.feat;
                    %src_feat_size = input.feat_size;
                    if isfield(input, 'grid')
                        grid = input.grid;
                        grid_size = input.grid_size;
                    end
                    if isfield(input, 'im_size')
                        im_size = input.im_size;
                    end
 
                else
                    error('Error! Invalid extension.');
                end
                
            elseif isnumeric(src)
                
                src_feat = src;
                %src_feat_size = size(src_feat);
                grid = src_grid; 
                grid_size = size(grid);
  
            else 
                error('Input feature must be either character or numeric array.');
            end
            
            % project on the first FeatSize principal components
            if size(obj.Dictionary,1) == size(src_feat,1) % && size(obj.Dictionary,2) == obj.DictionaryDim
               feat = obj.Dictionary' * src_feat;
            else 
                error('Check dictionary and input feature size.');
            end
            
            if (strcmp(mod_out,'file') || strcmp(mod_out,'both'))
                
                feat_size = size(feat);
                
                [~, ~, dst_ext] = fileparts(dst);
                
                if strcmp(dst_ext,'.bin')
                    fid = fopen(dst, 'w', 'L');
                    if (fid==-1)
                       fprintf(2, 'Cannot open file: %s', src);
                    end
                    % column major order
                    % format for Unix systems (i.e., L, big endian)
                    fwrite(fid, feat_size, 'double');
                    fwrite(fid, feat, 'double');
                    if ~isempty(grid)
                        fwrite(fid, grid_size, 'double');
                        fwrite(fid, grid, 'double');
                    end
                    if ~isempty(im_size)
                        fwrite(fid, im_size, 'double');
                    end
                    fclose(fid);
                    
                elseif strcmp(dst_ext,'.mat')
                    
                    if ~isempty(grid) && ~isempty(im_size)
                        save(dst,'feat', 'grid', 'feat_size', 'grid_size', 'im_size');
                    elseif ~isempty(grid)
                        save(dst,'feat', 'feat_size', 'grid', 'grid_size');
                    elseif ~isempty(im_size)
                        save(dst,'feat', 'feat_size', 'im_size');
                    else
                        save(dst,'feat', 'feat_size');
                    end
                    
                else
                    error('Error! Invalid extension.');
                end
   
            end
            
        end
            
        function dictionary = dictionarize_matrix(obj, features, dict_dim, mod_out, dst)
        
            obj.DictionaryDim = dict_dim;
            
            if (obj.DictionaryDim < size(features,1))
              
                % dictionarize
                [dictionary,~,~] = svd(features,'econ');
                
                % keep only the first FeatSize columns
                dictionary(:,(obj.DictionaryDim+1):end) = [];
            else
                dictionary = eye(size(features,1));
            end
            
            dictionary_size = size(dictionary);

            if (strcmp(mod_out, 'file') || strcmp(mod_out, 'both'))
                
                [~, ~, dst_ext] = fileparts(dst);
                
                if strcmp(dst_ext,'.bin')
                    fid = fopen(dst, 'w', 'L');
                    if (fid==-1)
                       fprintf(2, 'Cannot open file: %s', dst);
                    end
                    % column major order
                    % format for Unix systems (i.e., L, big endian)
                    fwrite(fid, dictionary_size, 'double');
                    fwrite(fid, dictionary, 'double');
                    fclose(fid);
                    
                elseif strcmp(dst_ext,'.mat')
                    
                    save(dst,'dictionary', 'dictionary_size');
                    
               elseif strcmp(dst_ext,'.txt')
                   
                    dlmwrite(dst, dictionary_size, 'delimiter', '\t');
                    dlmwrite(dst, dictionary, '-append', 'delimiter', '\t');
                
                else
                    error('Error! Invalid extension.');
                end
                
            end
        end
    end
end
