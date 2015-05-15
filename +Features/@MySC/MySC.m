classdef MySC < Features.GenericFeature
    
    properties
        
        DictionaryDim
        
        Beta
        Gamma
        nIter
        
        Pyramid
        FeatsPerBin
    end
    
    methods

        function obj = MySC(pyramid, beta, gamma, n_iter)
            
            obj = obj@Features.GenericFeature();
            
            obj.Beta = beta;
            obj.Gamma = gamma;
            obj.nIter = n_iter;
            
            if (isempty(pyramid))
                obj.Pyramid = [1 2 4;1 2 4]; % caltech-pyramid
            else
                obj.Pyramid = pyramid;
            end

        end
        
        function dictionary = dictionarize_matrix(obj, features, dict_size, mod_out, dst)
            
            obj.DictionaryDim = dict_size;
            
            [dictionary, ~, ~] = reg_sparse_coding(features, obj.DictionaryDim, eye(obj.DictionaryDim), obj.Beta, obj.Gamma, obj.nIter);
            
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
        
        function featsPerBin = feats_per_bin(obj, pyramid,im_size,grid)
            
            pyramid_w = pyramid(1,:);
            pyramid_h = pyramid(2,:);
            
            nLevels = size(pyramid,2);
            % spatial bins on each level
            binsPerLevel = pyramid_w.*pyramid_h;
            % total spatial bins
            nBins = sum(binsPerLevel);
            
            featsPerBin = cell(1,nBins);
            
            bId = 0;
            for l = 1:nLevels
                
                bin_w = im_size(2) / pyramid_w(l);
                bin_h = im_size(1) / pyramid_h(l);
                
                % find to which spatial bin each local descriptor belongs
                bin_x = ceil(grid(1,:) / bin_w);
                bin_y = ceil(grid(2,:) / bin_h);
                bin_idx = (bin_y-1)*pyramid(1,l) + bin_x;
                
                for b=1:binsPerLevel(l)
                    bId = bId + 1;
                    indices = find(bin_idx == b);
                    if isempty(indices),
                        continue;
                    end
                    
                    featsPerBin{bId} = indices;
                end
            end
        end
        
        function [feat, grid, im_size] = extract_image(obj, src, src_grid, im_size, mod_out, dst)
            
            if isempty(obj.Dictionary)
                error('Missing Dictionary in calling object.');
            end
            
            if ischar(src)
               
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
                    grid_size = fread(fid, [2 1], 'double');
                    grid = fread(fid, grid_size', 'double');
                    im_size = fread(fid, [2 1], 'double');
                    fclose(fid);
                    
                elseif strcmp(src_ext,'.mat')
                    
                    input = load(src, '-mat', 'feat', 'grid', 'feat_size', 'grid_size', 'im_size');
                    src_feat = input.feat;
                    %src_feat_size = input.feat_size;
                    grid = input.grid;
                    grid_size = input.grid_size;
                    im_size = input.im_size;
 
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


            % for each bin, idxs of the grid points falling inside it
            obj.FeatsPerBin = obj.feats_per_bin(obj.Pyramid,im_size,grid);
   
            % a SC code from an image is obj.DictionaryDim*nBins x 1
            feat = code_sc(src_feat, obj.Pyramid, obj.Gamma, obj.Dictionary, im_size, grid);
   
            if (strcmp(mod_out,'file') || strcmp(mod_out,'both'))
                
                feat_size = size(feat); 
                
                [~, ~, dst_ext] = fileparts(dst);
                
                if strcmp(dst_ext,'.bin')
                    
                    fid = fopen(dst, 'w', 'L');
                    if (fid==-1)
                       fprintf(2, 'Cannot open file: %s', dst);
                    end
                    % column major order
                    % format for Unix systems (i.e., L, big endian)
                    fwrite(fid, feat_size, 'double');
                    fwrite(fid, feat, 'double');
                    fwrite(fid, grid_size, 'double');
                    fwrite(fid, grid, 'double');
                    fwrite(fid, im_size, 'double');
                    fclose(fid);
                    
                elseif strcmp(dst_ext,'.mat')
                    
                    save(dst,'feat', 'grid', 'feat_size', 'grid_size', 'im_size');
                else
                    error('Error! Invalid extension.');
                end

            end
            
        end
  
    end
    
end
