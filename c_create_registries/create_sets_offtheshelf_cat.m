
clear all;

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%% Global data dir

DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

create_fullpath = false;
if create_fullpath
    dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
    %dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');
end

%% Dataset info

dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);
cat_names = keys(opts.Cat)';
%obj_names = keys(opts.Obj)';
transf_names = keys(opts.Transfs)';
day_names = keys(opts.Days)';
camera_names = keys(opts.Cameras)';

Ncat = opts.Cat.Count;
Nobj = opts.Obj.Count;
NobjPerCat = opts.ObjPerCat;
Ntransfs = opts.Transfs.Count;
Ndays = opts.Days.Count;
Ncameras = opts.Cameras.Count;

%% Setup the question

same_size = false;
if same_size == true
    %question_dir = 'frameORtransf';
    question_dir = 'frameORinst';
end

% whether to create the ImageNet labels
create_imnetlabels = true;

%% Setup the IO root directories

% input registries from which to select the subsets
reg_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/full_registries');
check_input_dir(reg_dir);

% output root dir for registries of the subsets
output_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
if create_fullpath
    output_dir_regtxt_root_fullpath = fullfile([dset_dir '_experiments'], 'registries', 'categorization');
end

%% Set up the trials

% categories
%cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
cat_idx_all = { [3 8 9 11 12 13 14 15 19 20] };

% objects per category
obj_lists_all = { 1:NobjPerCat };

% transformation
transf_lists_all = { 1:5 };

% day
day_mappings_all = { 1, 2, 1:2 };
%day_mappings_all = { 1:2 };
create_day_list;

% camera
camera_lists_all = { 1, 2 };
%camera_lists_all = { 1:2 };

%% For each experiment, go!

if same_size
    NsamplesReference = cell(Ncat, 1);
end

for icat=1:length(cat_idx_all)
    cat_idx = cat_idx_all{icat};
    
    % Assign the output dir
    output_dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
    if same_size==true
        output_dir_regtxt_relative = fullfile(output_dir_regtxt_relative, question_dir);
    end
    output_dir_regtxt = fullfile(output_dir_regtxt_root, output_dir_regtxt_relative);
    check_output_dir(output_dir_regtxt);
    if create_fullpath
        output_dir_regtxt_fullpath = fullfile(output_dir_regtxt_root_fullpath, output_dir_regtxt_relative);
        check_output_dir(output_dir_regtxt_fullpath);
    end
    
    % Assign the labels
    fid_labels = fopen(fullfile(output_dir_regtxt, 'labels.txt'), 'w');
    Y_digits = containers.Map (cat_names(cat_idx), 0:(length(cat_idx)-1));
    for line=cat_idx
        fprintf(fid_labels, '%s %d\n', cat_names{line}, Y_digits(cat_names{line}));
    end
    fclose(fid_labels);
    
    % Files to be created
    fcreated = zeros(length(obj_lists_all), length(transf_lists_all), length(day_lists_all), length(camera_lists_all));
         
    for cc=cat_idx
        
        % create flist_splitted
        reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
        
        fid = fopen(reg_path);
        loader = textscan(fid, '%s %d');
        flist_splitted = regexp(loader{1}, '/', 'split');
        clear loader;
        fclose(fid); 
        flist_splitted = vertcat(flist_splitted{:});
        flist_splitted(:,1) = [];
        
        for iobj=1:length(obj_lists_all)
            obj_list = obj_lists_all{iobj};
            
            oo_tobeloaded = ismember(flist_splitted(:,1), strrep(cellstr(strcat(cat_names{cc}, num2str(obj_list'))), ' ', '') );
            
            for itransf=1:length(transf_lists_all)
                transf_list = transf_lists_all{itransf};
                
                tt_tobeloaded = ismember(flist_splitted(:,2), transf_names(transf_list));
                
                for iday=1:length(day_lists_all)
                    day_list = day_lists_all{iday};
                    day_mapping = day_mappings_all{iday};
                    
                    dd_tobeloaded = ismember(flist_splitted(:,3), day_names(day_list));
                    
                    for icam=1:length(camera_lists_all)
                        camera_list = camera_lists_all{icam};
                        
                        ee_tobeloaded = ismember(flist_splitted(:,4), camera_names(camera_list));
                        
                        % Create the set name
                        set_name = [strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-') ...
                            '_tr_' strrep(strrep(num2str(transf_list), '   ', '-'), '  ', '-') ...
                            '_day_' strrep(strrep(num2str(day_mapping), '   ', '-'), '  ', '-') ...
                            '_cam_' strrep(strrep(num2str(camera_list), '   ', '-'), '  ', '-')];
                        
                        % Create fids or open them
                        if ~fcreated(iobj, itransf, iday, icam)
                            fcreated(iobj, itransf, iday, icam) = 1;
                            writemodality = 'w';
                        else
                            writemodality = 'a'; 
                        end                   
                        fid_Y = fopen(fullfile(output_dir_regtxt, [set_name '_Y.txt']), writemodality);
                        if create_imnetlabels
                            fid_Yimnet = fopen(fullfile(output_dir_regtxt, [set_name '_Yimnet.txt']), writemodality);
                        end
                        if create_fullpath                           
                            fid_Y_fullpath = fopen(fullfile(output_dir_regtxt_fullpath, [set_name '_fullpath_Y.txt']), writemodality);
                            if create_imnetlabels
                                fid_Yimnet_fullpath = fopen(fullfile(output_dir_regtxt_fullpath, [set_name '_fullpath_Yimnet.txt']), writemodality);
                            end
                        end
                        
                        % Select!
                        tobeloaded = oo_tobeloaded & tt_tobeloaded & dd_tobeloaded & ee_tobeloaded;
                        flist_splitted_tobeloaded = flist_splitted(tobeloaded==1, :);
                        
                        % Eventually reduce samples
                        if same_size==true
                            if icat==1 && iobj==1 && itransf==1 && iday==1 && icam==1
                                NsamplesReference{opts.Cat(cat_names{cc})} = length(flist_splitted_tobeloaded);
                            else
                                subs_idxs =  round(linspace(1, length(flist_splitted_tobeloaded), NsamplesReference{opts.Cat(cat_names{cc})}));
                                subs_idxs = unique(subs_idxs);
                                
                                flist_splitted_tobeloaded = flist_splitted_tobeloaded(subs_idxs, :);
                            end
                        end
                        nsmpl_xcat = length(flist_splitted_tobeloaded);
                        
                        % Assign REG
                        REG = fullfile(flist_splitted_tobeloaded(:,1), flist_splitted_tobeloaded(:,2), flist_splitted_tobeloaded(:,3), flist_splitted_tobeloaded(:,4), flist_splitted_tobeloaded(:,5));
                        
                        % Assign Y and Yimnet
                        Y = ones(nsmpl_xcat, 1)*Y_digits(cat_names{cc});
                        if create_imnetlabels
                            Yimnet = ones(nsmpl_xcat, 1)*double(opts.Cat_ImnetLabels(cat_names{cc}));
                        end
                        
                        % Write output
                        for line=1:nsmpl_xcat
                            
                            fprintf(fid_Y, '%s/%s %d\n', cat_names{cc}, REG{line}, Y(line));
                            if create_imnetlabels
                                fprintf(fid_Yimnet, '%s/%s %d\n', cat_names{cc}, REG{line}, Yimnet(line));
                            end
                            if create_fullpath
                                fprintf(fid_Y_fullpath, '%s/%s/%s %d\n', dset_dir, cat_names{cc}, REG{line}, Y(line));
                                if create_imnetlabels
                                    fprintf(fid_Yimnet_fullpath, '%s/%s/%s %d\n', dset_dir, cat_names{cc}, REG{line}, Yimnet(line));
                                end
                            end
                        end
                        
                        disp([set_name ': ' cat_names(cc)]);
                        
                        fclose(fid_Y);
                        if create_imnetlabels
                            fclose(fid_Yimnet);
                        end 
                        if create_fullpath
                            fclose(fid_Y_fullpath);
                            if create_imnetlabels
                                fclose(fid_Yimnet_fullpath);
                            end
                        end
                        
                    end
                end
            end
        end
    end
end
                   
