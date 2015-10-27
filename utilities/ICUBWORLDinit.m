function ICUBWORLDopts = ICUBWORLDinit(dataset_info)

clear ICUBWORLDopts

[filepath, dataset_name, fileext] = fileparts(dataset_info);

if strcmp(dataset_name,'iCubWorld0')
    
    categories = { ...
        };
    
    objects = {...
        'bottle'
        'box'
        'octopus'
        'phone'
        'pouch'
        'spray'
        'turtle'
        };

    tasks = { ...
        ''
        };
    
    modalities = { ...
        'human'
        'robot'
        };

    objects_per_cat = 1;
    
elseif strcmp(dataset_name,'Groceries')
   
    categories = { ...
        'bananas'
        'bottles'
        'boxes'
        'bread'
        'cans'
        'lemons'
        'pears'
        'peppers'
        'potatos'
        'yogurt'
        };
    
    objects = { 
        'banana_1'
        'banana_2'
        'banana_3'
        'banana_4'
        'bottle_blue'
        'coke'
        'santal'
        'water'
        'box_blue'
        'box_brown'
        'box_green'
        'kinder'
        'big_bread'
        'broken_big_bread'
        'broken_small_bread'
        'small_bread'
        'mais'
        'olives'
        'tuna'
        'chickpeas'
        'lemon_1'
        'lemon_2'
        'lemon_3'
        'lemon_4'
        'pear_1'
        'pear_2'
        'pear_3'
        'pear_4'
        'pepper_green'
        'pepper_orange'
        'pepper_red'
        'pepper_yellow'
        'potato_1'
        'potato_2'
        'potato_3'
        'potato_4'
        'activia'
        'fruity'
        'muller'
        'yomo'
        };
    
    tasks = { ...
        ''
        };
    
    modalities = { ...
       'demo1'
       'demo2'
        };

    objects_per_cat = 4;
    
elseif strcmp(dataset_name,'Groceries_4Tasks')
   
    categories = { ...
        'bananas'
        'bottles'
        'boxes'
        'bread'
        'cans'
        'lemons'
        'pears'
        'peppers'
        'potatos'
        'yogurt'
        };
    
    objects = { 
        'banana_1'
        'banana_2'
        'banana_3'
        'bottle_blue'
        'coke'
        'santal'
        'box_blue'
        'box_brown'
        'kinder'
        'big_bread'
        'broken_big_bread'
        'broken_small_bread'
        'mais'
        'olives'
        'tuna'
        'lemon_1'
        'lemon_2'
        'lemon_3'
        'pear_1'
        'pear_2'
        'pear_3'
        'pepper_green'
        'pepper_orange'
        'pepper_red'
        'potato_1'
        'potato_2'
        'potato_3'
        'activia'
        'fruity'
        'muller'
        };
    
    tasks = { ...
        'background'
        'categorization'
        'demonstrator'
        'robot'
        };
    
    modalities = { ...
        ''
        };
    
    objects_per_cat = 3;

elseif strcmp(dataset_name,'Groceries_SingleInstance')
    
    categories = { ...
        ''
        };
    
    objects = {...
        'banana'
        'big_bread'
        'box_blue'
        'box_brown'
        'chickpeas'
        'coke'
        'fruity'
        'kinder'
        'lemon'
        'muller'
        'olives'
        'pear'
        'pepper_red'
        'potato'
        'santal'
        };
        
    tasks = { ...
        ''
        };
    
    modalities = { ...
        ''
        };
    
    objects_per_cat = 1;
    
    LUT_cat_obj = [];
     
elseif strcmp(dataset_name,'iCubWorld20')
    
    categories = {...
        '1_laundrydetergent'
        '2_washingupliquid'
        '3_sprinkler'
        '4_mug'
        '5_soap'
        '6_sponge'
        '7_dish'
        };
    
    objects_per_cat = 4;
    
    objects = repmat(categories, objects_per_cat, 1);
    objects = objects(:);
    objects = strcat(objects, '_', cellstr(num2str(repmat((1:objects_per_cat)', length(categories), 1))));

    tasks = { ...
        ''
        };

    modalities = { ...
        'carlo_household_right'
        };
    
elseif strcmp(dataset_name,'iCubWorld28')
    
    categories = {...
        'plate'
        'laundry-detergent'
        'cup'
        'soap'
        'sponge'
        'sprayer'
        'dishwashing-detergent'
        };

    objects_per_cat = 4;
    
    objects = repmat(categories, objects_per_cat, 1);
    objects = objects(:);
    objects = strcat(objects, cellstr(num2str(repmat((1:objects_per_cat)', length(categories), 1))));

    LUT_cat_obj = [(1:length(objects))'  repmat((1:length(categories))', objects_per_cat, 1)];
    
    tasks = { ...
        ''
        };   
    
    modalities = { ...
        'day1'
        'day2'
        'day3'
        'day4'
        };
    
    elseif strcmp(dataset_name,'iCubWorld30')
    
    categories = {...
        'dish'
        'laundrydetergent'
        'mug'
        'soap'
        'sponge'
        'sprinkler'
        'washingup'
        };

    objects_per_cat = 4;
    
    objects = repmat(categories, objects_per_cat, 1);
    objects = objects(:);
    objects = strcat(objects, cellstr(num2str(repmat((1:objects_per_cat)', length(categories), 1))));

    LUT_cat_obj = [(1:length(objects))'  repmat((1:length(categories))', objects_per_cat, 1)];
    
    tasks = { ...
        ''
        };   
    
    modalities = { ...
        'lunedi22'
        'martedi23'
        'mercoledi24'
        'venerdi26'
        };
    
elseif strcmp(dataset_name,'iCubWorldUltimate')
    
    fid = fopen(dataset_info);
    infos = textscan(fid, '%s %s %q %s %s', 'TreatAsEmpty', 'skip', 'EmptyValue', -1);
    fclose(fid);
    
    categories = infos{1};
    wordnet_queries = infos{2};
    wordnet_descriptions = infos{3};
    imagenet_categories = infos{4};
    imagenet_wnids = infos{5};

    objects_per_cat = 10;
    
    objects = repmat(categories', objects_per_cat, 1);
    objects = objects(:);
    tmp = cellstr(num2str(repmat((1:objects_per_cat)', length(categories), 1)));
    
    tmp(cellfun(@isempty,strfind(tmp, ' '))) = strcat('_', tmp(cellfun(@isempty,strfind(tmp, ' '))));
    tmp = strrep(tmp,' ', '_');
    
    objects = strcat(objects, tmp);   
    
    LUT_cat_obj = repmat(1:length(categories), objects_per_cat, 1);
    LUT_cat_obj = [ (1:length(objects))' LUT_cat_obj(:) ];
    
    tasks = { ...
        ''
        };   
    
    modalities = { ...
        'SCALE'
        'ROT2D'
        'ROT3D'
        'TRANSL'
        'MIX'
        };
else
    disp('Name does not match any existing dataset, setting dataset parameters to void.');
    
    categories = { ...
        ''
        };
    
    objects_per_cat = [];
    
    objects = { ...
        ''
        };
    
    LUT_cat_obj = [];
    
    tasks = { ...
        ''
        };   
    
    modalities = { ...
        ''
        };   
end

ICUBWORLDopts.categories = containers.Map (categories, 1:length(categories)); 
ICUBWORLDopts.wordnet_queries = containers.Map (categories, wordnet_queries); 
ICUBWORLDopts.wordnet_descriptions = containers.Map (wordnet_queries, wordnet_descriptions); 
ICUBWORLDopts.imagenet_wnids = containers.Map (wordnet_descriptions, imagenet_wnids); 
ICUBWORLDopts.imagenet_categories = containers.Map (imagenet_wnids, imagenet_categories); 


ICUBWORLDopts.objects = containers.Map (objects, 1:length(objects));  
ICUBWORLDopts.tasks = containers.Map (tasks, 1:length(tasks)); 
ICUBWORLDopts.modalities = containers.Map (modalities, 1:length(modalities));  
ICUBWORLDopts.objects_per_cat = objects_per_cat;
ICUBWORLDopts.LUT_cat_obj = LUT_cat_obj;