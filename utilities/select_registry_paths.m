function [output_registry, tree] = select_registry_paths(input_registry, desired_paths)

% extract only path
paths = cellfun(@fileparts, input_registry, 'UniformOutput', false);

fslash = strfind(paths{1}, '/');
if isempty(fslash)
    separator = '\';
else
    separator = '/';
end

% for branches, keep only different paths and separate folder names
branches = unique(paths);
branches = regexp(branches, ['\' separator], 'split');

% select only specified folders
if ~isempty(desired_paths)
    
    % for files, separate folder names
    files = regexp(paths, ['\' separator], 'split');
    
    f_indices = zeros(length(input_registry),1);
    b_indices = zeros(length(branches),1);
    for idx_object=1:length(desired_paths)
        add_branch = 1;
        add_file = 1;
        for idx_folder=1:length(desired_paths(idx_object,:))
            add_branch = add_branch & sum(cell2mat(cellfun(@(x) strcmp(x,desired_paths{idx_object,idx_folder}), branches, 'UniformOutput', false)),2);
            add_file = add_file & sum(cell2mat(cellfun(@(x) strcmp(x,desired_paths{idx_object, idx_folder}), files, 'UniformOutput', false)),2);
        end
        b_indices = b_indices + add_branch;
        f_indices = f_indices + add_file;
    end
    branches = branches(b_indices~=0);
    output_registry = input_registry(f_indices~=0);
else
    output_registry = input_registry;
end

% cut the extension
%object.Registry = regexp(object.Registry,'\.','split');
%object.Registry = cellfun(@(x) x(1,1), object.Registry);

% convert column cell-array of row cell-arrays into cell matrix
nbranches = length(branches);
branch_deepness = zeros(nbranches,1);
for idx1=1:nbranches
    branch_deepness(idx1) = size(branches{idx1},2);
end
folders = cell(nbranches, max(branch_deepness));
for idx1=1:nbranches
    for idx2=1:branch_deepness(idx1)
        folders{idx1,idx2} = branches{idx1}{idx2};
    end
end
folders(cellfun('isempty',folders)) = {'-1'};

% convert cell-matrix into row cell-array of column cell-arrays
levels = cell(1,max(branch_deepness));
for idx2=1:max(branch_deepness)
    %levels{idx2} = folders( find(~cellfun('isempty',folders(:,idx2))), idx2 );
    levels{idx2} = folders( :, idx2 );
end

% create .Tree
tree = struct('name', {}, 'subfolder', {});
current_level_idx = 1;

folder_list = unique(levels{current_level_idx});
for f=1:length(folder_list)
    tree(f).name = folder_list{f};
    tree(f).subfolder = struct('name', {}, 'subfolder', {});
    selected_branches = strcmp(folder_list{f},levels{current_level_idx});
    tree(f).subfolder = explore_next_level_file(levels, selected_branches, current_level_idx+1, tree(f).subfolder);
end