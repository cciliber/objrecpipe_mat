function ICUBWORLDopts = ICUBWORLDinit(dataset_info)
    
fid = fopen(dataset_info);
infos = textscan(fid, '%s %s %q %s %s %d');
fclose(fid);

categories = infos{1};
wordnet_queries = infos{2};
wordnet_descriptions = infos{3};
imagenet_categories = infos{4};
imagenet_wnids = infos{5};
imagenet_labels = infos{6};

objects_per_cat = 10;

objects = repmat(categories', objects_per_cat, 1);
objects = objects(:);
tmp = cellstr(num2str(repmat((1:objects_per_cat)', length(categories), 1)));

%tmp(cellfun(@isempty,strfind(tmp, ' '))) = strcat('_', tmp(cellfun(@isempty,strfind(tmp, ' '))));
tmp = strrep(tmp,' ', '');

objects = strcat(objects, tmp);

LUT_cat_obj = repmat(1:length(categories), objects_per_cat, 1);
LUT_cat_obj = [ (1:length(objects))' LUT_cat_obj(:) ];

days = { ...
    'day1'
    'day2'
    'day3'
    'day4'
    'day5'
    'day6'
    'day7'
    'day8'
    };

cameras = { ...
    'left'
    'right'
    };

transfs = { ...
    'SCALE'
    'ROT2D'
    'ROT3D'
    'TRANSL'
    'MIX'
    };

ICUBWORLDopts.Cat_WnQueries = containers.Map (categories, wordnet_queries);
ICUBWORLDopts.WnQueries_WnDescr = containers.Map (wordnet_queries, wordnet_descriptions);
ICUBWORLDopts.WnDescr_ImnetWNIDs = containers.Map (wordnet_descriptions, imagenet_wnids);
ICUBWORLDopts.ImnetWNIDs_ImnetCat = containers.Map (imagenet_wnids(~cellfun(@isempty, imagenet_wnids)), imagenet_categories(~cellfun(@isempty, imagenet_categories)));
ICUBWORLDopts.Cat_ImnetWNIDs = containers.Map (categories, imagenet_wnids);
ICUBWORLDopts.Cat_ImnetLabels = containers.Map (categories, imagenet_labels);

ICUBWORLDopts.Days = containers.Map (days, repmat([1; 2], length(days)/2,1));
ICUBWORLDopts.Cameras = containers.Map (cameras, 1:length(cameras));
ICUBWORLDopts.Transfs = containers.Map (transfs, 1:length(transfs));

ICUBWORLDopts.Cat = containers.Map (categories, 1:length(categories));
ICUBWORLDopts.Obj = containers.Map (objects, 1:length(objects));
ICUBWORLDopts.ObjPerCat = objects_per_cat;
ICUBWORLDopts.LUT_CatObj = LUT_cat_obj;

ICUBWORLDopts.cat_names = keys(ICUBWORLDopts.Cat)';
ICUBWORLDopts.obj_names = keys(ICUBWORLDopts.Obj)';
ICUBWORLDopts.transf_names = keys(ICUBWORLDopts.Transfs)';
ICUBWORLDopts.day_names = keys(ICUBWORLDopts.Days)';
ICUBWORLDopts.camera_names = keys(ICUBWORLDopts.Cameras)';
ICUBWORLDopts.Ncat = ICUBWORLDopts.Cat.Count;
ICUBWORLDopts.Nobj = ICUBWORLDopts.Obj.Count;
ICUBWORLDopts.NobjPerCat = ICUBWORLDopts.ObjPerCat;
ICUBWORLDopts.Ntransfs = ICUBWORLDopts.Transfs.Count;
ICUBWORLDopts.Ndays = ICUBWORLDopts.Days.Count;
ICUBWORLDopts.Ncameras = ICUBWORLDopts.Cameras.Count;