root_path = init_machine('laptop_giulia_win');

ICUBWORLDopts = ICUBWORLDinit('iCubWorld30');
obj_names = keys(ICUBWORLDopts.objects)';

feat_name = 'caffe_centralcrop_meanimagenet2012';

dset_names = {'iCubWorld30_nocrop', ...
    'iCubWorld30_crop256', ...
    'iCubWorld30_crop256_withbackground', ...
    'iCubWorld30', ...
    'iCubWorld30_withbackground', ...
    'iCubWorld30_manually_cropped_withbackground'};

modality = 'venerdi26';

%% TRAIN 

imset = 'train';

for d=1:length(dset_names)
    
    X_path = fullfile(root_path, [dset_names{d} '_experiments'], 'obj_rec_28', feat_name)
    y_path = fullfile(root_path, [dset_names{d} '_experiments'], 'obj_rec_28')


    tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
    Xtr = tmp.feat';
    tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
    Ytr = tmp.y;

    model = gurls_train(Xtr,Ytr,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',0);
    
    cell_result.model = model;
    cell_result.classes = 2:28;
    save(fullfile(y_path, 'result_ven.mat'), 'cell_result');
    
end

%% TEST

imset = 'test';

acc_table = zeros(length(dset_names), length(dset_names));

for dtr = 1:length(dset_names)
    
    ytr_path = fullfile(root_path, [dset_names{dtr} '_experiments'], 'obj_rec_28');

    load(fullfile(ytr_path, 'result_ven.mat'));
    model = cell_result.model;

    cell_result.acc = zeros(length(dset_names),1);

    for dte = 1:length(dset_names)
        
            Xte_path = fullfile(root_path, [dset_names{dte} '_experiments'], 'obj_rec_28', feat_name);
            yte_path = fullfile(root_path, [dset_names{dte} '_experiments'], 'obj_rec_28');

    
            tmp = load(fullfile(Xte_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
            Xte = tmp.feat';
            tmp = load(fullfile(yte_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
            Yte = tmp.y;

            cell_result.acc(dte)= trace_confusion(Yte,gurls_test(model,Xte));
            acc_table(dtr, dte) = cell_result.acc(dte);
            
    end
    
    save(fullfile(ytr_path, 'result_ven.mat'), 'cell_result');
end