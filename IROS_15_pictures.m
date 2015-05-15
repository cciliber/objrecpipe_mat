%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IROS 2015 pictures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MACHINE

%machine_tag = 'server';
%machine_tag = 'laptop_giulia_win';
%machine_tag = 'laptop_giulia_lin';
machine_tag = 'laptop_giulia_mac';

root_path = init_machine(machine_tag);

%% DATASET NAME

dataset_name = 'iCubWorld30';

%% MODALITY

%modality = 'lunedi22';
%modality = 'martedi23';
%modality = 'mercoledi24';
%modality = 'venerdi26';
modality = '';

%% TASK

task = '';

%% FEATURES

%feature_names = {'sc_d1024_iros', 'overfeat_small_default'};
%feature_names = {'sc_d512', 'overfeat_small_default'};
%feature_names = {'sc_d1024_iros'};
%feature_names = {'sc_d512'};
%feature_names = {'overfeat_small_default'};
%feature_names = {'caffe_prova', 'overfeat_small_default', 'sc_d512'};
%feature_names = {'caffe_centralcrop_meanimagenet2012', 'overfeat_small_default', 'sc_d512'};
feature_names = {'caffe_centralcrop_meanimagenet2012'};

feature_number = length(feature_names);

%% INPUT

working_dir = fullfile(root_path, [dataset_name '_experiments'], 'IROS_2015');
check_input_dir(working_dir);

%% OUTPUT

tmp=cell2mat(strcat('_', feature_names')');
figures_dir = fullfile(working_dir, 'figures', tmp(2:end));
check_output_dir(figures_dir);

%% load

day = {'lun', 'mar', 'mer', 'ven'};
ndays = length(day);

frame = [10 50 100 1000];
nframes = length(frame);

%rawdata = cell(ndays,nframes);

% original data day by day
D = 1;
for d=D
    loader = load(fullfile(working_dir, ['DATA_' day{d} '.mat']));
    for f=1:nframes
        rawdata{d,f} = loader.DATA{f};
    end
end

T = length(rawdata{d,f});

%% filtering

% parameters

windows = [1:20 25:5:55];
fps = 11;

dt_frame = 1/fps; % sec
temporal_windows = (windows-1)*(dt_frame);
nwindows = length(windows);

% action!

D = 1;
F = nframes;

rawdata{D,F} = filter_allys_structversion(rawdata{D,F}, windows, 'gurls');

filtered_path = fullfile(working_dir, ['DATA_' day{d} '_n1000_filtered.mat']);
save(filtered_path, 'rawdata', '-v7.3');
%load(filtered_path);

%% stability dev std
 
% F = nframes; % plot the case with all frames included in training
% 
% meanstd = zeros(1,T);
% for t=1:T
%     
%     ntrials = length([rawdata{1,F}{t}.acc]);
%     accvector = zeros(ndays, ntrials);
%     for d=1:ndays
%         accvector(d,:) = [rawdata{d,F}{t}.acc];
%     end
%     stdvector = std(accvector, 0, 1); 
%     meanstd(t) = mean(stdvector);
%     
% end
% 
% figure(1)
% plot(2:T+1, meanstd);
% set(gca, 'Xtick', 2:T+1);
% xlim([2 T+1]);
% grid on, box on
% xlabel('# objects');
% ylabel('accuracy');
% title('Mean std. dev. of rec. acc. across 4 days');

%% accuracy_vs_t

D = ndays;

%nselected = 50;

% histogram bins
binw = 0.05;
halfbinw = binw/2;
bins = 0:binw:1;
nbins = length(bins)-1;

mean_acc_over_nuples = zeros(T, nframes);
std_acc_over_nuples = zeros(T, nframes);
    
hist_acc_over_nuples_normalized = zeros(T, nframes, nbins);
    
for t=1:T
      
    for f=nframes
    
       accvector = [rawdata{D,f}{t}.acc];
              
       mean_acc_over_nuples(t, f) = mean(accvector);
       std_acc_over_nuples(t, f) = std(accvector);
       
       hist_acc_over_nuples_normalized(t, f, :) = histcounts(accvector, bins, 'Normalization','probability'); 
        
    end
end

figure(2)

F = nframes;
std_factor = 1;

set(gcf,'units','normalized','outerposition',[0 0 3/4 1])
 
fontsize = 30;
set(gca, 'FontSize', fontsize);

errorfill(2:T+1, mean_acc_over_nuples(:,F)', std_acc_over_nuples(:,F)'*std_factor);
hold on
plot(2:T+1, mean_acc_over_nuples(:,F), 'w', 'LineWidth', 2);

grid on, box on
xlabel('# objects', 'FontSize', fontsize);
ylabel('accuracy', 'FontSize', fontsize);

set(gca, 'XTick', 2:T+1);
xlim([2 T+1]);
ylim([0.6 1]);

xticklabels = (2:T+1)';
xticklabels = cellstr(num2str(xticklabels));
for id=2:2:numel(xticklabels)
    xticklabels{id} = [];
end
set(gca, 'XTickLabel', xticklabels);

title('Histograms, mean and standard deviation of recognition accuracy over trials', 'FontSize', fontsize);
    
bincenters = bins(1:end-1)+halfbinw;
for t=1:T
      
    tmphist = hist_acc_over_nuples_normalized(t, F, :);
    scatter((t+1)*ones(size(bincenters(tmphist>0))),bincenters(tmphist>0),squeeze(tmphist(tmphist>0))*600, 'b', 'filled');
    
end

h = gcf;
figure_name = 'acc_vs_t_ven_1-46_100-270';
saveas(h, fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.fig']));
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 3/4 3/4]);
% set(gca,'InvertHardcopy','off')
print(h, '-dpdf', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.pdf']));
print(h, '-dpng', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.png']));

%% statistics

D = ndays;

acc = [0.75 0.8 0.85 0.9 0.95 1];
nacc = length(acc);

conf = [0.7 0.8 0.9 0.95 0.98];
nconf = length(conf);
    
num_accSupA = zeros(T, nframes, nacc);
maxT_accSupA_withConfSupC = zeros(nframes, nacc, nconf);

num_accSupA_mode = zeros(T, nwindows, nacc);
maxT_accSupA_withConfSupC_mode = zeros(nwindows, nacc, nconf);

for ia=1:nacc
    
    for t=1:T
        for f=1:nframes
            
            accvector = [rawdata{D,f}{t}.acc];
            num_accSupA(t, f, ia) = sum(accvector >= acc(ia)) / length(accvector);
            
            if f==nframes
                accmatrix = vertcat(rawdata{D,F}{t}.acc_mode);
                num_accSupA_mode(t, :, ia) = sum(accmatrix >= acc(ia),1) / size(accmatrix,1); 
            end
            
        end
    end
    
end

for ia=1:nacc
    for ic=1:nconf
        
        for f=1:nframes
            
            tmp = T+1;
            if ~isempty(find(num_accSupA(:, f, ia) < conf(ic), 1, 'first' ))
                tmp = find(num_accSupA(:, f, ia) < conf(ic), 1, 'first' );
                
                if tmp == 1
                    tmp = 0;
                end
            end
            
            maxT_accSupA_withConfSupC(f, ia, ic) = tmp;
            
            if f==nframes
                for w=1:nwindows
                    
                    tmp = T+1;
                    if ~isempty(find(num_accSupA_mode(:, w, ia) < conf(ic), 1, 'first' ))
                        tmp = find(num_accSupA_mode(:, w, ia) < conf(ic), 1, 'first' );
                        
                        if tmp == 1
                            tmp = 0;
                        end
                    end
                    
                    maxT_accSupA_withConfSupC_mode(w, ia, ic) = tmp;
                    
                end
            end
        end
        
    end
end

acc_confC = zeros(T, nframes, nconf);
acc_confC_mode = zeros(T, nwindows, nconf);

for ic=1:nconf
    
    for t=1:T
        for f=1:nframes
            
            accvector = [rawdata{D,f}{t}.acc];
            sorted_accvector = sort(accvector, 'descend');
            ia = ceil(conf(ic)*length(accvector));
            acc_confC(t, f, ic) = sorted_accvector(ia);

%               cumhist = cumsum(hist_acc_over_nuples_normalized(t, f, :), 'reverse');
%               ibin = find(cumhist>=conf(ic), 1, 'last');
%               acc_confC(t,f,ic) = bincenters(ibin);
              
              if f==nframes
                  for w=1:nwindows
                      
                      accmatrix = vertcat(rawdata{D,f}{t}.acc_mode);
                      sorted_accmatrix = sort(accmatrix, 1, 'descend');
                      ia = ceil(conf(ic)*size(accmatrix,1));
                      acc_confC_mode(t, :, ic) = sorted_accmatrix(ia, :);
                      
                  end
              end
            
        end
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prob_vs_t and threshprob_vs_maxt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% figure(3)
% subplot(2,1,1)
%
% COLORMAP = hsv(nacc);
% COLORMAP = [COLORMAP; zeros(1,3)];
% COLORMAP(end,:) = COLORMAP(1,:);
% COLORMAP(1,:) = [];
%
% 
% F = nframes;
% 
% set(gcf,'units','normalized','outerposition',[0 0 3/8 1])
%  
% fontsize = 15;
% set(gca, 'FontSize', fontsize);
% 
% set(0,'DefaultAxesColorOrder',COLORMAP)
% plot(2:(T+1), squeeze(num_accSupA(:, F, :)), 'LineWidth', 2);
% 
% grid on, box on
% 
% xlabel('# objects');
% ylabel('fraction of subsets with acc>A');
% title('p(acc>A)');
% 
% set(gca, 'XTick', 2:(T+1));
% set(gca, 'YTick', conf);
% 
% xlim([2 T+1]);
% ylim([0 1]);
% 
% xticklabels = (2:T+1)';
% xticklabels = cellstr(num2str(xticklabels));
% for id=2:2:numel(xticklabels)
%     xticklabels{id} = [];
% end
% set(gca, 'XTickLabel', xticklabels);       
% 
% yticklabels = cellstr(num2str(conf'));
% set(gca, 'YTickLabel', yticklabels)  
% 
% legend(cellstr(num2str(acc')))
% 
% set(gca, 'FontSize', fontsize);
% 
% subplot(2,1,2)
%  
% fontsize = 15;
% set(gca, 'FontSize', fontsize);
% 
% set(0,'DefaultAxesColorOrder',COLORMAP)
% hold on
% for ia=1:nacc
%     plot(squeeze(maxT_accSupA_withConfSupC(F, ia, :)), conf, 'Color', COLORMAP(ia,:), 'LineWidth', 2);
% end
% 
% grid on, box on
% 
% xlabel('# objects');
% ylabel('threshold P');
% title('max # objects for which p(acc>A) > P');
% 
% set(gca, 'XTick', 2:(T+1));
% set(gca, 'YTick', conf);
% 
% xlim([2 T+1]);
% ylim([conf(1) conf(end)]);
% 
% xticklabels = (2:T+1)';
% xticklabels = cellstr(num2str(xticklabels));
% for id=2:2:numel(xticklabels)
%     xticklabels{id} = [];
% end
% set(gca, 'XTickLabel', xticklabels);       
%   
% yticklabels = cellstr(num2str(conf'));
% set(gca, 'YTickLabel', yticklabels)        
% 
% legend(cellstr(num2str(acc')))
% 
% h = gcf;
% figure_name = 'prob_vs_t_and_threshprob_vs_maxt_ven_1-46_100-270';
% saveas(h, fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.fig']));
% set(h,'PaperOrientation','landscape');
% set(h,'PaperUnits','normalized');
% set(h,'PaperPosition', [0 0 3/8 1]);
% % set(gca,'InvertHardcopy','off')
% print(h, '-dpdf', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.pdf']));
% print(h, '-dpng', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.png']));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prob_vs_t and threshacc_vs_maxt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% figure(4)
% subplot(2,1,1)
% 
% F = nframes;
% 
% set(gcf,'units','normalized','outerposition',[0 0 3/8 1])
%  
% fontsize = 15;
% set(gca, 'FontSize', fontsize);
% 
% COLORMAP = jet(nacc);
% hold on
% for ia=1:nacc
%     plot(2:(T+1), num_accSupA(:, F, ia), 'Color', COLORMAP(ia,:), 'LineWidth', 2);
% end
% grid on, box on
% 
% xlabel('# objects');
% ylabel('fraction of subsets with acc>A');
% title('p(acc>A)');
% 
% set(gca, 'XTick', 2:(T+1));
% %set(gca, 'YTick', conf);
% 
% xlim([2 T+1]);
% ylim([0 1]);
% 
% xticklabels = (2:T+1)';
% xticklabels = cellstr(num2str(xticklabels));
% for id=2:2:numel(xticklabels)
%     xticklabels{id} = [];
% end
% set(gca, 'XTickLabel', xticklabels);       
% 
% %yticklabels = cellstr(num2str(conf'));
% %set(gca, 'YTickLabel', yticklabels)  
% 
% legend(cellstr(num2str(acc')))
% 
% set(gca, 'FontSize', fontsize);
% 
% subplot(2,1,2)
%  
% fontsize = 15;
% set(gca, 'FontSize', fontsize);
% 
% COLORMAP = parula(nconf);
% hold on
% for ic=1:nconf
%     plot(squeeze(maxT_accSupA_withConfSupC(F, :, ic)), acc, 'Color', COLORMAP(ic, :), 'LineWidth', 2);
% end
% 
% grid on, box on
% 
% xlabel('# objects');
% ylabel('threshold A');
% title('max # objects for which p(acc>A) > P');
% 
% set(gca, 'XTick', 2:(T+1));
% set(gca, 'YTick', acc);
% 
% xlim([2 T+1]);
% ylim([acc(1) acc(end)]);
% 
% xticklabels = (2:T+1)';
% xticklabels = cellstr(num2str(xticklabels));
% for id=2:2:numel(xticklabels)
%     xticklabels{id} = [];
% end
% set(gca, 'XTickLabel', xticklabels);       
%   
% yticklabels = cellstr(num2str(acc'));
% set(gca, 'YTickLabel', yticklabels)        
% 
% legend(cellstr(num2str(conf')))
% 
% 
% h = gcf;
% figure_name = 'prob_vs_t_and_threshacc_vs_maxt_ven_1-46_100-270';
% saveas(h, fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.fig']));
% set(h,'PaperOrientation','landscape');
% set(h,'PaperUnits','normalized');
% set(h,'PaperPosition', [0 0 3/8 1]);
% % set(gca,'InvertHardcopy','off')
% print(h, '-dpdf', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.pdf']));
% print(h, '-dpng', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.png']));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% acc_confC_vs_t
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(5)

F = nframes;

set(gcf,'units','normalized','outerposition',[0 0 3/4 1])
fontsize = 15;

COLORMAP = jet(nconf);
hold on
for ic=1:nconf
    plot(2:(T+1), acc_confC(:, F, ic), 'Color', COLORMAP(ic,:), 'LineWidth', 2);
end
grid on, box on

xlabel('# objects');
ylabel('\gamma');
title('C(a,t)|_{a=\gamma} = \int_{\gamma}^{1}p(a,t)da = C');

set(gca, 'XTick', 2:(T+1));

xlim([2 T+1]);
ylim([0 1]);

xticklabels = (2:T+1)';
xticklabels = cellstr(num2str(xticklabels));
for id=2:2:numel(xticklabels)
    xticklabels{id} = [];
end
set(gca, 'XTickLabel', xticklabels);       

legend(cellstr(num2str(conf')))

set(gca, 'FontSize', fontsize);

h = gcf;
figure_name = 'acc_confC_vs_t__onHIST_ven_1-46_100-270';
saveas(h, fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.fig']));
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 3/4 1]);
% set(gca,'InvertHardcopy','off')
print(h, '-dpdf', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.pdf']));
print(h, '-dpng', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.png']));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prob_vs_t and threshprob_vs_maxt for nuples and filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% idx_acc = [nacc-2];
% mark = {'s', 'o'};
% 
% figure(4)
% subplot(2,1,2)
% 
% set(gcf,'units','normalized','outerposition',[0 0 3/8 1])
%  
% fontsize = 15;
% set(gca, 'FontSize', fontsize);
% 
% hold on
% startbeta = 0.5;
% deltabeta = 1-startbeta;
% beta = startbeta:deltabeta/(nframes-1):1;
% for ia=1:length(idx_acc)
%     
%     for f=1:nframes
%         %beta = 0.5*f/nframes;
%         plot(2:(T+1), num_accSupA(:, f, idx_acc(ia)), 'Color', COLORMAP(idx_acc(ia),:)*beta(f), 'LineWidth', 2);
%     end
% end
% 
% grid on, box on
% 
% xlabel('# objects');
% ylabel('fraction of subsets with acc>A');
% title('p(acc>A)');
% 
% set(gca, 'XTick', 2:(T+1));
% set(gca, 'YTick', conf);
% 
% xlim([2 T+1]);
% ylim([0 1]);
% 
% xticklabels = (2:T+1)';
% xticklabels = cellstr(num2str(xticklabels));
% for id=2:2:numel(xticklabels)
%     xticklabels{id} = [];
% end
% set(gca, 'XTickLabel', xticklabels);       
% 
% yticklabels = cellstr(num2str(conf'));
% set(gca, 'YTickLabel', yticklabels)  
% 
% leg = cellstr(num2str(frame'));
% legend(leg)
% 
% set(gca, 'FontSize', fontsize);
% 
% figure(4)
% subplot(2,1,1)
% 
% jumpw = 4;
% 
% set(gcf,'units','normalized','outerposition',[0 0 3/8 1])
%  
% fontsize = 15;
% set(gca, 'FontSize', fontsize);
% 
% hold on
% endbeta=3;
% deltabeta=endbeta-1;
% beta=1:deltabeta/(nwindows-2):endbeta;
% for ia=idx_acc
%     
%     for w=1:jumpw:nwindows
%         
%         if w==1
%             currmap = COLORMAP(ia,:);
%         else
%             currmap = min(ones(1,3), (COLORMAP(ia,:)+0.2)*beta(w-1));
%         end
%         plot(2:(T+1), num_accSupA_mode(:, w, ia), 'Color', currmap, 'LineWidth', 2);
%     end
% end
% 
% grid on, box on
% 
% xlabel('# objects');
% ylabel('Fraction of subsets with acc>A');
%               
% set(gca, 'XTick', 2:(T+1));
% set(gca, 'YTick', conf);
% 
% xlim([2 T+1]);
% ylim([0 1]);
% 
% xticklabels = (2:T+1)';
% xticklabels = cellstr(num2str(xticklabels));
% for id=2:2:numel(xticklabels)
%     xticklabels{id} = [];
% end
% set(gca, 'XTickLabel', xticklabels);       
% 
% yticklabels = cellstr(num2str(conf'));
% set(gca, 'YTickLabel', yticklabels)  
% 
% windows_leg = round(temporal_windows(1:jumpw:nwindows)'*10)/10;
% leg = strcat(cellstr(num2str(windows_leg)), 's');
% legend(leg, 'Location', 'Best', 'FontSize', 13.5);
% 
% set(gca, 'FontSize', fontsize);
% 
% h = gcf;
% figure_name = ['prob_vs_t_withfilter_andnuples_ven_1-28_100-144_' num2str(idx_acc)];
% saveas(h, fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.fig']));
% set(h,'PaperOrientation','landscape');
% set(h,'PaperUnits','normalized');
% set(h,'PaperPosition', [0 0 3/8 1]);
% % set(gca,'InvertHardcopy','off')
% print(h, '-dpdf', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.pdf']));
% print(h, '-dpng', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.png']));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% acc_confC_vs_t for nuples and filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(5)

set(gcf,'units','normalized','outerposition',[0 0 3/8 1])
fontsize = 12;

idx_conf = [nconf-2];

subplot(2,1,1)

jumpw = 4;
w_tobeplotted = 1:jumpw:nwindows;

COLORMAP = spring(length(w_tobeplotted));
hold on
for iw=1:length(w_tobeplotted)
    plot(2:(T+1), acc_confC_mode(:, w_tobeplotted(iw), idx_conf), 'Color', COLORMAP(iw,:), 'LineWidth', 2);
end
grid on, box on

xlabel('# objects');
ylabel('\gamma');
title({'\int_{\gamma}^{1}p(a,t)da = C = 0.9'; 'Increasing temporal window:'});

set(gca, 'XTick', 2:(T+1));

xlim([2 T+1]);
ylim([0.4 1]);

xticklabels = (2:T+1)';
xticklabels = cellstr(num2str(xticklabels));
for id=2:2:numel(xticklabels)
    xticklabels{id} = [];
end
set(gca, 'XTickLabel', xticklabels);       

windows_leg = round(temporal_windows(1:jumpw:nwindows)'*10)/10;
leg = strcat(cellstr(num2str(windows_leg)), 's');
legend(leg);

set(gca, 'FontSize', fontsize);

subplot(2,1,2)

COLORMAP = cool(length(1:nframes));
hold on
for f=nframes:-1:1
    plot(2:(T+1), acc_confC(:, f, idx_conf), 'Color', COLORMAP(f,:), 'LineWidth', 2);
end
grid on, box on

xlabel('# objects');
ylabel('\gamma');
title({'\int_{\gamma}^{1}p(a,t)da = C = 0.9'; 'Decreasing # frames:'});

set(gca, 'XTick', 2:(T+1));

xlim([2 T+1]);
ylim([0.4 1]);

xticklabels = (2:T+1)';
xticklabels = cellstr(num2str(xticklabels));
for id=2:2:numel(xticklabels)
    xticklabels{id} = [];
end
set(gca, 'XTickLabel', xticklabels);       

leg = cellstr(num2str(frame(end-1:-1:1)'));
leg = [{'220'}; leg];
legend(leg)

set(gca, 'FontSize', fontsize);

h = gcf;
figure_name = 'acc_confC_vs_t_withfiltering_andnuples_ven_1-46_100-270';
saveas(h, fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.fig']));
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 3/8 1]);
% set(gca,'InvertHardcopy','off')
print(h, '-dpdf', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.pdf']));
print(h, '-dpng', fullfile(figures_dir, [figure_name '_' day{D} '_' num2str(frame(F)) '.png']));