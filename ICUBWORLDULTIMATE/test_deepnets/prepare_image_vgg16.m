function crops_data = prepare_image_vgg16(im, mean_data, CROPPED_DIM, overscale, SHORTER_SIDE, oversample, GRID)




if overscale
    
 
 
    
else
    
    %% 1. we resize to 1 scale where the shorter dim is 256
    rr = 1;
    new_dim = [NaN NaN];
    new_dim( min( [size(im_data,1) size(im_data,2)] ) ) = SHORTER_SIDE(rr);
    resized_data = imresize(im_data, new_dim, 'bilinear');
    
    if oversample && strcmp(GRID, '6crops')
        
        %% 2. we take the center square
        center = size(resized_data);
        center = floor(center(1:2)/2)+1;
        range = [center(:)-HALF_SIDE(rr) center(:)+HALF_SIDE(rr)-1];
        resized_data = resized_data(range(1,:), range(2,:));
        
        %% 3. we then take the 4 corners and the center 224×224 crop
        %    as well as the square resized to 224×224 and their mirrored versions
        
        indices = [0 SHORTER_SIDE(rr)-CROPPED_DIM] + 1;
        
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
        
    elseif oversample && strcmp(GRID, '5x5')
        
        %% 2. we take a 5x5 grid of crops and their mirrored versions
        
        grid_nodes = linspace(0,1,5) ;
        w = size(resized_data,2);
        h = size(resized_data,1);
        indices_j = floor((w - CROP_DIM) * grid_nodes) + 1 ;
        indices_i = floor((h - CROP_DIM) * grid_nodes) + 1 ;
        
        n = 1;
        for i = indices_i
            for j = indices_j
                crops_data(:, :, :, n) = resized_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
                crops_data(:, :, :, n+5*5) = crops_data(end:-1:1, :, :, n);
                n = n + 1;
            end
        end       
        
    else
        
        % pick the central crop
        grid_nodes = 0.5 ;
        w = size(resized_data,2);
        h = size(resized_data,1);
        indices_j = floor((w - CROP_DIM) * grid_nodes) + 1 ;
        indices_i = floor((h - CROP_DIM) * grid_nodes) + 1 ;
        crops_data = ...
            resized_data(indices_i:indices_i+CROPPED_DIM-1,indices_j:indices_j+CROPPED_DIM-1,:);
        
    end
    
end