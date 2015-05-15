
% FEATURES_DIR = 'D:/objrecpipe_mat';
% addpath(genpath(FEATURES_DIR));
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% in_root_dir = 'D:/DATASETS/iCubWorld30/test/venerdi26';
% check_input_dir(in_root_dir);
% 
% out_root_dir = 'D:/DATASETS/iCubWorld30_manually_cropped/test/venerdi26';
% check_output_dir(out_root_dir);
% 
% reg_file = 'D:/DATASETS/iCubWorld30_manually_cropped/registries/registry_test_ven.txt';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% dset = Features.GenericFeature();
% 
% dset.assign_registry_and_tree_from_folder(in_root_dir, [], reg_file);
% 
% dset.reproduce_tree(out_root_dir);
%  
% for im=4751:dset.ExampleCount
%     
%     I = imread(fullfile(in_root_dir, [dset.Registry{im} '.ppm']));
%    
%     h = figure
%     set(h,'units','normalized','outerposition',[0 0 3/4 1])
% 
%     Icrop = imcrop(I);
% 
%     imwrite(Icrop, fullfile(out_root_dir, [dset.Registry{im} '.ppm']));
%     im
%     close(h)
%     
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataset_folder_name = 'iCubWorld30_crop256';

modality = 'train/venerdi26';

in_root_dir = fullfile('D:/DATASETS', dataset_folder_name, modality);
check_input_dir(in_root_dir);

out_root_dir = fullfile('D:/DATASETS', [dataset_folder_name '_withbackground'], modality);
check_output_dir(out_root_dir);

out_size = 256;
bcenterx = out_size/2;
bcentery = bcenterx;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dset = Features.GenericFeature();

dset.assign_registry_and_tree_from_folder(in_root_dir, [], []);

dset.reproduce_tree(out_root_dir);

for im=1:dset.ExampleCount
    
    I = imread(fullfile(in_root_dir, [dset.Registry{im} '.ppm']));
   
    Ix = size(I,2);
    Iy = size(I,1);
    
    halfIx = ceil(Ix/2);
    halfIy = ceil(Iy/2);
   
    startx = bcenterx - halfIx + 1;
    endx = startx + Ix - 1;
    starty = bcentery - halfIy + 1;
    endy = starty + Iy - 1;

    background = zeros(out_size, out_size, 3, 'uint8');
    background(starty:endy, startx:endx, :) = I;
    
    imwrite(background, fullfile(out_root_dir, [dset.Registry{im} '.ppm']));
    im
   
end