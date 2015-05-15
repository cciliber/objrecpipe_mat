root_path = init_machine('laptop_giulia_win');

feat_name = 'overfeat_small_default';

ICUBWORLDopts = ICUBWORLDinit('iCubWorld30');
obj_names = keys(ICUBWORLDopts.objects)';

%dset_name = 'iCubWorld30_manually_cropped';
dset_name = 'iCubWorld30';
%dset_name = 'iCubWorld30_crop256';
%dset_name = 'iCubWorld30_nocrop';

%dset_name = 'iCubWorld30_manually_cropped_withbackground';
%dset_name = 'iCubWorld30_withbackground';
%dset_name = 'iCubWorld30_crop256_withbackground';

feat_root_path = fullfile(root_path, [dset_name '_experiments'], feat_name);
X_path = fullfile(root_path, [dset_name '_experiments'], 'obj_rec_28', feat_name);
y_path = fullfile(root_path, [dset_name '_experiments'], 'obj_rec_28');

check_output_dir(X_path);
check_output_dir(y_path);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imset = 'test';

modality = 'lunedi22';
day = 1;
[Xte{day}, Yte{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);

modality = 'martedi23';
day = 2;
[Xte{day}, Yte{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);

modality = 'mercoledi24';
day = 3;
[Xte{day}, Yte{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);

modality = 'venerdi26';
day = 4;
[Xte{day}, Yte{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imset = 'train';

modality = 'lunedi22';
day = 1;
[Xtr{day}, Ytr{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);

modality = 'martedi23';
day = 2;
[Xtr{day}, Ytr{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);

modality = 'mercoledi24';
day = 3;
[Xtr{day}, Ytr{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);

modality = 'venerdi26';
day = 4;
[Xtr{day}, Ytr{day}] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, obj_names);


Xtr = cell2mat(Xtr');
Ytr = cell2mat(Ytr');

model = gurls_train(Xtr,Ytr,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',0);

cell_result.model = model;
cell_result.classes = 2:28;
 
Xte = cell2mat(Xte');
Yte = cell2mat(Yte');

cell_result.acc = trace_confusion(Yte,gurls_test(model,Xte));

save(fullfile(X_path, 'result_all.mat'), 'cell_result');
