function codes_params = load_codes(p)
%   Detailed explanation goes here


    codes_params=struct;
    codes_params.train=struct;
    codes_params.test=struct;
    
    %registries path data
    display('Loading Registries');
    codes_params.train.registry=load_registry(fullfile(p.root_path,'registries/registry_train.txt'));
    codes_params.test.registry=load_registry(fullfile(p.root_path,'registries/registry_test.txt'));
    display('Done\n');

    %if the output codes have been forgotten
    if sum(strcmp(p.features,'out'))==0
       p.features{end+1}='out'; 
    end
    
    
    %if the output codes have been forgotten
    if sum(strcmp(p.features,'cat'))==0
       p.features{end+1}='cat'; 
    end
    
    
    for i=1:length(p.features)

        display(['Loading ' p.features{i}]);
        train_codes_path = fullfile(p.root_path,['/codes/codes_' p.features{i} '_train.codes']);
        test_codes_path = fullfile(p.root_path,['/codes/codes_' p.features{i} '_test.codes']);

        tmp=struct;

        train_codes=load(train_codes_path,'-mat');
        tmp.train.codes=train_codes.codes;

        test_codes=load(test_codes_path,'-mat');
        tmp.test.codes=test_codes.codes;

        codes_params=setfield(codes_params,p.features{i},tmp);
    end


end

