%% Setup

%FEATURES_DIR = '/Users/giulia/REPOS/objrecpipe_mat';
%FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
FEATURES_DIR = '/data/giulia/REPOS/objrecpipe_mat';
addpath(genpath(FEATURES_DIR));

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
loaded_set = 2;

% Experiment kind

experiment = 'categorization';
%experiment = 'identification';

% Mapping (used only to name the resulting predictions)

if strcmp(experiment, 'categorization')
    mapping = 'tuned';
    %mapping = 'none';
    %mapping = 'select';
elseif strcmp(experiment, 'identification')
    mapping = 'tuned';
else
    mapping = [];
end

% Whether to use the imnet or the tuning labels

if strcmp(experiment, 'categorization') && strcmp(mapping, 'none')
    use_imnetlabels = true;
elseif strcmp(experiment, 'categorization') && (strcmp(mapping, 'tuned') || strcmp(mapping, 'select'))
    use_imnetlabels = false;
elseif strcmp(experiment, 'identification')
    use_imnetlabels = false;
else
    use_imnetlabels = [];
end

% Choose categories

cat_idx_all = { [2 3 4 5 6 7 8 9 11 12 13 14 15 19 20] };

% Choose objects per category

if strcmp(experiment, 'categorization')
    
    %obj_lists_all = { {1:7, 8:10} };
    %obj_lists_all = { {1:7, 8:10} };
    obj_lists_all = { {1:3, 8:10}, {1:7, 8:10} };
    
elseif strcmp(experiment, 'identification')
    
    id_exps = {1:3, 1:5, 1:7, 1:10};
    obj_lists_all = cell(length(id_exps), 1);
    for ii=1:length(id_exps)
        obj_lists_all{ii} = repmat(id_exps(ii), 1, Nsets);
    end
    
end

% Choose transformation, day, camera

%transf_lists_all = { {1, 1:Ntransfs} {2, 1:Ntransfs} {3, 1:Ntransfs} {4, 1:Ntransfs}};
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

%same_size = false;
%same_size = true;
same_size = true;

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

%exp_dir = fullfile([dset_dir '_experiments'], 'test_offtheshelfnets');
exp_dir = fullfile([dset_dir '_experiments'], 'tuning');

%model = 'googlenet';
model = 'caffenet';
%model = 'vgg';

input_dir_root = fullfile(exp_dir, 'scores', model);
if strcmp(mapping, 'tuned')
    input_dir_root = fullfile(input_dir_root, experiment);
end
check_input_dir(input_dir_root);

output_dir = fullfile(exp_dir, 'predictions', model, experiment);
check_output_dir(output_dir);

input_dir_regtxt_root = fullfile(DATA_DIR, 'iCubWorldUltimate_registries', experiment);
check_input_dir(input_dir_regtxt_root);

%% Prediction parameters

max_batch_size = 10000;

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
                    
                    % Assign the proper output directory
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    if strcmp(experiment, 'identification')
                        dir_regtxt_relative = fullfile(dir_regtxt_relative, strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-'));
                    end
                    
                    if strcmp(mapping, 'tuned')
                        input_dir = fullfile(input_dir_root, dir_regtxt_relative, question_dir);
                        check_input_dir(input_dir);
                    end
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    output_dir_regtxt = fullfile(output_dir, dir_regtxt_relative, question_dir);
                    check_output_dir(output_dir_regtxt);
                    
                    % Create set names
                    
                    for ii=1:Nsets
                        set_names{ii} = [set_names_prefix{ii} strrep(strrep(num2str(obj_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_tr_' strrep(strrep(num2str(transf_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_cam_' strrep(strrep(num2str(camera_lists{ii}), '   ', '-'), '  ', '-')];
                        set_names{ii} = [set_names{ii} '_day_' strrep(strrep(num2str(day_mappings{ii}), '   ', '-'), '  ', '-')];
                    end
                    
                    %% Load Y and create X to compute native Ypred
                    
                    % load Y
                    if use_imnetlabels
                        load(fullfile(input_dir_regtxt, ['Yimnet_' set_names{loaded_set} '.mat']));
                    else
                        load(fullfile(input_dir_regtxt, ['Y_' set_names{loaded_set} '.mat']));
                    end
                    
                    % set selected scores
                    if strcmp(mapping, 'select')
                        
                        %sel_idxs = cell(Ncat, 1);
                        %sel_idxs(cell2mat(values(opts.Cat, cat_names(cat_idx)))) = values( opts.Cat_ImnetLabels, cat_names(cat_idx));
                        %sel_idxs = cell2mat(sel_idxs(~cellfun(@isempty, sel_idxs)));
                        
                        sel_idxs = cell2mat(values(opts.Cat_ImnetLabels));
                        sel_idxs = sel_idxs(cat_idx)+1;
                        
                        if sum(sel_idxs>1000)
                            error('You are selecting scores > 1000!');
                        end
                    end
                    
                    % load REG and create X
                    load(fullfile(input_dir_regtxt, ['REG_' set_names{loaded_set} '.mat']));
                    X = cell(Ncat, 1);
                    NframesPerCat = cell(Ncat, 1);
                    for cc=cat_idx
                        NframesPerCat{opts.Cat(cat_names{cc})} = length(REG{opts.Cat(cat_names{cc})});
                        if (strcmp(mapping, 'select') || strcmp(mapping, 'tuned')) && strcmp(experiment, 'categorization')
                            score_length = length(cat_idx);
                        elseif strcmp(mapping, 'tuned') && strcmp(experiment, 'identification')
                            score_length = length(obj_lists{loaded_set});
                        elseif strcmp(mapping, 'none')
                            score_length = 1000;
                        end
                        X{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, score_length);
                        for ff=1:NframesPerCat{opts.Cat(cat_names{cc})}
                            if strcmp(mapping, 'none') || strcmp(mapping, 'select')
                                fid = fopen(fullfile(input_dir_root, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
                            else
                                fid = fopen(fullfile(input_dir, set_names{1}, cat_names{cc}, [REG{opts.Cat(cat_names{cc})}{ff}(1:(end-4)) '.txt']));
                            end
                            if strcmp(mapping, 'select')
                                x = cell2mat(textscan(fid, '%f'))';
                                X{opts.Cat(cat_names{cc})}(ff,:) = x(sel_idxs);
                            else
                                X{opts.Cat(cat_names{cc})}(ff,:) = cell2mat(textscan(fid, '%f'))';
                            end
                            fclose(fid);
                        end
                    end
                    
                    % compute predictions
                    Ypred = cell(Ncat,1);
                    for cc=cat_idx
                        
                        Ypred{opts.Cat(cat_names{cc})} = zeros(NframesPerCat{opts.Cat(cat_names{cc})}, 1);
                        
                        batch_size = min(max_batch_size, NframesPerCat{opts.Cat(cat_names{cc})});
                        Nbatches = ceil(NframesPerCat{opts.Cat(cat_names{cc})}/batch_size);
                        for bidx=1:Nbatches
                            [~, I] = max(X{opts.Cat(cat_names{cc})}(((bidx-1)*batch_size+1):min(bidx*batch_size, NframesPerCat{opts.Cat(cat_names{cc})}),:), [], 2);
                            Ypred{opts.Cat(cat_names{cc})}((((bidx-1)*batch_size+1):min(bidx*batch_size, NframesPerCat{opts.Cat(cat_names{cc})}))) = I-1;
                        end
                        
                    end
                    
                    acc = compute_accuracy(cell2mat(Y), cell2mat(Ypred), 'gurls')
                    
                    if strcmp(mapping, 'tuned')
                        save(fullfile(output_dir_regtxt, ['Y_' mapping '_' set_names{1} '_' set_names{2} '.mat'] ), 'Ypred', 'acc', '-v7.3');
                    elseif strcmp(mapping, 'none') || strcmp(mapping, 'select')
                        save(fullfile(output_dir_regtxt, ['Y_' mapping '_' set_names{loaded_set}((length(set_names_prefix{loaded_set})+1):end) '.mat'] ), 'Ypred', 'acc', '-v7.3');
                    end
                    
                    
                end
            end
        end
    end
end
