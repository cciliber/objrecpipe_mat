

%%
maxT = 28;
minT = 1;

T = maxT-minT+1;


if ~exist('loaded','var')
    loaded = false;
end

save_path = ['DATA_' strrep(char(datetime(clock)),' ','_')];


data_folder = '~/Desktop/playground/data';
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

% for each day
Xtr_c = cell(numel(data_day),1);
Xts_c = cell(numel(data_day),1);
Ytr_c = cell(numel(data_day),1);
Yts_c = cell(numel(data_day),1);


min_n = Inf;
for idx_day=1:numel(data_day)     

    T = maxT-minT+1;

    Xtr_c{idx_day} = cell(T,1);
    Xts_c{idx_day} = cell(T,1);
    Ytr_c{idx_day} = cell(T,1);
    Yts_c{idx_day} = cell(T,1);

    for t=minT:maxT
       Xtr_c{idx_day}{t-minT+1} = Xtr{idx_day}(Ytr{idx_day}==t,:);
       Xts_c{idx_day}{t-minT+1} = Xts{idx_day}(Yts{idx_day}==t,:);
       Ytr_c{idx_day}{t-minT+1} = Ytr{idx_day}(Ytr{idx_day}==t,:);
       Yts_c{idx_day}{t-minT+1} = Yts{idx_day}(Yts{idx_day}==t,:);
    
        tmp_min_n = size(Xtr_c{idx_day}{t-minT+1},1);
        if tmp_min_n<min_n
            min_n = tmp_min_n;
        end
    end
end



%min_n = 106;
min_n_per_class = ceil(min_n/numel(data_day));

%

model_day = cell(numel(data_day),1);
error_day = zeros(numel(data_day)+1,numel(data_day)+1);

for idx_day_train=1:numel(data_day)  

    Xsel = [];
    Ysel = [];
    for t=minT:maxT
        Xsel = [Xsel;Xtr_c{idx_day_train}{t-minT+1}(1:min_n,:)];
        Ysel = [Ysel;Ytr_c{idx_day_train}{t-minT+1}(1:min_n,:)];
    end

    model_day{idx_day_train} = gurls_train(Xsel,Ysel,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',1);
    
    for idx_day_test=1:numel(data_day)
        error_day(idx_day_train,idx_day_test)=trace_confusion(Yts{idx_day_test},gurls_test(model_day{idx_day_train},Xts{idx_day_test}));
    end
    
    error_day(idx_day_train,end)=trace_confusion(cell2mat(Yts),gurls_test(model_day{idx_day_train},cell2mat(Xts)));
end



Xall = [];
Yall = [];
for idx_day=1:numel(data_day)     
    
    for t=minT:maxT
        Xall = [Xall;Xtr_c{idx_day}{t-minT+1}(1:4:min_n_per_class,:)];
        Yall = [Yall;Ytr_c{idx_day}{t-minT+1}(1:4:min_n_per_class,:)];
    end
end


model_all = gurls_train(Xall,Yall,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.9,'partuning','ho','verbose',1);

for idx_day_test=1:numel(data_day)
    error_day(end,idx_day_test)=trace_confusion(Yts{idx_day_test},gurls_test(model_all,Xts{idx_day_test}));
end

error_day(end,end)=trace_confusion(cell2mat(Yts),gurls_test(model_day{idx_day_train},cell2mat(Xts)));


error_day(:,end+1) = mean(error_day(:,1:4),2);


display(error_day)




