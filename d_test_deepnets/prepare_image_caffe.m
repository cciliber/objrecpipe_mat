function crops_data = prepare_image_caffe(im, caffestuff)

mean_data = caffestuff.mean_data;
CROP_SIZE = caffestuff.CROP_SIZE;
oversample = caffestuff.NCROPS~=1;

% Convert an image returned by Matlab's imread to im_data in caffe's data
% format: W x H x C with BGR channels
im_data = im(:, :, [3, 2, 1]);  % permute channels from RGB to BGR
im_data = permute(im_data, [2, 1, 3]);  % flip width and height
im_data = single(im_data);  % convert from uint8 to single

IMAGE_DIM = size(im_data);

if isequal(size(mean_data(:)), [3 1]) 
    
    MEAN_DIM = 256;
    if ~isequal(IMAGE_DIM(1:2), [MEAN_DIM MEAN_DIM])
        im_data = imresize(im_data, [MEAN_DIM MEAN_DIM], 'bilinear');
    end
    for ii=1:3
        im_data(:,:,ii) = im_data(:,:,ii) - mean_data(ii);
    end
    
else
    
    MEAN_DIM = size(mean_data,1);
    if MEAN_DIM~=size(mean_data,2)
        error('mean_data is not squared!');
    end
    if ~isequal(IMAGE_DIM(1:2), [MEAN_DIM MEAN_DIM])
        im_data = imresize(im_data, [MEAN_DIM MEAN_DIM], 'bilinear');
    end
    im_data = im_data - mean_data;  % subtract mean_data (already in W x H x C, BGR)
    
end

indices = [0 MEAN_DIM-CROP_SIZE] + 1;

if oversample
    
    % oversample (4 corners, center, and their x-axis flips)
    crops_data = zeros(CROP_SIZE, CROP_SIZE, 3, 10, 'single');
   
    n = 1;
    for i = indices
        for j = indices
            crops_data(:, :, :, n) = im_data(i:i+CROP_SIZE-1, j:j+CROP_SIZE-1, :);
            crops_data(:, :, :, n+5) = crops_data(end:-1:1, :, :, n);
            n = n + 1;
        end
    end
    
    %center = floor(indices(2) / 2) + 1;
    center = floor(indices(2) / 2);
    crops_data(:,:,:,5) = ...
        im_data(center:center+CROP_SIZE-1,center:center+CROP_SIZE-1,:);
    crops_data(:,:,:,10) = crops_data(end:-1:1, :, :, 5);
    
else
    
    % pick only the central crop
 
     %center = floor(indices(2) / 2) + 1;
     center = floor(indices(2) / 2);
     crops_data = ...
        im_data(center:center+CROP_SIZE-1,center:center+CROP_SIZE-1,:);
    
end