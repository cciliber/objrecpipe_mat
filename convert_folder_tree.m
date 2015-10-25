function convert_folder_tree(in_root_path, in_ext, out_root_path, out_ext)

feat = Features.GenericFeature();
feat.assign_registry_and_tree_from_folder(in_root_path, [], [], [], []);

[~, ~, fexts] = cellfun(@fileparts, feat.Registry, 'UniformOutput', 0);

check_output_dir(out_root_path);
feat.reproduce_tree(out_root_path);

reglist = feat.Registry(strcmp(fexts, '.txt'));
for ii=1:length(reglist)
    copyfile(fullfile(in_root_path, reglist{ii}), fullfile(out_root_path, reglist{ii}));
    disp([num2str(ii) '/' num2str(length(reglist))]);
end

imlist = feat.Registry(strcmp(fexts, in_ext));
for ii=1:length(imlist)
    I = imread(fullfile(in_root_path, imlist{ii}));
    imwrite(I, [fullfile(out_root_path, imlist{ii}(1:(end-4))) out_ext]);
    disp([num2str(ii) '/' num2str(length(imlist))]);
end

