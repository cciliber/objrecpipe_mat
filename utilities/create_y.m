function [y, n, nclasses] = create_y(registry, classes_list, output_path)

if isempty(registry)
    error('Empty: registry.');
end
if isempty(classes_list)
    error('Empty: classes_list.');
end

fslash = strfind(registry{1}, '/');
if isempty(fslash)
    separator = '\';
else
    separator = '/';
end

n = size(registry, 1);
nclasses = length(classes_list);

y = -ones(n, nclasses);

folder_names = regexp(registry, ['\' separator], 'split');

true_classes = zeros(n,1);
for idx_class=1:nclasses
    true_classes = true_classes + idx_class*(sum(cell2mat(cellfun(@(x) strcmp(x,classes_list{idx_class}), folder_names, 'UniformOutput', false)),2)~=0);
end

y( sub2ind(size(y),1:n,true_classes') ) = 1;

if ~isempty(output_path)
    
    [out_dir, ~, out_ext] = fileparts(output_path);
    check_output_dir(out_dir);
    
    if strcmp(out_ext,'.bin')
        
        fid = fopen(output_path, 'w', 'L');
        if (fid==-1)
            fprintf(2, 'Cannot open file: %s', output_path);
        end
        % column major order
        % format for Unix systems (i.e., L, big endian)
        fwrite(fid, n, 'double');
        fwrite(fid, nclasses, 'double');
        fwrite(fid, y, 'double');
        fclose(fid);
        
    elseif strcmp(out_ext,'.mat')
        
        save(output_path, 'n', 'nclasses', 'y');
        
    else
        error('Error! Invalid extension.');
    end
    
end