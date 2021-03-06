function crops = compute_grid(im, CROP_SIZE, GRID, resize, mirror)

if GRID>1
    grid_nodes = linspace(0,1,GRID);
else
    grid_nodes = 0.5;
end

NCROPS = (GRID*GRID+mod(GRID+1,2)+resize)*(mirror+1);
offset = mod(GRID+1,2)+resize;

w = size(im,2);
h = size(im,1);

indices_j = floor((w - CROP_SIZE) * grid_nodes) + 1 ;
indices_i = floor((h - CROP_SIZE) * grid_nodes) + 1 ;
        
crops = zeros(CROP_SIZE, CROP_SIZE, 3, NCROPS, 'single');

n = 1;
for i = indices_i
    for j = indices_j
        crops(:, :, :, n) = im(i:i+CROP_SIZE-1, j:j+CROP_SIZE-1, :);
        if mirror
            crops(:, :, :, n+GRID*GRID+offset) = crops(end:-1:1, :, :, n);
        end
        n = n + 1;
    end
end

if mod(GRID+1,2)
    j = floor((w - CROP_SIZE) * 0.5) + 1 ;
    i = floor((h - CROP_SIZE) * 0.5) + 1 ;
    crops(:, :, :, n) = im(i:i+CROP_SIZE-1, j:j+CROP_SIZE-1, :, :);
    if mirror
        crops(:, :, :, n+GRID*GRID+offset) = crops(end:-1:1, :, :, n);
    end 
    n = n + 1;
end

if resize
    crops(:,:,:,n) = imresize(im, [CROP_SIZE CROP_SIZE], 'bilinear');
    if mirror
        crops(:,:,:, n+GRID*GRID+offset) = crops(end:-1:1, :, :, n); 
    end
end