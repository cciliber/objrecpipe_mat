function tree = compute_tree_from_registry(input_registry)

% extract only path
paths = cellfun(@fileparts, input_registry, 'UniformOutput', false);

% for branches, keep only different paths and separate folder names
branches = unique(paths);
branches = regexp(branches, ['\' filesep], 'split');

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
    tree(f).subfolder = explore_next_level_file(levels, selected_branches, current_level_idx+1, tree(f).name, tree(f).subfolder);
end