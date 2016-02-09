function caffestuff = setup_preprocessing(caffestuff)

if strcmp(caffestuff.model, 'caffenet')
    
    % scales
    caffestuff.SHORTER_SIDE = [];
    caffestuff.MEAN_W = size(caffestuff.mean_data, 1);
    caffestuff.MEAN_H = size(caffestuff.mean_data, 2);
    
    % crops
    %if oversample
        caffestuff.NCROPS = 10;
        caffestuff.central_score_idx = 5;
    %else
    %    caffestuff.NCROPS = 1;
    %    caffestuff.central_score_idx = [];
    %end
    caffestuff.GRID = [];
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);

elseif strcmp(caffestuff.model, 'googlenet_caffe')
    
    % scales
    caffestuff.SHORTER_SIDE = [];
    
    % crops
    if oversample
        caffestuff.NCROPS = 10;
        caffestuff.central_score_idx = 5;
    else
        caffestuff.NCROPS = 1;
        caffestuff.central_score_idx = [];
    end
    caffestuff.GRID = [];
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);
 
elseif strcmp(caffestuff.model, 'googlenet_paper')
    
    % scales
    if oversample && overscale   
        caffestuff.SHORTER_SIDE = [256 288 320 352];
    else
        caffestuff.SHORTER_SIDE = 256;
    end
    centralscale = 1;
    
    % crops
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            caffestuff.NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
            caffestuff.central_score_idx = floor(grid_side/2)*(sub_grid_side*sub_grid_side+2)*2+(sub_grid_side*sub_grid_side+1);
        else
            caffestuff.NCROPS = grid_side;
            caffestuff.central_score_idx = floor(grid_side/2)+1;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        if grid_side>1
            caffestuff.NCROPS = grid_side*grid_side*2;
        else
            caffestuff.NCROPS = 1;
        end
        caffestuff.central_score_idx = floor(grid_side*grid_side/2)+1;
    end
    caffestuff.GRID = GRID;
    caffestuff.central_score_idx = caffestuff.central_score_idx + caffestuff.NCROPS*(centralscale-1);
    caffestuff.NCROPS = caffestuff.NCROPS*length(caffestuff.SHORTER_SIDE);
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);
  
elseif strcmp(caffestuff.model, 'vgg16')
    
    % scales
    if oversample && overscale 
        caffestuff.SHORTER_SIDE = [256 384 512];
    else
        caffestuff.SHORTER_SIDE = 384;
    end
    centralscale = 2;

    % crops
    grid1 = strsplit(GRID, '-');
    grid2 = strsplit(GRID, 'x');
    if length(grid1)>1
        grid_side = str2num(grid1{1});
        sub_grid_side = str2num(grid1{2});
        if sub_grid_side>1
            caffestuff.NCROPS = grid_side*(sub_grid_side*sub_grid_side+2)*2;
            caffestuff.central_score_idx = floor(grid_side/2)*(sub_grid_side*sub_grid_side+2)*2+(sub_grid_side*sub_grid_side+1);
        else
            caffestuff.NCROPS = grid_side;
            caffestuff.central_score_idx = floor(grid_side/2)+1;
        end
    elseif length(grid2)>1
        grid_side = str2num(grid2{1});
        if grid_side>1
            caffestuff.NCROPS = grid_side*grid_side*2;
        else
            caffestuff.NCROPS = 1;
        end
        caffestuff.central_score_idx = floor(grid_side*grid_side/2)+1;
    end
    caffestuff.GRID = GRID;
    caffestuff.central_score_idx = caffestuff.central_score_idx + caffestuff.NCROPS*(centralscale-1);
    caffestuff.NCROPS = caffestuff.NCROPS*length(caffestuff.SHORTER_SIDE);
    
    % batch size, in images
    caffestuff.max_bsize = round(500/caffestuff.NCROPS);

end