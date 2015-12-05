%% Setup

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

%DATA_DIR = '/Volumes/MyPassport';
DATA_DIR = '/data/giulia/ICUBWORLD_ULTIMATE';

%% Dataset info

dset_info = fullfile(DATA_DIR, 'iCubWorldUltimate_registries/info/iCubWorldUltimate.txt');
dset_name = 'iCubWorldUltimate';

opts = ICUBWORLDinit(dset_info);

cat_names = keys(opts.Cat);
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

%% Set up the experiments

% Default sets that are searched

set_names_prefix = {'train_', 'val_', 'test_'};
Nsets = length(set_names_prefix);

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

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
    [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };

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

dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');

model = 'googlenet';
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

input_dir = fullfile(exp_dir, 'scores', model);
check_input_dir(input_dir);

save_I = true;

output_dir = fullfile(exp_dir, 'predictions', model, experiment);
check_output_dir(output_dir);

input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt_root);

%% kNN parameters

max_batch_size = 5000;

max_Irows = 50000;

max_k = 5000;
num_k = 10;

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        % Assign the proper IO directories
        
        dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
        if strcmp(experiment, 'identification')
            dir_regtxt_relative = fullfile(dir_regtxt_relative, strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-'));
        end
        
        input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
        check_input_dir(input_dir_regtxt);
        
        output_dir_regtxt = fullfile(output_dir, dir_regtxt_relative);
        check_output_dir(output_dir_regtxt);
        
        % Create set names
        
        for ii=1:Nsets
            set_names{ii} = [set_names_prefix{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
            set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
        end
        
        %% Load Y and create X for train and val sets
        disp('Loading Y and creating X for train and val...');
        
        XX = cell(2, 1);
        XX2 = cell(2, 1);
        
        YY = cell(3, 1);
        
        N = zeros(3, 1);
        NframesPerCat = cell(3, 1);
        
        for sidx=1:2
            
            set_name = set_names{sidx};
            
            % load Y
            if use_imnetlabels
                load(fullfile(input_dir_regtxt, ['Yimnet_' set_name '.mat']));
            else
                load(fullfile(input_dir_regtxt, ['Y_' set_name '.mat']));
            end
            YY{sidx} = cell2mat(Y);
            clear Y
            
            % load scores and create X
            load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
            X = cell(Ncat, 1);
            NframesPerCat{sidx} = cell(Ncat, 1);
            for cc=cat_idx
                NframesPerCat{sidx}{opts.Cat(cat_names{cc})} = length(REG{opts.Cat(cat_names{cc})});
                X{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{sidx}{opts.Cat(cat_names{cc})}, 1000);
                for ff=1:NframesPerCat{sidx}{opts.Cat(cat_names{cc})}
                    fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
                    X{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
                    fclose(fid);
                end
            end
            
            XX{sidx} = cell2mat(X);
            XX2{sidx} = sum(XX{sidx}.*XX{sidx},2);
            
            N(sidx) = size(XX{sidx},1);
            
            clear REG X
            
        end
        
        %% Train and cross-validate
        
        Kvalues = round(linspace(1, min(max_k, N(1)), num_k));
        Irows = min(max_Irows, N(1));
        acc = -ones(3, length(Kvalues));
        
        % Prepare scores and compute I for set 1-2 (val),
        % then predict on set 2 (train) for different Ks
        
        disp('Preparing scores to compute I for sets 1-2 (validation)...');
        
        batch_size = min(max_batch_size, N(2));
        Nbatches = ceil(N(2)/batch_size);
        
        x1 = XX{1};
        xx1 = XX2{1};
        
        x2 = cell(Nbatches, 1);
        xx2 = cell(Nbatches, 1);
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N(2));
            
            x2{bidx} = XX{2}(start_idx:end_idx, :)';
            xx2{bidx} = XX2{2}(start_idx:end_idx)';
        end
        
        clear XX XX2;
        
        disp('Computing I for sets 1-2 (validation)...');
        
        m = matfile(fullfile(output_dir_regtxt, ['I_' set_names{1} '_' set_names{2} '.mat']), 'Writable', true);
        m.I = zeros(Irows, 1);
        
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N(2));
            Dbatch = bsxfun( @plus, xx1, xx2{bidx} ) - 2*x1*x2{bidx};
            
            [~, I] = sort(Dbatch, 1);
            
            m.I(:, start_idx:end_idx) = I(1:Irows, :);
            
            disp(num2str(bidx));
            
        end
        
        clear x2 xx2
        
        disp('Predict on set 2 (validation) for different Ks...');
        
        for k=1:length(Kvalues)
            
            Ypred = zeros(N(2), 1);
            
            Kcurrent = min(Kvalues(k), N(1));
            
            for bidx=1:Nbatches
                
                start_idx = (bidx-1)*batch_size+1;
                end_idx = min(bidx*batch_size, N(2));
                
                if Kcurrent==1
                    Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
                else
                    Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
                end
                
            end
            
            % store the accuracy for current K
            acc(2, k) = compute_accuracy(Ypred, YY{2}, 'gurls');
            
        end
        
        % Remove intermediate I matrices if requested
        
        if save_I==false
            rmfile(fullfile(output_dir_regtxt, ['I_' set_names{1} '_' set_names{2} '.mat']));
        end
        
        % Prepare scores and compute I for sets 1-1 (train),
        % then predict on set 1 (train) for different Ks
        
        disp('Preparing scores to compute I for sets 1-1 (train)...');
        
        batch_size = min(max_batch_size, N(1));
        Nbatches = ceil(N(1)/batch_size);
        
        x1cell = cell(Nbatches, 1);
        xx1cell = cell(Nbatches, 1);
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N(1));
            
            x1cell{bidx} = x1(start_idx:end_idx, :)';
            xx1cell{bidx} = xx1(start_idx:end_idx)';
        end
        
        disp('Compute I for sets 1-1 (train)...');
        
        m = matfile(fullfile(output_dir_regtxt, ['I_' set_names{1} '_' set_names{1} '.mat']), 'Writable', true);
        m.I = zeros(Irows, 1);
        
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N(1));
            Dbatch = bsxfun( @plus, xx1, xx1cell{bidx} ) - 2*x1*x1cell{bidx};
            
            [~, I] = sort(Dbatch, 1);
            
            m.I(:, start_idx:end_idx) = I(1:Irows, :);
            
            disp(num2str(bidx));
            
        end
        
        clear x1cell xx1cell
        
        disp('Predict on set 1 (train) for different Ks...');
        
        for k=1:length(Kvalues)
            
            Ypred = zeros(N(1), 1);
            
            Kcurrent = min(k, N(1));
            
            for bidx=1:Nbatches
                
                start_idx = (bidx-1)*batch_size+1;
                end_idx = min(bidx*batch_size, N(1));
                
                if Kcurrent==1
                    Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
                else
                    Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
                end
                
            end
            
            % store the accuracy for current K
            acc(1, k) = compute_accuracy(Ypred, YY{1}, 'gurls');
            
        end
        
        % Remove intermediate I matrices if requested
        
        if save_I==false
            rmfile(fullfile(output_dir_regtxt, ['I_' set_names{1} '_' set_names{1} '.mat']));
        end
        
        %% Test
        
        % Load Y and create X for test set
        disp('Loading Y and creating X for test...');
        
        sidx=3;
        set_name = set_names{sidx};
        
        % load Y
        if use_imnetlabels
            load(fullfile(input_dir_regtxt, ['Yimnet_' set_name '.mat']));
        else
            load(fullfile(input_dir_regtxt, ['Y_' set_name '.mat']));
        end
        YY{3} = cell2mat(Y);
        clear Y
        
        % load scores and create X
        load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
        X = cell(Ncat, 1);
        NframesPerCat = cell(Ncat, 1);
        for cc=cat_idx
            NframesPerCat{opts.Cat(cat_names{cc})} = length(REG{opts.Cat(cat_names{cc})});
            X{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, 1000);
            for ff=1:NframesPerCat{opts.Cat(cat_names{cc})}
                fid = fopen(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
                X{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
                fclose(fid);
            end
        end
        
        XX = cell2mat(X);
        XX2 = sum(XX.*XX,2);
        
        N(sidx) = size(XX,1);
        
        clear REG X
        
        % Prepare scores and compute I for sets 1-3 (test),
        % then predict on set 3 (test) for the best K
        
        disp('Preparing scores to compute I for sets 1-3 (test)...');
        
        batch_size = min(max_batch_size, N(3));
        Nbatches = ceil(N(3)/batch_size);
        
        x3 = cell(Nbatches, 1);
        xx3 = cell(Nbatches, 1);
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N(3));
            
            x3{bidx} = XX(start_idx:end_idx, :)';
            xx3{bidx} = XX2(start_idx:end_idx)';
        end
        
        clear XX XX2;
        
        disp('Computing I for sets 1-3 (test)...');
        
        m = matfile(fullfile(output_dir_regtxt, ['I_' set_names{1} '_' set_names{3} '.mat']), 'Writable', true);
        m.I = zeros(Irows, 1);
        
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N(3));
            Dbatch = bsxfun( @plus, xx1, xx3{bidx} ) - 2*x1*x3{bidx};
            
            [~, I] = sort(Dbatch, 1);
            
            m.I(:, start_idx:end_idx) = I(1:Irows, :);
            
            disp(num2str(bidx));
            
        end
        
        clear x3 xx3
        
        disp('Predict on set 3 (test) for the best K...');
        
        % Choose best K on validation
        
        [v, best_k_idx] = max(acc(2,:));
        best_k = Kvalues(best_k_idx);
        
        %for k=1:length(Kvalues)
        for k=best_k_idx
            
            Ypred = zeros(N(3), 1);
            
            Kcurrent = min(Kvalues(k), N(3));
            
            for bidx=1:Nbatches
                
                start_idx = (bidx-1)*batch_size+1;
                end_idx = min(bidx*batch_size, N(3));
                
                if Kcurrent==1
                    Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
                else
                    Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
                end
                
            end
            
            % store the accuracy for current K
            acc(3, k) = compute_accuracy(Ypred, YY{3}, 'gurls')
            Kvalues
            
        end
        
        % Remove intermediate I matrix if requested
        
        if save_I==false
            rmfile(fullfile(output_dir_regtxt, ['I_' set_names{1} '_' set_names{3} '.mat']));
        end
        
        %% Store results
        
        Ypred = mat2cell(Ypred, cell2mat(NframesPerCat));
        if use_imnetlabels
            save(fullfile(output_dir_regtxt, ['Yimnet_NN_' set_names{3} '.mat']), 'Ypred', 'Kvalues', 'acc', '-v7.3');
        else
            save(fullfile(output_dir_regtxt, ['Y_NN_' set_names{3} '.mat']), 'Ypred', 'Kvalues', 'acc', '-v7.3');
        end
        
    end
    
end