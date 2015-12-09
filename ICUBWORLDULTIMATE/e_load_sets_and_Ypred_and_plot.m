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
loaded_set = 3;

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Mapping

if strcmp(experiment, 'categorization')
    %mapping = 'tuned';
    %mapping + 'NN';
    mapping = 'none';
elseif strcmp(experiment, 'identification')
    %mapping = 'NN';
    mapping = 'tuned';
else
    mapping = [];
end

% Whether to compute the average prediction or only the frame-based+mode

if strcmp(mapping, 'NN')
    compute_avg = false;
elseif strcmp(mapping, 'none')
    %compute_avg = true;
    compute_avg = false;
else
    compute_avg = [];
end

% Whether to use the imnet or the tuning labels

if strcmp(experiment, 'categorization') && strcmp(mapping, 'none') 
    use_imnetlabels = true;
elseif strcmp(experiment, 'categorization') && strcmp(mapping, 'NN') 
    %use_imnetlabels = false;
    use_imnetlabels = true;
elseif strcmp(experiment, 'categorization') && strcmp(mapping, 'tuned') 
     use_imnetlabels = true;
elseif strcmp(experiment, 'identification')
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
acc_all = cell(length(cat_idx_all), length(obj_lists_all));

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
        
        %% Load REG, Y, Ypred and make suited variables
        
        for ii=1:Nsets
            set_names{ii} = [set_names_prefix{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
        end

        obj_list = obj_lists{loaded_set};
        transf_list = transf_lists{loaded_set};
        camera_list = camera_lists{loaded_set};
        day_mapping = day_mappings{loaded_set};
        
        % load Y and Ypred
        if use_imnetlabels
            load(fullfile(input_dir_regtxt, ['Yimnet_' set_names{choose_set} '.mat']), 'Y');
            if strcmp(mapping, 'none')
                load(fullfile(input_dir, ['Yimnet_none_' set_names{choose_set} '.mat']), 'Ypred', 'acc');
            elseif strcmp(mapping, 'NN')
                load(fullfile(input_dir, ['Yimnet_NN_' set_names{1} '_' set_names{2} '_' set_names{3} '.mat']), 'Ypred', 'acc', 'Kvalues')
                acc_global(icat, iobj) = acc(3,(acc(3,:)~=-1));
                K(icat, iobj) = Kvalues(acc(3,:)~=-1);
            end;
        else
            load(fullfile(input_dir_regtxt, ['Y_' set_names{choose_set} '.mat']), 'Y');
            if strcmp(mapping, 'NN')
                load(fullfile(input_dir, ['Y_NN' set_names{1} '_' set_names{2} '_' set_names{3} '.mat']), 'Ypred', 'acc', 'Kvalues');
                acc_global(icat, iobj) = acc(3,(acc(3,:)~=-1));
                K(icat, iobj) = Kvalues(acc(3,:)~=-1);
            elseif strcmp(mapping, 'tuned')
                load(fullfile(input_dir, ['Y_tuned' set_names{1} '_' set_names{2} '_' set_names{3} '.mat']), 'Ypred', 'acc');
            end
        end
        
        % load REG
        load(fullfile(input_dir_regtxt, ['REG_' set_names{choose_set} '.mat']));
        
        if compute_avg
            % load/compute X
            % ....
        end
        
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
        if compute_avg
            Ypred_avg = cell(Ncat, 1);
        end
        for cc=cat_idx
            
            Ypred_01{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            Ypred_4plots{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            
            Ytrue_4plots{opts.Cat(cat_names{cc})} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
            Ypred_mode{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            if compute_avg
                Ypred_avg{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
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
                
                Ytrue_4plots{opts.Cat(cat_names{cc})}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = ytrue(1);
                Ypred_mode{opts.Cat(cat_names{cc})}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = mode(ypred);
                if compute_avg
                    x = X{opts.Cat(cat_names{cc})}(idx_start:idx_end, :);
                    xavg = mean(x,1);
                    [~, I] = max(xavg);
                    Ypred_avg{opts.Cat(cat_names{cc})}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = I-1;
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
                        hh = subplot(Nrows, Ncols, cc);
                        
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
                        set(gca, 'YTickLabel', cellstr(num2str(obj_list(:)))');
                        
                    end
                    
                    stringtitle = [experiment ' ' mapping ' ' transf_names{transf_list(idxt)} ' ' day_names{day_mapping(idxd)} ' ' camera_names{camera_list(idxe)}];
                    
                    if strcmp()
                        string_title
                        
                    suptitle({ })
                    
                    figname = ['Ypred_01' set_names_prefix{loaded_set} strrep(strrep(num2str(obj_lists{loaded_set}), '   ', '-'), '  ', '-')];
                    figname = [figname '_tr_' num2str(transf_list(idxt))];
                    figname = [figname '_cam_' num2str(camera_list(idxe))];
                    figname = [figname '_day_' num2str(day_mapping(idxd))];
                    
                    saveas(gcf, fullfile(output_dir, 'figs', [figname '.fig']));
                end
            end
        end
        
        close all
        
        %% Ypred_4plots, Ytrue_4plots, Ypred_mode, Ypred_avg
        
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
                    
                    for cc=1:length(cat_idx)
                        
                        OO = [Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
                        
                        TT = Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie);
                        MODE = [Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
                        if compute_avg
                            AVG = [Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
                        end
                        
                        hh1 = subplot(Nrows, 2*Ncols, 2*cc-1);
                        
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
                        
                        imagesc(AA, [-1 Nlbls-1])
                        title(cat_names{cat_idx(cc)})
                        cmap = colormap(hh1, [0 0 0; jet(double(Nlbls))]);                      
                        %ylim([0.5 length(obj_list)+0.5]);
                        set(gca, 'YTick', 1:length(obj_list));
                        set(gca, 'YTickLabel', cellstr(num2str(obj_list(:)))');
                        
                        hh2 = subplot(Nrows, 2*Ncols, 2*cc);
                        
                        if compute_avg 
                            AA = -ones(length(obj_list), 3);
                        else
                            AA = -ones(length(obj_list), 2);
                        end
                        for oo=1:length(obj_list)
                            AA(oo, 1) = TT(obj_list(oo));
                            AA(oo, 2) = MODE{obj_list(oo)};
                            if compute_avg
                                AA(oo, 3) = AVG{obj_list(oo)};
                            end
                        end
                        
                        imagesc(AA, [0 Nlbls-1])
                        title(cat_names{cat_idx(cc)})
                        colormap(hh2, cmap(2:end, :));                      
                        %ylim([0.5 length(obj_list)+0.5]);
                        set(gca, 'YTick', 1:length(obj_list));
                        ax = get(gca, 'Position');
                        ax(3) = ax(3)/2;
                        set(gca, 'Position', ax);
                        set(gca, 'YTickLabel', cellstr(num2str(obj_list(:)))');
                        if compute_avg
                            set(gca, 'XTickLabel', {'true', 'mode', 'avg'});
                        else
                            set(gca, 'XTickLabel', {'true', 'mode'});
                        end
                        
                    end
                    
                    suptitle([experiment ' ' mapping ' ' transf_names{transf_list(idxt)} ' ' day_names{day_mapping(idxd)} ' ' camera_names{camera_list(idxe)}])
                    
                    figname = ['Ypred_' mapping '_' set_names_prefix{loaded_set} strrep(strrep(num2str(obj_lists{loaded_set}), '   ', '-'), '  ', '-')];
                    figname = [figname '_tr_' num2str(transf_list(idxt))];
                    figname = [figname '_cam_' num2str(camera_list(idxe))];
                    figname = [figname '_day_' num2str(day_mapping(idxd))];
                    
                    saveas(gcf, fullfile(output_dir, 'figs', [figname '.fig']));
                end
            end
        end

        close all
        
        %% accuracies (frame-based / mode / avg)
        
        accum_method = 'none';
        %accum_method = 'mode';
        %accum_method = 'avg';
        
        Nplots = 6;
        Ncols = 3;
        Nrows =  ceil(Nplots/Ncols);
        
        AA = cell(Nplots,1);
        for ii=1:Nplots 
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
                    
                            if strcmp(accum_method, 'none')
                                ypred = Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}{io, it, id ,ie};
                            elseif strcmp(accum_method, 'mode')
                                ypred = Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}{io, it, id ,ie};
                            elseif compute_avg && strcmp(accum_method, 'avg')
                                ypred = Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}{io, it, id ,ie};
                            end 
                            ytrue = Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id ,ie);
                            ytrue = repmat(ytrue, length(ypred), 1);
                           
                            AA{1}((cc-1)*length(obj_list)+idxo,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = compute_accuracy(ypred, ytrue, 'gurls');
            
                        end
                    end
                end
                
            end
        end

        % accuracy frame-based xCat xObj xTr xDay 
        for cc=1:length(cat_idx) 
            for idxo=1:length(obj_list)
                for idxt =1:length(transf_list)
                    for idxd=1:length(day_mapping)
                        
                            io = obj_list(idxo);
                            it = opts.Transfs(transf_names{transf_list(idxt)});             
                            id = opts.Days(day_names{day_mapping(idxd)});
                    
                            if strcmp(accum_method, 'none')
                                ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
                            elseif strcmp(accum_method, 'mode')
                                ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
                            elseif compute_avg && strcmp(accum_method, 'avg')
                                ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
                            end
                            ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :));
                            foo = ones(size(ytrue));
                            nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
                            ytrue = cellfun(@repmat, mat2cell(ytrue, foo), nfrxdir, mat2cell(foo, foo), 'UniformOutput', 0);
                            
                            ypred = cell2mat(ypred(:));
                            ytrue = cell2mat(ytrue(:));
                            
                            rowidx = (cc-1)*length(obj_list)+idxo;
                            colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+1;
                            colidx2 = colidx1+(length(camera_list)-1);
                            colidx = colidx1:colidx2;
                            a = compute_accuracy(ypred, ytrue, 'gurls');
                            AA{2}(rowidx,colidx) = repmat(a, 1, length(camera_list));
            
                        
                    end
                end
            end
        end
        
        % accuracy frame-based xCat xObj xTr
        for cc=1:length(cat_idx) 
            for idxo=1:length(obj_list)
                for idxt =1:length(transf_list)
                    
                    io = obj_list(idxo);
                    it = opts.Transfs(transf_names{transf_list(idxt)});
                    
                    if strcmp(accum_method, 'none')
                        ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
                    elseif strcmp(accum_method, 'mode')
                        ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
                    elseif compute_avg && strcmp(accum_method, 'avg')
                        ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
                    end
                    ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, : , :));
                    
                    foo = ones(size(ytrue));
                    foo1 = ones(size(ytrue,1),1);
                    foo2 = ones(size(ytrue,2),1);
                    nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
                    ytrue = cellfun(@repmat, mat2cell(ytrue, foo1, foo2), nfrxdir, mat2cell(foo, foo1, foo2), 'UniformOutput', 0);

                    ypred = cell2mat(ypred(:));
                    ytrue = cell2mat(ytrue(:));
                    
                    rowidx = (cc-1)*length(obj_list)+idxo;
                    colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
                    colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
                    colidx = colidx1:colidx2;
                    a = compute_accuracy(ypred, ytrue, 'gurls');
                    AA{3}(rowidx,colidx) = repmat(a, 1, length(camera_list)*length(day_mapping));
                    
                end
            end
        end
        
        % accuracy frame-based xCat xTr
        for cc=1:length(cat_idx) 
            for idxt =1:length(transf_list)
                
                it = opts.Transfs(transf_names{transf_list(idxt)});
                
                if strcmp(accum_method, 'none')
                    ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                elseif strcmp(accum_method, 'mode')
                    ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                elseif compute_avg && strcmp(accum_method, 'avg')
                    ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                end
                
                ytrue = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                
                foo = ones(size(ytrue));
                foo1 = ones(size(ytrue,1),1);
                foo2 = ones(size(ytrue,2),1);
                foo3 = ones(size(ytrue,3),1);
                nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
                ytrue = cellfun(@repmat, mat2cell(ytrue, foo1, foo2, foo3), nfrxdir, mat2cell(foo, foo1, foo2, foo3), 'UniformOutput', 0);
                
                ypred = cell2mat(ypred(:));
                ytrue = cell2mat(ytrue(:));
                
                rowidx1 = (cc-1)*length(obj_list)+1;
                rowidx2 = rowidx1+length(obj_list)-1;
                rowidx = rowidx1:rowidx2;
                colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
                colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
                colidx = colidx1:colidx2;
                a = compute_accuracy(ypred, ytrue, 'gurls');
                AA{4}(rowidx,colidx) = repmat(a, length(obj_list), length(camera_list)*length(day_mapping));
                
            end    
        end

        % accuracy frame-based xTr   
        
        for idxt =1:length(transf_list)
            
            it = opts.Transfs(transf_names{transf_list(idxt)});
            
            ypred = cell(length(cat_idx),1);
            ytrue = cell(length(cat_idx),1);
            for cc=1:length(cat_idx)
                
                if strcmp(accum_method, 'none')
                    ypred{cc} = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                elseif strcmp(accum_method, 'mode')
                    ypred{cc} = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                elseif compute_avg && strcmp(accum_method, 'avg')
                    ypred{cc} = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                end
                ytrue{cc} = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
                
                foo = ones(size(ytrue{cc}));
                foo1 = ones(size(ytrue{cc},1),1);
                foo2 = ones(size(ytrue{cc},2),1);
                foo3 = ones(size(ytrue{cc},3),1);
                nfrxdir = cellfun(@length, ypred{cc}, 'UniformOutput', 0);
                ytrue{cc} = cellfun(@repmat, mat2cell(ytrue{cc}, foo1, foo2, foo3), nfrxdir, mat2cell(foo, foo1, foo2, foo3), 'UniformOutput', 0);
                
                ypred{cc} = cell2mat(ypred{cc}(:));
                ytrue{cc} = cell2mat(ytrue{cc}(:));
                
            end
            
            ypred = cell2mat(ypred);
            ytrue = cell2mat(ytrue);
            
            rowidx1 = 1;
            rowidx2 = rowidx1+length(obj_list)*length(cat_idx)-1;
            rowidx = rowidx1:rowidx2;
            colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
            colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
            colidx = colidx1:colidx2;
            a = compute_accuracy(ypred, ytrue, 'gurls');
            AA{5}(rowidx,colidx) = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping));
            
        end
            
        % accuracy frame-based
        
        if strcmp(accum_method, 'none')
            a = compute_accuracy(cell2mat(Ypred), cell2mat(Y), 'gurls');
        elseif strcmp(accum_method, 'mode')
            
        elseif compute_avg && strcmp(accum_method, 'avg')
            
        end
        
        AA{6} = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping)*length(transf_list));
        
        % plot and save 
        bottom = 1;
        top = 0;
        for ii=1:Nplots
            bottom = min(bottom, min(min(AA{ii})));
            top = max(top, max(max(AA{ii})));
        end
        
        figure
        for ii=1:Nplots
            subplot(Nrows, Ncols, ii)
            imagesc(AA{ii}, [bottom top]);
            %imagesc(AA{ii});
            
            set(gca, 'YTick', 1:length(cat_idx)*length(obj_list));
            ytl = cat_names(cat_idx);
            ytl = ytl(:)';
            ytl = repmat(ytl, length(obj_list), 1);
            ytl = strcat(ytl(:), repmat(strrep(cellstr(num2str(obj_list(:))), ' ' , ''), length(cat_idx), 1));
            set(gca, 'YTickLabel', ytl);
            set(gca, 'XTick', 1:length(camera_list)*length(day_mapping):length(transf_list)*length(camera_list)*length(day_mapping));
            set(gca, 'XTickLabel', transf_names(transf_list));
            
        end
        colormap(jet); 
        colorbar 
        
        suptitle([experiment ' ' mapping ' ' accum_method ' ' set_names_prefix{loaded_set}])
        
        figname = ['acc_' mapping '_' accum_method '_' set_names_prefix{loaded_set} strrep(strrep(num2str(obj_lists{loaded_set}), '   ', '-'), '  ', '-')];
        saveas(gcf, fullfile(output_dir, 'figs', [figname '.fig']));
        
        acc_all{icat, iobj} = AA;
               
    end
end

%% Plot all experiments together

tobeplotted = zeros(length(cat_idx_all), length(obj_lists_all), length(transf_lists{3}));
for icat=1:length(cat_idx_all)
    for iobj=1:length(obj_lists_all)
        for idxt=1:length(transf_lists{3})
            
            tobeplotted(icat, iobj, idxt) = acc_all{icat, iobj}{5}(1, (idxt-1)*length(day_mappings{3})*length(camera_lists{3})+1);
            
        end
    end
end

top = max(max(max(tobeplotted))) ;
bottom = min(min(min(tobeplotted))) ;

cmap = jet(length(obj_lists_all));
figure
for idxt=1:length(transf_lists{3})
    
    subplot(1, length(transf_lists{3}), idxt)
    hold on
    for iobj=1:length(obj_lists_all)
        plot(cellfun(@length, cat_idx_all), squeeze(tobeplotted(:, iobj, idxt)) , '-o', 'Color', cmap(iobj, :), 'MarkerEdgeColor', cmap(iobj, :), 'MarkerFaceColor', cmap(iobj, :));   
    end
    ylim([bottom top])
    title(transf_names(transf_lists{3}(idxt)))
    set(gca, 'XTick', cellfun(@length, cat_idx_all));
end

lgnd = cell(length(obj_lists_all), 1);
for iobj=1:length(obj_lists_all)
    
    obj_lists = obj_lists_all{iobj};
    lgnd{iobj} = '';
    for sidx=1:Nsets
        lgnd{iobj} = [lgnd{iobj} ' ' strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')]; 
    end
end

legend(lgnd);

suptitle([experiment ' ' mapping ' ' accum_method ' ' set_names_prefix{loaded_set}(1:(end-1))])
figname = ['acc_' mapping '_' accum_method '_' set_names_prefix{loaded_set}(1:(end-1))];
saveas(gcf, fullfile(output_dir_root, [figname '.fig']));
