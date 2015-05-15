function [theStruct, theTree] = parseXML_giulia_prova(xml_filename, output_filename)
% PARSEXML Convert XML file to a MATLAB structure and to a MATLAB tree.
try
   xml_input = xmlread(xml_filename);
catch
   error('Failed to read XML file %s.',xml_filename);
end

% Recurse over child nodes. This could run into problems 
% with very deeply nested trees.

theTree = tree('root');
fid = fopen(output_filename, 'w');
[theStruct, theTree] = parseChildNodes(xml_input, theTree, 0, fid);
fclose(fid);

% ----- Local function PARSECHILDNODES -----
function [children, theTree] = parseChildNodes(theParent, theTree, parentNodeId, fid)

children = [];

if theParent.hasChildNodes
    
   childNodes = theParent.getChildNodes;
   numChildNodes = childNodes.getLength;
   
   children = struct('Name', {}, 'Attributes', {}, 'Children', {});

    for count = 1:numChildNodes
        
        theChild = childNodes.item(count-1);

        if strcmp(char(theChild.getNodeName), 'synset') || strcmp(char(theChild.getNodeName), 'ImageNetStructure')
           
            children(end+1).Name = char(theChild.getNodeName);
            children(end).Attributes = parseAttributes(theChild);

            if strcmp(char(theChild.getNodeName), 'synset')
                
                if ~strcmp(char(children(end).Attributes(3).Value), 'Misc')
                    [theTree, childNodeId] = theTree.addnode(parentNodeId,children(end).Attributes(3).Value);
                    fprintf(fid, '%d\t%s\t%s\t%s\n', childNodeId, children(end).Attributes(2).Value, children(end).Attributes(3).Value, children(end).Attributes(1).Value);
                    [children(end).Children, theTree] = parseChildNodes(theChild, theTree, childNodeId, fid);
                else
                    children(end) = [];
                end
                
            else
                [children(end).Children, theTree] = parseChildNodes(theChild, theTree, parentNodeId, fid);
            end
        end
        
    end
    
end

% ----- Local function PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
% Create attributes structure.

attributes = [];
if theNode.hasAttributes
   theAttributes = theNode.getAttributes;
   numAttributes = theAttributes.getLength;
   allocCell = cell(1, numAttributes);
   attributes = struct('Name', allocCell, 'Value', ...
                       allocCell);

   for count = 1:numAttributes
      attrib = theAttributes.item(count-1);
      attributes(count).Name = char(attrib.getName);
      attributes(count).Value = char(attrib.getValue);
   end
end