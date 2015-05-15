classdef MyHMAX < Features.GenericFeature
    
    properties
        
        % HMAX package params
        InstallDir
        ComputMode
               
        % Number of dictionary patches used in S2 layer
        DictionaryDim
        
        % HMAX net params
        NScales
        ScaleFactor
        NOrientations
        S2RFCount
        BSize
        
        netParam
        netModel
        
    end
    
    methods
        
        function obj = MyHMAX(install_dir, mode, NScales, ScaleFactor, NOrientations, S2RFCount, BSize)
            
            obj = obj@Features.GenericFeature();
            
            obj.InstallDir     = install_dir;
            obj.ComputMode = mode;
     
            obj.NScales       = NScales;
            obj.ScaleFactor   = ScaleFactor;
            obj.NOrientations = NOrientations;
            obj.S2RFCount     = S2RFCount;
            obj.BSize         = BSize;
            
            obj.create_netParam();
            
        end
        
        function create_netParam(obj)
 
            obj.netParam = struct;
            
            obj.netParam.groups = {};
            
            %-----------------------------------------------------------------------------------------------------------------------
            
            c = struct;
            c.name = 'input';
            c.type = 'input';
            c.size = [400 600];
            
            obj.netParam.groups{end + 1} = c;
            obj.netParam.input = numel(obj.netParam.groups);
            
            %-----------------------------------------------------------------------------------------------------------------------
            
            c = struct;
            c.name        = 'scale';
            c.type        = 'scale';
            c.pg          = obj.netParam.input;
            c.baseSize    = [obj.BSize obj.BSize];
            c.scaleFactor = obj.ScaleFactor;
            c.numScales   = obj.NScales;
            
            obj.netParam.groups{end + 1} = c;
            obj.netParam.scale = numel(obj.netParam.groups);
            
            %-----------------------------------------------------------------------------------------------------------------------
            
            c = struct;
            c.name    = 's1';
            c.type    = 'sdNDP';
            c.pg      = obj.netParam.scale;
            c.rfCount = 11;
            c.rfStep  = 1;
            c.zero    = 1;
            c.thres   = 0.15;
            c.abs     = 1;
            c.fCount  = obj.NOrientations;
            c.fParams = {'gabor', 0.3, 5.6410, 4.5128};
            
            obj.netParam.groups{end + 1} = c;
            obj.netParam.s1 = numel(obj.netParam.groups);
            
            %-----------------------------------------------------------------------------------------------------------------------
            
            c = struct;
            c.name    = 'c1';
            c.type    = 'cMax';
            c.pg      = obj.netParam.s1;
            c.sCount  = 2;
            c.sStep   = 1;
            c.rfCount = 10;
            c.rfStep  = 5;
            
            obj.netParam.groups{end + 1} = c;
            obj.netParam.c1 = numel(obj.netParam.groups);
            
            %-----------------------------------------------------------------------------------------------------------------------
            
            c = struct;
            c.name    = 's2';
            c.type    = 'sdNDP';
            c.pg      = obj.netParam.c1;
            c.rfCount = obj.S2RFCount;
            c.rfStep  = 1;
            c.zero    = 1;
            c.thres   = 0.00001;
            c.abs     = 1;
            
            obj.netParam.groups{end + 1} = c;
            obj.netParam.s2 = numel(obj.netParam.groups);
            
            %-----------------------------------------------------------------------------------------------------------------------
            
            c = struct;
            c.name    = 'c2';
            c.type    = 'cMax';
            c.pg      = obj.netParam.s2;
            c.sCount  = 4;
            c.sStep   = 3;
            c.rfCount = inf;
            
            obj.netParam.groups{end + 1} = c;
            obj.netParam.c2 = numel(obj.netParam.groups);
            
            %-----------------------------------------------------------------------------------------------------------------------
            
        end

        function dictionary = dictionarize_matrix(obj, registry, dict_size, mod_out, dst)
            
            obj.DictionaryDim = dict_size;
            
            obj.Dictionary.netLib = struct;
            
            obj.netModel = hmax.Model(obj.netParam, obj.Dictionary.netLib);
            cns('init', obj.netModel, obj.ComputMode);

            d = hmax_s.EmptyDict(obj.netModel, obj.netModel.s2, obj.DictionaryDim);
            
            count = min(obj.nRandFeatures, obj.DictionaryDim);
            for i=1:count
                
                num_samples = floor(obj.DictionaryDim/count);
                if i <= mod(obj.DictionaryDim, count)
                    num_samples = num_samples + 1;
                end

                hmax_input.Load(obj.netModel, obj.netModel.input, registry{i});
                cns('run');
                d = hmax_s.SampleFeatures(obj.netModel, obj.netModel.s2, d, num_samples);
            end
      
            cns('done');
            
            d = hmax_s.SortFeatures(obj.netModel, obj.netModel.s2, d);
            
            if cns_istype(obj.netModel, -obj.netModel.s2, 'ss')
                d = hmax_ss.SparsifyDict(obj.netModel, obj.netModel.s2, d);
            end
            
            obj.Dictionary.netLib.groups{obj.netModel.s2} = d;
            
            dictionary = obj.Dictionary;
            dictionary_size = size(dictionary);
            
            if (strcmp(mod_out, 'file') || strcmp(mod_out, 'both'))
                
                [~, ~, dst_ext] = fileparts(dst);
                if strcmp(dst_ext,'.mat')
                     save(dst, 'dictionary', 'dictionary_size');
                else 
                    error('Error! Invalid extension: HMAX only saves dictionary in .mat!');
                end
                
            end
            
        end
        
        function initModel(obj)
             
            obj.netModel = hmax.Model(obj.netParam, obj.Dictionary.netLib);
            
            cns('init', obj.netModel, obj.ComputMode);
            
        end
        
        function freeModel(obj)
            
            cns('done');
            
        end
        
        function [feat, grid, im_size] = extract_image(obj, src, src_grid, im_size, mod_out, dst)
            
            flag = 0;
            
            if ischar(src)   
                
                [~, ~, src_ext] = fileparts(src);
                 
                if strcmp(src_ext, '.txt')      
                     
                    feat = dlmread(src);
                    flag = 1;
                     
                elseif strcmp(src_ext, '.bin')
                    
                    fid = fopen(src);
                    feat = fread(fid, [4096 1], 'float');
                    fclose(fid);
                    flag = 1;
  
                else
                    
                    % in this case it is (probably) a path to an image
                    I = src; 
                    flag = 2;
                end
                
            elseif isnumeric(src)
                
                % in this case it is an image 
                 I = src;
                 flag = 0;
                 
            else
                
                error('Input image must be either character or numeric array.');
                
            end
 
            if flag==0 || flag==2
                
                if flag==0
                    im_size = size(I)';
                end
                
                hmax_input.Load(obj.netModel, obj.netModel.input, I);
                cns('run');
                
                c2 = cns('get', -obj.netModel.c2, 'val');
                feat = cat(1, c2{:});
                feat(feat == cns_fltmin) = 0; % Convert any "unknown" values to 0.
            end
            
            feat_size = size(feat);
            
            grid = [];
            grid_size = size(grid);
            
            if (strcmp(mod_out,'file') || strcmp(mod_out,'both'))
                
                [~, ~, dst_ext] = fileparts(dst);
                
                if strcmp(dst_ext,'.bin')
                    fid = fopen(dst, 'w', 'L');
                    if (fid==-1)
                        fprintf(2, 'Cannot open file: %s', dst);
                    end
                    % column major order (transpose before writing)
                    % format for Unix systems (i.e., L, big endian)
                    fwrite(fid, feat_size, 'double');
                    fwrite(fid, feat, 'double');
                    %fwrite(fid, grid_size, 'double');
                    %fwrite(fid, grid, 'double');
                    fwrite(fid, im_size, 'double');
                    fclose(fid);
                    
                elseif strcmp(dst_ext,'.mat')
                    
                    save(dst, 'feat', 'feat_size', 'im_size');
                    
                else
                    error('Error! Invalid extension.');
                end
            end
            
        end
        
    end
    
end

