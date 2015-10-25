%%

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

day = 4;
camera = 'right';

in_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg', ['day' num2str(day)]);
out_root_path_bb_disp = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg_BB_disp', ['day' num2str(day)]);
out_root_path_centroid_disp = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg_BB_disp', ['day' num2str(day)]);

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
    
    xmin = img_info{1}(img_counter);
    ymin = img_info{1}(img_counter);
    width = img_info{1}(img_counter);
    height = img_info{1}(img_counter);
    
    xc = ;
    yc = ;
    
    I2 = imcrop(I, [xmin ymin width height]);
    
    imwrite(I2, fullfile(out_root_path_bb_disp, feat.Registry{ii}));
    
    img_counter = img_counter + 1;
    
    disp([num2str(ii) '/' num2str(length(feat.Registry))]);
end