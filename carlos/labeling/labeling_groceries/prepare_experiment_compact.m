

%%

clear all
addpath(genpath('/home/icub/Dev'));


p=struct;
p.root_path='/home/icub/Experiments/';

p.features={'sc'};


codes_params=load_codes(p);

 
p.exp_root_path='/home/icub/Experiments/Experiments';


%%
known_categories={
    'box_brown' 'box_blue' 'kinder'
    'banana_1' 'banana_2' 'banana_3'
    'potato_1' 'potato_2' 'potato_3'
    'lemon_1' 'lemon_2' 'lemon_3'
    'pear_1' 'pear_2' 'pear_3'
    'pepper_green'  'pepper_orange'  'pepper_red'
    'activia'  'fruity' 'muller'
    'mais'  'olives'  'tuna'
    'big_bread'  'broken_big_bread'  'broken_small_bread'  
    'bottle_blue'  'coke'  'santal'
};

novel_categories={
    'box_green'
    'banana_4'
    'potato_4'
    'lemon_4'
    'pear_4'
    'pepper_yellow'
    'yomo'
    'chickpeas'
    'small_bread'
    'water'
};






%% prepare the experiments
experiments={};

%Experiment 1 - Easy: Known Instance -> Same Demo
exp=struct;
exp.name='Easy';

%train
exp.type='train';
exp.n_samples=[200];
exp.sample='subseq';
exp.demo='demo2';
exp.class_list=known_categories;
exp.out='cat';

experiments{end+1}=exp;


exp=struct;
exp.name='Easy';

%test
exp.type='test';
exp.n_samples=[200];
exp.sample='subseq';
exp.demo='demo2';
exp.class_list=known_categories;
exp.out='cat';


experiments{end+1}=exp;

%%

%Experiment 2 - Known Instance -> Different Demo
exp=struct;
exp.name='Demo';

%train
exp.type='train';
exp.n_samples=[200];
exp.sample='subseq';
exp.demo='demo2';
exp.class_list=known_categories;
exp.out='cat';

experiments{end+1}=exp;


exp=struct;
exp.name='Demo';

%test
exp.type='test';
exp.n_samples=[200];
exp.sample='subseq';
exp.demo='demo1';
exp.class_list=known_categories;
exp.out='cat';


experiments{end+1}=exp;


%%

%Experiment 3 - Unknown Instance -> Same Demo
exp=struct;
exp.name='Generalization';

%train
exp.type='train';
exp.n_samples=[200];
exp.sample='subseq';
exp.demo='demo2';
exp.class_list=known_categories;
exp.out='cat';

experiments{end+1}=exp;


exp=struct;
exp.name='Generalization';

%test
exp.type='test';
exp.n_samples=[200];
exp.sample='subseq';
exp.demo='demo2';
exp.class_list=novel_categories;
exp.out='cat';


experiments{end+1}=exp;



%% prepare temp experiments
% experiments={};
% 
% %Experiment 1 - Easy: Known Instance -> Same Demo
% exp=struct;
% exp.name='Benchmark';
% 
% %train
% exp.type='train';
% exp.n_samples=[200];
% exp.sample='subseq';
% exp.demo='demo2';
% %exp.categories=known_categories;
% 
% experiments{end+1}=exp;
% 
% exp=struct;
% exp.name='Benchmark';
% 
% %test
% exp.type='test';
% exp.n_samples=[200];
% exp.sample='subseq';
% exp.demo='demo2';
% %exp.categories=known_categories;
% 
% 
% experiments{end+1}=exp;



%%

for i=1:length(experiments)
    display(['Experiment: ' experiments{i}.name ' - ' experiments{i}.type]);
    prepare_experiment(p,experiments{i},codes_params);
    display('done');
end

















