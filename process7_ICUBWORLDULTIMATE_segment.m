%%

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

day = 4;
camera = 'right';

in_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg', ['day' num2str(day)]);

%%

out_root_path_bb_disp = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg_BB_disp', ['day' num2str(day)]);
out_root_path_centroid_disp = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg_BB_disp', ['day' num2str(day)]);

box_radius = 127; % half side of the bounding box
% e.g. 127 to crop 2x127+1+1 = 256 squared images
% e.g. 63 to crop 2x63+1+1 = 128 squared images
% e.g. 31 to crop 2x31+1+1 = 64 squared images

%%

feat = Features.GenericFeature();
feat.assign_registry_and_tree_from_folder(in_root_path, [], [], [], []);

feat.reproduce_tree(out_root_path_bb_disp);
feat.reproduce_tree(out_root_path_centroid_disp);

[img_paths, ~, img_exts] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);

reg_files = feat.Registry(strcmp(img_exts, '.txt'));
ref_files_path = img_paths(strcmp(img_exts, '.txt'));

feat.Registry(strcmp(img_exts, '.txt')) = [];
img_paths(strcmp(img_exts, '.txt')) = [];

change_dir = [1; ~strcmp(img_paths(1:(end-1)), img_paths(2:end))];

for ii=1:length(feat.Registry)
    
    if change_dir(ii)
        fid = fopen(fullfile(in_root_path, reg_files{strcmp(reg_files_path, img_paths{ii})}));
        if strcmp(camera, 'left')
            img_info = textscan(fid, '%s %f %f %d %d %d %d %d %d %d');
        elseif strcmp(camera, 'right')
            img_info = textscan(fid, '%s %f %f %d %d');
        end
        fclose(fid);
        
        img_counter = 1;
    end
    
    I = imread(fullfile(in_root_path, feat.Registry{ii}));
    
    xc = img_info{4}(img_counter);
    yc = img_info{5}(img_counter);
    
    radius = min(box_radius,xc-1);
    radius = min(radius,yc-1);
    radius = min(radius,size(I,2)-xc);
    radius = min(radius,size(I,1)-yc);
    
    xmin = img_info{7}(img_counter);
    ymin = img_info{8}(img_counter);
    width = img_info{9}(img_counter);
    height = img_info{10}(img_counter);
      
    if radius>10
        
        radius2 = radius*2+1;
        
        xminc = xc - radius;
        yminc = yc - radius;
        widthc = radius2;
        heightc = radius2;
    
    else
        
        disp(['SKIPPED: ' feat.Registry{ii} '.']);
        
    end
    
    I2 = imcrop(I, [xmin ymin width height]);
    I3 = imcrop(I, [xminc yminc widthc heightc]);
    
    imshow(I2);
    imwrite(I2, fullfile(out_root_path_bb_disp, feat.Registry{ii}));
    imshow(I3);
    imwrite(I3, fullfile(out_root_path_centroid_disp, feat.Registry{ii}));
    
    img_counter = img_counter + 1;
    
    disp([num2str(ii) '/' num2str(length(feat.Registry))]);
end