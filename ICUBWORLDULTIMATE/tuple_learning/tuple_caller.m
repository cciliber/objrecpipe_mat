
%%
maxT = 28;
minT = 1;

if ~exist('loaded','var')
    loaded = false;
end

if ~loaded
    Xtr = load('../data/Xtr_lun.mat');
    Xtr = Xtr.feat';
    Ytr = load('../data/Ytr_lun.mat');
    Ytr = Ytr.y;

    idx = (minT<=Ytr) & (Ytr<=maxT);
    Ytr = Ytr(idx);
    Xtr = Xtr(idx,:);

    Xts = load('../data/Xte_lun.mat');
    Xts = Xts.feat';
    Yts = load('../data/Yte_lun.mat');
    Yts = Yts.y;


    idx = Yts<=maxT;
    Yts = Yts(idx);
    Xts = Xts(idx,:);
    
    loaded = true;
end

T = maxT-minT+1;

Xtr_c = cell(T,1);
Xts_c = cell(T,1);

for t=minT:maxT
   Xtr_c{t-minT+1} = Xtr(Ytr==t,:);
   Xts_c{t-minT+1} = Xts(Yts==t,:);
end



Acc = tuple_rls(Xtr_c,Xts_c,1000);

[Acc{1}.acc]


