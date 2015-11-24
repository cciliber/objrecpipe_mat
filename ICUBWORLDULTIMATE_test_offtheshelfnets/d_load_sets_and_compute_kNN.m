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

reg_dir = '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

experiment = 'kNN-categorization';
%experiment = 'kNN-identification';

dset_dirs = {'/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb60_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid256_disp_finaltree', ...
    '/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_bb30_disp_finaltree'};

%% Sets

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

set_names = {'even', 'odd'};
set_name1 = set_names{1};
set_name2 = set_names{2};

% limit the dataset to one camera for memory reasons on D matrix
camera = 'left';

%% kNN parameters

batch_size = 5000;

Kmax = 15000;
Kvalues = [1 100 200 500 1000 5000];

%% Go!

for dset_idx=1:length(dset_dirs)
     
    dset_dir = dset_dirs{dset_idx};
    
    disp(dset_dir);
    
    output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model, experiment);
    check_output_dir(output_dir);

    %% Load scores
    disp('Loading X and Y...');
    tic
    
    XX = cell(length(set_names), 1);
    XX2 = cell(length(set_names), 1);
    YY = cell(length(set_names), 1);

    N = zeros(length(set_names), 1);
    NframesPerCat = cell(length(set_names), 1);

    for sidx=1:length(set_names)
    
        set_name = set_names{sidx};
    
        load(fullfile(output_dir, ['REG_' set_name '.mat']));
        load(fullfile(output_dir, ['X_' set_name '.mat']));
        load(fullfile(output_dir, ['Y_' set_name '.mat']));
    
        NframesPerCat{sidx} = cell(Ncat, 1);
        
        for cc=1:Ncat
            if ~isempty(REG{cc})
            
                flist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
            
                flist_splitted = regexp(flist, '/', 'split');
                flist_splitted = vertcat(flist_splitted{:});
            
                % remove the other camera
                X{cc}(~strcmp(flist_splitted(:,end), camera), :) = [];
                Y{cc}(~strcmp(flist_splitted(:,end), camera)) = [];
            
                NframesPerCat{sidx}{cc} = length(X{cc});
            
            end
        end
    
        XX{sidx} = cell2mat(X);
        YY{sidx} = cell2mat(Y);
    
        XX2{sidx} = sum(XX{sidx}.*XX{sidx},2);
    
        N(sidx) = size(XX{sidx},1);
        
    end

    clear X Y REG

    N1 = N(1);
    N2 = N(2);
    
    toc
    %% Prepare scores to compute I for set 2 (validation)
    disp('Preparing scores to compute I for set 2 (validation)...');
    
    
    Nbatches = ceil(N2/batch_size);

    x1 = XX{1};
    xx1 = XX2{1};

    x2 = cell(Nbatches, 1);
    xx2 = cell(Nbatches, 1);
    for bidx=1:Nbatches
    
        start_idx = (bidx-1)*batch_size+1;
        end_idx = min(bidx*batch_size, N2);
    
        x2{bidx} = XX{2}(start_idx:end_idx, :)';
        xx2{bidx} = XX2{2}(start_idx:end_idx)';
    end
    
    clear XX XX2;

    
    %% Compute I for set 2 (validation)
    disp('Computing I for set 2 (validation)...');
    tic
    
    m = matfile(fullfile(output_dir, ['I_' camera '_' set_name1 '_' set_name2 '.mat']), 'Writable', true);
    m.I = zeros(Kmax, 1);
    
    for bidx=1:Nbatches
        
        start_idx = (bidx-1)*batch_size+1;
        end_idx = min(bidx*batch_size, N2);
        Dbatch = bsxfun( @plus, xx1, xx2{bidx} ) - 2*x1*x2{bidx};

        [~, I] = sort(Dbatch, 1);
       
        m.I(:, start_idx:end_idx) = I(1:Kmax, :);
        
        disp(num2str(bidx));
    
    end

    toc
    %% Prepare scores to compute I for set 1 (train)
    disp('Preparing scores to compute I for set 1 (train)...');
    tic
    
    Nbatches = ceil(N1/batch_size);

    x1cell = cell(Nbatches, 1);
    xx1cell = cell(Nbatches, 1);
    for bidx=1:Nbatches
    
        start_idx = (bidx-1)*batch_size+1;
        end_idx = min(bidx*batch_size, N1);
    
        x1cell{bidx} = x1(start_idx:end_idx, :)';
        xx1cell{bidx} = xx1(start_idx:end_idx)';
    end

    clear x2 xx2;
    
    toc
    %% Compute I for set 1 (train)
    disp('Computing I for set 1 (train)...');
    tic
    
    m = matfile(fullfile(output_dir, ['I_' camera '_' set_name1 '_' set_name1 '.mat']), 'Writable', true);
    m.I = zeros(Kmax, 1);
    
    for bidx=1:Nbatches
        
        start_idx = (bidx-1)*batch_size+1;
        end_idx = min(bidx*batch_size, N1);
        Dbatch = bsxfun( @plus, xx1, xx1cell{bidx} ) - 2*x1*x1cell{bidx};

        [~, I] = sort(Dbatch, 1);
       
        m.I(:, start_idx:end_idx) = I(1:Kmax, :);
        
        disp(num2str(bidx));
    
    end
    
    toc
    %% Predict on set 2 (validation) for different Ks
    disp('Predict on set 2 (validation) for different Ks...');
    tic
    
    m = matfile(fullfile(output_dir, ['I_' camera '_' set_name1 '_' set_name2 '.mat']), 'Writable', true);
    
    Nbatches = ceil(N2/batch_size);
    
    for k=Kvalues
        
        Ypred = zeros(N2, 1);
        
        Kcurrent = min(k, N1);
        
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N2);
            
            if Kcurrent==1
                Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
            else
                Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
            end
            
        end
        
        Ypred = mat2cell(Ypred, cell2mat(NframesPerCat{2}));
        save(fullfile(output_dir, ['Y_' num2str(Kcurrent) 'NN_' camera '_' set_name2 '.mat']), 'Ypred', '-v7.3');
        
    end
    
    toc
    %% Predict on set 1 (train) for different Ks
    disp('Predict on set 1 (train) for different Ks...');
    tic
    
    m = matfile(fullfile(output_dir, ['I_' camera '_' set_name1 '_' set_name1 '.mat']), 'Writable', true);
    
    Nbatches = ceil(N1/batch_size);
    
    for k=Kvalues
        
        Ypred = zeros(N1, 1);
        
        Kcurrent = min(k, N1);
        
        for bidx=1:Nbatches
            
            start_idx = (bidx-1)*batch_size+1;
            end_idx = min(bidx*batch_size, N2);
            
            if Kcurrent==1
                Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) )',1)';
            else
                Ypred(start_idx:end_idx) = mode(YY{1}( m.I(1:Kcurrent, start_idx:end_idx) ),1)';
            end
            
        end
        
        Ypred = mat2cell(Ypred, cell2mat(NframesPerCat{1}));
        save(fullfile(output_dir, ['Y_' num2str(Kcurrent) 'NN_' camera '_' set_name1 '.mat']), 'Ypred', '-v7.3');
        
    end
 
end