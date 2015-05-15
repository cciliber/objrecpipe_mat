function [Xtr, Ytr, Xte, Yte] = load_selectedXY(train_root, train_reg_path, test_root, test_reg_path, objlist, feat_ext)

    dataset_train = Features.GenericFeature();
    dataset_test = Features.GenericFeature();

    dataset_train.load_feat(train_root, train_reg_path, feat_ext, objlist, []);
    dataset_test.load_feat(test_root, test_reg_path, feat_ext, objlist, []);

    Xtr = dataset_train.Feat';
    Xte = dataset_test.Feat';

    Ytr = create_y(dataset_train.Registry, objlist, []);
    Yte = create_y(dataset_test.Registry, objlist, []);

    clear dataset_train dataset_test
    
end