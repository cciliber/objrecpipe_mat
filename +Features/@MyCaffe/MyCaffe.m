classdef MyCaffe < Features.GenericFeature
    
    properties
        
        InstallDir
        ComputMode
        
        DatasetMean
        
        Oversample
        
    end
    
    methods
        
        function obj = MyCaffe(install_dir, mode, path_dataset_mean, model_def_file, model_file, oversample)
            
            obj = obj@Features.GenericFeature();
            
            if nargin<1 || isempty(install_dir)
                install_dir = getenv('Caffe_ROOT');
            else
                obj.InstallDir = install_dir;
            end
            addpath(genpath(fullfile(install_dir,'matlab','caffe')));
            
            if nargin<2 || isempty(mode)
                use_gpu = 0;
                obj.ComputMode = 'cpu';
            elseif strcmp(mode, 'gpu')
                use_gpu = 1;
                obj.ComputMode = 'gpu';
            elseif strcmp(mode, 'cpu')
                use_gpu = 0;
                obj.ComputMode = 'cpu';
            else
                error('Caffe mode not recognized, using GPU');
                use_gpu = 0;
                obj.ComputMode = 'gpu';
            end
            
            if nargin<3 || isempty(path_dataset_mean)
                path_dataset_mean = fullfile(install_dir,'matlab','caffe','ilsvrc_2012_mean');
            end
            obj.DatasetMean = load(path_dataset_mean);
            
            if nargin<4 || isempty(model_def_file)
                if obj.Oversample
                    model_def_file = fullfile(mfilename('fullpath'),'..','..','..','data','caffe','deploy_oversample.prototxt');
                    %model_def_file = fullfile(install_dir,'models/bvlc_reference_caffenet/deploy.prototxt');
                else
                    model_def_file = fullfile(mfilename('fullpath'),'..','..','..','data','caffe','deploy.prototxt');
                end
            end
            
            if nargin<5 || isempty(model_file)
                model_file = fullfile(install_dir,'models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel');
            end
            
            matcaffe_init(use_gpu, model_def_file, model_file);
            
            if nargin<6 || isempty(oversample)
                obj.Oversample = 0;
            elseif oversample==1 ||oversample==0
                obj.Oversample = oversample;
            else
                error('oversample must be 0 or 1, setting it to 0');
                obj.Oversample = 0;
            end
            
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
                     
                     I = imread(src);   
                     
                 end
                
            elseif isnumeric(src)
                
                 I = src;
                 
            else
                
                error('Input image must be either character or numeric array.');
                
            end
       
            if flag==0
                
                im_size = size(I)';
            
                % here we need to prepare the image
                input_data = {obj.prepare_image(I)};
            
                % feature extraction
                %tic
                feat = caffe('forward',input_data);
                %toc
                feat = feat{1};
                feat = squeeze(feat);
                if (obj.Oversample)
                    feat = mean(feat,2);
                end
                
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
        
        function images = prepare_image(obj, im)
        
            % convert to single
            im = single(im);
            
            % get the mean image
            IMAGE_MEAN = obj.DatasetMean.image_mean;
            
            % compute the dims
            im_DIM = size(im);
            NUM_CHANNELS = size(im,3);
            
            if NUM_CHANNELS==1
                im = cat(3, im, im, im);
                NUM_CHANNELS=3;
            end
            
            IMAGE_MEAN_DIM = size(IMAGE_MEAN);
            
            % set crop dim
            CROP_SIZE = 227;
            
            if min(IMAGE_MEAN_DIM(1:2))<CROP_SIZE
                error('Mean image must be not smaller than input crop.');
            end
            
            if ~isequal(im_DIM(1:2),IMAGE_MEAN_DIM(1:2))
                % resize to the mean image dim
                im = imresize(im, IMAGE_MEAN_DIM(1:2), 'bilinear');
            end
            
            if NUM_CHANNELS==3
            % permute from RGB to BGR (IMAGE_MEAN is already BGR)
                im = im(:,:,[3 2 1]) - IMAGE_MEAN;
            elseif NUM_CHANNELS==1 && size(IMAGE_MEAN,3)==3
                im = im - sum(IMAGE_MEAN,3);
            elseif NUM_CHANNELS==1 && size(IMAGE_MEAN,3)==1
                im = im - IMAGE_MEAN;
            end
               
            if obj.Oversample==1 && sum(IMAGE_MEAN_DIM(1:2)==CROP_SIZE)
                
                disp('Mean image is equal to input crop: cannot oversample.');
                obj.Oversample=0;
                
            end
                
            if obj.Oversample==1
                
                % 4 corners and their x-axis flips
                images = zeros(CROP_SIZE, CROP_SIZE, NUM_CHANNELS, 10, 'single');
                h_off = IMAGE_MEAN_DIM(1)-CROP_SIZE + 1;
                w_off = IMAGE_MEAN_DIM(2)-CROP_SIZE + 1;
                curr = 1;
                for i = [0 h_off]
                    for j = [0 w_off]
                        if NUM_CHANNELS==3
                            images(:, :, :, curr) = permute(im(i:i+CROP_SIZE-1, j:j+CROP_SIZE-1, :), [2 1 3]);
                        else
                            images(:, :, :, curr) = im(i:i+CROP_SIZE-1, j:j+CROP_SIZE-1)';
                        end
                        images(:, :, :, curr+5) = images(end:-1:1, :, :, curr);
                        curr = curr + 1;
                    end
                end
                
                % central crop and x-axis flip
                h_off = ceil(( IMAGE_MEAN_DIM(1)-CROP_SIZE) / 2);
                w_off = ceil(( IMAGE_MEAN_DIM(2)-CROP_SIZE) / 2);
                images(:,:,:,5) = permute(im(h_off:h_off+CROP_SIZE-1,w_off:w_off+CROP_SIZE-1,:), [2 1 3]);
                images(:,:,:,10) = images(end:-1:1, :, :, curr);
                
            elseif obj.Oversample==0
                
                % pick only the central crop
                h_off = ceil(( IMAGE_MEAN_DIM(1)-CROP_SIZE) / 2);
                w_off = ceil(( IMAGE_MEAN_DIM(2)-CROP_SIZE) / 2);
                if NUM_CHANNELS==3
                    images = permute(im(h_off:h_off+CROP_SIZE-1,w_off:w_off+CROP_SIZE-1,:), [2 1 3]);
                else
                    images = im(h_off:h_off+CROP_SIZE-1,w_off:w_off+CROP_SIZE-1)';
                end
 
            end
        end
        
    end

end

