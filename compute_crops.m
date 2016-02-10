function crops = compute_crops(im, GRID)

if isempty(GRID)
    
    error('Empty GRID!');
    
else
    
    if GRID>1
        grid_nodes = linspace(0,1,GRID);
    else
        grid_nodes = 0.5;
    end
    
    NCROPS = GRID;
    
    w = size(im,2);
    h = size(im,1);
    
    CROP_SIZE = min(w,h);
    
    indices = floor((max(w,h) - CROP_SIZE) * grid_nodes) + 1 ;
    
    crops = zeros(CROP_SIZE, CROP_SIZE, 3, NCROPS);
    
    n = 1;
    for i=indices
        if w > h
            crops(:,:,:,n) = im(:, i:i+CROP_SIZE-1, :);
        else
            crops(:,:,:,n) = im( i:i+SCROP_SIZE-1, :, :);
        end
        n = n + 1;
    end
    
end