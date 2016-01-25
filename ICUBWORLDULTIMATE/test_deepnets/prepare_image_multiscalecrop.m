function crops_data = prepare_image_googlenet(im, mean_data, CROPPED_DIM, SHORTER_SIDE, GRID)
                                    
%% GOOGLENET paper preprocessing:
% 1. resize the image to 4 scales where the shorter dim is 256, 288, 320, 352
% 2. take the left, center and right squares (top, center and bottom)
% 3. for each square, take the 4 corners and the center 224×224 crop
%    as well as the square resized to 224×224 and their mirrored versions
% --> this results in 4×3×6×2 = 144 crops per image

%% VGG paper's preprocessing:
% 1. resize the image to 3 scales where the shorter dim is 256, 384, 512
% 2. take a 5x5 grid of 224×224 crops + mirrored versions
% --> this results in 3×25×2 = 150 crops per image

% Our alternative reduced preprocessing:
% 1. we also fix the scale
% 2. we also try the other's preprocessing between the two
% 3. we also take only the center 224×224 crop

%% Convert an image returned by Matlab's imread to im_data in caffe's data
% format: W x H x C with BGR channels

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
if ~isempty(grid1)
    
    grid_side = grid1{1};
    grid_side = num2str(grid_side);
    if grid_side>1
        grid_nodes = linspace(0,1,grid_side);
    else
        grid_nodes = 0.5;
    end
    NsmallCROPS = grid1{2};
    NsmallCROPS = num2str(NsmallCROPS);
    NCROPS = grid_side*NsmallCROPS*2;

elseif ~isempty(grid2)
    
    grid_side = num2str(grid2{1});
    if grid_side>1
        grid_nodes = linspace(0,1,grid_side);
    else 
        grid_nodes = 0.5;
    end
    NCROPS = grid_side*grid_side*2;
    
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
    
    if ~isempty(grid1)
        
        w = size(resized_data,2);
        h = size(resized_data,1);
        resized_cropped_data = zeros(SHORTER_SIDE(rr), SHORTER_SIDE(rr), 3, grid_side);
        if w > h
            indices = floor((w - SHORTER_SIDE(rr)) * grid_nodes) + 1 ;
            n = 1;
            for i=indices
                resized_cropped_data(:,:,:,n) = resized_data(:, i:i+CROPPED_DIM-1);
                n = n + 1;
            end
        else
            indices = floor((h - SHORTER_SIDE(rr)) * grid_nodes) + 1 ;
            n = 1;
            for i=indices
                resized_cropped_data(:,:,:,n) = resized_data( i:i+CROPPED_DIM-1, :);
                n = n + 1;
            end 
        end
        
        % for each squared crop take:
        % either the 4 corners + center + resized and mirrored versions
        % or only the center + resized and mirrored version
        indices = [0 SHORTER_SIDE(rr)-CROPPED_DIM] + 1;
        center = floor(indices(2) / 2);
        
        for cc=1:grid_side
            
            if NsmallCROPS==6   
                startidx = N_SCALES*grid_side*NsmallCROPS*2*(rr-1)+NsmallCROPS*2*(cc-1);
                n = 1;
                for i = indices
                    for j = indices
                        crops_data(:, :, :, startidx+n) = resized_cropped_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :, cc);
                        crops_data(:, :, :, startidx+n+NsmallCROPS) = crops_data(end:-1:1, :, :, startidx+n);
                        n = n + 1;
                    end
                end
                % pick the central crop + all image resized and mirror
                crops_data(:,:,:,startidx+NsmallCROPS-1) = ...
                    resized_cropped_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:,cc);
                crops_data(:,:,:,startidx+(NsmallCROPS-1)*2) = crops_data(end:-1:1, :, :, startidx+NsmallCROPS-1);
                crops_data(:,:,:,startidx+NsmallCROPS) = ...
                    imresize(resized_cropped_data(:,:,:,cc), [CROPPED_DIM CROPPED_DIM], 'bilinear');
                crops_data(:,:,:,startidx+NsmallCROPS*2) = crops_data(end:-1:1, :, :, startidx+NsmallCROPS);
            elseif NsmallCROPS==1
                startidx = N_SCALES*grid_side*NsmallCROPS*(rr-1)+NsmallCROPS*(cc-1);
                n = 1;
                crops_data(:, :, :, startidx+n) = ...
                    resized_cropped_data(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:,cc);
            end            
        end
        
    elseif ~isempty(grid2)
        
        w = size(resized_data,2);
        h = size(resized_data,1);
        
        indices_j = floor((w - CROP_DIM) * grid_nodes) + 1 ;
        indices_i = floor((h - CROP_DIM) * grid_nodes) + 1 ;
        startidx = grid_side*grid_side*2*(rr-1);
        n = 1;
        for i = indices_i
            for j = indices_j
                crops_data(:, :, :, startidx+n) = resized_data(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
                crops_data(:, :, :, startidx+n+grid_side*grid_side) = crops_data(end:-1:1, :, :, startidx+n);
                n = n + 1;
            end
        end

    end

end