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
Ndays = opts.Days.Count;
Ncameras = opts.Cameras.Count;

%% IO

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_centroid256_disp_finaltree';
%dset_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb30_disp_finaltree';

reg_dir = '/data/giulia/DATASETS/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

input_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model);
check_input_dir(input_dir);

output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model);
check_output_dir(output_dir);

%% Read the registries

load(fullfile(output_dir, 'REGeven.mat'));
REG = REGeven;
clear REGeven;
load(fullfile(output_dir, 'Xeven.mat'));
X = Xeven;
clear Xeven;

load(fullfile(output_dir, 'Yeven_none.mat'));
Y = Yeven_none;
clear Yeven_none;
load(fullfile(output_dir, 'Yeven.mat'));
Ytrue = Yeven;
clear Yeven;


% load(fullfile(output_dir, 'REGodd.mat'));
% REG = REGodd;
% clear REGodd;
% load(fullfile(output_dir, 'Xodd.mat'));
% X = Xodd;
% clear Xodd;
% 
% load(fullfile(output_dir, 'Yodd_none.mat'));
% Y = Yodd_none;
% clear Yodd_none;
% load(fullfile(output_dir, 'Yodd.mat'));
% Ytrue = Yodd;
% clear Yodd;

%% Populate the cell structures

scores = cell(Ncat,1);
pred = cell(Ncat,1);
trueclass = cell(Ncat,1);
pred_yesno = cell(Ncat, 1);
acc = cell(Ncat,1);

pred_avg = cell(Ncat,1);
pred_mode = cell(Ncat,1);

pred_avg_daycam = cell(Ncat,1);
acc_avg_daycam = cell(Ncat,1);
pred_mode_daycam = cell(Ncat,1);
acc_mode_daycam = cell(Ncat,1);

for cc=1:Ncat
    if ~isempty(REG{cc})
        
        scores{cc} = cell(NobjPerClass, Ntransfs, Ndays, Ncameras);
        pred{cc} = cell(NobjPerClass, Ntransfs, Ndays, Ncameras);
        trueclass{cc} = cell(NobjPerClass, Ntransfs, Ndays, Ncameras);
        pred_yesno{cc} = cell(NobjPerClass, Ntransfs, Ndays, Ncameras);
        acc{cc} = zeros(NobjPerClass, Ntransfs, Ndays, Ncameras);
        
        pred_avg{cc} = zeros(NobjPerClass, Ntransfs, Ndays, Ncameras);
        pred_mode{cc} = zeros(NobjPerClass, Ntransfs, Ndays, Ncameras);
        
        REG{cc} = cellfun(@fileparts, REG{cc}, 'UniformOutput', 'false');
        
        [dirlist, ia, ic] = unique(REG{cc}, 'stable');
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
        
        for ii=1:(length(dirlist)-1)
            
            obj = dirlist_splitted(ii,1);
            transf = dirlist_splitted(ii,2);
            day = dirlist_splitted(ii,3);
            cam = dirlist_splitted(ii,4);
            
            idx_start = cumsum(ii)+1;
            idx_end = cumsum(ii+1);
            
            x = X{cc}(idx_start:idx_end, :);
            y = Y{cc}(idx_start:idx_end);
            ytrue = Ytrue{cc}(idx_start:idx_end);
            
            scores{cc}{opts.Obj(obj), opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = x;
            pred{cc}{opts.Obj(obj), opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = y;
            trueclass{cc}{opts.Obj(obj), opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = ytrue;
            pred_yesno{cc}{opts.Obj(obj), opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)} = (y == ytrue);
            
            acc{cc}(opts.Obj(obj), opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = compute_accuracy(ytrue, y, 'gurls');
            
            pred_avg{cc}(opts.Obj(obj), opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = max(mean(x, 1));
            pred_mode{cc}(opts.Obj(obj), opts.Transfs(transf), opts.Days(day), opts.Cameras(cam)) = mode(y);
            
        end
      
    end
end

 pred_avg_daycam{cc} = zeros(NobjPerClass, Ntransfs);
        acc_avg_daycam{cc} = zeros(NobjPerClass, Ntransfs);
        pred_mode_daycam{cc} = zeros(NobjPerClass, Ntransfs);
        acc_mode_daycam{cc} = zeros(NobjPerClass, Ntransfs);
        
for cc=cat_list

    reg_path = fullfile(reg_dir, [cat_names{cc} '.txt']);
    
    loader = Features.GenericFeature();
    loader.assign_registry_and_tree_from_file(reg_path, [], []);
    
    if sum(loader.Y==loader.Y(1))==length(loader.Y)
        Ytrue(cc)=loader.Y(1);
    else
        disp(['Not all files in ' reg_path ' have the same label.']);
    end
        
    fpaths = loader.Registry;
    clear loader;
    fdirs = regexp(fpaths, '/', 'split');
    fdirs = vertcat(fdirs{:});
    fdirs(:,1) = [];
    fdirs(:,end) = [];
    
    prediction{cc} = cell(NobjPerCat, Ntransfs, 2, Ncameras);
    prediction_yesno{cc} = cell(NobjPerCat, Ntransfs, 2, Ncameras);
    more_freq_prediction{cc} = zeros(NobjPerCat, Ntransfs, 2, Ncameras);
    accuracy{cc} = zeros(NobjPerCat, Ntransfs, 2, Ncameras);
    
    fid = fopen(fullfile(output_dir, model, [cat_names{cc} '_' num2str(Ytrue(cc)) '_pred.txt']), 'w');
    line_idx = cellfun(@fileparts, fpaths, 'UniformOutput', false);
    [~, ~, ic] = unique(line_idx, 'stable'); 

    
    ff=1;
    
    prob = textread(fullfile(input_dir, model, [fpaths{ff}(1:(end-4)) '.txt']), '%f', 'delimiter', '\n');
    [dummy, y] = max(prob);
    
    Ypred = zeros(sum(ic==ic(ff)), 1);
    counter = 1;
    Ypred(counter) = y-1;
    
    counter = counter + 1;
    
    for ff=2:length(fpaths)
        
        prob = textread(fullfile(input_dir, model, [fpaths{ff}(1:(end-4)) '.txt']), '%f', 'delimiter', '\n');
        [dummy, y] = max(prob);
        
        if ic(ff)==ic(ff-1)
            
            Ypred(counter) = y-1;
          
        else
            
            prediction{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = Ypred;
            fprintf(fid, '%s\t', line_idx{ff-1});
            fprintf(fid, '%3d ', Ypred);
            fprintf(fid, '\n');

            prediction_yesno{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = (Ypred==Ytrue(cc));
        
            more_freq_prediction{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = mode(Ypred); 
        
            accuracy{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
            ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
            ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
            ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = compute_accuracy(repmat(Ytrue(cc), length(Ypred), 1), Ypred, 'gurls');
            
            Ypred = zeros(sum(ic==ic(ff)), 1);
            counter = 1;
            Ypred(counter) = y-1;
            
        end
        
        counter = counter + 1;
        
    end
    
    
    prediction{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = Ypred;
    fprintf(fid, '%s\t', line_idx{ff-1});
    fprintf(fid, '%3d ', Ypred);
    fprintf(fid, '\n');
    
    prediction_yesno{cc}{mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})} = (Ypred==Ytrue(cc));
    
    more_freq_prediction{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = mode(Ypred);
    
    accuracy{cc}(mod(ICUBWORLDopts.Obj(fdirs{ff-1,1})-1, NobjPerCat)+1, ...
        ICUBWORLDopts.Transfs(fdirs{ff-1,2}), ...
        ICUBWORLDopts.Days(fdirs{ff-1,3}), ...
        ICUBWORLDopts.Cameras(fdirs{ff-1,4})) = compute_accuracy(repmat(Ytrue(cc), length(Ypred), 1), Ypred, 'gurls');
    
    fclose(fid);

end

save(fullfile(output_dir, model, 'all.mat'), 'prediction', 'prediction_yesno', 'accuracy', 'more_freq_prediction');

%%

Ytrue = [0 921 487 985 0 0 584 673 504 0 709 711 761 446 804 0 0 0 837 893]';

DATA = load(fullfile(output_dir, model, 'all.mat'), 'prediction', 'prediction_yesno', 'accuracy', 'more_freq_prediction');
prediction = DATA.prediction;
prediction_yesno = DATA.prediction_yesno;
accuracy = DATA.accuracy; 
more_freq_prediction = DATA.more_freq_prediction; 

clear DATA;

%% prediction yes no

chooseday = 1;
choosecam = 1; 

for choosetransf=keys(ICUBWORLDopts.Transfs)
    
    ff = figure;
    
    for cc=1:length(cat_list)
        
        hh = subplot(3, 5, cc);
        
        CC = prediction_yesno{cat_list(cc)};
        
        maxW = 1;
        for oo=1:NobjPerCat
            W = length(CC{oo, ICUBWORLDopts.Transfs(cell2mat(choosetransf)), chooseday, choosecam});
            if W>maxW
                maxW = W;
            end
        end
        
        AA = -ones(NobjPerCat, maxW);
        
        for oo=1:NobjPerCat
            AA(oo, 1:length(CC{oo, ICUBWORLDopts.Transfs(cell2mat(choosetransf)), chooseday, choosecam})) = CC{oo, ICUBWORLDopts.Transfs(cell2mat(choosetransf)), chooseday, choosecam};
        end
        
        imagesc(AA)
        title(cat_names(cat_list(cc)))
        if max(max(AA))==0
            colormap(hh, [1 0 0; 0 0 0]);
        else
            colormap(hh, [1 0 0; 0 0 0; 1 1 1]);
        end
        %colorbar
    end
    
    suptitle(cell2mat(choosetransf) )
    saveas(gcf, fullfile(output_dir, model, 'figs', [cell2mat(choosetransf) '.fig']));
    
end

%% more_freq_prediction

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
