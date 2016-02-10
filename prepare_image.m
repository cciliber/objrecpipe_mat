function crops_data = prepare_image(im, prep, mean_data, CROP_SIZE)

%% Convert an image returned by Matlab's imread 

% to caffe's data format: W x H x C with BGR channels
im_data = im(:, :, [3, 2, 1]);  % permute channels from RGB to BGR
im_data = permute(im_data, [2, 1, 3]);  % flip width and height
im_data = single(im_data);  % convert from uint8 to single

%% Subtract mean

if isequal(size(mean_data(:)), [3 1]) 
    % mean data: BGR pixels
    for ii=1:3
        im_data(:,:,ii) = im_data(:,:,ii) - mean_data(ii);
    end
    rescaled = false;
else
    % mean data: mat file already in W x H x C with BGR channels
    MEAN_W = size(mean_data,1);
    MEAN_H = size(mean_data,2);
    IMAGE_W = size(im_data,1);
    IMAGE_H = size(im_data,2);
    if ~isequal([IMAGE_W IMAGE_H], [MEAN_W MEAN_H])
        im_data = imresize(im_data, [MEAN_W MEAN_H], 'bilinear');
    end
    prep.SCALING.scales = [MEAN_W MEAN_H];
    prep.SCALING.aspect_ratio = false;
    rescaled = true;
    im_data = im_data - mean_data;
end

%% Determine the preprocessing operations

if prep.SCALING.aspect_ratio
    if size(prep.SCALING.scales, 2)>1
        error('');
    end
else
    if size(prep.SCALING.scales, 2)==1
        error('');
    end
end
NSCALES = size(prep.SCALING.scales, 1);

NCROPS = (prep.GRID.nodes*prep.GRID.nodes+mod(prep.GRID.nodes+1,2)+prep.GRID.resize)*(prep.GRID.mirror+1);

if ~isempty(prep.OUTER_GRID)
    crops_data = zeros(CROP_SIZE, CROP_SIZE, 3, NCROPS*prep.OUTER_GRID*NSCALES, 'single'); 
else
    crops_data = zeros(CROP_SIZE, CROP_SIZE, 3, NCROPS*NSCALES, 'single'); 
end
    
for is=1:NSCALES
    
    if rescaled==false
        if prep.SCALING.aspect_ratio==false
            im_data_resized = imresize(im_data, [prep.SCALING.scales(is,1) prep.SCALING.scales(is,2)], 'bilinear');   
        else
            new_dim = [NaN NaN];
            if size(im_data,1) < size(im_data,2)
                new_dim(1) = prep.SCALING.scales(is,1);
            else
                new_dim(2) = prep.SCALING.scales(is,2);
            end
            im_data_resized = imresize(im_data, new_dim, 'bilinear'); 
        end
    else
        im_data_resized = im_data;
    end
    
    if ~isempty(prep.OUTER_GRID)
        
        if prep.SCALING.scales(is,1)==prep.SCALING.scales(is,2)
            error('Specifying square resize and non empty OUTER_GRID');
        end
        outer_crops = compute_crops(im_data_resized, prep.OUTER_GRID);
        
        crops = zeros(CROP_SIZE, CROP_SIZE, 3, NCROPS*prep.OUTER_GRID, 'single');
        for ic=1:prep.OUTER_GRID
            crops(:,:,:,((ic-1)*NCROPS+1):ic*NCROPS) = compute_grid(outer_crops(:,:,:,ic), prep.GRID.nodes, prep.resize, prep.mirror);
        end
        crops_data(:,:,:, ((is-1)*NCROPS*prep.OUTER_GRID + 1) : (is*NCROPS*prep.OUTER_GRID) ) = crops;
    else
        crops = compute_grid(im_data_resized, CROP_SIZE, prep.GRID.nodes, prep.GRID.resize, prep.GRID.mirror);
        crops_data(:,:,:, ((is-1)*NCROPS + 1) : (is*NCROPS) ) = crops;
    end
    
end