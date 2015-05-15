
%%
minT = 1;
maxT = 28;

T = maxT-minT+1;



if ~exist('loaded','var')
    loaded = false;
end


data_folder = '~/../ccilberto/data';



save_path = 'DATA_VEN.mat';

data_day = 'ven';


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
    
    Xtr = cell2mat(Xtr);
    Ytr = cell2mat(Ytr);
    Xts = cell2mat(Xts);
    Yts = cell2mat(Yts);
    
    loaded = true;
end


T = maxT-minT+1;

Xtr_c = cell(T,1);
Xts_c = cell(T,1);

for t=minT:maxT
   Xtr_c{t-minT+1} = Xtr(Ytr==t,:);
   Xts_c{t-minT+1} = Xts(Yts==t,:);
end

n_vals = [10 50 100 1000];
DATA = cell(numel(n_vals),1);

tuple_step = 2;
tuples = 1:tuple_step:nchoosek(T,2);
if tuples(end)~=nchoosek(T,2)
    tuples(end+1) = nchoosek(T,2);
end
    


for t = 1:numel(tuples)
    for i=1:numel(n_vals)
        DATA{i} = tuple_rls(Xtr_c,Xts_c,n_vals(i),tuples(t),tuple_step,DATA{i});    
        save(save_path,'DATA');
    end
end

    


