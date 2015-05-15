[imNetStruct_noMisc, imnetTree_noMisc] = parseXML_giulia_prova('D:\imagenet-wordnet\structure_released.xml', 'nodeid_wnid_words_gloss_noMisc.txt');

fid = fopen('nodeid_wnid_words_gloss_noMisc.txt', 'r');
inputData_noMisc = textscan(fid,'%d\t%s\t%s\t%s', 'Delimiter', '\t');
fclose(fid);
imnetMap_noMisc = containers.Map(inputData_noMisc{1}, inputData_noMisc{3});


% load('D:\imagenet-wordnet\structure_released.mat');
% 
% rootNode = imnetStruct.Children.Children;
% 
% category = 'potato';
% 
% potato = struct('Name', {}, 'Attributes', {}, 'Children', {}, 'Indices', {});
% potato = find_category(category, rootNode, potato, 0, []);
% 
%  category = 'sprinkler';
%  
%  sprinkler = struct('Name', {}, 'Attributes', {}, 'Children', {}, 'Indices', {});
%  sprinkler = find_category(category, rootNode, sprinkler, []);
%  
%  selected_indices = {[1 27 11 1]; [1 27 11 2 1]};
%  prova = get_substruct(rootNode, selected_indices);







% regexpTree = imnetTree_noMisc.strfind('sprinkler');
% regexpTree.issync(imnetTree_noMisc);
%  
specificTree = tree(imnetTree_noMisc);
%  
% iterator = regexpTree.breadthfirstiterator;

for i=iterator(end):-1:iterator(1)
    
    if i==30831
        disp('ciao');
    end
    % remove the node if:
    % - the node is empty
    toRemove = isempty(regexpTree.get(i));
    % - all its parents are empty
    pId=1;
    parentId(pId) = regexpTree.getparent(i);
    while parentId(pId)
        toRemove = toRemove & isempty(regexpTree.get(parentId(pId)));
        parentId(pId+1) = regexpTree.getparent(parentId(pId));
        pId = pId+1;
    end
    parentId(pId) = [];
    
    % - the node is a leaf
    nodeId = find( strcmp(specificTree, imnetMap_noMisc(i)) );
    
    pId=1;
    parentList = nodeId;
    parentListName = [];
    while length(nodeId)>1 && sum(parentList)
        
        for ii=1:length(parentList)
            parentList(ii) = specificTree.getparent(parentList(ii));
            if ~parentList(ii)
                parentListName{ii,1} = specificTree.get(parentList(ii));
            end
        end
        
        if sum(parentList)
            nodeId = nodeId(strcmp(imnetMap_noMisc(parentId(pId)), parentListName)');
            pId = pId+1;
        end
    end
    
    for ii=1:length(nodeId)
        
        if toRemove && specificTree.isleaf(nodeId(ii))
            specificTree = specificTree.removenode(nodeId(ii));
        else
            disp(specificTree.get(nodeId(ii)));
        end
        
    end

end

