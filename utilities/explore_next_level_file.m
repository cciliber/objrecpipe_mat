function level_tree = explore_next_level_file(levels, selected_branches_upper, level_idx, level_tree)

if level_idx>length(levels)
    return
end
folder_list = unique( levels{level_idx}(selected_branches_upper) );
folder_list(strcmp(folder_list, '-1')) = [];
for f=1:length(folder_list)
    level_tree(f).name = folder_list{f};
    level_tree(f).subfolder = struct('name', {}, 'subfolder', {});
    selected_branches = selected_branches_upper & strcmp(folder_list{f}, levels{level_idx});
    level_tree(f).subfolder = explore_next_level_file(levels, selected_branches, level_idx+1, level_tree(f).subfolder);
end

end