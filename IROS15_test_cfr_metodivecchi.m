root_path = init_machine('laptop_giulia_win');

%feat_name = 'overfeat_small_default';
%feat_name = 'sc_d512';
feat_name = 'HMAX';
%feat_name = 'caffe_centralcrop_meanimagenet2012';

ICUBWORLDopts = ICUBWORLDinit('iCubWorld30');
obj_names = keys(ICUBWORLDopts.objects)';

dset_name = 'iCubWorld30';

feat_root_path = fullfile(root_path, [dset_name '_experiments'], feat_name);
X_path = fullfile(root_path, [dset_name '_experiments'], 'obj_rec_28', feat_name);
y_path = fullfile(root_path, [dset_name '_experiments'], 'obj_rec_28');

check_output_dir(X_path);
check_output_dir(y_path);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imset = 'train';

modality = 'lunedi22';
day = 1;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xtr{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Ytr{day} = tmp.y;

modality = 'martedi23';
day = 2;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xtr{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Ytr{day} = tmp.y;
    
modality = 'mercoledi24';
day = 3;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xtr{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Ytr{day} = tmp.y;
    
modality = 'venerdi26';
day = 4;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xtr{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Ytr{day} = tmp.y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imset = 'test';

modality = 'lunedi22';
day = 1;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xte{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Yte{day} = tmp.y;

modality = 'martedi23';
day = 2;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xte{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Yte{day} = tmp.y;

modality = 'mercoledi24';
day = 3;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xte{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Yte{day} = tmp.y;

modality = 'venerdi26';
day = 4;
tmp = load(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));
Xte{day} = tmp.feat';
tmp = load(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']));
Yte{day} = tmp.y;

acc = zeros(4,1);
for day=1:4
    
    day
    model = gurls_train(Xtr{day},Ytr{day},'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',0);

    cell_result.model = model;
    cell_result.classes = 2:28;
    
    cell_result.acc = trace_confusion(Yte{day},gurls_test(model,Xte{day}));
    acc(day) = cell_result.acc;
    
    save(fullfile(X_path, ['result_' num2str(day) '.mat']), 'cell_result');
end


Xtr = cell2mat(Xtr');
Ytr = cell2mat(Ytr');
model = gurls_train(Xtr,Ytr,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',0);
cell_result.model = model;
cell_result.classes = 2:28;

%Xte = cell2mat(Xte');
%Yte = cell2mat(Yte');

tmp = load(fullfile(X_path, 'result_all.mat'));
cell_result = tmp.cell_result;

acc_partial = zeros(4,1);
for day=1:4
    acc_partial(day) = trace_confusion(Yte{day},gurls_test(cell_result.model,Xte{day}));
end
cell_result.acc = mean(acc_partial);

save(fullfile(X_path, 'result_all.mat'), 'cell_result');
