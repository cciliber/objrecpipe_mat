%% Setup

%FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
%FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%DATA_DIR = '/media/giulia/MyPassport';
%DATA_DIR = '/Volumes/MyPassport';
DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

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
Ndays = length(unique(cell2mat(values(opts.Days))));
Ncameras = opts.Cameras.Count;

%% Set up the experiments

% Default sets that are searched

set_names_prefix = {'train_', 'val_', 'test_'};
Nsets = length(set_names_prefix);
choose_set = 3;

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Mapping

mapping = 'NN';
%mapping = 'none';

% Whether to use the ImageNet labels

if strcmp(experiment, 'categorization')
    use_imnetlabels = true;
else
    use_imnetlabels = [];
end

% Choose categories

cat_idx_all = { [9 13], ...
    [8 9 13 14 15], ...
    [3 8 9 11 12 13 14 15 19 20], ...
    [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20]};

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    obj_lists_all = { {1, 5, [2 3 4 6 7 8 9 10]}, ...
        {1:2, 5, [3 4 6 7 8 9 10]}, ...
        {1:4, 5:7, 8:10}, ...
        {[1:4 6 7], 5, 8:10}, ...
        {[1:4 6:9], 5, 10}};
    
elseif strcmp(experiment, 'identification')
    
    id_exps = {1:3, 1:5, 1:7, 1:10};
    obj_lists_all = cell(length(id_exps), 1);
    for ii=1:length(id_exps)
        obj_lists_all{ii} = repmat(id_exps(ii), 1, Nsets);
    end
    
end

% Choose transformation, day, camera

%transf_lists = {1:Ntransfs, 1:Ntransfs, 1:Ntransfs};
%transf_lists = {[2 3], [2 3], [2 3]};
transf_lists = {2, 2, 1:Ntransfs};

day_mappings = {1, 1, 1:2};
day_lists = cell(Nsets,1);
tmp = keys(opts.Days);
for ii=1:Nsets
    for dd=1:length(day_mappings{ii})
        tmp1 = tmp(cell2mat(values(opts.Days))==day_mappings{ii}(dd))';
        tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
        day_lists{ii} = [day_lists{ii} tmp2];
    end
end

%camera_lists = {[1 2], [1 2], [1 2]};
camera_lists = {1, 1, 1:2};

%% Set the IO root directories

% Location of the scores

dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');

model = 'googlenet';
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

input_dir_root = fullfile(exp_dir, 'predictions', model, experiment);
check_input_dir(input_dir_root);

output_dir_root = fullfile(exp_dir, 'predictions', model, experiment);
check_output_dir(output_dir_root);

input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt_root);

%% For each experiment, go!

acc_global = -ones(length(cat_idx_all), length(obj_lists_all));
K = -ones(length(cat_idx_all), length(obj_lists_all));

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        % Assign the proper IO directories
        
        dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
        if strcmp(experiment, 'identification')
            dir_regtxt_relative = fullfile(dir_regtxt_relative, strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-'));
        end
        
        input_dir = fullfile(input_dir_root, dir_regtxt_relative);
        check_input_dir(input_dir);
        
        output_dir = fullfile(output_dir_root, dir_regtxt_relative);
        check_output_dir(output_dir);
        check_output_dir(fullfile(output_dir, 'figs'));
        
        input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
        check_input_dir(input_dir_regtxt);
        
        % Create set names
        
        for sidx=choose_set
            set_names{sidx} = [set_names_prefix{sidx} strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
            set_names{sidx} = [set_names{sidx} '_tr_' strrep(strrep(num2str(transf_lists{sidx}), '   ', '-'), '  ', '-')];
            set_names{sidx} = [set_names{sidx} '_cam_' strrep(strrep(num2str(camera_lists{sidx}), '   ', '-'), '  ', '-')];
            set_names{sidx} = [set_names{sidx} '_day_' strrep(strrep(num2str(day_mappings{sidx}), '   ', '-'), '  ', '-')];
        end
        
        %% Load REG, Y, Ypred and make suited variables
        
        for sidx=choose_set
            
            set_name = set_names{sidx};
            obj_list = obj_lists{sidx};
            transf_list = transf_lists{sidx};
            camera_list = camera_lists{sidx};
            day_mapping = day_mappings{sidx};
            
            % load Y and Ypred
            if strcmp(experiment, 'categorization') && use_imnetlabels
                load(fullfile(input_dir_regtxt, ['Yimnet_' set_name '.mat']), 'Y');
                if strcmp(mapping, 'none')
                    load(fullfile(input_dir, ['Yimnet_none_' set_name '.mat']), 'Ypred', 'acc');
                elseif strcmp(mapping, 'NN')
                    load(fullfile(input_dir, ['Yimnet_NN_' set_name '.mat']), 'Ypred', 'acc', 'Kvalues')
                    acc_global(icat, iobj) = acc(3,(acc(3,:)~=-1));
                    K(icat, iobj) = Kvalues(acc(3,:)~=-1);
                end;
            else
                load(fullfile(input_dir_regtxt, ['Y_' set_name '.mat']), 'Y');
                if strcmp(mapping, 'none')
                    load(fullfile(input_dir, ['Y_none' set_name '.mat']), 'Ypred', 'acc');
                elseif strcmp(mapping, 'NN')
                    load(fullfile(input_dir, ['Y_NN' set_name '.mat']), 'Ypred', 'acc', 'Kvalues');
                    acc_global(icat, iobj) = acc(3,(acc(3,:)~=-1));
                    K(icat, iobj) = Kvalues(acc(3,:)~=-1);
                end
            end
            
            % load REG
            load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
            
            % extract true labels (for plot colormaps)
            if use_imnetlabels
                Nlbls = max(1000, max(cell2mat(values(opts.Cat_ImnetLabels))));
            else
                Nlbls = length(unique(cell2mat(Y)));
            end
            
            % store values to plot
            Ypred_01 = cell(Ncat, 1);
            Ypred_4plots = cell(Ncat, 1);
            Ytrue_4plots = cell(Ncat, 1);
            Ypred_mode = cell(Ncat, 1);
            if strcmp(mapping, 'none')
                Ypred_avg = cell(Ncat, 1);
            end
            for cc=cat_idx

                Ypred_01{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
                Ypred_4plots{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
                
                Ytrue_4plots{opts.Cat(cat_names{cc})} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
                Ypred_mode{opts.Cat(cat_names{cc})} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
                if strcmp(mapping, 'none')
                    Ypred_avg{opts.Cat(cat_names{cc})} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
                end
                   
                dirlist = cellfun(@fileparts, REG{opts.Cat(cat_names{cc})}, 'UniformOutput', false);
                [dirlist, ia, ic] = unique(dirlist, 'stable');
                % [C,ia,ic] = unique(A) % C = A(ia) % A = C(ic)
                
                dirlist_splitted = regexp(dirlist, '/', 'split');
                dirlist_splitted = vertcat(dirlist_splitted{:});
                
                Nframes = zeros(length(dirlist),1);
                for ii=1:length(dirlist)
                    Nframes(ii) = sum(ic==ii);
                end
                startend = zeros(length(dirlist)+1,1);
                startend(2:end) = cumsum(Nframes);
                
                for ii=1:length(dirlist)
                    
                    obj = str2double(dirlist_splitted{ii,1}(regexp(dirlist_splitted{ii,1}, '\d'):end));
                    transf = dirlist_splitted{ii,2};
                    day = dirlist_splitted{ii,3};
                    cam = dirlist_splitted{ii,4};
                    
                    idx_start = startend(ii)+1;
                    idx_end = startend(ii+1);
                    ytrue = Y{opts.Cat(cat_names{cc})}(idx_start:idx_end);
                    ypred = Ypred{opts.Cat(cat_names{cc})}(idx_start:idx_end);
                    
                    Ypred_01{opts.Cat(cat_names{cc})}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = (ytrue==ypred);
                    Ypred_4plots{opts.Cat(cat_names{cc})}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = ypred;
                    
                    Ytrue_4plots{opts.Cat(cat_names{cc})}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = ytrue;
                    Ypred_mode{opts.Cat(cat_names{cc})}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = mode(ypred);
                    if strcmp(mapping, 'none')
                        x = X{opts.Cat(cat_names{cc})}(idx_start:idx_end, :);
                        xavg = mean(x,1);
                        [~, I] = max(xavg);
                        Ypred_avg{opts.Cat(cat_names{cc})}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = I-1;
                    end
                    
                end
                
                
            end
            
        end
        
        %% Ypred_01
        
        Nplots = length(cat_idx);
        Ncols = min(Nplots, 5);
        Nrows = ceil(Nplots/Ncols);
        
        for idxt=1:length(transf_list)
            for idxd=1:length(day_mapping)
                for idxe=1:length(camera_list)
                    
                    it = opts.Transfs(transf_names{transf_list(idxt)});
                    ie = opts.Cameras(camera_names{camera_list(idxe)});
                    id = opts.Days(day_names{day_mapping(idxd)});
                    
                    figure( (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe )
                    
                    for cc=1:Nplots
                        
                        OO = [Ypred_01{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
                        hh = subplot(Nrows, Ncols, cc)
                        
                        maxW = 1;
                        for oo=obj_list
                            W = length(OO{oo});
                            if W>maxW
                                maxW = W;
                            end
                        end
                        
                        AA = -ones(length(obj_list), maxW);
                        for oo=1:length(obj_list)
                            AA(oo, 1:length(OO{obj_list(oo)})) = OO{obj_list(oo)};
                        end
                        
                        imagesc(AA)
                        title(cat_names{cat_idx(cc)})
                        cmapcomplete = [0 0 0; 1 0 0; 1 1 1]; % -1, 0, 1
                        AAvalues = unique(AA);
                        if length(AAvalues)<3
                            if max(AAvalues)==0
                                cmapcomplete(3,:) = [];
                            end
                            if min(AAvalues)==0
                                cmapcomplete(1,:) = [];
                            end
                            if ~sum(AAvalues==0)
                                cmapcomplete(2,:) = [];
                            end
                        end
                        colormap(hh, cmapcomplete);
                            
                        %ylim([0.5 length(obj_list)+0.5]);
                        set(gca, 'YTick', 1:length(obj_list));
                        set(gca, 'YTickLabels', cellstr(num2str(obj_list(:)))');
                        
                    end
                    
                    suptitle([experiment ' ' mapping ' ' transf_names{transf_list(idxt)} ' ' day_names{day_mapping(idxd)} ' ' camera_names{camera_list(idxe)}])
                    
                    figname = ['Ypred_01' set_names_prefix{sidx} strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
                    figname = [figname '_tr_' num2str(transf_list(idxt))];
                    figname = [figname '_cam_' num2str(camera_list(idxe))];
                    figname = [figname '_day_' num2str(day_mapping(idxd))];
                    
                    saveas(gcf, fullfile(output_dir, 'figs', [figname '.fig']));
                end
            end
        end
        
        %% Ypred_4plots, Ytrue_4plots, Ypred_mode, Ypred_avg
        
        Nplots = 2*length(cat_idx);
        Ncols = min(Nplots, 5);
        Nrows = ceil(Nplots/Ncols);
        
        for idxt=1:length(transf_list)
            for idxd=1:length(day_mapping)
                for idxe=1:length(camera_list)
                    
                    it = opts.Transfs(transf_names{transf_list(idxt)});
                    ie = opts.Cameras(camera_names{camera_list(idxe)});
                    id = opts.Days(day_names{day_mapping(idxd)});
                    
                    figure( (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe )
                    
                    for cc=1:2:Nplots
                        
                        OO = [Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
                        
                        TT = Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie);
                        MODE = Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie);
                        if strcmp(mapping, 'none')
                            AVG = Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie);
                        end
                        
                        hh1 = subplot(Nrows, 2*Ncols, cc);
                        hh2 = subplot(Nrows, 2*Ncols, cc+1);
                        
                        maxW = 1;
                        for oo=obj_list
                            W = length(OO{oo});
                            if W>maxW
                                maxW = W;
                            end
                        end
                        
                        AA = -ones(length(obj_list), maxW);
                        for oo=1:length(obj_list)
                            AA(oo, 1:length(OO{obj_list(oo)})) = OO{obj_list(oo)};
                        end
                        
                        imagesc(AA)
                        title(cat_names{cat_idx(cc)})
                        colormap(hh1, [0 0 0; parula(Nlbls)]);                      
                        %ylim([0.5 length(obj_list)+0.5]);
                        set(gca, 'YTick', 1:length(obj_list));
                        set(gca, 'YTickLabels', cellstr(num2str(obj_list(:)))');
                        
                        AA = -ones(length(obj_list), 3);
                        for oo=1:length(obj_list)
                            AA(oo, 1) = TT{obj_list(oo)}(1);
                            AA(oo, 2) = MODE{obj_list(oo)};
                            if strcmp(mapping, 'none')
                                AA(oo, 3) = AVG{obj_list(oo)};
                            else
                                AA(oo, 3) = [];
                            end
                        end
                        
                        imagesc(AA)
                        title(cat_names{cat_idx(cc)})
                        colormap(hh2, parula(Nlbls));                      
                        %ylim([0.5 length(obj_list)+0.5]);
                        set(gca, 'YTick', 1:length(obj_list));
                        set(gca, 'YTickLabels', cellstr(num2str(obj_list(:)))');
                        set(gca, 'XTickLabels', {'true', 'mode', 'avg'});
                        
                    end
                    
                    suptitle([experiment ' ' mapping ' ' transf_names{transf_list(idxt)} ' ' day_names{day_mapping(idxd)} ' ' camera_names{camera_list(idxe)}])
                    
                    figname = ['Ypred_mode_avg' set_names_prefix{sidx} strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
                    figname = [figname '_tr_' num2str(transf_list(idxt))];
                    figname = [figname '_cam_' num2str(camera_list(idxe))];
                    figname = [figname '_day_' num2str(day_mapping(idxd))];
                    
                    saveas(gcf, fullfile(output_dir, 'figs', [figname '.fig']));
                end
            end
        end

        %% accuracies (frame-based, mode, avg, per folder and global)  
        
        Nplots = 6;
        Ncols = 3;
        Nrows =  ceil(Nplots/Ncols);
        
        AA = cell(Nplots,1);
        for ii=1:Nplots
           figure(ii)
           AA{ii} = zeros(length(cat_idx)*length(obj_list), length(transf_list)*length(camera_list)*length(day_mapping));
        end
        
        % accuracy xCat xObj xTr xDay xCam
        for cc=1:length(cat_idx) 
            for idxo=1:length(obj_list)
                
                for idxt =1:length(transf_list)
                    for idxd=1:length(day_mapping)
                        for idxe=1:length(camera_list)
                        
                            io = obj_list(idxo);
                            it = opts.Transfs(transf_names{transf_list(idxt)});
                            ie = opts.Cameras(camera_names{camera_list(idxe)});
                            id = opts.Days(day_names{day_mapping(idxd)});
                    
                            ypred = Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id ,ie);
                            ytrue = Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id ,ie);
                            
                            AA{ii}((cc-1)*length(obj_list)+idxo,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = compute_accuracy(ypred, ytrue, 'gurls');
            
                        end
                    end
                end
                
            end
        end
            
        % accuracy xCat xObj xTr xDay 
        for cc=cat_idx 
            for idxo=1:length(obj_list)
                for idxt =1:length(transf_list)
                    for idxd=1:length(day_mapping)
                        
                        
                            io = obj_list(idxo);
                            it = opts.Transfs(transf_names{transf_list(idxt)});
                            
                            id = opts.Days(day_names{day_mapping(idxd)});
                    
                            ypred = [Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :)];
                            ytrue = [Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :)];
                            
                            ypred = cell2mat(ypred(:));
                            ytrue = cell2mat(ytrue(:));
                            
                            rowidx = (cc-1)*length(obj_list)+idxo;
                            colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list);
                            colidx2 = colidx1+(length(camera_list)-1);
                            colidx = colidx1:colidx2;
                            a = compute_accuracy(ypred, ytrue, 'gurls');
                            AA{ii}(rowidx,colidx) = repmat(a, 1, length(camera_list));
            
                        
                    end
                end
            end
        end
        
        % accuracy xCat xObj xTr
        for cc=cat_idx
            for idxo=1:length(obj_list)
                for idxt =1:length(transf_list)
                    
                    io = obj_list(idxo);
                    it = opts.Transfs(transf_names{transf_list(idxt)});
                    
                    ypred = [Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :)];
                    ytrue = [Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :)];
                    
                    ypred = cell2mat(ypred(:));
                    ytrue = cell2mat(ytrue(:));
                    
                    rowidx = (cc-1)*length(obj_list)+idxo;
                    colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list);
                    colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
                    colidx = colidx1:colidx2;
                    a = compute_accuracy(ypred, ytrue, 'gurls');
                    AA{ii}(rowidx,colidx) = repmat(a, 1, length(camera_list)*length(day_mapping));
                    
                end
            end
        end
        
        % accuracy xCat      xTr
        for cc=cat_idx
            for idxt =1:length(transf_list)
                
                it = opts.Transfs(transf_names{transf_list(idxt)});
                
                ypred = [Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :)];
                ytrue = [Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :)];
                
                ypred = cell2mat(ypred(:));
                ytrue = cell2mat(ytrue(:));
                
                rowidx1 = (cc-1)*length(obj_list);
                rowidx2 = rowidx1+(length(obj_list)-1);
                colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list);
                colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
                colidx = colidx1:colidx2;
                a = compute_accuracy(ypred, ytrue, 'gurls');
                AA{ii}(rowidx,colidx) = repmat(a, length(obj_list), length(camera_list)*length(day_mapping));
                
            end    
        end

        % accuracy           xTr   
        
        for idxt =1:length(transf_list)
            
            it = opts.Transfs(transf_names{transf_list(idxt)});
            
            ypred = cell(length(cat_idx),1);
            ytrue = cell(length(cat_idx),1);
            for cc=1:length(cat_idx)
                ypred{cc} = [Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :)];
                ypred{cc} = ypred{cc}(:);
                ytrue{cc} = [Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :)];
                ytrue{cc} = ytrue{cc}(:);
            end
            
            ypred = cell2mat(ypred);
            ytrue = cell2mat(ytrue);
            
            rowidx1 = 1;
            rowidx2 = rowidx1+length(obj_list)*length(cat_idx)-1;
            colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list);
            colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
            colidx = colidx1:colidx2;
            a = compute_accuracy(ypred, ytrue, 'gurls');
            AA{ii}(rowidx,colidx) = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping));
            
        end
        
            
        % accuracy
        a = compute_accuracy(cell2mat(Ypred), cell2mat(Y), 'gurls');
        AA{ii} = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping)*length(transf_list));
        
        for ii=1:Nplots
            
            subplot(Nrows, Ncols, ii);
            imagesc(AA{ii});
            
            title(cat_names{cat_idx(cc)})

            set(gca, 'YTick', 1:length(obj_list):length(cat_idx)*length(obj_list));
            set(gca, 'YTickLabels', cellstr(num2str(cat_names(cat_idx)))');
            set(gca, 'XTick', 1:length(camera_list)*length(day_mapping):length(transf_list)*length(camera_list)*length(day_mapping));
            set(gca, 'XTickLabels', cellstr(num2str(transf_names(transf_list))'));
            
        end
        colormap(grey); 
        
        suptitle([experiment ' ' mapping ' ' transf_names{transf_list(idxt)} ' ' day_names{day_mapping(idxd)} ' ' camera_names{camera_list(idxe)}])
        
        figname = ['acc_' set_names_prefix{sidx} strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
        figname = [figname '_tr_' num2str(transf_list(idxt))];
        figname = [figname '_cam_' num2str(camera_list(idxe))];
        figname = [figname '_day_' num2str(day_mapping(idxd))];
        
        saveas(gcf, fullfile(output_dir, 'figs', [figname '.fig']));
        
    end
end