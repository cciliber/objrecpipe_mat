classdef GenericFeature < handle %matlab.mixin.Copyable %hgsetget 
    
    properties
       
        Tree
        Registry
        
        RootPath
        Feat
        FeatSize
        ExampleCount
        Y
        
        ImSize
        Grid
        GridSize
      
        nRandFeatures
        Dictionary
        DictionarySize
        
    end
    
    methods
        
        function obj = GenericFeature()
            
        end
        
        function import_registry_and_tree(object, prev_object) 
            
            object.Tree = prev_object.Tree;
            object.ExampleCount = prev_object.ExampleCount;
            object.Registry = prev_object.Registry;

        end
        
        function assign_registry_and_tree_from_folder(object, in_rootpath, objlist, labelslist, out_registry_path, out_ext)
            
            % Init members
            object.Registry = [];
            object.Tree = struct('name', {}, 'subfolder', {});
            object.ExampleCount = 0;
            
            % explore folders creating .Tree .Registry .ExampleCount
            
            check_input_dir(in_rootpath);
            object.RootPath = in_rootpath;
            
            object.Tree = explore_next_level_folder(object, '', object.Tree, objlist);
            
            if ~isempty(labelslist)
                y_1 = create_y(object.Registry, labelslist, []);
                [~, object.Y] = max(y_1, [], 2);
            end
            
            if ~isempty(out_registry_path)
                
                [reg_dir, ~, ~] = fileparts(out_registry_path);
                check_output_dir(reg_dir);
                
                fid = fopen(out_registry_path,'w');
                if (fid==-1)
                    fprintf(2, 'Cannot open file: %s', out_registry_path);
                end
      
                for line_idx=1:object.ExampleCount
                    if isempty(out_ext) && isempty(labelslist) 
                        fprintf(fid, '%s\n', object.Registry{line_idx});
                    elseif isempty(labelslist) 
                        fprintf(fid, '%s\n', [object.Registry{line_idx}(1:(end-4)) out_ext]);
                    elseif isempty(out_ext)
                        fprintf(fid, '%s\n', [object.Registry{line_idx} ' ' labelslist{object.Y(line_idx)}]);
                    else
                        fprintf(fid, '%s\n', [object.Registry{line_idx}(1:(end-4)) out_ext  ' ' labelslist{object.Y(line_idx)}]);
                    end
                end
                fclose(fid);
            end
            
        end
        function current_level = explore_next_level_folder(obj, current_path, current_level, objects_list)
            
            % get the listing of files at the current level
            files = dir(fullfile(obj.RootPath, current_path));
 
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
                        current_level(length(current_level)).subfolder = explore_next_level_folder(obj, current_path, current_level(length(current_level)).subfolder, objects_list);
                        
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
                           %[file_dir, file_name, ~] = fileparts(file_src);
                           obj.ExampleCount = obj.ExampleCount + 1;
                           %obj.Registry{obj.ExampleCount,1} = fullfile(file_dir, file_name);
                           obj.Registry{obj.ExampleCount,1} = file_src;
                           
                        end

                    end
                end
            end
        end
                
        function reproduce_tree(obj, out_rootpath)
            
            check_output_dir(out_rootpath);
            reproduce_level(obj, out_rootpath, obj.Tree);
        end
        function reproduce_level(obj, current_path, current_level)
            
            for idx=1:length(current_level)
                
                tmp_path = current_path;
                current_path = fullfile(current_path, current_level(idx).name);
                if ~isdir(current_path)
                    mkdir(current_path);
                end
                reproduce_level(obj, current_path, current_level(idx).subfolder);
                % fall back to the previous level
                current_path= tmp_path;
            end
        end
        
        function assign_registry_and_tree_from_file(object, in_registry_path, objlist, out_registry_path)

            [reg_dir, ~, ~] = fileparts(in_registry_path);
            check_input_dir(reg_dir);
            
            try
            input_registry = textread(in_registry_path, '%s', 'delimiter', '\n'); 
            catch err
                fprintf(2, 'Cannot open file: %s', in_registry_path);
            end
            
            % select only specified folders
            [object.Registry, object.Tree] = select_registry_paths(input_registry, objlist);
            object.ExampleCount = size(object.Registry,1);

            if ~isempty(out_registry_path)
             
                [reg_dir, ~, ~] = fileparts(out_registry_path);
                check_output_dir(reg_dir);
                
                fid = fopen(out_registry_path,'w');
                if fid==-1
                    fprintf(2, 'Cannot open file: %s',out_registry_path);
                end
                for line_idx=1:object.ExampleCount
                    fprintf(fid, '%s\n', object.Registry{line_idx});
                end  
                fclose(fid);
 
            end

        end

        function extract_file(object, in_rootpath, in_registry_path, in_ext, objlist, out_registry_path, dictionary, modality_out, out_rootpath, out_ext)
                    
            check_input_dir(in_rootpath);
                      
            if isempty(in_registry_path)
                object.assign_registry_and_tree_from_folder(in_rootpath, objlist, out_registry_path);
            else
                object.assign_registry_and_tree_from_file(in_registry_path, objlist, out_registry_path);
            end

            if (strcmp(modality_out,'wspace') || strcmp(modality_out,'both'))
                object.FeatSize = zeros(2, object.ExampleCount);
                object.ImSize = zeros(2, object.ExampleCount);
                object.GridSize = zeros(2, object.ExampleCount);
                object.Grid = [];
                object.Feat = [];
            end
            
            if (strcmp(modality_out,'file') || strcmp(modality_out,'both'))
                check_output_dir(out_rootpath);
                object.RootPath = out_rootpath;
                object.reproduce_tree(out_rootpath);
            end
            
            if ~isempty(dictionary)
                dict_type = 0;
                if isnumeric(dictionary)
                    dict_type = 1;
                end
                if ischar(dictionary)
                    dict_type = 2;
                end
                
                if dict_type==0
                    error('Dictionary must be either character or numeric array.');
                end
                if dict_type==1
                    object.import_dictionary(dictionary);
                end
                if dict_type==2
                    object.load_dictionary(dictionary);
                end
            end
            
            if isa(object, 'Features.MyHMAX')
                
                if isempty(object.Dictionary)
                    error('Missing Dictionary in calling object.');
                end
                
                object.initModel();
                
            end
            
            for idx_feat = 1:object.ExampleCount
                
                src_relative_path = object.Registry{idx_feat};
                feat_src = fullfile(in_rootpath, [src_relative_path in_ext]);
                
                feat_src_grid = '';
                im_size = [];

                if (strcmp(modality_out,'file') || strcmp(modality_out,'both'))
                    dst_relative_path = object.Registry{idx_feat};
                    file_dst = fullfile(object.RootPath, [dst_relative_path out_ext]);
                end
                if (strcmp(modality_out,'wspace'))
                    file_dst = '';
                end

                [feat_dst, feat_dst_grid, im_size] = extract_image(object, feat_src, feat_src_grid, im_size, modality_out, file_dst);
                              
                if (strcmp(modality_out,'wspace') || strcmp(modality_out,'both'))
                    if ~isempty(feat_dst)
                        object.FeatSize(:, idx_feat) = size(feat_dst);
                        object.Feat(:,(end+1):(end+size(feat_dst,2))) = feat_dst;
                    end
                    if ~isempty(im_size)
                        object.ImSize(:, idx_feat) = im_size(1:2);
                    end
                    if ~isempty(feat_dst_grid)
                        object.GridSize(:, idx_feat) = size(feat_dst_grid);
                        object.Grid(:,(end+1):(end+size(feat_dst_grid,2))) = feat_dst_grid;
                    end                 
                end
                
                disp([num2str(idx_feat) '/' num2str(object.ExampleCount)]);
            end
            
            if isa(object, 'MyHMAX')
                object.freeModel()
            end
            
        end 
        function extract_wspace(object, feat_matrix, featsize_matrix, grid_matrix, gridsize_matrix, imsize_matrix, dictionary, modality_out, out_rootpath)
          
            if (strcmp(modality_out,'wspace') || strcmp(modality_out,'both'))
                object.FeatSize = zeros(2, object.ExampleCount);
                object.ImSize = zeros(2, object.ExampleCount);
                object.GridSize = zeros(2, object.ExampleCount);
                object.Grid = [];
                object.Feat = [];
            end
            
            if (strcmp(modality_out,'file') || strcmp(modality_out,'both'))
                check_output_dir(out_rootpath);
                object.RootPath = out_rootpath;
                object.reproduce_tree(out_rootpath);
            end
            
            dict_type = 0;
            if isnumeric(dictionary) 
                dict_type = 1;
            end
            if ischar(dictionary)
                dict_type = 2;
            end
            
            if dict_type==0            
                error('Dictionary must be either character or numeric array.');
            end
            if dict_type==1
                object.Dictionary = dictionary;
            end
            if dict_type==2
                object.load_dictionary(dictionary);
            end

            for idx_feat = 1:object.ExampleCount
                
                if (strcmp(modality_out,'file') || strcmp(modality_out,'both'))
                    dst_relative_path = object.Registry{idx_feat};
                    file_dst = fullfile(object.RootPath, [dst_relative_path out_ext]);
                end 
                if (strcmp(modality_out,'wspace'))
                    file_dst = '';
                end
                
                feat_src = feat_matrix(:, (sum(featsize_matrix(2, 1:(idx_feat-1)))+1):sum(featsize_matrix(2, 1:idx_feat)));
                feat_src_grid = grid_matrix(:, (sum(gridsize_matrix(2, 1:(idx_feat-1)))+1):sum(gridsize_matrix(2, 1:idx_feat)));
                im_size = imsize_matrix(:,idx_feat);

                [feat_dst, feat_dst_grid, im_size] = extract_image(object, feat_src, feat_src_grid, im_size, modality_out, file_dst);
                
                if (strcmp(modality_out,'wspace') || strcmp(modality_out,'both'))
                    object.FeatSize(:, idx_feat) = size(feat_dst);
                    object.ImSize(:, idx_feat) = im_size;
                    object.GridSize(:, idx_feat) = size(feat_dst_grid);
                    object.Grid(:,(end+1):(end+size(feat_dst_grid,2))) = feat_dst_grid;
                    object.Feat(:,(end+1):(end+size(feat_dst,2))) = feat_dst;
                end
                
                disp([num2str(idx_feat) '/' num2str(object.ExampleCount)]);
            end
            
        end
        
        function load_feat_rndsubset(object, feat_rootpath, in_registry_path, feat_ext, objlist, n_rand_feat, out_registry_path)
            
            check_input_dir(feat_rootpath);
            object.RootPath = feat_rootpath;
                   
            if isempty(in_registry_path)
                object.assign_registry_and_tree_from_folder(feat_rootpath, objlist, out_registry_path);
            else
                object.assign_registry_and_tree_from_file(in_registry_path, objlist, out_registry_path);
            end
        
            % clear feature matrix
            object.Feat = [];
            object.Grid = [];
            
            % init feature size (= size of feature matrix for each image)  
            object.FeatSize = zeros(2,object.ExampleCount);
            object.GridSize = zeros(2,object.ExampleCount);
            object.ImSize = [];
            
            if ~strcmp(feat_ext,'.ppm')
                
                % load first only feature sizes
                for line_idx=1:object.ExampleCount
                    
                    relative_path = object.Registry{line_idx};
                    
                    if strcmp(feat_ext,'.bin')
                        fid = fopen(fullfile(object.RootPath, [relative_path feat_ext]), 'r', 'L');
                        if (fid==-1)
                            fprintf(2, 'Cannot open file: %s', fullfile(object.RootPath, [relative_path feat_ext]));
                        end
                        % append modality
                        % column major order
                        % format for Unix systems (i.e., L, big endian)
                        object.FeatSize(:,line_idx) = fread(fid, [2 1], 'double');
                        fclose(fid);
                    elseif strcmp(feat_ext,'.mat')
                        input = load(fullfile(object.RootPath, [relative_path feat_ext]),'-mat', 'feat_size');
                        object.FeatSize(:,line_idx) = input.feat_size;
                    else
                        error('Invalid extension: it is not .bin, .mat, .ppm. If it is another image ext you can add it as for .ppm!');
                    end
                end
                
                % compute overall number of features in the dataset
                n_feat = sum(object.FeatSize(2,:));
                
            else
                n_feat = object.ExampleCount;
            end
         
            % ...to get a range in which extract random indices
            if n_rand_feat<n_feat
                rnd_indices = vl_colsubset(1:n_feat, n_rand_feat);
                object.nRandFeatures = n_rand_feat;
            else 
                rnd_indices = 1:n_feat;
                object.nRandFeatures = n_feat;
            end
            
            if ~strcmp(feat_ext,'.ppm')
            
                % store selected features
                start_idx = 0;
                for line_idx=1:object.ExampleCount
                    relative_path = object.Registry{line_idx};
                    
                    end_idx = start_idx + object.FeatSize(2,line_idx);
                    selected_indices = rnd_indices(rnd_indices>start_idx & rnd_indices<=end_idx) - start_idx;
                    start_idx = end_idx;
                    
                    if strcmp(feat_ext,'.bin')
                        
                        fid = fopen(fullfile(object.RootPath, [relative_path feat_ext]), 'r', 'L');
                        if (fid==-1)
                            fprintf(2, 'Cannot open file: %s', fullfile(object.RootPath, [relative_path feat_ext]));
                        end
                        % append modality
                        % column major order
                        % format for Unix systems (i.e., L, big endian)
                        feat_size = fread(fid, [2 1], 'double');
                        feat = fread(fid, feat_size', 'double');
                        object.Feat(:, (end+1):(end+size(selected_indices,2))) = feat(:,selected_indices);
                        object.FeatSize(:, line_idx) = size(feat(:,selected_indices));
                        
                        if ~feof(fid)
                            grid_size = fread(fid, [2 1], 'double');
                            grid = fread(fid, grid_size', 'double');
                            object.Grid(:, (end+1):(end+size(selected_indices,2))) = grid(:,selected_indices);
                            object.GridSize(:, line_idx) = size(grid(:,selected_indices));
                        end
                        if ~feof(fid)
                            im_size = fread(fid, [2 1], 'double');
                            object.ImSize(:, end+1) = im_size;
                        end
                        fclose(fid);
                        
                    elseif strcmp(feat_ext,'.mat')
                        input = load(fullfile(object.RootPath, [relative_path feat_ext]),'-mat');
                        object.Feat(:,(end+1):(end+size(selected_indices,2))) = input.feat(:,selected_indices);
                        object.FeatSize(:, line_idx) = size(input.feat(:,selected_indices));
                        if isfield(input, 'grid')
                            object.Grid(:,(end+1):(end+size(selected_indices,2))) = input.grid(:,selected_indices);
                            object.GridSize(:, line_idx) = size(input.grid(:,selected_indices));
                        end
                        if isfield(input, 'im_size')
                            object.ImSize(:,end+1) = input.im_size;
                        end
                    else
                        error('Invalid extension.');
                    end
                    
                end
            else   
                object.Feat = fullfile(object.RootPath, strcat(object.Registry(rnd_indices), feat_ext));
            end
                
        end
        function load_feat(object, feat_rootpath, in_registry_path, feat_ext, objlist, out_registry_path)
            
            check_input_dir(feat_rootpath);
            object.RootPath = feat_rootpath;
                      
            if isempty(in_registry_path)
                object.assign_registry_and_tree_from_folder(feat_rootpath, objlist, out_registry_path);
            else
                object.assign_registry_and_tree_from_file(in_registry_path, objlist, out_registry_path);
            end
                
            % clear feature matrix
            object.Feat = [];
            object.Grid = [];
            
            % init feature size (= size of feature matrix for each image)  
            object.FeatSize = zeros(2,object.ExampleCount);
            object.GridSize = zeros(2,object.ExampleCount);
            object.ImSize = [];
            
            for line_idx=1:object.ExampleCount
                
                relative_path = object.Registry{line_idx};
                
                if strcmp(feat_ext,'.bin')
                    
                    fid = fopen(fullfile(object.RootPath, [relative_path feat_ext]), 'r', 'L');
                    if (fid==-1)
                        fprintf(2, 'Cannot open file: %s', fullfile(object.RootPath, [relative_path feat_ext]));
                    end
                    % append modality
                    % column major order 
                    % format for Unix systems (i.e., L, big endian)
                    object.FeatSize(:, line_idx) = fread(fid, [2 1], 'double');
                    object.Feat(:,(end+1):(end+object.FeatSize(2, line_idx))) = fread(fid, object.FeatSize(:, line_idx)', 'double');
                    if ~feof(fid)
                        object.GridSize(:, line_idx) = fread(fid, [2 1], 'double');
                        object.Grid(:,(end+1):(end+object.GridSize(2, line_idx))) = fread(fid, object.GridSize(:, line_idx)', 'double');
                    end
                    if ~feof(fid)
                        object.ImSize(:, end+1) = fread(fid, [2 1], 'double');
                    end
                    fclose(fid);
                    
                elseif strcmp(feat_ext,'.mat')
                    
                    input = load(fullfile(object.RootPath, [relative_path feat_ext]));
                    object.FeatSize(:, line_idx) = input.feat_size;
                    object.Feat(:,(end+1):(end+input.feat_size(2))) = input.feat;
                    if isfield(input, 'grid')
                        object.GridSize(:, line_idx) = input.grid_size;
                        object.Grid(:,(end+1):(end+input.grid_size(2))) = input.grid;
                    end
                    if isfield(input, 'im_size') && ~isempty(input.im_size)
                        object.ImSize(:,end+1) = input.im_size;
                    end
                else
                    error('Invalid extension.');
                end
   
            end  

        end
        function load_feat_matrix(object, path)
            
            [file_dir, ~, ~] = fileparts(path);
            check_input_dir(file_dir);
            
            % clear feature matrix
            object.Feat = [];
            object.Grid = [];
            
            % init feature size (= size of feature matrix for each image)  
            object.FeatSize = zeros(2,object.ExampleCount);
            object.GridSize = zeros(2,object.ExampleCount);
            object.ImSize = [];
            
            if strcmp(file_ext,'.bin')
                fid = fopen(path, 'r', 'L');
                if (fid==-1)
                   fprintf(2, 'Cannot open file: %s', path);
                end
                % column major order
                % format for Unix systems (i.e., L, big endian)
                object.FeatSize = fread(fid, [2 1], 'double');
                object.Feat = fread(fid, object.FeatSize', 'double');
                fclose(fid);
            elseif strcmp(file_ext,'.mat')
                
                input = load(path, '-mat', 'feat_size', 'feat');
                if isfield(input, 'feat') && ~isempty(input.feat)
                    object.FeatSize = input.feat_size;
                    object.Feat = input.feat;
                else
                    error('Error! Could not load .mat dictionary from specified path.');
                end
            else
                error('Error! Invalid feature matrix extension.');
            end
        end
        
        function save_feat(object, feat_rootpath, in_registry_path, feat_ext)

            object.assign_registry_and_tree_from_file(in_registry_path, [], []);
            
            object.reproduce_tree(feat_rootpath);
             
            for line_idx=1:object.ExampleCount
                
                relative_path = object.Registry{line_idx};
                
                feat_size = object.FeatSize(:, line_idx);
                feat = object.Feat(:, (sum(object.FeatSize(2, 1:(line_idx-1)))+1):sum(object.FeatSize(2, 1:line_idx)));
                
                grid_size = [];
                grid = [];
                im_size = [];
                
                if ~isempty(object.Grid)
                    grid_size = object.GridSize(:, line_idx);
                    grid = object.Grid(:, (sum(object.GridSize(2, 1:(line_idx-1)))+1):sum(object.GridSize(2, 1:line_idx)));
                end
                if ~isempty(object.ImSize)
                    im_size = object.ImSize(:, line_idx);
                end
               
                if strcmp(feat_ext,'.bin')
                    fid = fopen(fullfile(feat_rootpath, [relative_path feat_ext]), 'w', 'L');
                    if (fid==-1)
                        fprintf(2, 'Cannot open file: %s', fullfile(feat_rootpath, [relative_path feat_ext]));
                    end
                    % column major order
                    % format for Unix systems (i.e., L, big endian)
                    fwrite(fid, feat_size, 'double');
                    fwrite(fid, feat, 'double');
                    if ~isempty(grid)
                        fwrite(fid, grid_size, 'double');
                        fwrite(fid, grid, 'double');
                    end
                    if ~isempty(im_size)
                        fwrite(fid, im_size, 'double');
                    end
                    fclose(fid);
                    
                elseif strcmp(feat_ext,'.mat')
                    
                    if ~isempty(grid) && ~isempty(im_size)
                        save(fullfile(feat_rootpath, [relative_path feat_ext]),'feat', 'grid', 'feat_size', 'grid_size', 'im_size');
                    elseif ~isempty(grid)
                        save(fullfile(feat_rootpath, [relative_path feat_ext]),'feat', 'feat_size', 'grid', 'grid_size');
                    elseif ~isempty(im_size)
                        save(fullfile(feat_rootpath, [relative_path feat_ext]),'feat', 'feat_size', 'im_size');
                    else
                        save(fullfile(feat_rootpath, [relative_path feat_ext]),'feat', 'feat_size');
                    end
                    
                else
                    error('Error! Invalid extension.');
                end
 
            end     
            
        end
        function save_feat_matrix(object, path)
            
            feat_size = object.FeatSize;
            feat = object.Feat;
            grid_size = object.GridSize;
            grid = object.Grid;
            im_size = object.ImSize;
            
            [file_dir, ~, file_ext] = fileparts(path);
            check_output_dir(file_dir);
            
            if strcmp(file_ext,'.bin')
                fid = fopen(path, 'w', 'L');
                if (fid==-1)
                   fprintf(2, 'Cannot open file: %s', path);
                end
                % column major order 
                % format for Unix systems (i.e., L, big endian)
                fwrite(fid, feat_size, 'double');
                fwrite(fid, feat, 'double');
                if ~isempty(grid)
                    fwrite(fid, grid_size, 'double');
                    fwrite(fid, grid, 'double');
                end
                if ~isempty(im_size)
                    fwrite(fid, im_size, 'double');
                end
                fclose(fid);
            elseif strcmp(file_ext,'.mat')
                
                if ~isempty(grid) && ~isempty(im_size)
                    save(path,'feat', 'grid', 'feat_size', 'grid_size', 'im_size');
                elseif ~isempty(grid)
                    save(path,'feat', 'feat_size', 'grid', 'grid_size');
                elseif ~isempty(im_size)
                    save(path,'feat', 'feat_size', 'im_size');
                else
                    save(path,'feat', 'feat_size');
                end
                
            else
                error('Error! Invalid feature matrix extension.');
            end
            
        end
        
        function dictionarize_file(object, in_rootpath, in_registry_path, in_extension, objlist, dict_size, n_rand_feat, out_registry_path, modality_out, dictionary_path)
            
            % create previous generic object to load the features
            previous_object = Features.GenericFeature();
             
            previous_object.load_feat_rndsubset(in_rootpath, in_registry_path, in_extension, objlist, n_rand_feat, out_registry_path);
            object.nRandFeatures = previous_object.nRandFeatures;
            
            % prepare output
            
            if (strcmp(modality_out,'file') || strcmp(modality_out,'both'))
               
                [dict_dir, ~, ~] = fileparts(dictionary_path);
                check_output_dir(dict_dir);
                
                file_dst = dictionary_path;
            end
            
            if (strcmp(modality_out,'wspace'))
                file_dst = '';
            end
            
            % dictionarize
            
            if (strcmp(modality_out,'wspace') || strcmp(modality_out,'both'))
                object.Dictionary = object.dictionarize_matrix(previous_object.Feat, dict_size, modality_out, file_dst);
                object.DictionarySize = size(object.Dictionary);
            end
            
            if (strcmp(modality_out,'file'))
                object.dictionarize_matrix(previous_object.Feat, dict_size, modality_out, file_dst);
            end
            
        end
        
        function dictionarize_wspace(object, feat_matrix, modality_out, dictionary_path)
            
            % prepare output
            
            if (strcmp(modality_out,'file') || strcmp(modality_out,'both'))
               
                [dict_dir, ~, ~] = fileparts(dictionary_path);
                check_output_dir(dict_dir);
                
                file_dst = dictionary_path;
            end
            
            if (strcmp(modality_out,'wspace'))
                file_dst = '';
            end
            
            % dictionarize
            
            if (strcmp(modality_out,'wspace') || strcmp(modality_out,'both'))
                object.Dictionary = object.dictionarize_matrix(feat_matrix, modality_out, file_dst);
                object.DictionarySize = size(object.Dictionary);
            end
            if (strcmp(modality_out,'file'))
                object.dictionarize_matrix(feat_matrix, modality_out, file_dst);
            end

        end
        
        function load_dictionary(object, path)

            [dict_dir, ~, dict_ext] = fileparts(path);
            check_input_dir(dict_dir);
            
            if strcmp(dict_ext,'.bin')
                    fid = fopen(path, 'r', 'L');
                    if (fid==-1)
                       fprintf(2, 'Cannot open file: %s', path);
                    end
                    % append modality
                    % column major order 
                    % format for Unix systems (i.e., L, big endian)
                    object.DictionarySize = fread(fid, [2 1], 'double');
                    object.Dictionary = fread(fid, object.DictionarySize', 'double');
                    fclose(fid);
            elseif strcmp(dict_ext,'.mat')
                
                input = load(path, '-mat');
                if isfield(input, 'dictionary')
                    object.DictionarySize = input.dictionary_size;
                    object.Dictionary = input.dictionary;
                else
                    error('Could not load from: %s ', path);
                end
            elseif strcmp(dict_ext, '.txt')
               
                dict_string = dlmread(path);
                object.DictionarySize = dict_string(1,1:2);
                object.Dictionary = dict_string(2:end,:);
               
            else
                error('Error! Invalid extension.');
            end
            
        end
        function save_dictionary(object, path)
            
            dictionary_size = object.DictionarySize;
            dictionary = object.Dictionary;
            
            [dict_dir, ~, dict_ext] = fileparts(path);
            check_output_dir(dict_dir);
            
            if strcmp(dict_ext,'.bin')
                
                fid = fopen(path, 'w', 'L');
                if (fid==-1)
                   fprintf(2, 'Cannot open file: %s', path);
                end
                % column major order 
                % format for Unix systems (i.e., L, big endian)
                fwrite(fid, dictionary_size, 'double');
                fwrite(fid, dictionary, 'double');
                fclose(fid);
                
            elseif strcmp(dict_ext,'.mat')
                
                save(path, 'dictionary', 'dictionary_size');
                
            elseif strcmp(dict_ext, '.txt')
                            
                dlmwrite(path, dictionary_size, 'delimiter', '\t');
                dlmwrite(path, dictionary, '-append', 'delimiter', '\t');

            else
                error('Error! Invalid extension.');
            end
            
        end
        function import_dictionary(object, dictionary)    
           object.Dictionary = dictionary;
           object.DictionarySize = size(dictionary); 
        end
        
    end
    
end