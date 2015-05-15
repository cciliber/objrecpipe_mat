function partial_struct = find_category( cat_name, cat_struct, partial_struct, indices)

nChildren = length(cat_struct);

for node_idx=1:nChildren
   
    words = cat_struct(node_idx).Attributes(3).Value;
    words = strsplit(words, ' ');
    
    for w_idx=1:length(words)
        if strcmp(words{w_idx}(end),',')
            words{w_idx}(end) = [];
        end
    end
    
    is_category = sum(strcmp(words, cat_name));
    
    if is_category
        partial_struct(end+1,1).Name = cat_struct(node_idx).Name;
        partial_struct(end,1).Attributes = cat_struct(node_idx).Attributes;
        partial_struct(end,1).Children = cat_struct(node_idx).Children;
        partial_struct(end,1).Indices = [indices node_idx];
        
    else  
         partial_struct = find_category( cat_name, cat_struct(node_idx).Children, partial_struct, [indices node_idx]);    
    end
    
end

end

