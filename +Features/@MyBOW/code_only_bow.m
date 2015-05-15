
addpath(genpath('.'));


%%
%Create the dictionary

% for the SIFT ----------------
p.sift=struct;
p.sift.feature_size=128;
p.sift.use_lowe=false;
p.sift.dense=true;
p.sift.normalize=true;
p.sift.step=8;
p.sift.scale=16;
p.mode='human';


%BOW
p=init_bow(p);


p.sift.registry=load_registry('/home/icub/Experiments/registries/sift_registry_dict.txt');

p.sift.desc=load_descriptors(p.sift.registry);

%%

display('Creating Dictionary BOW');
p=dict_bow(p);

clear p.sift.desc;


%%
%Coding

%code the training set
p.sift.registry=load_registry('/home/icub/Experiments/registries/sift_registry_train.txt');
p.bow.codes_path='/home/icub/Experiments/codes/codes_bow_train.codes';

display('Coding Training BOW');
code_bow_dataset(p);

%%

%code the test set
p.sift.registry=load_registry('/home/icub/Experiments/registries/sift_registry_test.txt');
p.bow.codes_path='/home/icub/Experiments/codes/codes_bow_test.codes';

display('Coding Test BOW');
code_bow_dataset(p);


















