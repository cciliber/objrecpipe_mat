function crops_data = prepare_image_googlenet(im, mean_data, overscale, oversample)

%% Paper's preprocessing:
% 1. we resize the image to 4 scales where the shorter dimension (height or
%    width) is 256, 288, 320 and 352 respectively
% 2. we take the left, center and right squares (top, center and bottom)
% 3. for each square, we then take the 4 corners and the center 224×224 crop
%    as well as the square resized to 224×224 and their mirrored versions
% --> this results in 4×3×6×2 = 144 crops per image

% Our preprocessing:
% 1. we resize to 4 scales where the shorter dim is 256, 288, 320 and 352
% 2. we take the center square
% 3. we then take the 4 corners and the center 224×224 crop
%    as well as the square resized to 224×224 and their mirrored versions
% --> this results in 4×6×2 = 48 crops per image

SHORTER_SIDE = [256 288 320 352];
HALF_SIDE = SHORTER_SIDE/2-1;
CROPPED_DIM = 224;

%% Convert an image returned by Matlab's imread to im_data in caffe's data
% format: W x H x C with BGR channels

im_data = im(:, :, [3, 2, 1]);  % permute channels from RGB to BGR
im_data = permute(im_data, [2, 1, 3]);  % flip width and height
im_data = single(im_data);  % convert from uint8 to single

%% Subtract mean_data (BGR pixels)
im_data(:,:,1) = im_data(:,:,1) - mean_data(1);
im_data(:,:,2) = im_data(:,:,2) - mean_data(2);
im_data(:,:,3) = im_data(:,:,3) - mean_data(3);

%% Start scaling and cropping!

if overscale
    if oversample
        crops_data = zeros(CROPPED_DIM, CROPPED_DIM, 3, length(SHORTER_SIDE)*12, 'single');
    else
        crops_data = zeros(CROPPED_DIM, CROPPED_DIM, 3, length(SHORTER_SIDE), 'single');
    end
else
    if oversample
        crops_data = zeros(CROPPED_DIM, CROPPED_DIM, 3, 12, 'single');
    end
end

if overscale
    for rr=1:length(SHORTER_SIDE)
        
        %% 1. we resize to 4 scales where the shorter dim is 256, 288, 320 and 352
        new_dim = [NaN NaN];
        new_dim( min( [size(im_data,1) size(im_data,2)] ) ) = SHORTER_SIDE(rr);
        resized_data = imresize(im_data, new_dim, 'bilinear');
        
        %% 2. we take the center square
        center = size(resized_data);
        center = floor(center(1:2)/2)+1;
        range = [center(:)-HALF_SIDE(rr) center(:)+HALF_SIDE(rr)-1];
        resized_data = resized_data(range(1,:), range(2,:));
        
        %% 3. we then take the 4 corners and the center 224×224 crop
        %    as well as the square resized to 224×224 and their mirrored versions
        
        indices = [0 SHORTER_SIDE(rr)-CROPPED_DIM] + 1;
        
        if oversample
            
            startidx = 12*(rr-1);
            n = 1;
            for i = indices
                for j = indices
                    crops_data(:, :, :, startidx+n) = resized_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
                    crops_data(:, :, :, startidx+n+6) = crops_data(end:-1:1, :, :, startidx+n);
                    n = n + 1;
                end
            end
            
            % pick the central crop and mirror
            center = floor(indices(2) / 2);
            crops_data(:,:,:,startidx+5) = ...
                resized_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:);
            crops_data(:,:,:,startidx+10) = crops_data(end:-1:1, :, :, startidx+5);
            
            % resize and mirror
            center = floor(indices(2) / 2);
            crops_data(:,:,:,startidx+6) = ...
                imresize(resized_data, [CROPPED_DIM CROPPED_DIM], 'bilinear');
            crops_data(:,:,:,startidx+12) = crops_data(end:-1:1, :, :, startidx+6);
            
        else
            
            % pick the central crop
            %center = floor(indices(2) / 2) + 1;
            center = floor(indices(2) / 2);
            crops_data(:,:,:,rr) = ...
                resized_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:);
            
        end
    end
    
else
    
        %% 1. we resize to 1 scale where the shorter dim is 256
        rr = 1;
        new_dim = [NaN NaN];
        new_dim( min( [size(im_data,1) size(im_data,2)] ) ) = SHORTER_SIDE(rr);
        resized_data = imresize(im_data, new_dim, 'bilinear');
        
        %% 2. we take the center square
        center = size(resized_data);
        center = floor(center(1:2)/2)+1;
        range = [center(:)-HALF_SIDE(rr) center(:)+HALF_SIDE(rr)-1];
        resized_data = resized_data(range(1,:), range(2,:));
        
        %% 3. we then take the 4 corners and the center 224×224 crop
        %    as well as the square resized to 224×224 and their mirrored versions
        
        indices = [0 SHORTER_SIDE(rr)-CROPPED_DIM] + 1;
        
        if oversample
            
            n = 1;
            for i = indices
                for j = indices
                    crops_data(:, :, :, n) = resized_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
                    crops_data(:, :, :, n+6) = crops_data(end:-1:1, :, :, n);
                    n = n + 1;
                end
            end
            
            % pick the central crop and mirror
            center = floor(indices(2) / 2);
            crops_data(:,:,:,5) = ...
                resized_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:);
            crops_data(:,:,:,10) = crops_data(end:-1:1, :, :, 5);
            
            % resize and mirror
            center = floor(indices(2) / 2);
            crops_data(:,:,:,6) = ...
                imresize(resized_data, [CROPPED_DIM CROPPED_DIM], 'bilinear');
            crops_data(:,:,:,12) = crops_data(end:-1:1, :, :, 6);
            
        else
            
            % pick the central crop
            %center = floor(indices(2) / 2) + 1;
            center = floor(indices(2) / 2);
            crops_data = ...
                resized_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:);
            
        end
    end
    
end