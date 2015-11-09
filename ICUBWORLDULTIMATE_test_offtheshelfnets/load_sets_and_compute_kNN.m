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

cat_idx = [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20];

model = 'googlenet'; 
%model = 'bvlc_reference_caffenet';
%model = 'vgg';

dset_dir = '/media/giulia/Elements/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree';
%dset_dir = '/Volumes/MyPassport/iCubWorldUltimate_bb60_disp_finaltree';
%dset_dir = '/Volumes/MyPassport/iCubWorldUltimate_centroid256_disp_finaltree';
%dset_dir = '/Volumes/MyPassport/iCubWorldUltimate_bb30_disp_finaltree';

reg_dir = '/media/giulia/Elements/ICUBWORLD_ULTIMATE/iCubWorldUltimate_digit_registries/test_offtheshelfnets';
check_input_dir(reg_dir);

input_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'scores', model);
check_input_dir(input_dir);

output_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets', 'predictions', model);
check_output_dir(output_dir);

%% Compute & save D matrix

set_names = {'even', 'odd'};

% limit the dataset to one camera for memory reasons on D matrix
camera = 'left';

%

batch_size = 5000;
batches_in_ram = 6;

%

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
    
    for cc=1:Ncat
        if ~isempty(REG{cc})
            
            flist = cellfun(@fileparts, REG{cc}, 'UniformOutput', false);
            
            flist_splitted = regexp(flist, '/', 'split');
            flist_splitted = vertcat(flist_splitted{:});
            
            X{cc}(~strcmp(flist_splitted(:,end), camera), :) = [];
            Y{cc}(~strcmp(flist_splitted(:,end), camera)) = [];
            
            NframesPerCat{sidx} = length(X{cc});
            
        end
    end
    
    XX{sidx} = cell2mat(X);
    YY{sidx} = cell2mat(Y);
    
    XX2{sidx} = sum(XX{sidx}.*XX{sidx},2);
    
    N(sidx) = size(XX{sidx},1);
        
end

clear X Y REG

Nbatches = ceil(N(2)/batch_size);

%m = matfile(fullfile(output_dir, ['D_' camera '_' set_name1 '_' set_name2 '_' num2str(bidx) '.mat']), 'Writable', true);
%m.D = zeros(N(1), 1);

m = cell(Nbatches, 1);

N1 = N(1);
N2 = N(2);
set_name1 = set_names{1};
set_name2 = set_names{2};

x1 = XX{1};
xx1 = XX2{1};

x2 = cell(Nbatches, 1);
xx2 = cell(Nbatches, 1);
for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N2);
    n = end_idx-start_idx+1;
    
    xx2{bidx} = XX2{2}(start_idx:end_idx)';
    x2{bidx} = XX{2}(start_idx:end_idx, :)';
end

clear XX XX2;

NforCycles = ceil(Nbatches/batches_in_ram);

for super_bidx=4:NforCycles
    
    tic
    
    start_bidx = (super_bidx-1)*batches_in_ram+1;
    end_bidx = min(super_bidx*batches_in_ram, Nbatches);
    
    parfor bidx=start_bidx:end_bidx
    
        m{bidx} = matfile(fullfile(output_dir, ['D_' camera '_' set_name1 '_' set_name2 '_' num2str(bidx) '.mat']), 'Writable', true);

        %m.D(:, start_idx:end_idx) = XX2{1}*ones(1,n) - 2 * XX{1} * XX{2}(start_idx:end_idx, :)' + ones(N(1),1)*(XX2{2}(start_idx:end_idx))'; 
        %m{bidx}.D(:, start_idx:end_idx) = bsxfun( @plus, XX2{1}, XX2{2}(start_idx:end_idx)' ) - 2*XX{1}*XX{2}(start_idx:end_idx, :)';
        
        m{bidx}.D = bsxfun( @plus, xx1, xx2{bidx} ) - 2*x1*x2{bidx};

        disp(num2str(bidx));
    
    end
    
    toc
end

%% Compute kNN predictions

K = 1;

m = matfile(fullfile(output_dir, ['D_' camera '_' set_names{1} '_' set_names{2} '.mat']));

% On set 2

Nbatches = ceil(N(2)/batch_size);

Ypred = zeros(N(2), 1);
k = min(K, N(1));

for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(2));
    
    [~, I] = sort(m.D(:, start_idx:end_idx), 1);
    idx = I(1:k, :);
    
    if k==1
        Ypred(start_idx:end_idx) = mode(YY{1}(idx)',1)';
    else
        Ypred(start_idx:end_idx) = mode(YY{1}(idx),1)';
    end
           
end

Ypred = mat2cell(Ypred, NframesPerCat{2});
set_name = set_names{2};
save(fullfile(output_dir, ['Y_' num2str(k) 'NN_' camera '_' set_name '.mat']), 'Ypred', '-v7.3');

% On set 1

Nbatches = ceil(N(1)/batch_size);

Ypred = zeros(N(1), 1);
k = min(K, N(2));

for bidx=1:Nbatches
    
    start_idx = (bidx-1)*batch_size+1;
    end_idx = min(bidx*batch_size, N(1));
      
    [~, I] = sort(m.D(start_idx:end_idx,:),2);
    idx = I(:, 1:k)';
    
    if k==1
        Ypred(start_idx:end_idx) = mode(YY{2}(idx)',1)';
    else
        Ypred(start_idx:end_idx) = mode(YY{2}(idx),1)';
    end
    
end

Ypred = mat2cell(Ypred, NframesPerCat{1});
set_name = set_names{1};
save(fullfile(output_dir, ['Y_kNN_' camera '_' set_name '.mat']), 'Ypred', '-v7.3');
    