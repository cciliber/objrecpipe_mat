function [tree1, tree2, node2name, node2id] = merge_trees(tree1, tree2, node2name, node2id)

% scendi livello e ricorsione
node1id = find(strcmp(tree1, node2name)); %node1id = children1id(node2present~=0);

if ~isempty(node2id) && ~isempty(node1id)
    
    children1id = tree1.getchildren(node1id);
    children1name = cell(1,length(children1id));
    for cc1=1:length(children1id)
        children1name{cc1} =  tree1.get(children1id(cc1));
    end
            
    children2id = tree2.getchildren(node2id);
    for cc2=1:length(children2id)
        
        node2id = children2id(cc2);
        
        if ~isempty(node2id)
        
            node2name = tree2.get(node2id);
            node2present = strcmp(children1name, node2name);
        
            if sum(node2present)
                % scendi di un livello e ricorsione
                [tree1, tree2, node2name, node2id] = merge_trees(tree1, tree2, node2name, node2id);
            else
                % appendi il sotto albero
                tree1 = tree1.graft(node1id,tree2.subtree(node2id));
            end
        
        end
        
    end
end