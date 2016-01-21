function crops_data = prepare_image_caffenet(im, mean_data, oversample)

MEAN_DIM = 256;
CROPPED_DIM = 227;

% Convert an image returned by Matlab's imread to im_data in caffe's data
% format: W x H x C with BGR channels
im_data = im(:, :, [3, 2, 1]);  % permute channels from RGB to BGR
im_data = permute(im_data, [2, 1, 3]);  % flip width and height
im_data = single(im_data);  % convert from uint8 to single

IMAGE_DIM = size(im_data);

if ~isequal(IMAGE_DIM(1:2),MEAN_DIM)
    im_data = imresize(im_data, [MEAN_DIM MEAN_DIM], 'bilinear');  % resize im_data
end

im_data = im_data - mean_data;  % subtract mean_data (already in W x H x C, BGR)

indices = [0 MEAN_DIM-CROPPED_DIM] + 1;

if oversample
    
    % oversample (4 corners, center, and their x-axis flips)
    crops_data = zeros(CROPPED_DIM, CROPPED_DIM, 3, 10, 'single');
   
    n = 1;
    for i = indices
        for j = indices
            crops_data(:, :, :, n) = im_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
            crops_data(:, :, :, n+5) = crops_data(end:-1:1, :, :, n);
            n = n + 1;
        end
    end
    
    %center = floor(indices(2) / 2) + 1;
    center = floor(indices(2) / 2);
    crops_data(:,:,:,5) = ...
        im_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:);
    crops_data(:,:,:,10) = crops_data(end:-1:1, :, :, 5);
    
else
    
    % pick only the central crop
 
     center = floor(indices(2) / 2) + 1;
     crops_data = ...
        im_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:);
    
end