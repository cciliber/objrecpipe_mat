function [xtr, ytr] = load_and_save_xy (feat_root_path, imset, modality, y_path, X_path, class_names)

loader = Features.GenericFeature();

loader.load_feat(fullfile(feat_root_path, fullfile(imset, modality)), [], '.mat', [], fullfile(y_path, [imset '_' modality '.txt']));
y_1 = create_y(loader.Registry, class_names, []);
[~, y] = max(y_1, [], 2);

save(fullfile(y_path, ['Y' imset(1:2) '_' modality(1:3) '.mat']), 'y');
loader.save_feat_matrix(fullfile(X_path, ['X' imset(1:2) '_' modality(1:3) '.mat']));

xtr = loader.Feat';
ytr = y_1;

end