
%%
maxT = 28;
minT = 1;

T = maxT-minT+1;

verbose = 0;

if ~exist('loaded','var')
    loaded = false;
end

save_path = ['DATA_incremental_nuple_' strrep(char(datetime(clock)),' ','_')];


%data_folder = '~/../cciliberto/data';
data_folder = '/data/DATASETS/iCubWorld30_experiments/Xy_IROS15_caffe_meanimnet_ccrop';


data_day = {'lun','mar','mer','ven'};

if ~loaded

    Xtr = cell(numel(data_day),1);
    Ytr = cell(numel(data_day),1);
    Xts = cell(numel(data_day),1);
    Yts = cell(numel(data_day),1);


    for idx_day = 1:numel(data_day)
        
        Xtr{idx_day} = load(fullfile(data_folder,['Xtr_',data_day{idx_day},'.mat']));
        Xtr{idx_day} = Xtr{idx_day}.feat';
        Ytr{idx_day} = load(fullfile(data_folder,['Ytr_',data_day{idx_day},'.mat']));
        Ytr{idx_day} = Ytr{idx_day}.y;

        idx = (minT<=Ytr{idx_day}) & (Ytr{idx_day}<=maxT);
        Ytr{idx_day} = Ytr{idx_day}(idx);
        Xtr{idx_day} = Xtr{idx_day}(idx,:);

        Xts{idx_day} = load(fullfile(data_folder,['Xte_',data_day{idx_day},'.mat']));
        Xts{idx_day} = Xts{idx_day}.feat';
        Yts{idx_day} = load(fullfile(data_folder,['Yte_',data_day{idx_day},'.mat']));
        Yts{idx_day} = Yts{idx_day}.y;


        idx = (minT<=Yts{idx_day}) & (Yts{idx_day}<=maxT);
        Yts{idx_day} = Yts{idx_day}(idx);
        Xts{idx_day} = Xts{idx_day}(idx,:);

    end
    
    loaded = true;
end


%%

Xtr_c = cell(T,1);
Xts_c = cell(T,1);
Ytr_c = cell(T,1);
Yts_c = cell(T,1);


Xtr_ct = cell(3,1);
Ytr_ct = cell(3,1);

for idx_day=2:numel(data_day)    
    Xtr_ct{idx_day-1}=cell(T,1); 
    Ytr_ct{idx_day-1}=cell(T,1); 
end


max_n_per_class = Inf;
for idx_day=2:numel(data_day)   
    for t=minT:maxT
        if max_n_per_class > sum(Ytr{idx_day}==t)
            max_n_per_class = sum(Ytr{idx_day}==t)
        end
    end
end



max_n_per_class = 170;


min_n = Inf;
for t=minT:maxT
    Xtr_c{t-minT+1} = [];
    Ytr_c{t-minT+1} = [];
    Xts_c{t-minT+1} = [];
    Yts_c{t-minT+1} = [];

    for idx_day=2:numel(data_day)   
        
        tmp_X = Xtr{idx_day}(Ytr{idx_day}==t,:);
        %Xtr_ct{idx_day-1}{t-minT+1} = Xtr{idx_day}(Ytr{idx_day}==t,:);
        Xtr_ct{idx_day-1}{t-minT+1} = tmp_X(1:max_n_per_class,:);
        
        tmp_Y = Ytr{idx_day}(Ytr{idx_day}==t);
        Ytr_ct{idx_day-1}{t-minT+1}=tmp_Y(1:max_n_per_class);   
        %Ytr_ct{idx_day-1}{t-minT+1}=Ytr{idx_day}(Ytr{idx_day}==t,:);   
        %Xtr_c{t-minT+1} = [Xtr_c{t-minT+1}; Xtr{idx_day}(Ytr{idx_day}==t,1:max_n_per_class)];
        Xtr_c{t-minT+1} = [Xtr_c{t-minT+1}; tmp_X(1:max_n_per_class,:)];
        
        %Ytr_c{t-minT+1} = [Ytr_c{t-minT+1}; Ytr{idx_day}(Ytr{idx_day}==t,1:max_n_per_class)];  
        Ytr_c{t-minT+1} = [Ytr_c{t-minT+1}; tmp_Y(1:max_n_per_class)];  
    

        %quick hack
        Xts_c{t-minT+1} = [Xts_c{t-minT+1};  Xts{idx_day}(Yts{idx_day}==t,:)];
        Yts_c{t-minT+1} = [Yts_c{t-minT+1};  Yts{idx_day}(Yts{idx_day}==t,:)];
        
    end    
% 
%     Xts_c{t-minT+1} = Xts{1}(Yts{1}==t,:);
%     Yts_c{t-minT+1} = Yts{1}(Yts{1}==t,:);
    

    
    if min_n > numel(Ytr_c{t-minT+1})
        min_n = numel(Ytr_c{t-minT+1});
    end
end




%%

min_n = 3*max_n_per_class;
min_n = min_n+1;
                                                                                                                        
nuple_size = 10;

nuples = 1:nuple_size:min_n;
nuples = nuples-1;
nuples(1)=[];

nuples_total = nuples;

acc_nuples = zeros(size(nuples));

day_acc = cell(size(nuples));

model = cell(size(nuples));

fig = figure;
for idx_n = 1:numel(nuples)
    
    idx_n
    
    X = cellfun(@(X)X(1:nuples(idx_n),:),Xtr_c,'UniformOutput',0);
    Y = cellfun(@(Y)Y(1:nuples(idx_n),:),Ytr_c,'UniformOutput',0);
    
    X = cell2mat(X);
    Y = cell2mat(Y);
    
    
    model{idx_n} = gurls_train(X,Y,'kernelfun','linear','nlambda',20,'nholdouts',1,'hoproportion',0.1,'partuning','ho','verbose',verbose);
    
    % test on present
    acc_nuples(idx_n)=trace_confusion(cell2mat(Yts_c),gurls_test(model{idx_n},cell2mat(Xts_c)));     
   
    save('acc_nuples','acc_nuples');
    
    
    figure(fig);
    plot(nuples(1:idx_n),acc_nuples(1:idx_n));
    pause(0.1);
end

hold on;


%%
min_n_tc = ceil(min_n/3)+1;
nuples = 1:nuple_size:min_n_tc;
nuples = nuples-1;
nuples(1)=[];

model_tc = cell(3,1);
acc_nuples_tc = zeros(3,numel(nuples));

for idx_t = 2:4
    
    model_tc{idx_t-1} = cell(size(nuples));
    
    
    figure(fig);
    cla;
    hold on;
    plot(nuples_total,acc_nuples);
    
    for idx_n = 1:numel(nuples)
    
        [idx_t-1 idx_n]
    
        
        X = cellfun(@(X)X(1:nuples(idx_n),:),Xtr_ct{idx_t-1},'UniformOutput',0);
        Y = cellfun(@(Y)Y(1:nuples(idx_n),:),Ytr_ct{idx_t-1},'UniformOutput',0);

        X = cell2mat(X);
        Y = cell2mat(Y);


        model_tc{idx_t-1}{idx_n} = gurls_train(X,Y,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.8,'partuning','loo','verbose',verbose);

        % test on present
        acc_nuples_tc(idx_t,idx_n)=trace_confusion(cell2mat(Yts),gurls_test(model_tc{idx_t-1}{idx_n},cell2mat(Xts)));    
   

        save('acc_nuples_tc','acc_nuples_tc');

        for idx_tt = 2:idx_t-1
            plot(nuples+(idx_tt-1)*min_n_tc,acc_nuples_tc(idx_tt,:));
        end

        plot(nuples(1:idx_n)+(idx_t-1)*min_n_tc,acc_nuples_tc(idx_t,1:idx_n));
        pause(0.1);
    end
end




%%


for idx_t = 1:3
   plot(nuples+(idx_t-1)*min_n_tc,acc_nuples_tc(idx_t,:));
end










