function [registry, Y] = registry_from_folder(in_rootpath, objlist, labelslist, out_registry_path, out_ext)

check_input_dir(in_rootpath);

% explore folders creating tree registry exampleCount
tree = struct('name', {}, 'subfolder', {});
registry = [];
[~, registry] = explore_next_level_folder(in_rootpath, 0, [], '', tree, registry, objlist);

if ~isempty(labelslist)
    y = create_y(registry, labelslist, []);
    [~, Y] = max(y, [], 2);
    Y = Y - 1;
end

if ~isempty(out_registry_path)
    
    [reg_dir, ~, ~] = fileparts(out_registry_path);
    check_output_dir(reg_dir);
    
    fid = fopen(out_registry_path,'w');
    if (fid==-1)
        fprintf(2, 'Cannot open file: %s', out_registry_path);
    end
    for line_idx=1:length(registry)
        if isempty(out_ext) && isempty(labelslist)
            fprintf(fid, '%s\n', registry{line_idx});
        elseif isempty(labelslist)
            fprintf(fid, '%s\n', [registry{line_idx}(1:(end-4)) out_ext]);
        elseif isempty(out_ext)
            fprintf(fid, '%s\n', [registry{line_idx} ' ' Y(line_idx)]);
        else
            fprintf(fid, '%s\n', [registry{line_idx}(1:(end-4)) out_ext  ' ' Y(line_idx)]);
        end 
    end
    fclose(fid);
    
end