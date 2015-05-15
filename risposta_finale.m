
% working_dir = 'D:\DATASETS\iCubWorld30_experiments\IROS_2015\definitivi';
% 
% l = cell(4,1);
% 
% l{1} = load(fullfile(working_dir,'DATA_lun_n1000_filtered.mat'));
% l{2} = load(fullfile(working_dir,'DATA_mar_n1000_filtered.mat'));
% l{3} = load(fullfile(working_dir,'DATA_mer_293_n1000_filtered.mat'));
% l{4} = load(fullfile(working_dir,'DATA_ven_341_n1000_filtered.mat'));
% 
% rawdata = cell(4,1);
% 
% f = 4;
% for d=1:4
%     rawdata{d} = l{d}.rawdata{d,f};
%     l{d} = [];
% end
% clear l;

A = 0.98;
D = 4;
T = 27;
num_accSupA = zeros(D, T);

for d=1:D
    for t=1:T
        
        accmatrix = vertcat(rawdata{d}{t}.acc_mode);
        accvector = accmatrix(:,end);
        num_accSupA(d, t) = sum(accvector >= A) / length(accvector);
        
    end
end