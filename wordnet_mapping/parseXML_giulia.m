function [theStruct, theTree] = parseXML_giulia(filename)
% PARSEXML Convert XML file to a MATLAB structure and to a MATLAB tree.
try
   tree = xmlread(filename);
catch
   error('Failed to read XML file %s.',filename);
end

% Recurse over child nodes. This could run into problems 
% with very deeply nested trees.
try
   [theStruct, theTree] = parseChildNodes(tree, theTree);

catch
   error('Unable to parse XML file %s.',filename);
end


% ----- Local function PARSECHILDNODES -----
function children = parseChildNodes(theNode)
% Recurse over node children.
children = [];
if theNode.hasChildNodes
   childNodes = theNode.getChildNodes;
   numChildNodes = childNodes.getLength;
   allocCell = cell(1, numChildNodes);

   %children = struct('Name', allocCell, 'Attributes', allocCell, 'Data', allocCell, 'Children', allocCell);
   children = struct('Name', {}, 'Attributes', {}, 'Children', {});

    for count = 1:numChildNodes
        theChild = childNodes.item(count-1);
        %children(count) = makeStructFromNode(theChild);
        children(end+1) = makeStructFromNode(theChild);
        if ~(strcmp(children(end).Name, 'synset') || strcmp(children(end).Name, 'ImageNetStructure'))
            children(end) = [];
        end
        
    end
end

% ----- Local function MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.

%nodeStruct = struct('Name', char(theNode.getNodeName), 'Attributes', parseAttributes(theNode), 'Data', '', 'Children', parseChildNodes(theNode));
nodeStruct = struct('Name', char(theNode.getNodeName), 'Attributes', parseAttributes(theNode), 'Children', parseChildNodes(theNode));

% if any(strcmp(methods(theNode), 'getData'))
%    nodeStruct.Data = char(theNode.getData); 
% else
%    nodeStruct.Data = '';
% end

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