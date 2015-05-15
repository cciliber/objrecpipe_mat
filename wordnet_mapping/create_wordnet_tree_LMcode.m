%% MACHINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%machine = 'server';
machine = 'laptop_giulia_win';
%machine = 'laptop_giulia_lin';
    
if strcmp(machine, 'server')
    
    FEATURES_DIR = '/home/icub/GiuliaP/objrecpipe_mat';
    root_path = '/DATA/DATASETS';
    
    run('/home/icub/Dev/GURLS/gurls/utils/gurls_install.m');
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
    
elseif strcmp (machine, 'laptop_giulia_win')
    
    FEATURES_DIR = 'C:\Users\Giulia\REPOS\objrecpipe_mat';
    LABELME_DIR = 'C:\Users\Giulia\REPOS\objrecpipe_mat\LabelMeToolbox';
    TREE_DIR = 'C:\Users\Giulia\REPOS\objrecpipe_mat\tree_class_from_tiavez';
    root_path = 'D:\DATASETS';
    
elseif strcmp (machine, 'laptop_giulia_lin')
    
    FEATURES_DIR = '/home/giulia/REPOS/objrecpipe_mat';
    root_path = '/media/giulia/DATA/DATASETS';
    
    curr_dir = pwd;
    cd([getenv('VLFEAT_ROOT') '/toolbox']);
    vl_setup;
    cd(curr_dir);
    clear curr_dir;
end

addpath(genpath(FEATURES_DIR));
addpath(genpath(TREE_DIR));
addpath(genpath(LABELME_DIR));

check_input_dir(root_path);

%% DATASET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%dataset_name = 'Groceries_4Tasks';
%dataset_name = 'Groceries';
%dataset_name = 'Groceries_SingleInstance';
%dataset_name = 'iCubWorld0';
%dataset_name = 'iCubWorld20';
dataset_name = 'iCubWorld30';
%dataset_name = 'prova';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ICUBWORLDopts = ICUBWORLDinit(dataset_name);

cat_names = keys(ICUBWORLDopts.categories);
obj_names = keys(ICUBWORLDopts.objects)';
tasks = keys(ICUBWORLDopts.tasks);
modalities = keys(ICUBWORLDopts.modalities);

Ncat = ICUBWORLDopts.categories.Count;
Nobj = ICUBWORLDopts.objects.Count;
NobjPerCat = ICUBWORLDopts.objects_per_cat;

%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tree_path = fullfile(root_path, 'TREES');

%% CODE EXECUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(dataset_name, 'Groceries')
    queries = {'banana',...
               'bottle',...
               'box',...
               'bread',...
               'can',...
               'lemon',...
               'pear',...
               'pepper',...
               'potato',...
               'yogurt'};
elseif strcmp(dataset_name, 'iCubWorld30')
    queries = {'laundry detergent', ...
        'plate', ...
        'dishwashing detergent', ...
        'sponge', ...
        'cup', ...
        'soap', ...
        'sprayer'};
end               

dataset_tree = create_wordnet_tree(queries);

showTreeHTML_giulia(dataset_tree, fullfile(tree_path, [dataset_name '.html']));

if strcmp(dataset_name, 'Groceries')
    
    dataset_index = 1;
    
    dataset_tree = chop_tree(dataset_tree, 'woody');
    dataset_tree = chop_tree(dataset_tree, 'herb');
    dataset_tree = chop_tree(dataset_tree, 'bottle, feeding bottle');
    dataset_tree = chop_tree(dataset_tree, 'furnishing');
    dataset_tree = chop_tree(dataset_tree, 'structure');
    dataset_tree = chop_tree(dataset_tree, 'fixture');
    dataset_tree = chop_tree(dataset_tree, 'lemon, stinker');
    dataset_tree = chop_tree(dataset_tree, 'living');
    dataset_tree = chop_tree(dataset_tree, 'ingredient');
    dataset_tree = chop_tree(dataset_tree, 'thing');
    dataset_tree = chop_tree(dataset_tree, 'abstract entity');
    
elseif strcmp(dataset_name, 'iCubWorld30')
    
    dataset_index = 2;
    
    dataset_tree = chop_tree(dataset_tree, 'abstract ');
    dataset_tree = chop_tree(dataset_tree, 'location'); 
    dataset_tree = chop_tree(dataset_tree, 'living');  
    dataset_tree = chop_tree(dataset_tree, 'solid');  
    dataset_tree = chop_tree(dataset_tree, 'food');  
    dataset_tree = chop_tree(dataset_tree, 'causal');
    dataset_tree = chop_tree(dataset_tree, 'equipment');
    dataset_tree = chop_tree(dataset_tree, 'creation');
    dataset_tree = chop_tree(dataset_tree, 'conductor');
    dataset_tree = chop_tree(dataset_tree, 'sheet');
    dataset_tree = chop_tree(dataset_tree, 'dental');
    dataset_tree = chop_tree(dataset_tree, 'device');
    dataset_tree = chop_tree(dataset_tree, 'thing');
    dataset_tree = chop_tree(dataset_tree, 'covering');
    % dataset_tree = chop_tree(dataset_tree, 'beverage');
    dataset_tree = chop_tree(dataset_tree, 'opening');
    dataset_tree = chop_tree(dataset_tree, 'natural');
    dataset_tree = chop_tree(dataset_tree, 'receptacle');
    
else
    disp('Dataset name not recognized.');
end

showTreeHTML_giulia(dataset_tree, fullfile(tree_path, [dataset_name '.html']));

% showTree_giulia(dataset_tree);
% dataset_tree.plot;
% disp(dataset_tree.tostring);

multiple_tree{dataset_index,1} = dataset_tree;

node2id = 1;
node2name = multiple_tree{2}.get(node2id);
[multiple_tree{1}, multiple_tree{2}, ~, ~] = merge_trees(multiple_tree{1}, multiple_tree{2}, node2name, node2id);

showTreeHTML_giulia(multiple_tree{1}, fullfile(tree_path, 'both.html'));

%% Compute distance matrix

height_tree = tree(multiple_tree{1}, 0);
height_tree =  height_tree.recursivecumfun(@add_tree_level);
disp(height_tree.tostring);

iterator = height_tree.breadthfirstiterator;
nleaves = 0;
leaves_id = [];
leaves_name = [];
for it=iterator
    if height_tree.isleaf(it)
       nleaves = nleaves + 1;
       leaves_id(end+1) = it;
       leaves_name{end+1,1} = multiple_tree{1}.get(it);
    end
end

dist_mat = ones(nleaves, nleaves)*NaN;

for it1=1:length(leaves_id)
    for it2=1:length(leaves_id)
        
        parent1ids = [];
        parent2ids = [];
        parent1ids(end+1,1) = multiple_tree{1}.getparent(leaves_id(it1));
        parent2ids(end+1,1) = multiple_tree{1}.getparent(leaves_id(it2));
        
        while parent1ids(end)~=0 
            parent1ids(end+1) = multiple_tree{1}.getparent(parent1ids(end));
        end
        while parent2ids(end)~=0 
            parent2ids(end+1) = multiple_tree{1}.getparent(parent2ids(end));
        end
        
        parent12id = intersect(parent1ids, parent2ids, 'stable');
        
        if it1==it2
            dist_mat(it1,it2) = 0;
        elseif parent12id(1)~=0 
            dist_mat(it1,it2) = height_tree.get(parent12id(1));
        else
            dist_mat(it1,it2) = height_tree.get(1);
        end
            
    end
end

for ii=1:nleaves
    w = getwords(leaves_name{ii}); 
    w = w{1};
    w(1) = upper(w(1));
    labels{ii,1} = w;
end

figure
imagesc(dist_mat)
colormap gray
colorbar
set(gca, 'XTick', 1:nleaves);
set(gca, 'YTick', 1:nleaves);
set(gca, 'XTickLabel', labels, 'FontSize', 8);
set(gca, 'YTickLabel', labels, 'FontSize', 8);
rotateXLabels( gca(), 45 );
grid on
