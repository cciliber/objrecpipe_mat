function crops_data = prepare_image(im, caffestuff)

mean_data = caffestuff.mean_data;

GRID = caffestuff.GRID;
SCALING = caffestuff.SCALING;

%% Convert an image returned by Matlab's imread 
% to caffe's data format: W x H x C with BGR channels
im_data = im(:, :, [3, 2, 1]);  % permute channels from RGB to BGR
im_data = permute(im_data, [2, 1, 3]);  % flip width and height
im_data = single(im_data);  % convert from uint8 to single

IMAGE_DIM = size(im_data);

%% Subtract mean

if isequal(size(mean_data(:)), [3 1]) 
    % mean data: BGR pixels
    for ii=1:3
        im_data(:,:,ii) = im_data(:,:,ii) - mean_data(ii);
    end
else
    % mean data: mat file already in W x H x C with BGR channels
    MEAN_W = size(mean_data,1);
    MEAN_H = size(mean_data,2);
    if ~isequal(IMAGE_DIM(1:2), [MEAN_W MEAN_H])
        im_data = imresize(im_data, [MEAN_W MEAN_H], 'bilinear');
    end
    im_data = im_data - mean_data;
end

%% Determine the preprocessing operations

N_SCALES = size(SCALING,1);

N_LEVELS = numel(GRID);


grid1 = strsplit(GRID, '-');
if length(grid1)>1
    
    grid_side = str2num(grid1{1});
    if grid_side>1
        grid_nodes = linspace(0,1,grid_side);
    else
        grid_nodes = 0.5;
    end
    
    sub_grid_side = str2num(grid1{2});
    if sub_grid_side>1
        sub_grid_nodes = linspace(0,1,sub_grid_side);
        NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
    else
        sub_grid_nodes = 0.5;
        NCROPS = grid_side;
    end
end

grid2 = strsplit(GRID, 'x');

elseif length(grid2)>1
    
    grid_side = str2num(grid2{1});
    if grid_side>1
        grid_nodes = linspace(0,1,grid_side);
        NCROPS = grid_side*grid_side*2;
    else 
        grid_nodes = 0.5;
        NCROPS = 1;
    end
    
end



NCROPS=NCROPS*N_SCALES;
crops_data = zeros(CROPPED_DIM, CROPPED_DIM, 3, NCROPS, 'single');






SCALING = caffestuff.scaling;
if ~isempty(SCALING)
    
    if 
    
    if ~isequal(IMAGE_DIM(1:2), [MEAN_DIM MEAN_DIM])
        im_data = imresize(im_data, [MEAN_DIM MEAN_DIM], 'bilinear');
    end
    
end