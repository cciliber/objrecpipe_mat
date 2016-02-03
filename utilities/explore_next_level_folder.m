function current_level = explore_next_level_folder(in_rootpath, exampleCount, registry, current_path, current_level, objects_list)

if ischar(objects_list)
    objects_list = {objects_list};
end

% get the listing of files at the current level
files = dir(fullfile(in_rootpath, current_path));

flag = 0;

for idx_file = 1:size(files)
    
    % for each folder, create its duplicate in the hierarchy
    % then get inside it and repeat recursively
    if (files(idx_file).name(1)~='.')
        
        if (files(idx_file).isdir)
            
            tmp_path = current_path;
            current_path = fullfile(current_path, files(idx_file).name);
            
            current_level(length(current_level)+1).name = files(idx_file).name;
            current_level(length(current_level)).subfolder = struct('name', {}, 'subfolder', {});
            current_level(length(current_level)).subfolder = explore_next_level_folder(in_rootpath, current_path, current_level(length(current_level)).subfolder, objects_list);
            
            % fall back to the previous level
            current_path = tmp_path;
            
        else
            
            if flag==0
                
                flag = 1;
                
                if isempty(objects_list)
                    tobeadded = 1;
                else
                    file_src = fullfile(current_path, files(idx_file).name);
                    [file_dir, ~, ~] = fileparts(file_src);
                    
                    file_dir_splitted = strsplit(file_dir, '/');
                    
                    tobeadded = 0;
                    for s=1:length(objects_list)
                        contains_path = 1;
                        for ss=1:length(objects_list(s,:))
                            contains_path = contains_path & sum(strcmp(file_dir_splitted,objects_list{s,ss}));
                        end
                        tobeadded = tobeadded + contains_path;
                    end
                end
                
            end
            
            if tobeadded
                file_src = fullfile(current_path, files(idx_file).name);
                exampleCount = exampleCount + 1;
                registry{exampleCount,1} = file_src; 
            end
            
        end
    end
end