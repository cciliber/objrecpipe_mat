function tree = chop_tree(tree, node_string)

node_id = find( strncmpi(tree, node_string, length(node_string)) );

if length(node_id)>1
    disp('Multiple node ids found.');
elseif isempty(node_id)
    disp('Node id not found.');
else
tree = tree.chop(node_id);
end