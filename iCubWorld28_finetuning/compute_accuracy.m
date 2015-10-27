
in_registry_dir = '/data/DATASETS/iCubWorld30_experiments/registries/digits_labels_icubworld30/train.txt';

registry = textread(in_registry_dir, '%s', 'delimiter', '\n'); 

fslash = strfind(registry{1}, '/');
if isempty(fslash)
    separator = '\';
else
    separator = '/';
end

y_pred = zeros(length(registry), 1);
y_true = zeros(length(registry), 1);

class_ids = regexp(registry, ' ', 'split');
class_ids = cellfun(@(x) x{end}, class_ids, 'UniformOutput', false);
class_ids = cellfun(@(x) str2num(x), class_ids, 'UniformOutput', false);
class_ids = unique(cell2mat(class_ids), 'stable');

class_names = regexp(registry, ['\' separator], 'split');
class_names = unique(cellfun(@(x) x{6}, class_names, 'UniformOutput', false), 'stable');

name_id_map = containers.Map(class_names', class_ids'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%root_path = '/data/DATASETS/iCubWorld30_experiments/caffe_finetuned_prob/train/';
%in_registry_path = '/data/DATASETS/iCubWorld30_experiments/registries/iCubWorld30_train.txt';

root_path = '/data/DATASETS/iCubWorld30_experiments/caffe_finetuned_prob/test/';
in_registry_path = '/data/DATASETS/iCubWorld30_experiments/registries/iCubWorld30_test.txt';

registry = textread(in_registry_path, '%s', 'delimiter', '\n');

for ii=1:length(registry)
    
    prob = textread([root_path registry{ii} '.txt'], '%f', 'delimiter', '\n');
    
    class_name = strsplit(registry{ii}, separator);
    class_name = class_name{end-1};
    
    [dummy, y] = max(prob);
    y_pred(ii) = y;
    y_true(ii) = name_id_map(class_name);
    y_true(ii) = y_true(ii) + 1;
    
end

Cr = C(:, cell2mat(values(name_id_map))+1);
Crc = Cr(cell2mat(values(name_id_map))+1, :);
 
figure, imagesc(Crc)
set(gca, 'YTickLabels', keys(name_id_map))
set(gca, 'XTickLabels', keys(name_id_map), 'XTickLabelRotation', 45)
grid on
colorbar

[acc, C] = compute_accuracy(y_true, y_pred, 'carlo');
acc = compute_accuracy(y_true, y_pred, 'gurls');

