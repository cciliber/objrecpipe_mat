classdef MySIFT < Features.GenericFeature
    
    properties
        
        Step
        Scale
        UseLowe
        Dense
        Normalize
        
    end
    
    methods
        
        function obj = MySIFT(step, scale, use_lowe, dense, normalize)
            
            obj = obj@Features.GenericFeature();
             
            obj.Step = step;
            obj.Scale = scale;
                
            obj.UseLowe = use_lowe;
            obj.Dense = dense;
            obj.Normalize = normalize;
 
        end
        
        function [feat, grid, im_size] = extract_image(obj, src, src_grid, im_size, mod_out, dst)
          
            if ischar(src)
                I = imread(src);
            elseif isnumeric(src)
                I = src;
            else 
                error('Input image must be either character or numeric array.');
            end
            
            if (size(I,3) == 3)
                I = rgb2gray(I);
            end
               
            im_size = size(I)';
            im_h = im_size(1);
            im_w = im_size(2);

            if obj.UseLowe
                
                convG = fspecial('gaussian');
                I = imfilter(I, convG,'replicate');
                [~, tmp_feat, tmp_locations] = sift(I);
                % one scale
                feat = tmp_feat';
                grid = tmp_locations(:,1:2)';

            else
                
                I = im2double(I);
                
                if (obj.Dense)
                    
                    gridSpacing = obj.Step;
                    patchSize = max(obj.Scale);
 
                    remX = mod(im_w-patchSize, gridSpacing);
                    offsetX = floor(remX/2)+1;
                    remY = mod(im_h-patchSize, gridSpacing);
                    offsetY = floor(remY/2)+1;
                    
                    [gridX, gridY] = meshgrid(offsetX:gridSpacing:im_w-patchSize+1, offsetY:gridSpacing:im_h-patchSize+1);
                    
                    locx = gridX(:) + patchSize/2 - 0.5;
                    locy = gridY(:) + patchSize/2 - 0.5;
                    tmp_grid = [locx'; locy'];
                    grid = repmat(tmp_grid,1,numel(obj.Scale));

                    % multiple scales
                    idx_scale = 1;
                    sift_arr = obj.sp_find_sift_grid(I, gridX, gridY, obj.Scale(idx_scale), 0.8);
                    [tmp_feat, ~] = obj.sp_normalize_sift(sift_arr, 1);                        
                    feat = zeros(numel(obj.Scale)*size(tmp_feat,1),size(tmp_feat,2));
                    feat( ((idx_scale-1)*size(tmp_feat,1)+1) : (idx_scale*size(tmp_feat,1)), : ) = tmp_feat;
                    for idx_scale = 2:numel(obj.Scale)
                        
                        sift_arr = obj.sp_find_sift_grid(I, gridX, gridY, obj.Scale(idx_scale), 0.8);
                        [tmp_feat, ~] = obj.sp_normalize_sift(sift_arr, 1);                        
                        feat( ((idx_scale-1)*size(tmp_feat,1)+1) : (idx_scale*size(tmp_feat,1)), : ) = tmp_feat;
                    end
                    
                else
                    [tmp_locations,tmp_feat] = vl_sift(I,'FloatDescriptors');
                    
                    if (obj.Normalize)
                       for k = 1:size(tmp_feat,2)
                           factor = norm(tmp_feat(:,k));
                           if (factor>0)
                              tmp_feat(:,k) = tmp_feat(:,k)/factor;
                           end
                            
                           tmp_feat(tmp_feat(:,k)>0.2,k) = 0.2;
                           factor = norm(tmp_feat(:,k));
                           if (factor>0)
                              tmp_feat(:,k) = tmp_feat(:,k)/factor;
                           end
                       end
                    end
                end
                   
            end
            
            feat = feat';
            feat_size = size(feat);
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
        
        function sift_arr = sp_find_sift_grid(obj, I, grid_x, grid_y, patch_size, sigma_edge)
            
            % parameters
            num_angles = 8;
            num_bins = 4;
            num_samples = num_bins * num_bins;
            alpha = 9;
            
            if nargin < 5
                sigma_edge = 1;
            end
            
            angle_step = 2 * pi / num_angles;
            angles = 0:angle_step:2*pi;
            angles(num_angles+1) = []; % bin centers
            
            [hgt wid] = size(I);
            num_patches = numel(grid_x);
            
            sift_arr = zeros(num_patches, num_samples * num_angles);
            
            [G_X,G_Y] = obj.gen_dgauss(sigma_edge);
            I_X = filter2(G_X, I, 'same'); % vertical edges
            I_Y = filter2(G_Y, I, 'same'); % horizontal edges
            I_mag = sqrt(I_X.^2 + I_Y.^2); % gradient magnitude
            I_theta = atan2(I_Y,I_X);
            I_theta(find(isnan(I_theta))) = 0; % necessary????
            
            % make default grid of samples (centered at zero, width 2)
            interval = 2/num_bins:2/num_bins:2;
            interval = interval - (1/num_bins + 1);
            [sample_x sample_y] = meshgrid(interval, interval);
            sample_x = reshape(sample_x, [1 num_samples]);
            sample_y = reshape(sample_y, [1 num_samples]);
            
            % make orientation images
            I_orientation = zeros(hgt, wid, num_angles);
            % for each histogram angle
            for a=1:num_angles
                % compute each orientation channel
                tmp = cos(I_theta - angles(a)).^alpha;
                tmp = tmp .* (tmp > 0);
                
                % weight by magnitude
                I_orientation(:,:,a) = tmp .* I_mag;
            end
            
            % for all patches
            for i=1:num_patches
                r = patch_size/2;
                cx = grid_x(i) + r - 0.5;
                cy = grid_y(i) + r - 0.5;
                
                % find coordinates of sample points (bin centers)
                sample_x_t = sample_x * r + cx;
                sample_y_t = sample_y * r + cy;
                sample_res = sample_y_t(2) - sample_y_t(1);
                
                % find window of pixels that contributes to this descriptor
                x_lo = grid_x(i);
                x_hi = grid_x(i) + patch_size - 1;
                y_lo = grid_y(i);
                y_hi = grid_y(i) + patch_size - 1;
                
                % find coordinates of pixels
                [sample_px, sample_py] = meshgrid(x_lo:x_hi,y_lo:y_hi);
                num_pix = numel(sample_px);
                sample_px = reshape(sample_px, [num_pix 1]);
                sample_py = reshape(sample_py, [num_pix 1]);
                
                % find (horiz, vert) distance between each pixel and each grid sample
                dist_px = abs(repmat(sample_px, [1 num_samples]) - repmat(sample_x_t, [num_pix 1]));
                dist_py = abs(repmat(sample_py, [1 num_samples]) - repmat(sample_y_t, [num_pix 1]));
                
                % find weight of contribution of each pixel to each bin
                weights_x = dist_px/sample_res;
                weights_x = (1 - weights_x) .* (weights_x <= 1);
                weights_y = dist_py/sample_res;
                weights_y = (1 - weights_y) .* (weights_y <= 1);
                weights = weights_x .* weights_y;
                %     % make sure that the weights for each pixel sum to one?
                %     tmp = sum(weights,2);
                %     tmp = tmp + (tmp == 0);
                %     weights = weights ./ repmat(tmp, [1 num_samples]);
                
                % make sift descriptor
                curr_sift = zeros(num_angles, num_samples);
                for a = 1:num_angles
                    tmp = reshape(I_orientation(y_lo:y_hi,x_lo:x_hi,a),[num_pix 1]);
                    tmp = repmat(tmp, [1 num_samples]);
                    curr_sift(a,:) = sum(tmp .* weights);
                end
                sift_arr(i,:) = reshape(curr_sift, [1 num_samples * num_angles]);
                
                %     % visualization
                %     if sigma_edge >= 3
                %         subplot(1,2,1);
                %         rescale_and_imshow(I(y_lo:y_hi,x_lo:x_hi) .* reshape(sum(weights,2), [y_hi-y_lo+1,x_hi-x_lo+1]));
                %         subplot(1,2,2);
                %         rescale_and_imshow(curr_sift);
                %         pause;
                %     end
            end
        end
        function G = gen_gauss(obj, sigma)
            
            if all(size(sigma)==[1, 1])
                % isotropic gaussian
                f_wid = 4 * ceil(sigma) + 1;
                G = fspecial('gaussian', f_wid, sigma);
                %	G = normpdf(-f_wid:f_wid,0,sigma);
                %	G = G' * G;
            else
                % anisotropic gaussian
                f_wid_x = 2 * ceil(sigma(1)) + 1;
                f_wid_y = 2 * ceil(sigma(2)) + 1;
                G_x = normpdf(-f_wid_x:f_wid_x,0,sigma(1));
                G_y = normpdf(-f_wid_y:f_wid_y,0,sigma(2));
                G = G_y' * G_x;
            end
        end
        function [GX,GY] = gen_dgauss(obj, sigma)
            
            % laplacian of size sigma
            %f_wid = 4 * floor(sigma);
            %G = normpdf(-f_wid:f_wid,0,sigma);
            %G = G' * G;
            G = obj.gen_gauss(sigma);
            [GX,GY] = gradient(G);
            
            GX = GX * 2 ./ sum(sum(abs(GX)));
            GY = GY * 2 ./ sum(sum(abs(GY))); 
        end
        function [sift_arr, siftlen] = sp_normalize_sift(obj, sift_arr, threshold)
            % normalize SIFT descriptors (after Lowe)
            
            % find indices of descriptors to be normalized (those whose norm is larger than 1)
            siftlen = sqrt(sum(sift_arr.^2, 2));
            
            normalize_ind1 = [siftlen >= threshold];
            normalize_ind2 = ~normalize_ind1;
            
            sift_arr_hcontrast = sift_arr(normalize_ind1, :);
            sift_arr_hcontrast = sift_arr_hcontrast ./ repmat(siftlen(normalize_ind1, :), [1 size(sift_arr,2)]);
            
            sift_arr_lcontrast = sift_arr(normalize_ind2,:);
            sift_arr_lcontrast = sift_arr_lcontrast./ threshold;
            
            % suppress large gradients
            sift_arr_hcontrast( sift_arr_hcontrast > 0.2 ) = 0.2;
            sift_arr_lcontrast( sift_arr_lcontrast > 0.2 ) = 0.2;
            
            % finally, renormalize to unit length
            sift_arr_hcontrast = sift_arr_hcontrast ./ repmat(sqrt(sum(sift_arr_hcontrast.^2, 2)), [1 size(sift_arr,2)]);
            
            sift_arr(normalize_ind1,:) = sift_arr_hcontrast;
            sift_arr(normalize_ind2,:) = sift_arr_lcontrast;
        end
    end
end

