function D = create_annotations(registry, classes_list, labels_for_wn, output_path)

if isempty(registry)
    error('Empty: registry.');
end
if isempty(classes_list)
    error('Empty: classes_list.');
end

n = size(registry, 1);
nclasses = length(classes_list);

%y = -ones(n, nclasses);

folder_names = regexp(registry, ['\' filesep], 'split');

true_classes = zeros(n,1);
for idx_class=1:nclasses
    true_classes = true_classes + idx_class*(sum(cell2mat(cellfun(@(x) strcmp(x,classes_list{idx_class}), folder_names, 'UniformOutput', false)),2)~=0);
end

%y( sub2ind(size(y),1:n,true_classes') ) = 1;

D = struct('annotation', {});

for ii=1:n
    
    [ffolder, fname, fext] = fileparts(registry{ii});
    D(ii).annotation = struct('filename', [fname fext], 'folder', ffolder);
    D(ii).annotation.object = struct('name', labels_for_wn{true_classes(ii)});
    
end

if ~isempty(output_path)
    
    [out_dir, ~, out_ext] = fileparts(output_path);
    check_output_dir(out_dir);
    
    if isempty(out_ext)
        
        for ii=1:n
            out_file = fullfile(output_path, [registry{ii} '.xml']);
            writeXML(out_file, D(ii));
        end
        
    elseif strcmp(out_ext,'.mat')
        save(output_path, 'n', 'nclasses', 'D');
    else
        error('Error! Invalid extension.');
    end
    
end