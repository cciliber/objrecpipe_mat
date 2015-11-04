%% Setup 

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

gurls_setup('/data/REPOS/GURLS/');
vl_feat_setup();

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
%Ndays = opts.Days.Count;
Ndays = length(unique(cell2mat(values(opts.Days))));
Ncameras = opts.Cameras.Count;

%% IO

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid384_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb60_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid256_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb30_disp_finaltree';

reg_dir = '/data/giulia/DATASETS/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

input_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model);
check_input_dir(input_dir);

output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model);
check_output_dir(output_dir);

%% Read the registries & populate the cell structures

set_names = {'even', 'odd'};

scores = cell(Ncat,1);
scoresavg = cell(Ncat, 1);
Xavg = cell(Ncat, 1);

trueclass = cell(Ncat,1);

for sidx=1:length(set_names)
    
    set_name = set_names{sidx};
    
    load(fullfile(output_dir, ['REG_' set_name '.mat'])); % REG
    load(fullfile(output_dir, ['X_' set_name '.mat'])); % X
    load(fullfile(output_dir, ['Y_' set_name '.mat'])); % Y
   
    for cc=1:Ncat
        if ~isempty(REG{cc})
            
            scores{cc} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            scoresavg{cc} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras, 1000);
            trueclass{cc} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            
            dirlist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
            
            [dirlist, ia, ic] = unique(dirlist, 'stable');
            % [C,ia,ic] = unique(A)
            % C = A(ia)
            % A = C(ic)
            
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
                
                scores{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = x;
                scoresavg{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam), :) = mean(x,1);
                trueclass{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = ytrue;
                
            end
            
        end
    end
    
end

save(fullfile(output_dir, 'scores.mat'), 'scores', '-v7.3');
save(fullfile(output_dir, 'scoresavg.mat'), 'scoresavg', '-v7.3');
save(fullfile(output_dir, 'trueclass.mat'), 'trueclass', '-v7.3');

%%

set_names = {'even', 'odd'};

mapping = 'kNN'; % 'none' or 'kNN'

predclass = cell(Ncat,1);
pred01 = cell(Ncat, 1);
accframebased = cell(Ncat,1);

predmode = cell(Ncat,1);

for sidx=1:length(set_names)
    
    load(fullfile(output_dir, ['REG_' set_name '.mat'])); % REG
    load(fullfile(output_dir, ['Y_' set_name '.mat'])); % Y
    load(fullfile(output_dir, ['Y_' mapping '_' set_name '.mat'])); % Ypred
    
    for cc=1:Ncat
        if ~isempty(REG{cc})
            
            predclass{cc} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            pred01{cc} = cell(NobjPerCat, Ntransfs, Ndays, Ncameras);
            accframebased{cc} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
            
            predmode{cc} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
            
            dirlist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
            
            [dirlist, ia, ic] = unique(dirlist, 'stable');
            % [C,ia,ic] = unique(A)
            % C = A(ia)
            % A = C(ic)
            
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
                
                predclass{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = ypred;
                pred01{cc}{obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = (ypred == ytrue);
                accframebased{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = compute_accuracy(ytrue, ypred, 'gurls');
                
                predmode{cc}(obj, opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = mode(ypred);
                
            end
            
        end
    end
  
end

save(fullfile(output_dir, ['predclass_' mapping '.mat']), 'predclass', '-v7.3');
save(fullfile(output_dir, ['pred01_' mapping '.mat']), 'pred01', '-v7.3');
save(fullfile(output_dir, ['accframebased_' mapping '.mat']), 'accframebased', '-v7.3');
save(fullfile(output_dir, ['predmode_' mapping '.mat']), 'predmode', '-v7.3');
    
%%

set_names = {'even', 'odd'};

mapping = 'kNN'; % 'none' or 'kNN'

predavg = cell(Ncat,1);

load(fullfile(output_dir, 'scoresavg.mat')); % scoresavg

for sidx=1:length(set_names)
    
    if strcmp(mapping, 'kNN')
        k = 1;
        other_set_name = set_names(-sidx+3));
        
        load(fullfile(output_dir, ['X_' other_set_name '.mat'])); % X
        load(fullfile(output_dir, ['Y_' other_set_name '.mat'])); % Y
    end

    for cc=1:Ncat
        if ~isempty(REG{cc})
            
            predavg{cc} = zeros(NobjPerCat, Ntransfs, Ndays, Ncameras);
            
            Xavg = reshape(scoresavg{cc}, NobjPerCat*Ntransfs*Ndays*Ncameras, 1000);
            
            if strcmp(mapping, 'none')
                [~, tmpy] = max(Xavg,[], 2);
                tmpy = tmpy - 1;
            elseif strcmp(mapping, 'kNN')
                tmpy = kNNClassify_multiclass(cell2mat(X), cell2mat(Y), k, Xavg);   
            end
            
            predavg{cc} = reshape(tmpy, NobjPerCat, Ntransfs, Ndays, Ncameras);
            
        end
    end
  
end

save(fullfile(output_dir, ['predavg_' mapping '.mat']), 'predavg', '-v7.3');

%% prediction yes no

mapping = 'none'; % 'none' or 'kNN'

load(fullfile(output_dir, ['pred01_' mapping '.mat']), 'pred01');

chooseday = 1;
choosecam = 1; 

for choosetransf=keys(opts.Transfs)
    
    ff = figure;
        
    for cc=1:Ncat
        if ~isempty(pred01{cc})
            
            hh = subplot(4, 5, double(cc));
            
            CC = pred01{cc};
            
            maxW = 1;
            for oo=1:NobjPerCat
                W = length(CC{oo, opts.Transfs(cell2mat(choosetransf)), chooseday, choosecam});
                if W>maxW
                    maxW = W;
                end
            end

            AA = -ones(NobjPerCat, maxW);
            for oo=1:NobjPerCat
                AA(oo, 1:length(CC{oo, opts.Transfs(cell2mat(choosetransf)), chooseday, choosecam})) = CC{oo, opts.Transfs(cell2mat(choosetransf)), chooseday, choosecam};
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
    
    suptitle(cell2mat(choosetransf) )
    saveas(gcf, fullfile(output_dir, 'figs', [cell2mat(choosetransf) '.fig']));

end

%% more_freq_prediction

load(fullfile(output_dir, ['predavg_' mapping '.mat']), 'predavg');
load(fullfile(output_dir, ['predmode_' mapping '.mat']), 'predmode');

totalMM = zeros(length(cat_list)*NobjPerCat, Ntransfs*2*Ncameras+1);

for cc=1:length(cat_list)
    
    MM = more_freq_prediction{cat_list(cc)};
    reshapedMM = zeros(NobjPerCat, Ntransfs*2*Ncameras);
    
    for oo=1:NobjPerCat
        for tt=1:Ntransfs

                tmpMM = MM(oo, tt, :, :);
                reshapedMM(oo, ((tt-1)*2*Ncameras+1):(tt*2*Ncameras)) = tmpMM(:)';
        end
    end
   
    totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), 2:end) = reshapedMM;
    totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), 1) = repmat(Ytrue(cat_list(cc)), NobjPerCat, 1);
    
end

figure
imagesc(totalMM);
set(gca, 'YTick', 1:NobjPerCat:Nobj);
set(gca, 'YTickLabel', cat_names(cat_list));
set(gca, 'XTick', 2:4:Ntransfs*2*Ncameras+1);
xtk = keys(ICUBWORLDopts.Transfs);
xtk(cell2mat(values(ICUBWORLDopts.Transfs))) = xtk;
%xtk = repmat(xtk, 1, 4)';
set(gca, 'XTickLabel', xtk(:));

N=unique(totalMM);
colormap(jet(length(N)))
colorbar
saveas(gcf, fullfile(output_dir, model, 'figs', 'more_freq_prediciton.fig'));

%% more_freq_prediction over day & cam

pred_avg_daycam = cell(Ncat,1);
pred_mode_daycam = cell(Ncat,1);


        
pred_avg_daycam{cc} = zeros(NobjPerCat, Ntransfs);
pred_mode_daycam{cc} = zeros(NobjPerCat, Ntransfs);


totalMM = zeros(length(cat_list)*NobjPerCat, Ntransfs+1);

for cc=1:length(cat_list)
    
    MM = more_freq_prediction{cat_list(cc)};
    reshapedMM = zeros(NobjPerCat, Ntransfs);
    
    for oo=1:NobjPerCat
        for tt=1:Ntransfs

                tmpMM = MM(oo, tt, :, :);
                reshapedMM(oo, tt) = mean(tmpMM(:));
        end
    end
   
    totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), 2:end) = reshapedMM;
    totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), 1) = repmat(Ytrue(cat_list(cc)), NobjPerCat, 1);
    
end

figure
imagesc(totalMM);
set(gca, 'YTick', 1:NobjPerCat:Nobj);
set(gca, 'YTickLabel', cat_names(cat_list));
set(gca, 'XTick', 2:Ntransfs+1);
xtk = keys(ICUBWORLDopts.Transfs);
xtk(cell2mat(values(ICUBWORLDopts.Transfs))) = xtk;
%xtk = repmat(xtk, 1, 4)';
set(gca, 'XTickLabel', xtk(:));

N=unique(totalMM);
colormap(jet(length(N)))
colorbar
saveas(gcf, fullfile(output_dir, model, 'figs', 'more_freq_prediciton_meanover_daycam.fig'));

%% accuracy

load(fullfile(output_dir, ['accframebased_' mapping '.mat']), 'accframebased');

totalMM = zeros(length(cat_list)*NobjPerCat, Ntransfs*2*Ncameras);
for cc=1:length(cat_list)
    
    MM = accuracy{cat_list(cc)};
    reshapedMM = zeros(NobjPerCat, Ntransfs*2*Ncameras);
    
    for oo=1:NobjPerCat
        for tt=1:Ntransfs

                tmpMM = MM(oo, tt, :, :);
                reshapedMM(oo, ((tt-1)*2*Ncameras)+1:(tt*2*Ncameras)) = tmpMM(:)';
        end
    end
   
    totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), :) = reshapedMM;
    
end

figure
imagesc(totalMM);
set(gca, 'YTick', 1:NobjPerCat:Nobj);
set(gca, 'YTickLabel', cat_names(cat_list));
set(gca, 'XTick', 1:4:Ntransfs*2*Ncameras);
xtk = keys(ICUBWORLDopts.Transfs);
xtk(cell2mat(values(ICUBWORLDopts.Transfs))) = xtk;
%xtk = repmat(xtk, 1, 4)';
set(gca, 'XTickLabel', xtk(:));

colormap(jet)
colorbar
saveas(gcf, fullfile(output_dir, model, 'figs', 'accuracy.fig'));

%% accuracy over day & cam

totalMM = zeros(length(cat_list)*NobjPerCat, Ntransfs);
for cc=1:length(cat_list)
    
    MM = accuracy{cat_list(cc)};
    reshapedMM = zeros(NobjPerCat, Ntransfs);
    
    for oo=1:NobjPerCat
        for tt=1:Ntransfs

                tmpMM = MM(oo, tt, :, :);
                reshapedMM(oo, tt) = mean(tmpMM(:));
        end
    end
   
    totalMM(((cc-1)*NobjPerCat+1):(cc*NobjPerCat), :) = reshapedMM;
    
end

figure
imagesc(totalMM);
set(gca, 'YTick', 1:NobjPerCat:Nobj);
set(gca, 'YTickLabel', cat_names(cat_list));
set(gca, 'XTick', 1:Ntransfs);
xtk = keys(ICUBWORLDopts.Transfs);
xtk(cell2mat(values(ICUBWORLDopts.Transfs))) = xtk;
%xtk = repmat(xtk, 1, 4)';
set(gca, 'XTickLabel', xtk(:));

colormap(jet)
colorbar
saveas(gcf, fullfile(output_dir, model, 'figs', 'accuracy_meanover_daycam.fig'));
