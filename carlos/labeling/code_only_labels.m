

%%

addpath(genpath('.'));

train_reg=load_registry('/home/icub/Experiments/registries/registry_train.txt');
test_reg=load_registry('/home/icub/Experiments/registries/registry_test.txt');

%%
display('Creating Class Labels Codes');


train_out_codes_path='/home/icub/Experiments/codes/codes_out_train.codes';
test_out_codes_path='/home/icub/Experiments/codes/codes_out_test.codes';


p=struct;
%output codes for training
p.registry=train_reg;
codes=create_output_codes(p);
save(train_out_codes_path,'codes','-v7.3');

%output codes for test
p.registry=test_reg;
create_output_codes(p);
save(test_out_codes_path,'codes','-v7.3');
display('Done\n');


%%

display('Creating Category Labels Codes');


train_cat_out_codes_path='/home/icub/Experiments/codes/codes_cat_train.codes';
test_cat_out_codes_path='/home/icub/Experiments/codes/codes_cat_test.codes';


p=struct;
%output codes for training
p.registry=train_reg;
codes=create_cat_output_codes(p);
save(train_cat_out_codes_path,'codes','-v7.3');

%output codes for test
p.registry=test_reg;
create_cat_output_codes(p);
save(test_cat_out_codes_path,'codes','-v7.3');
display('Done\n');
