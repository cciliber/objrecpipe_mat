
clear all;

FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

gurls_setup();
vl_feat_setup();

%% Global data dir
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

%% Where to put the models
mapping = 'rls';

%% Setup the question
same_size = false;
if same_size == true
    %question_dir = 'frameORtransf';
    question_dir = 'frameORinst';
end

%% Setup the IO root directories

% input scores
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

% input registries
input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% output root
exp_dir = fullfile([dset_dir '_experiments'], 'categorization');
check_output_dir(exp_dir);

%% Categories
%cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };
cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };

%% Set up train and val test sets

% objects per category
Ntest = 1;
Nval = 1;
Ntrain = NobjPerCat - Ntest - Nval;
obj_lists_all = cell(Ntrain, 1);
p = randperm(NobjPerCat);
for oo=1:Ntrain
    obj_lists_all{oo} = cell(1,3);
    obj_lists_all{oo}{3} = p(1:Ntest);
    obj_lists_all{oo}{2} = p((Ntest+1):(Ntest+Nval));
    obj_lists_all{oo}{1} = p((Ntest+Nval+1):(Ntest+Nval+oo));
end

% transformation
%transf_lists_all = { {1, 1:Ntransfs}; {2, 1:Ntransfs}; {3, 1:Ntransfs}; {4, 1:Ntransfs}};
%transf_lists_all = { {5, 1:Ntransfs}; {4:5, 1:Ntransfs}; {[2 4:5], 1:Ntransfs}; {2:5, 1:Ntransfs}; {1:Ntransfs, 1:Ntransfs} };
transf_lists_all = { {5, 2} };
%transf_lists_all = { {1:Ntransfs} };

% day
day_mappings_all = { {1, 1} };
day_lists_all = create_day_list(day_mappings_all, opts.Days);

% camera
camera_lists_all = { {1, 1} };

trainval_prefixes = {'train_', 'val_'};
trainval_sets = [1 2];
tr_set = trainval_sets(1);
val_set = trainval_sets(2);
eval_set = 3;

%% Caffe model

%model = 'googlenet';
model = 'caffenet';
%model = 'vgg';

feature = 'fc6';

%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_lists = obj_lists_all{iobj};
        
        for itransf=1:length(transf_lists_all)
            
            transf_lists = transf_lists_all{itransf};
            
            for iday=1:length(day_lists_all)
                
                day_lists = day_lists_all{iday};
                day_mappings = day_mappings_all{iday};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_lists = camera_lists_all{icam};
                    
                    %% Create the train val folder name 
                    for iset=trainval_sets
                        set_names{iset} = [strrep(strrep(num2str(obj_lists{iset}), '   ', '-'), '  ', '-') ...
                        '_tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-') ...
                        '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-') ...
                        '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                    end
                    trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                    trainval_dir = trainval_dir(1:end-1);
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(num_output)], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir = fullfile(exp_dir, model, dir_regtxt_relative, trainval_dir, mapping);
                    check_output_dir(output_dir);

                    %% Load true Y and create X
      
                    N = zeros(Nsets, 1);
                    NframesPerCat = cell(Nsets, 1);
        
                    first_loaded = false;
                    
                    for iset=trainval_sets
            
                        set_name = set_names{iset};
            
                        %% Load the registry and Y (true labels)
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                        input_registry = textscan(fid, '%s %d');
                        fclose(fid);
                        Y = input_registry{2};
                        REG = input_registry{1};
                        if use_imnetlabels
                            fid = fopen(fullfile(input_dir_regtxt, [set_name '_Yimnet.txt']));
                            input_registry = textscan(fid, '%s %d');
                            fclose(fid);
                            Yimnet = input_registry{2};
                        end
                        clear input_registry;
                        
                        
                        
                        
                        
                        % create X
                        regstruct = load(fullfile(input_dir_regtxt, ['REG_' set_name '.mat']));
                        REG = regstruct.REG;
                        clear regstruct;
                        
                        X = cell(Ncat, 1);
                        NframesPerCat{iset} = cell(Ncat, 1);
                        for cc=cat_idx
                            NframesPerCat{iset}{opts.Cat(cat_names{cc})} = length(REG{opts.Cat(cat_names{cc})});
                            if ~first_loaded
                                fcstruct = load(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{1}(1:(end-4)) '.mat']));
                                feat_length = size(fcstruct.fc,1);
                                first_loaded = true;
                                clear fcstruct;
                            end 
                            X{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{iset}{opts.Cat(cat_names{cc})}, feat_length);
                            for ff=1:NframesPerCat{iset}{opts.Cat(cat_names{cc})}
                                fcstruct = load(fullfile(input_dir, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.mat']));
                                %X{opts.Cat(cat_names{cc})}(ff,:) = max(fcstruct.fc, [], 2);;
                                X{opts.Cat(cat_names{cc})}(ff,:) = mean(fcstruct.fc, 2);
                            end
                        end
            
                        X = cell2mat(X);
                        N(iset) = size(X,1);
                        
                        clear fcstruct REG

                        if strcmp(set_names_prefix{iset}(1:end-1), 'train')
                            
                            % train the model
                            % convert Y to 1-base indexing for GURLS!
                            model = gurls_train(X,Y+1,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',1);
                            
                            % save the model 
                            save(fullfile(output_dir, ['model_' mapping '_' set_names{iset} '.mat']), 'model', '-v7.3');
                            
                        elseif strcmp(set_names_prefix{iset}(1:end-1), 'test')
                            
                            % load the model 
                            % assume that the train is the previous set in the list
                            training_set = set_names{iset-1};
                            modelstruct = load(fullfile(output_dir, ['model_' mapping '_' training_set '.mat']));
                            model = modelstruct.model;
                           
                            % test
                            Ypred = gurls_test(model,X);
                            [~, Ypred] = max(Ypred, [], 2);
                            % back to 0-base indexing
                            Ypred = Ypred-1;
                            
                            % compute accuracy
                            % again convert to 1-base indexing
                            [acc, C] = trace_confusion(Y+1,Ypred+1);
                            
                            % store results
                            tmp = cell(length(NframesPerCat),1);
                            tmp(~cellfun(@isempty, NframesPerCat)) = mat2cell(Ypred, cell2mat(NframesPerCat));
                            Ypred = tmp;
                            save(fullfile(output_dir, ['Y_' mapping cell2mat(strcat('_', set_names(:))') '.mat']), 'Ypred', 'acc', 'C', '-v7.3');
                            
                        end
 
                    end
                    
                end
            end
        end
    end
end
