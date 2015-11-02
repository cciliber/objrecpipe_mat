%% Setup 

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';

run('/data/REPOS/GURLS/gurls/utils/gurls_install.m');

curr_dir = pwd;
cd('/data/REPOS/vlfeat-0.9.20/toolbox');
vl_setup;
cd(curr_dir);
clear curr_dir;

addpath(genpath(FEATURES_DIR));

%% ImageNet synsets

imnet_1000synsets_path = '/data/giulia/REPOS/caffe/data/ilsvrc12/synsets.txt';
fid = fopen(imnet_1000synsets_path);
imnet_1000synsets = textscan(fid, '%s');
imnet_1000synsets = imnet_1000synsets{1};
fclose(fid);

%% Dataset

dset_path = '/data/giulia/MyPassport/iCubWorldUltimate_bb_disp_finaltree';
dset_info = '/data/giulia/DATASETS/iCubWorldUltimate.txt';
dset_name = 'iCubWorldUltimate';

ICUBWORLDopts = ICUBWORLDinit(dset_info);

cat_names = keys(ICUBWORLDopts.Cat)';
obj_names = keys(ICUBWORLDopts.Obj)';

Ncat = ICUBWORLDopts.Cat.Count;
Nobj = ICUBWORLDopts.Obj.Count;
NobjPerCat = ICUBWORLDopts.ObjPerCat;
Ntransfs = ICUBWORLDopts.Transfs.Count;
%Ndays = ICUBWORLDopts.Days.Count;
Ncameras = ICUBWORLDopts.Cameras.Count;

%% IO

input_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb_disp_finaltree_experiments/test_offtheshelfnets/scores';
check_input_dir(input_dir);

reg_dir = '/data/giulia/DATASETS/iCubWorldUltimate_digit_registries/test_offtheshelfnets';

output_dir = '/data/giulia/DATASETS/iCubWorldUltimate_bb_disp_finaltree_experiments/test_offtheshelfnets/predictions';

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';
%model = 'vgg';


%% go!

cat_list = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

prediction = cell(Ncat,1);
more_freq_prediction = cell(Ncat,1);
prediction_yesno = cell(Ncat,1);
accuracy = cell(Ncat,1);

Ytrue = zeros(Ncat, 1);

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
    % [C,ia,ic] = unique(A) 
    % C = A(ia)
    % A = C(ic)
    
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
