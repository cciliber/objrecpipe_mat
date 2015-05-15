function substruct = get_substruct(root_node, indices)

substruct = root_node;

nbranches = lenght(indices);

for branch_idx=1:nbranches
    
    
    
    
    
    
    nlevels = length(indices{branch_idx});
    for level_idx=1:nlevels
        substruct = substruct(indices(branch_idx)).Children;
    end
    
    
end