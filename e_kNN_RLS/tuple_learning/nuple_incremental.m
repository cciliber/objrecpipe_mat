
%%
maxT = 28;
minT = 1;

T = maxT-minT+1;

verbose = 0;

if ~exist('loaded','var')
    loaded = false;
end

save_path = ['DATA_incremental_' strrep(char(datetime(clock)),' ','_')];


data_folder = '~/../cciliberto/data';

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


min_n = Inf;
for t=minT:maxT
    Xtr_c{t-minT+1} = [];
    Ytr_c{t-minT+1} = [];
    Xts_c{t-minT+1} = [];
    Yts_c{t-minT+1} = [];

    for idx_day=1:numel(data_day)     
       Xtr_c{t-minT+1} = [Xtr_c{t-minT+1}; Xtr{idx_day}(Ytr{idx_day}==t,:)];
       Ytr_c{t-minT+1} = [Ytr_c{t-minT+1}; Ytr{idx_day}(Ytr{idx_day}==t,:)];
       Xts_c{t-minT+1} = [Xts_c{t-minT+1}; Xts{idx_day}(Yts{idx_day}==t,:)];
       Yts_c{t-minT+1} = [Yts_c{t-minT+1}; Yts{idx_day}(Yts{idx_day}==t,:)];   
    end
    
    if min_n > numel(Ytr_c{t-minT+1})
        min_n = numel(Ytr_c{t-minT+1});
    end
end




nuple_size = 10;

nuples = 1:nuple_size:min_n;
nuples = nuples-1;
nuples(1)=[];

if nuples(end)~=min_n
   nuples = [nuples min_n]; 
end

acc_nuples = zeros(size(nuples));
acc_nuples_weighted = zeros(size(nuples));

day_acc = cell(size(nuples));

model = cell(size(nuples));

for idx_n = 1:numel(nuples)
    
    X = cellfun(@(X)X(1:nuples(idx_n),:),Xtr_c,'UniformOutput',0);
    Y = cellfun(@(Y)Y(1:nuples(idx_n),:),Ytr_c,'UniformOutput',0);
    
    X = cell2mat(X);
    Y = cell2mat(Y);
    
    
    model{idx_n} = gurls_train(X,Y,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',verbose);
    
    % test on present
    day_acc{idx_n} = zeros(size(data_day));
    for idx_day=1:numel(data_day)
        day_acc{idx_n}(idx_day) = trace_confusion(Yts{idx_day},gurls_test(model{idx_n},Xts{idx_day}));
    end
    acc_nuples_weighted(idx_n) = mean(day_acc{idx_n});
    acc_nuples(idx_n)=trace_confusion(cell2mat(Yts),gurls_test(model{idx_n},cell2mat(Xts)));    

    [acc_nuples_weighted(idx_n) acc_nuples(idx_n)]    
   
    save('acc_nuples','acc_nuples');
    save('acc_nuples_weighted','acc_nuples_weighted');
end













