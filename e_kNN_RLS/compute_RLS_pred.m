%% Setup

%FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
%FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

gurls_setup();
vl_feat_setup();

%DATA_DIR = '/media/giulia/MyPassport';
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

set_names_prefix = {'train_', 'test_'};
Nsets = length(set_names_prefix);

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Mapping (used only to name the resulting predictions)

mapping = 'RLS';

% Choose categories

cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20]};

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    obj_lists_all = { {1:7, 8:10} };
    %obj_lists_all = { {1:7, 8:10} };
    %obj_lists_all = { {1:3, 8:10}, {1:7, 8:10} };
    
elseif strcmp(experiment, 'identification')
    
    id_exps = {1:3, 1:5, 1:7, 1:10};
    obj_lists_all = cell(length(id_exps), 1);
    for ii=1:length(id_exps)
        obj_lists_all{ii} = repmat(id_exps(ii), 1, Nsets);
    end
    
end

%transf_lists_all = { {1, 1:Ntransfs} {2, 1:Ntransfs} {3, 1:Ntransfs} {4, 1:Ntransfs} {5, 1:Ntransfs}};
%transf_lists_all = { {5, 1:Ntransfs} {4:5, 1:Ntransfs} {[2 4:5], 1:Ntransfs} {2:5, 1:Ntransfs} {1:Ntransfs, 1:Ntransfs} };
transf_lists_all = { {5, 5} };

day_mappings_all = { {1, 1:2} };
day_lists_all = cell(length(day_mappings_all),1);

for ee=1:length(day_mappings_all)
    
    day_mappings = day_mappings_all{ee};
    
    day_lists = cell(Nsets,1);
    tmp = keys(opts.Days);
    for ii=1:Nsets
        for dd=1:length(day_mappings{ii})
            tmp1 = tmp(cell2mat(values(opts.Days))==day_mappings{ii}(dd))';
            tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
            day_lists{ii} = [day_lists{ii} tmp2];
        end
    end
    
    day_lists_all{ee} = day_lists;
    
end

camera_lists_all = { {1, 1} };

% Choose whether to maintain the same size of 1st set for all sets

same_size = false;
%same_size = true;
%same_size = true;

if same_size == true
    %question_dir = 'frameORtransf';
    question_dir = 'frameORinst';
else
    question_dir = '';
end

%% Set the IO root directories

% Location of the scores

%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid384_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb60_disp_finaltree');
dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_centroid256_disp_finaltree');
%dset_dir = fullfile(DATA_DIR, 'iCubWorldUltimate_bb30_disp_finaltree');

exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');

%model = 'googlenet';
model = 'caffenet';
%model = 'vgg';

feature = 'fc6';

input_dir = fullfile(exp_dir, 'scores', model, feature);
check_input_dir(input_dir);

output_dir_root = fullfile(exp_dir, 'predictions', model, feature, experiment);
check_output_dir(output_dir_root);

input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt_root);

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
                    
                    % Assign the proper IO directories
        
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    if strcmp(experiment, 'identification')
                        dir_regtxt_relative = fullfile(dir_regtxt_relative, strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-'));
                    end
        
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative, question_dir);
                    check_input_dir(input_dir_regtxt);
        
                    output_dir = fullfile(output_dir_root, dir_regtxt_relative, question_dir);
                    check_output_dir(output_dir);
        
                    % Create set names
                    
                    for ii=1:Nsets
                        set_names{iset} = [set_names_prefix{iset} strrep(strrep(num2str(obj_lists{iset}), '   ', '-'), '  ', '-')];
                        set_names{iset} = [set_names{iset} '_tr_' strrep(strrep(num2str(transf_lists{iset}), '   ', '-'), '  ', '-')];
                        set_names{iset} = [set_names{iset} '_cam_' strrep(strrep(num2str(camera_lists{iset}), '   ', '-'), '  ', '-')];
                        set_names{iset} = [set_names{iset} '_day_' strrep(strrep(num2str(day_mappings{iset}), '   ', '-'), '  ', '-')];
                    end
        
                    %% Load Y and create X
                    disp('Loading Y and creating X...');
      
                    N = zeros(Nsets, 1);
                    NframesPerCat = cell(Nsets, 1);
        
                    first_loaded = false;
                    
                    for iset=1:Nsets
            
                        set_name = set_names{iset};
            
                        % load Y
                        ystruct = load(fullfile(input_dir_regtxt, ['Y_' set_name '.mat']));
                        Y = cell2mat(ystruct.Y);
                        clear ystruct
                        
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
