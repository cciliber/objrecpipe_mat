function crops_data = prepare_image_multiscalecrop(im, mean_data, CROPPED_DIM, SHORTER_SIDE, GRID)
                                    
%% GOOGLENET paper preprocessing:
% 1. resize the image to 4 scales where the shorter dim is 256, 288, 320, 352
% 2. take the left, center and right squares (top, center and bottom)
% 3. for each square, take the 4 corners and the center 224x224 crop
%    as well as the square resized to 224x224 and their mirrored versions
% --> this results in 4x3x6x2 = 144 crops per image

%% VGG paper's preprocessing:
% 1. resize the image to 3 scales where the shorter dim is 256, 384, 512
% 2. take a 5x5 grid of 224x224 crops + mirrored versions
% --> this results in 3x25x2 = 150 crops per image

% Our alternative reduced preprocessing:
% 1. we also fix the scale
% 2. we also try the other's preprocessing between the two
% 3. we also take only the center 224x224 crop

%% Convert an image returned by Matlab's imread 
% to caffe's data format: W x H x C with BGR channels
im_data = im(:, :, [3, 2, 1]);  % permute channels from RGB to BGR
im_data = permute(im_data, [2, 1, 3]);  % flip width and height
im_data = single(im_data);  % convert from uint8 to single

%% Subtract mean_data (BGR pixels)
im_data(:,:,1) = im_data(:,:,1) - mean_data(1);
im_data(:,:,2) = im_data(:,:,2) - mean_data(2);
im_data(:,:,3) = im_data(:,:,3) - mean_data(3);

%% Determine the preprocessing operations

grid1 = strsplit(GRID, '-');
grid2 = strsplit(GRID, 'x');
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

N_SCALES = length(SHORTER_SIDE);

NCROPS=NCROPS*N_SCALES;
crops_data = zeros(CROPPED_DIM, CROPPED_DIM, 3, NCROPS, 'single');


%% Start scaling and cropping!

for rr=1:N_SCALES
    
    %% 1. resize maintaining aspect ratio
    
    new_dim = [NaN NaN];
    if size(im_data,1) < size(im_data,2)
        new_dim(1) = SHORTER_SIDE(rr);
    else
        new_dim(2) = SHORTER_SIDE(rr);
    end
    resized_data = imresize(im_data, new_dim, 'bilinear');
    
    %% 2. take the squared crops according to GRID
    
    if length(grid1)>1
        
        w = size(resized_data,2);
        h = size(resized_data,1);
        resized_cropped_data = zeros(SHORTER_SIDE(rr), SHORTER_SIDE(rr), 3, grid_side);
        indices = floor((max(w,h) - SHORTER_SIDE(rr)) * grid_nodes) + 1 ;
        n = 1;
        for i=indices
            if w > h
                resized_cropped_data(:,:,:,n) = resized_data(:, i:i+SHORTER_SIDE(rr)-1, :);
            else
                resized_cropped_data(:,:,:,n) = resized_data( i:i+SHORTER_SIDE(rr)-1, :, :);
            end
            n = n + 1;
        end
        
        % for each squared crop take:
        % either the 4 corners + center + resized and mirrored versions
        % or only the center
        indices = floor((SHORTER_SIDE(rr) - CROPPED_DIM) * sub_grid_nodes) + 1 ;
        for cc=1:grid_side
            if sub_grid_side>1   
                startidx = (rr-1)*grid_side*(sub_grid_side*sub_grid_side+2)*2 + ...
                    (cc-1)*(sub_grid_side*sub_grid_side+2)*2;
            else
                startidx = (rr-1)*grid_side+cc-1;
            end
            n = 1;
            for i = indices
                for j = indices
                    crops_data(:, :, :, startidx+n) = resized_cropped_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :, cc);
                    if sub_grid_side>1
                        crops_data(:, :, :, startidx+n+(sub_grid_side*sub_grid_side+2)) = crops_data(end:-1:1, :, :, startidx+n);
                    end
                    n = n + 1;
                end
            end
            if sub_grid_side>1
                i = floor((SHORTER_SIDE(rr) - CROPPED_DIM) * 0.5) + 1 ;
                j = i;
                crops_data(:, :, :, startidx+n) = resized_cropped_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :, cc);
                crops_data(:, :, :, startidx+2*n) = crops_data(end:-1:1, :, :, startidx+n);
                crops_data(:,:,:,startidx+n+1) = ...
                    imresize(resized_cropped_data(:,:,:,cc), [CROPPED_DIM CROPPED_DIM], 'bilinear');
                crops_data(:,:,:,startidx+(n+1)*2) = crops_data(end:-1:1, :, :, startidx+n+1);     
            end      
        end
        
    elseif length(grid2)>1
        
        w = size(resized_data,2);
        h = size(resized_data,1);
        
        indices_j = floor((w - CROPPED_DIM) * grid_nodes) + 1 ;
        indices_i = floor((h - CROPPED_DIM) * grid_nodes) + 1 ;
        startidx = grid_side*grid_side*2*(rr-1);
        n = 1;
        for i = indices_i
            for j = indices_j
                crops_data(:, :, :, startidx+n) = resized_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
                if grid_side>1
                    crops_data(:, :, :, startidx+n+grid_side*grid_side) = crops_data(end:-1:1, :, :, startidx+n);
                end
                n = n + 1;
            end
        end

    end

end