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

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

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

%% 

mappings = {'1NN', 'none'};

set_names = {'even', 'odd'};

accum_methods = {'predmode', 'predavg'};

%% Read the registries & populate the cell structures

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
