function extracted_tree = create_wordnet_tree(synset_list)

wnentries = cell(length(synset_list),1);
wnsenses = zeros(length(synset_list),1);
for ii=1:length(synset_list)
    [wnentries{ii}, found] = getWordnetSense(synset_list{ii});
    wnentries{ii}(2:end) = [];
    wnsenses(ii) = length(wnentries{ii}.branch);
    wnentries{ii}.tree = cell(1, wnsenses(ii));
    
    for jj=1:wnsenses(ii)
        wnentries{ii}.tree{jj} = tree(wnentries{ii}.branch{jj}{end});
        parent = 1;
        for kk=length(wnentries{ii}.branch{jj})-1:-1:1
            [wnentries{ii}.tree{jj}, parent] = wnentries{ii}.tree{jj}.addnode(parent, wnentries{ii}.branch{jj}{kk});
        end
    end
end

extracted_tree = wnentries{1}.tree{1};

for ii=1:length(synset_list)
    for jj=1:wnsenses(ii)
        
        tmp_tree = wnentries{ii}.tree{jj};
        
        node2id = 1;
        node2name = tmp_tree.get(node2id);
        
        [extracted_tree, tmp_tree, node2name, node2id] = merge_trees(extracted_tree, tmp_tree, node2name, node2id);
        
    end
end