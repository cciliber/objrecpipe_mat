%% Setup

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% Dataset info

dset_info = fullfile(FEATURES_DIR, 'ICUBWORLDULTIMATE_test_offtheshelfnets', 'iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat)';
obj_names = keys(opts.Obj)';
transf_names = keys(opts.Transfs)';
day_names = keys(opts.Days)';
camera_names = keys(opts.Cameras)';

Ncat = opts.Cat.Count;
Nobj = opts.Obj.Count;
NobjPerCat = opts.ObjPerCat;
Ntransfs = opts.Transfs.Count;
Ndays = opts.Days.Count;
Ncameras = opts.Cameras.Count;

%% IO

model = 'googlenet';
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

experiment = 'categorization';
%experiment = 'identification';

dset_dirs = {'/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb60_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid256_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree'};

reg_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries';
check_input_dir(reg_dir);

output_dir_regtxt = fullfile(reg_dir, experiment);
check_output_dir(output_dir_regtxt);

%% Sets

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

set_names = {'train', 'val', 'test'};

day_lists = {3:2:Ndays, 3:2:Ndays, 3:Ndays};

obj_lists = {1:3, 4:6, 7:10};

transf_lists = {1:Ntransfs, 1:Ntransfs, 1:Ntransfs};

camera_lists = {[1 2], [1 2], [1 2]};

%% Create the registries REG and the true labels Y (ImageNet labels), Ynew

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    day_list = day_lists{sidx};
    obj_list = obj_lists{sidx};
    transf_list = transf_lists{sidx};
    camera_list = camera_lists{sidx};
    
    REG = cell(Ncat, 1);
    Y = cell(Ncat, 1);
    Ynew = cell(Ncat, 1);
    
    fid_Y = fopen(fullfile(output_dir_regtxt, [set_name '_Y.txt'], 'w'));
    fid_Ynew = fopen(fullfile(output_dir_regtxt, [set_name '_Ynew.txt'], 'w'));
    
    for cc=cat_idx
        
        reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
        
        loader = Features.GenericFeature();
        loader.assign_registry_and_tree_from_file(reg_path, [], []);
        
        flist_splitted = regexp(loader.Registry, '/', 'split');
        clear loader;
        flist_splitted = vertcat(flist_splitted{:});
        flist_splitted(:,1) = [];
        
        tobeloaded = zeros(length(flist_splitted), 1);
        
        for oo=obj_list
            
            oo_tobeloaded = strcmp(flist_splitted(:,1), strcat(cat_names{cc}, num2str(oo)));
            
            for tt=transf_list
                
                tt_tobeloaded = oo_tobeloaded & strcmp(flist_splitted(:,2), transf_names(tt));
                
                for dd=day_list
                    
                    dd_tobeloaded = tt_tobeloaded & strcmp(flist_splitted(:,3), day_names(dd));
                    
                    for ee=camera_list
                        
                        ee_tobeloaded = dd_tobeloaded & strcmp(flist_splitted(:,4), camera_names(ee));
                        
                        tobeloaded = tobeloaded + ee_tobeloaded;
                        
                    end
                end
            end
        end
        
        REG{opts.Cat(cat_names{cc})} = fullfile(flist_splitted(tobeloaded==1,1), flist_splitted(tobeloaded==1,2), flist_splitted(tobeloaded==1,3), flist_splitted(tobeloaded==1,4), flist_splitted(tobeloaded==1,5));
        
        Y{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
        Ynew{opts.Cat(cat_names{cc})} = ones(length(REG{opts.Cat(cat_names{cc})}), 1)*double(opts.Cat(cat_names{cc}));
        
        for line=1:length(REG{opts.Cat(cat_names{cc})})
            fprintf(fid_Y, '%s %d\n', REG{opts.Cat(cat_names{cc})}{line}, Ynew{opts.Cat(cat_names{cc})}{line});
            fprintf(fid_Ynew, '%s %d\n', REG{opts.Cat(cat_names{cc})}{line}, Y{opts.Cat(cat_names{cc})}{line});
        end
        
        disp([set_name ': ' cat_names(cc)]);
        
    end
    
    save(fullfile(output_dir_regtxt, ['REG_' set_name '.mat']), 'REG', '-v7.3');
    
    save(fullfile(output_dir_regtxt, ['Y_' set_name '.mat']), 'Y', '-v7.3');
    save(fullfile(output_dir_regtxt, ['Ynew_' set_name '.mat']), 'Ynew', '-v7.3');
    
    fclose(fid_Y);
    fclose(fid_Ynew);
    
end