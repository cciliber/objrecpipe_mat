%% Setup

FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%DATA_DIR = '/Volumes/MyPassport';
DATA_DIR = '/media/giulia/MyPassport';
%DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

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
    [8 9 13 14 15]%, ...
    %[3 8 9 11 12 13 14 15 19 20], ...
    %[2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] 
    };

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    obj_lists_all = { %{1:4, 5:7, 8:10}, ...
        %{1, 5, [2 3 4 6 7 8 9 10]}, ...
        %{1:6, 7, 8:10}, ...
        {[1:6 8 9], 7, 10}};
    
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
transf_lists = {2, 2, 2};

day_mappings = {1, 1, 1};
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
camera_lists = {1, 1, 1};

%% Set the IO root directories

% Location of the scores

%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');

%model = 'googlenet';
model = 'bvlc_reference_caffenet';
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
            
            % store values to plot
            accuracy = cell(Ncat, 1);
            Ypred_mode = cell(Ncat, 1);
            Ypred_01 = cell(Ncat, 1);      
            for cc=cat_idx
                
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
                
                accuracy{opts.Cat(cat_names{cc})} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
                Ypred_mode{opts.Cat(cat_names{cc})} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
                Ypred_01{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
                for ii=1:length(dirlist)
                     
                    obj = str2double(dirlist_splitted{ii,1}(regexp(dirlist_splitted{ii,1}, '\d'):end));
                        
                    transf = dirlist_splitted{ii,2};
                    day = dirlist_splitted{ii,3};
                    cam = dirlist_splitted{ii,4};
                        
                    idx_start = startend(ii)+1;
                    idx_end = startend(ii+1);
                    
                    ytrue = Y{opts.Cat(cat_names{cc})}(idx_start:idx_end);
                    ypred = Ypred{opts.Cat(cat_names{cc})}(idx_start:idx_end);
                    
                    io = obj;
                    it = opts.Transfs(transf);
                    ic = opts.Cameras(cam);
                    id = opts.Days(day);
                    
                    Ypred_01{opts.Cat(cat_names{cc})}{io, it, id, ic} = (ytrue==ypred);
                    accuracy{opts.Cat(cat_names{cc})}(io, it, id, ic) = compute_accuracy(ytrue, ypred, 'gurls');
                    Ypred_mode{opts.Cat(cat_names{cc})}(io, it, id, ic) = mode(ypred);
                    
                    %x = X{opts.Cat(cat_names{cc})}(idx_start:idx_end, :);
                    %xavg = mean(x,1);
                    %[~, I] = max(xavg);
                    %yavg = I-1;
                    
                end
                
            end
            
            % pred01
 
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
                                if max(max(AA))==0
                                    colormap(hh, [1 0 0; 0 0 0]);
                                elseif min(min(AA))==0
                                    colormap(hh, [0 0 0; 1 1 1]);
                                else
                                     colormap(hh, [1 0 0; 0 0 0; 1 1 1]);
                                end
                                
                                %ylim([0.5 length(obj_list)+0.5]);
                                set(gca, 'YTick', 1:length(obj_list));
                                set(gca, 'YTickLabels', cellstr(num2str(obj_list(:)))');
                                
                                ax=get(hh,'Position');
                                if cc==1
                                    axh = ax(4);
                                else
                                    ax(4) = axh;
                                    set(hh,'Position', ax);
                                end
                            end
                            
                            suptitle([experiment ' ' mapping ' ' transf_names{transf_list(idxt)} ' ' day_names{day_mapping(idxd)} ' ' camera_names{camera_list(idxe)}])
                            
                            figname = [set_names_prefix{sidx} strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
                            figname = [figname '_tr_' num2str(transf_list(idxt))];
                            figname = [figname '_cam_' num2str(camera_list(idxe))];
                            figname = [figname '_day_' num2str(day_mapping(idxd))];
                            
                            saveas(gcf, fullfile(output_dir, 'figs', [figname '.fig']));
                    end
                end
            end
            
        end
    end
end

close all
  
    %scores = cell(Ncat,1);
    scoresavg = cell(Ncat, 1);
    trueclass = cell(Ncat,1);
    for cc=cat_idx
    %scores{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
    scoresavg{opts.Cat(cat_names{cc})} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras, 1000);
    trueclass{opts.Cat(cat_names{cc})} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
end

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    load(fullfile(output_dir, ['REG_' set_name '.mat'])); % REG
    load(fullfile(output_dir, ['X_' set_name '.mat'])); % X
    load(fullfile(output_dir, ['Y_' set_name '.mat'])); % Y
    
    for cc=1:Ncat
        if ~isempty(REG{cc})
            
            dirlist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
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
                
                x = X{cc}(idx_start:idx_end, :);
                ytrue = Y{cc}(idx_start:idx_end);
                
                %scores{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = x;
                scoresavg{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam), :) = mean(x,1);
                trueclass{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = ytrue;
                
            end
            
        end
    end
    
end

%save(fullfile(output_dir, 'scores.mat'), 'scores', '-v7.3');
save(fullfile(output_dir, 'scoresavg.mat'), 'scoresavg', '-v7.3');
save(fullfile(output_dir, 'trueclass.mat'), 'trueclass', '-v7.3');

%%

for midx = 1:length(mappings)
    
    mapping = mappings{midx};
    
    %predclass = cell(Ncat,1);
    pred01 = cell(Ncat, 1);
    accframebased = cell(Ncat,1);
    predaccum = cell(Ncat,1);
    for cc=1:Ncat
        if ~isempty(REG{cc})
            %predclass{cc} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            pred01{cc} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            accframebased{cc} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
            predaccum{cc} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
        end
    end
    
    for sidx=1:length(set_names)
        
        set_name = set_names{sidx};
        
        load(fullfile(output_dir, ['REG_' set_name '.mat'])); % REG
        load(fullfile(output_dir, ['Y_' set_name '.mat'])); % Y
        load(fullfile(output_dir, ['Y_' mapping '_' set_name '.mat'])); % Ypred
        
        for cc=1:Ncat
            if ~isempty(REG{cc})
                
                dirlist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
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
                    
                    ypred = Ypred{cc}(idx_start:idx_end);
                    ytrue = Y{cc}(idx_start:idx_end);
                    
                    %predclass{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = ypred;
                    pred01{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = (ypred == ytrue);
                    accframebased{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = compute_accuracy(ytrue, ypred, 'gurls');
                    
                    predaccum{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = mode(ypred);
                    
                end
                
            end
        end
        
    end
    
    %save(fullfile(output_dir, ['predclass_' mapping '.mat']), 'predclass', '-v7.3');
    save(fullfile(output_dir, ['pred01_' mapping '.mat']), 'pred01', '-v7.3');
    save(fullfile(output_dir, ['accframebased_' mapping '.mat']), 'accframebased', '-v7.3');
    save(fullfile(output_dir, [accum_methods{1} '_' mapping '.mat']), 'predaccum', '-v7.3');
    
end

%%

load(fullfile(output_dir, 'scoresavg.mat'), 'scoresavg');
load(fullfile(output_dir, 'trueclass.mat'), 'trueclass');

for midx = 1:length(mappings)
    
    mapping = mappings{midx};
    
    predaccum = cell(Ncat, 1);
    for cc=1:Ncat
        if ~isempty(scoresavg{cc})
            predaccum{cc} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
        end
    end
    
    if midx==1
        
        k = str2double(mapping(1:regexp(mapping, '\d')));
        
        xx = cell(length(set_names), 1);
        yy = cell(length(set_names), 1);
        
        for sidx=1:length(set_names)
            
            set_name = set_names{sidx};
            
            load(fullfile(output_dir, ['REG_' set_name '.mat'])); % REG
            
            xx{sidx} = cell(Ncat, 1);
            yy{sidx} = cell(Ncat, 1);
            
            for cc=1:Ncat
                if ~isempty(REG{cc})
                    
                    dirlist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
                    [dirlist, ia, ic] = unique(dirlist, 'stable');
                    % [C,ia,ic] = unique(A) % C = A(ia) % A = C(ic)
                    
                    dirlist_splitted = regexp(dirlist, '/', 'split');
                    dirlist_splitted = vertcat(dirlist_splitted{:});
                    
                    xx{sidx}{cc} = zeros(length(dirlist), 1000);
                    yy{sidx}{cc} = zeros(length(dirlist), 1);
                    
                    for ii=1:length(dirlist)
                        
                        obj = str2double(dirlist_splitted{ii,1}(regexp(dirlist_splitted{ii,1}, '\d'):end));
                        transf = dirlist_splitted{ii,2};
                        day = dirlist_splitted{ii,3};
                        cam = dirlist_splitted{ii,4};
                        
                        xx{sidx}{cc}(ii,:) = scoresavg{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam), :);
                        yy{sidx}{cc}(ii) = trueclass{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)}(1);
                        
                    end
                end
            end
            
        end
        
        for sidx=1:length(set_names)
            
            set_name = set_names{sidx};
            other_sidx = -sidx + 3;
            
            load(fullfile(output_dir, ['REG_' set_name '.mat'])); % REG
            
            for cc=1:Ncat
                if ~isempty(REG{cc})
                    
                    dirlist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
                    [dirlist, ia, ic] = unique(dirlist, 'stable');
                    % [C,ia,ic] = unique(A) % C = A(ia) % A = C(ic)
                    
                    dirlist_splitted = regexp(dirlist, '/', 'split');
                    dirlist_splitted = vertcat(dirlist_splitted{:});
                    
                    tmpy = kNNClassify_multiclass(cell2mat(xx{other_sidx}), cell2mat(yy{other_sidx}), k, xx{sidx}{cc});
                    
                    for ii=1:length(dirlist)
                        
                        obj = str2double(dirlist_splitted{ii,1}(regexp(dirlist_splitted{ii,1}, '\d'):end));
                        transf = dirlist_splitted{ii,2};
                        day = dirlist_splitted{ii,3};
                        cam = dirlist_splitted{ii,4};
                        
                        predaccum{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = tmpy(ii);
                    end
                end
            end
        end
        
    elseif midx==2
        
        for cc=1:Ncat
            if ~isempty(REG{cc})
                [~, tmpy] = max(reshape(scoresavg{cc}, NobjPerCat*Ntransfs*Ndays*Ncameras, 1000),[], 2);
                tmpy = tmpy - 1;
                predaccum{cc} = reshape(tmpy, NobjPerCat, Ntransfs, Ndays, Ncameras);
            end
        end
        
    end
    
    save(fullfile(output_dir, [accum_methods{2} '_' mapping '.mat']), 'predaccum', '-v7.3');
    
end

%% Fig. 1: pred01

chooseday = 2;
choosecam = 2;

choosetransf = keys(opts.Transfs);

for midx=1:length(mappings)
    
    mapping = mappings{midx};
    load(fullfile(output_dir, ['pred01_' mapping '.mat']), 'pred01');
    
    for ct = choosetransf
        
        ff = figure;
        
        for cc=1:Ncat
            if ~isempty(pred01{cc})
                
                hh = subplot(4, 5, double(cc));
                
                CC = pred01{cc};
                
                maxW = 1;
                for oo=1:NobjPerCat
                    W = length(CC{oo, opts.Transfs(cell2mat(ct)), chooseday, choosecam});
                    if W>maxW
                        maxW = W;
                    end
                end
                
                AA = -ones(NobjPerCat, maxW);
                for oo=1:NobjPerCat
                    AA(oo, 1:length(CC{oo, opts.Transfs(cell2mat(ct)), chooseday, choosecam})) = CC{oo, opts.Transfs(cell2mat(ct)), chooseday, choosecam};
                end
                
                imagesc(AA)
                title(cat_names( cell2mat(values(opts.Cat))==cc))
                if max(max(AA))==0
                    colormap(hh, [1 0 0; 0 0 0]);
                else
                    colormap(hh, [1 0 0; 0 0 0; 1 1 1]);
                end
                
            end
        end
        
        suptitle([mapping ' ' cell2mat(ct) ' ' num2str(chooseday) ' ' num2str(choosecam)])
        saveas(gcf, fullfile(output_dir, 'figs', [mapping '_' cell2mat(ct) '_' num2str(chooseday) '_' num2str(choosecam) '.fig']));
        
    end
    
end

%% Fig. 2: predmode or predavg

for aidx=1:length(accum_methods)
    
    accum_method = accum_methods{aidx};
    
    for midx=1:length(mappings)
        
        mapping = mappings{midx};
        load(fullfile(output_dir, [accum_method '_' mapping '.mat']));
        
        totalMM = zeros(length(cat_idx)*NobjPerCat, Ntransfs*Ndays*Ncameras+1);
        
        for cc=1:length(cat_idx)
            
            MM = predaccum{opts.Cat(cat_names{cat_idx(cc)})};
            reshapedMM = zeros(NobjPerCat, Ntransfs*Ndays*Ncameras);
            
            for oo=1:NobjPerCat
                for tt=1:Ntransfs
                    reshapedMM(oo, ((tt-1)*Ndays*Ncameras+1):(tt*Ndays*Ncameras)) = reshape(permute(MM(oo, tt, :, :), [1 2 4 3]), 1, 4);
                end
            end
            
            totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), 2:end) = reshapedMM;
            totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), 1) = repmat(opts.Cat_ImnetLabels(cat_names{cat_idx(cc)}), NobjPerCat, 1);
        end
        
        figure
        imagesc(totalMM);
        set(gca, 'YTick', 1:NobjPerCat:NobjPerCat*length(cat_idx));
        set(gca, 'YTickLabel', cat_names(cat_idx));
        set(gca, 'XTick', 2:Ndays*Ncameras:Ntransfs*Ndays*Ncameras+1);
        xtk = keys(opts.Transfs);
        xtk(cell2mat(values(opts.Transfs))) = xtk;
        %xtk = repmat(xtk, 1, 4)';
        set(gca, 'XTickLabel', xtk(:));
        
        colormap(jet(1000))
        colorbar
        saveas(gcf, fullfile(output_dir, 'figs', [accum_method '_' mapping '.fig']));
        
    end
    
end

%% Fig. 3: acc_framebased

for midx=1:length(mappings)
    
    mapping = mappings{midx};
    load(fullfile(output_dir, ['accframebased_' mapping '.mat']), 'accframebased');
    
    totalMM = zeros(length(cat_idx)*NobjPerCat, Ntransfs*Ndays*Ncameras);
    
    for cc=1:length(cat_idx)
        
        MM = accframebased{opts.Cat(cat_names{cat_idx(cc)})};
        reshapedMM = zeros(NobjPerCat, Ntransfs*Ndays*Ncameras);
        
        for oo=1:NobjPerCat
            for tt=1:Ntransfs
                reshapedMM(oo, ((tt-1)*Ndays*Ncameras+1):(tt*Ndays*Ncameras)) = reshape(permute(MM(oo, tt, :, :), [1 2 4 3]), 1, 4);
            end
        end
        
        totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), :) = reshapedMM;
        
    end
    
    figure
    imagesc(totalMM);
    set(gca, 'YTick', 1:NobjPerCat:NobjPerCat*length(cat_idx));
    set(gca, 'YTickLabel', cat_names(cat_idx));
    set(gca, 'XTick', 1:Ndays*Ncameras:Ntransfs*Ndays*Ncameras);
    xtk = keys(opts.Transfs);
    xtk(cell2mat(values(opts.Transfs))) = xtk;
    %xtk = repmat(xtk, 1, 4)';
    set(gca, 'XTickLabel', xtk(:));
    
    colormap(jet)
    colorbar
    saveas(gcf, fullfile(output_dir, 'figs', ['accuracy_' mapping '.fig']));
    
end
