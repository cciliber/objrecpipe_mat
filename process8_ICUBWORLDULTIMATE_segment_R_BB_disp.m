%%

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%%

day = 7;

in_root_path = fullfile('/media/giulia/DATA/ICUBWORLD_ULTIMATE_folderized_jpg', ['day' num2str(day)]);

%%

out_root_path_bb_disp = fullfile('/media/giulia/MyPassport/ICUBWORLD_ULTIMATE_BB_disp', ['day' num2str(day)]);


box_radius = 191; % half side of the bounding box
% e.g. 191 to crop 2x191+1+1 = 384 squared images
% e.g. 127 to crop 2x127+1+1 = 256 squared images
% e.g. 63 to crop 2x63+1+1 = 128 squared images
% e.g. 31 to crop 2x31+1+1 = 64 squared images

widthc = 2*box_radius+1;
heightc = 2*box_radius+1;
    
width = 2*box_radius+1;
height = 2*box_radius+1;

disp_bb_margin = 40;

%%

feat = Features.GenericFeature();
feat.assign_registry_and_tree_from_folder(in_root_path, [], [], [], []);

feat.reproduce_tree(out_root_path_bb_disp);

[img_paths, ~, img_exts] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);

[~, camera, ~] = cellfun(@fileparts, img_paths, 'UniformOutput', 0);

feat.Registry(strcmp(camera, 'left')) = [];
img_paths(strcmp(camera, 'left')) = [];
img_exts(strcmp(camera, 'left')) = [];
camera(strcmp(camera, 'left')) = [];

reg_files = feat.Registry( (strcmp(img_exts, '.txt') & (~strcmp(camera, 'right'))) );
reg_files_path = img_paths( (strcmp(img_exts, '.txt') & (~strcmp(camera, 'right'))) );

feat.Registry(strcmp(img_exts, '.txt')) = [];
img_paths(strcmp(img_exts, '.txt')) = [];

change_dir = [1; ~strcmp(img_paths(1:(end-1)), img_paths(2:end))];

figure(1);

tic

for ii=1:length(feat.Registry)
    
    if change_dir(ii)
        regfile_current = reg_files{strcmp(reg_files_path, fileparts(img_paths{ii}))};
        fid = fopen(fullfile(in_root_path, regfile_current));
        img_info = textscan(fid, '%s %f %f %d %d %s %f %f %d %d %d %d %d %d %d\n'); % the camera is 'right' but we want the 'left' bb
        fclose(fid);
        
        img_counter = 1;
        
        copyfile(fullfile(in_root_path, regfile_current), fullfile(out_root_path_bb_disp, regfile_current));
    end

    I = imread(fullfile(in_root_path, feat.Registry{ii}));
    
    % img_info contains:
    % (imgR_path, imgR_t, bbR_t, bbR_cx, bbR_cy, imgL_path, imgL_t, bbL_t, bbL_cx, bbL_cy, bbL_pxN, bbL_tlx, bbL_tly, bbL_w, bbL_h)
    
    xcL = img_info{9}(img_counter);
    ycL = img_info{10}(img_counter);
        
    if ~(img_info{4}(img_counter)==0 && img_info{5}(img_counter)==0)
        
        xcR = img_info{4}(img_counter);
        ycR = img_info{5}(img_counter);
        
    else
        disp(['ATTENTION, 0 0: ' feat.Registry{ii} '.']);
    end

%        radius = min(box_radius,xc-1);
%        radius = min(radius,yc-1);
%        radius = min(radius,size(I,2)-xc);
%        radius = min(radius,size(I,1)-yc);
%
%        if radius>10
%         
%           radius2 = radius*2+1;
%         
%           xminc = xc - radius;
%           yminc = yc - radius;
%           widthc = radius2;
%           heightc = radius2;
%     
%        else
%         
%           disp(['SKIPPED: ' feat.Registry{ii} '.']);
%         
%        end

    if img_info{12}(img_counter)==0 && img_info{13}(img_counter)==0 && img_info{14}(img_counter)==0 && img_info{15}(img_counter)==0
    
        xminL = xcL - (widthL-1)/2;
        yminL = ycL - (heightL-1)/2;
    
    else
    
        xminL = img_info{12}(img_counter);
        yminL = img_info{13}(img_counter);
    
        widthL = img_info{14}(img_counter);
        heightL = img_info{15}(img_counter);
    
        xminL = xminL - disp_bb_margin;
        yminL = yminL - disp_bb_margin;
        widthL = widthL + 2*disp_bb_margin;
        heightL = heightL + 2*disp_bb_margin;
        
    end

    % compute BB for the right using the left, assuming:
    % 1) no vertical disparity
    % 2) that the horiz disparity is constant in the BB
    disp = xcL - xcR;
    xminR = xminL - disp;
    yminR = yminL;
    widthR = widthL;
    heightR = heightL;
    
    I2 = imcrop(I, [xminR yminR widthR heightR]);

%     if radius>10
%         
%         radius2 = radius*2+1;
%         
%         xminc = xc - radius;
%         yminc = yc - radius;
%         widthc = radius2;
%         heightc = radius2;
%     
%     else
%         
%         disp(['SKIPPED: ' feat.Registry{ii} '.']);
%         
%     end
       
    %imwrite(I2, fullfile(out_root_path_bb_disp, feat.Registry{ii}));
    
    figure(1), imshow(I2);
    
    img_counter = img_counter + 1;
    
    if  mod(ii,500)==0
        disp([num2str(ii) '/' num2str(length(feat.Registry))]);
        toc
        tic
    end
end