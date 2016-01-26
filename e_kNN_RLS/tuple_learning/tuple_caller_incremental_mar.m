

run('/data/REPOS/GURLS/gurls/utils/gurls_install.m');
run('/data/REPOS/vlfeat-0.9.20/toolbox/vl_setup.m');

%%
maxT = 28;
minT = 1;

if ~exist('loaded','var')
    loaded = false;
end

save_path = ['DATA_mar_' strrep(char(datetime(clock)),' ','_')];


data_folder = '/data/DATASETS/iCubWorld30_experiments/Xy_IROS15_caffe_meanimnet_ccrop';
data_day = 'mar';


if ~loaded
    Xtr = load(fullfile(data_folder,['Xtr_',data_day,'.mat']));
    Xtr = Xtr.feat';
    Ytr = load(fullfile(data_folder,['Ytr_',data_day,'.mat']));
    Ytr = Ytr.y;

    idx = (minT<=Ytr) & (Ytr<=maxT);
    Ytr = Ytr(idx);
    Xtr = Xtr(idx,:);

    Xts = load(fullfile(data_folder,['Xte_',data_day,'.mat']));
    Xts = Xts.feat';
    Yts = load(fullfile(data_folder,['Yte_',data_day,'.mat']));
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

n_vals = [10,50,100,1000];
DATA = cell(numel(n_vals),1);

for i=1:numel(n_vals)
    DATA{i} = tuple_rls(Xtr_c,Xts_c,n_vals(i));
end

save(save_path,'DATA');

