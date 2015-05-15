%% MACHINE

% depending on the machine:
% GURLS and/or VL_FEAT and/or CNS are initialized
% FEATURES_DIR is set and added to Matlab path
% 'root_path' is set, dir containing every input/output dir from now on

%machine_tag = 'server';
%machine_tag = 'laptop_giulia_win';
machine_tag = 'laptop_giulia_lin';

root_path = init_machine(machine_tag);

%% DATASET NAME

% name of the directory inside 'root_path' that is root of the dataset 

%dataset_name = 'Groceries_4Tasks';
%dataset_name = 'Groceries';
%dataset_name = 'Groceries_SingleInstance';
%dataset_name = 'iCubWorld0';
%dataset_name = 'iCubWorld20';
dataset_name = 'iCubWorld30';
%dataset_name = 'cfr_caffe_cpp_matlab';

%% MODALITY

% optional subfolder inside dataset

%modality = 'carlo_household_right';
%modality = 'human';
%modality = 'robot';
modality = 'lunedi22';
%modality = 'martedi23';
%modality = 'mercoledi24';
%modality = 'venerdi26';
%modality = '';

%% TASK

% optional subfolder inside modality, just for the test set

%task = 'background';
%task = 'categorization';
%task = 'demonstrator';
%task = 'robot';
task = '';

%% CLASSIFICATION

classification_kind = 'obj_rec_random_nuples';
%classification_kind = 'obj_rec_inter_class';
%classification_kind = 'obj_rec_intra_class';
%classification_kind = 'categorization';

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

working_folder = fullfile(root_path, [dataset_name '_experiments'], classification_kind);
check_input_dir(working_folder);

if isempty(task) && isempty(modality)
    filtered_ys_filename = 'saved_output_filtered.mat';
elseif isempty(modality)
     filtered_ys_filename = ['saved_output_filtered_' task '.mat'];
elseif isempty(task)
     filtered_ys_filename = ['saved_output_filtered_' modality '.mat'];
else
    filtered_ys_filename = ['saved_output_filtered_' modality '_' task '.mat'];
end

%% OUTPUT

figures_dir = fullfile(working_folder, 'figures');
check_output_dir(figures_dir);

figure_name_prefix = cell2mat(strcat(feature_names', '_')');
if ~isempty(modality) && ~isempty(task)
    figure_name_prefix = [figure_name_prefix modality '_' task '_'];
elseif isempty(modality)
    figure_name_prefix = [figure_name_prefix task '_'];
elseif isempty(task)
    figure_name_prefix = [figure_name_prefix modality '_'];
end

%% FILTER PARAMETERS

%windows = [1:20 24:4:50];
%fps = 7.5;
windows = [1:20 25:5:55];
fps = 11;

dt_frame = 1/fps; % sec
temporal_windows = windows*dt_frame;
windows_leg = [round(1/33*100)/100; round(temporal_windows(:)*10)/10];
nwindows = length(windows);

%% PLOT PARAMETERS

%w_tbp_newplots = [1 length(windows)];
w_tbp_newplots = 1;
Nw = length(w_tbp_newplots);

%% CONVERT FORMAT CELL ARRAYS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cell_input = cell(feature_number,1);

for feat_idx=1:feature_number

    %tobeconverted = 1;
    %loaded_ys = load(fullfile(working_folder, feature_names{feat_idx}, filtered_ys_filename));
    %cell_feat = loaded_ys.cell_output;
    
    tobeconverted = 0;
    loaded_ys = load('/media/giulia/DATA/DATASETS/iCubWorld30_experiments/Xy_IROS15_caffe_meanimnet_ccrop/Acc.mat');
    cell_feat = loaded_ys.Acc;
    

    if (tobeconverted==0)
        
        cell_input{feat_idx} = cell_feat;
        
    else
        
        N1 = length(cell_feat);
        cell_input{feat_idx} = cell(N1,1);
        
        for n1=1:N1
            
            [N2, N3] = size(cell_feat{n1});
            
            cell_input{feat_idx}{n1} = struct('acc', {}, 'classes', {});
            
            for n3=1:N3
                for n2=1:N2
                    
                    if strcmp(feature_names{feat_idx}, 'overfeat_small_default') || strcmp(feature_names{feat_idx}, 'sc_d512')
                        % if there are still the 3 methods, take the 3rd (gurls)
                        cell_input{feat_idx}{n1}((n3-1)*N3+n2).acc = cell2mat(cell_feat{n1}{n2, n3}.accuracy_mode(end,:));
                    else
                        cell_input{feat_idx}{n1}((n3-1)*N3+n2).acc = cell_feat{n1}{n2, n3}.accuracy_mode(end,:);
                    end
                    
                    cell_input{feat_idx}{n1}((n3-1)*N3+n2).classes = cell_feat{n1}{n2, n3}.experiment;
                    
                end
            end
            
        end
        
    end
    
end

%% CREATE STRUCTURES FOR NEW PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cell_newplots = cell(feature_number, 1);

for feat_idx=1:feature_number
    
    N1 = length(cell_input{feat_idx});
    cell_newplots{feat_idx,1} = cell(N1,Nw);
    
    for n1=1:N1
        
        N2 = length(cell_input{feat_idx}{n1});
        
        for nw=1:Nw
            cell_newplots{feat_idx}{n1,nw} = zeros(N2, 1);
        end
        
        for n2=1:N2
            
            for nw=1:Nw
                
                cell_newplots{feat_idx}{n1,nw}(n2) = cell_input{feat_idx}{n1}(n2).acc(w_tbp_newplots(nw));

                cell_newplots{feat_idx}{n1,nw}(randperm(size(cell_newplots{feat_idx}{n1,nw},1)));
                
                %if size(cell_newplots{feat_idx}{n1,nw},1)>40
                %    cell_newplots{feat_idx}{n1,nw}(101:end)=[];
                %end
            end
            
        end

    end
    
end
 
%% COMPUTE stats of acc %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mean_acc_over_nuples = cell(feature_number, 1);
mod_acc_over_nuples = cell(feature_number, 1);
med_acc_over_nuples = cell(feature_number, 1);
std_acc_over_nuples = cell(feature_number, 1);

bin = 0.05;
halfbin = bin/2;
bins = 0:bin:1;
Nbins = length(bins);
hist_acc_over_nuples = cell(feature_number, 1);
hist_acc_over_nuples_normalized = cell(feature_number, 1);

for feat_idx=1:feature_number
    
    N1 = size(cell_newplots{feat_idx}, 1);
    Nw = size(cell_newplots{feat_idx}, 2);
    
    mean_acc_over_nuples{feat_idx} = zeros(N1, Nw);
    std_acc_over_nuples{feat_idx} = zeros(N1, Nw);
    mod_acc_over_nuples{feat_idx} = zeros(N1, Nw);
    med_acc_over_nuples{feat_idx} = zeros(N1, Nw);
    hist_acc_over_nuples{feat_idx} = zeros(N1, Nw, Nbins);
    hist_acc_over_nuples_normalized{feat_idx} = zeros(N1, Nw, Nbins);
    
    for n1=1:N1
        for nw=1:Nw
            
            mean_acc_over_nuples{feat_idx}(n1, nw) = mean(cell_newplots{feat_idx}{n1, nw});
            std_acc_over_nuples{feat_idx}(n1, nw) = std(cell_newplots{feat_idx}{n1, nw});
            
            mod_acc_over_nuples{feat_idx}(n1, nw) = mode(cell_newplots{feat_idx}{n1, nw});
            med_acc_over_nuples{feat_idx}(n1, nw) = median(cell_newplots{feat_idx}{n1, nw});
            
            hist_acc_over_nuples{feat_idx}(n1, nw, :) = histc(cell_newplots{feat_idx}{n1, nw}, bins);
            hist_acc_over_nuples_normalized{feat_idx}(n1, nw, :) = hist_acc_over_nuples{feat_idx}(n1, nw, :) / sum(hist_acc_over_nuples{feat_idx}(n1, nw, :));
        end
    end
    
end

%% plot old %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

std_factor = 2;

fsize = 30;

figure 
set(gcf,'units','normalized','outerposition',[0 0 1 1])

for feat_idx=1:feature_number
  
    N1 = size(mean_acc_over_nuples{feat_idx},1);
    Nw = size(mean_acc_over_nuples{feat_idx},2);
    
    subplot(1,length(feature_names),feat_idx)
    
    set(0,'DefaultAxesColorOrder',jet(Nw))
    plot(2:N1+1, mean_acc_over_nuples{feat_idx}, 'w', 'LineWidth', 2);
    if (feat_idx==1)
        legend(strcat(cellstr(num2str(windows_leg(w_tbp_newplots))), 's'), 'Location', 'Best', 'FontSize', fsize);
    end
    
    wndw_idx = 1;
%     for wndw_idx=1:nwindows+1
         errorfill(2:N1+1, mean_acc_over_nuples{feat_idx}(:, wndw_idx)', std_acc_over_nuples{feat_idx}(:, wndw_idx)'*std_factor);
%     end

    hold on
    plot(2:N1+1, mean_acc_over_nuples{feat_idx}, 'w', 'LineWidth', 2);
    grid on, box on
    xlabel('# objects', 'FontSize', fsize);
    set(gca, 'XTick', 2:N1+1);
    xticklabels = (2:N1+1)';
    xticklabels = cellstr(num2str(xticklabels));
    for id=2:2:numel(xticklabels)
        xticklabels{id} = [];
    end
    set(gca, 'XTickLabel', xticklabels);
    set(gca, 'FontSize', fsize);
    if (feat_idx==1)
        ylabel('accuracy', 'FontSize', fsize);
    end
    if (feat_idx==2)
        yticklabels = cellstr(get(gca, 'YTickLabel'));
        for id=1:numel(yticklabels)
            yticklabels{id} = [];
        end
        set(gca, 'YTickLabel', yticklabels, 'FontSize', fsize);
    end
    
    xlim([2 N1+1]);
    ylim([0 1]);
    title(strrep(feature_names{feat_idx}, '_', ' ' ), 'FontSize', fsize);
    
    hold on
    for n1=1:N1
        for nw=1:Nw
            
           %scatter((n1+1)*ones(size(cell_newplots{feat_idx}{n1, nw})),cell_newplots{feat_idx}{n1, nw},'b');
           tmp = hist_acc_over_nuples_normalized{feat_idx}(n1, nw, :);
           tmppos = tmp(tmp>0);
           scatter((n1+1)*ones(size(tmppos)),bins(tmp>0)+halfbin,tmppos*1000, 'b', 'filled');
            
        end
    end
    axis([2 28 0 1]);
end

h = gcf;
figures_dir = '/media/giulia/DATA/IIT/ARTICOLI/IROS2015/draft';
figure_name_prefix = 'mean_hist_vs_nobj';

saveas(h, fullfile(figures_dir, [figure_name_prefix '.fig']));
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
% set(gca,'InvertHardcopy','off')
print(h, '-dpdf', fullfile(figures_dir, [figure_name_prefix '.pdf']));
print(h, '-dpng', fullfile(figures_dir, [figure_name_prefix '.png']));

%% plot 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
set(gcf,'units','normalized','outerposition',[0 0 1 1])

for feat_idx=1:feature_number
    
    N1 = length(mean_acc_over_nuples{feat_idx});
    
    subplot(feature_number, 4, (feat_idx-1)*4+1)
    plot(mean_acc_over_nuples{feat_idx}, 2:N1+1);
    grid on, box on
    xlabel('mean(acc)', 'FontSize', 15);
    if mod(feat_idx,3)==1
        ylabel('# objects', 'FontSize', 20);
    end
    if feat_idx<4
        title(strrep(feature_names{feat_idx}, '_', ' ' ), 'FontSize', 20);   
    end
    ylim([2 N1+1]);
    set(gca, 'YTick', 2:N1+1);
    yticklabels = (2:N1+1)';
    yticklabels = cellstr(num2str(yticklabels));
    for id=2:2:numel(yticklabels)
        yticklabels{id} = [];
    end
    set(gca, 'YTickLabel', yticklabels);
    set(gca, 'FontSize', 15);
    
    
    subplot(feature_number, 4, (feat_idx-1)*4+2)
    plot(mod_acc_over_nuples{feat_idx}, 2:N1+1);
    grid on, box on
    xlabel('mode(acc)', 'FontSize', 15);
    if mod(feat_idx,3)==1
        ylabel('# objects', 'FontSize', 20);
    end
    if feat_idx<4
        title(strrep(feature_names{feat_idx}, '_', ' ' ), 'FontSize', 20);   
    end
    ylim([2 N1+1]);
    set(gca, 'YTick', 2:N1+1);
    yticklabels = (2:N1+1)';
    yticklabels = cellstr(num2str(yticklabels));
    for id=2:2:numel(yticklabels)
        yticklabels{id} = [];
    end
    set(gca, 'YTickLabel', yticklabels);
    set(gca, 'FontSize', 15);
    
    
    subplot(feature_number, 4, (feat_idx-1)*4+3)
    plot(med_acc_over_nuples{feat_idx}, 2:N1+1);
    grid on, box on
    xlabel('median(acc)', 'FontSize', 15);
    if mod(feat_idx,3)==1
        ylabel('# objects', 'FontSize', 20);
    end
    if feat_idx<4
        title(strrep(feature_names{feat_idx}, '_', ' ' ), 'FontSize', 20);   
    end
    ylim([2 N1+1]);
    set(gca, 'YTick', 2:N1+1);
    yticklabels = (2:N1+1)';
    yticklabels = cellstr(num2str(yticklabels));
    for id=2:2:numel(yticklabels)
        yticklabels{id} = [];
    end
    set(gca, 'YTickLabel', yticklabels);
    set(gca, 'FontSize', 15);
    
    subplot(feature_number, 4, (feat_idx-1)*4+4)
    
    tmp = squeeze(hist_acc_over_nuples_normalized{feat_idx}(:, nw, :))';
    tmp = unique(tmp(:));
    
    %imagesc(squeeze(hist_acc_over_nuples{feat_idx}(:, nw, :))');
    imagesc(squeeze(hist_acc_over_nuples_normalized{feat_idx}(:, nw, :))', [min(tmp) max(tmp)]);
    set(gca,'YDir','normal')
    xlabel('# objects');
    ylabel('acc bins');
    
    set(gca, 'XTick', 1:N1);
    xticklabels = cellstr(num2str((2:(N1+1))'));
    for id=2:2:numel(xticklabels)
        xticklabels{id} = [];
    end
    set(gca, 'XTickLabel', xticklabels, 'FontSize', 15)
    
    set(gca, 'YTick', 1:Nbins);
    yticklabels = cellstr(num2str((bins+halfbin)'));
    set(gca, 'YTickLabel', yticklabels, 'FontSize', 15)
    
    title({strrep(feature_names{feat_idx}, '_', ' ' ), 'hist(acc) over exps'}, 'FontSize', 20);
    
    %l = load('cmap_hist.mat');
    %colormap(l.cmap_hist)

    colormap(jet(length(tmp)))
    
    h = colorbar;
    %set(h, 'YTickLabel', strcat(cellstr(num2str((get(h, 'YTick')*100)')), '%'));
    
end

%% COMPUTE frac trials with acc>A %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

acc = 0.5:0.05:1;
nacc = length(acc);

num_accSupA = cell(feature_number, 1);

for feat_idx=1:feature_number
    
    N1 = size(cell_newplots{feat_idx}, 1);
    Nw = size(cell_newplots{feat_idx}, 2);
    
    num_accSupA{feat_idx} = zeros(nacc, N1, Nw);
    
    for ia=1:nacc
        
        for n1=1:N1
            for nw=1:Nw
        
                num_accSupA{feat_idx}(ia, n1, nw) = sum(cell_newplots{feat_idx}{n1, nw} >= acc(ia), 1) / size(cell_newplots{feat_idx}{n1, nw},1);
                    
            end
                     
        end
    end
    
end

%% plot 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
set(gcf,'units','normalized','outerposition',[0 0 1 1])


for feat_idx=1:feature_number
    
    N1 = size(num_accSupA{feat_idx}, 2);
    Nw = size(num_accSupA{feat_idx}, 3);
    
    for nw=1:Nw
        
        subplot(feature_number,Nw,(feat_idx-1)*Nw+nw)
        
        imagesc(num_accSupA{feat_idx}(:, :, nw));
        set(gca,'YDir','normal')
        xlabel('# objects');
        %ylabel('thresh A');
        
        set(gca, 'XTick', 1:N1);
        xticklabels = cellstr(num2str((2:(N1+1))'));
        for id=2:2:numel(xticklabels)
            xticklabels{id} = [];
        end
        set(gca, 'XTickLabel', xticklabels, 'FontSize', 15)        
        
        set(gca, 'YTick', 1:nacc);
        yticklabels = cellstr(num2str(acc'));
        set(gca, 'YTickLabel', yticklabels, 'FontSize', 15)        
        
        title({strrep(feature_names{feat_idx}, '_', ' ' ), 'frac of trials with acc>A'}, 'FontSize', 20); 
        
        h = colorbar;
        %set(h, 'YTickLabel', strcat(cellstr(num2str((get(h, 'YTick')*100)')), '%'));
    end
end

%% plot 3 no imagesc %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
set(gcf,'units','normalized','outerposition',[0 0 1 1])

for feat_idx=1:feature_number
    
    N1 = size(num_accSupA{feat_idx}, 2);
    Nw = size(num_accSupA{feat_idx}, 3);
    
    for nw=1:Nw
        
        subplot(feature_number,Nw,(feat_idx-1)*Nw+nw)
        
        set(0,'DefaultAxesColorOrder',jet(nacc))
        plot(2:(N1+1), num_accSupA{feat_idx}(:, :, nw), 'LineWidth', 2);
        xlabel('# objects');
        ylabel('frac of trials with acc>A');
        
        grid on, box on
        
         set(gca, 'XTick', 2:(N1+1));
         xticklabels = cellstr(num2str((2:(N1+1))'));
%         for id=2:2:numel(xticklabels)
%             xticklabels{id} = [];
%         end
         set(gca, 'XTickLabel', xticklabels, 'FontSize', 15)        
         xlim([2 28])
         
%          set(gca, 'YTick', acc);
%          yticklabels = cellstr(num2str(acc'));
%          set(gca, 'YTickLabel', yticklabels, 'FontSize', 15)        
        
        title({strrep(feature_names{feat_idx}, '_', ' ' ), 'frac of trials with acc>A'}, 'FontSize', 20); 
        
        legend(cellstr(num2str(acc')))
        %set(h, 'YTickLabel', strcat(cellstr(num2str((get(h, 'YTick')*100)')), '%'));
    end
end

%% compute max # obj for which [frac trials with acc>A ] > C %%%%%%%%%%%%%%

conf = 1:-0.05:0.0;
nconf = length(conf);

maxT_accSupA_withConfSupC = cell(feature_number, 1);

for feat_idx=1:feature_number
    
    maxT_accSupA_withConfSupC{feat_idx} = zeros(nacc, nconf, Nw);
    
    for ia=1:nacc
        for ic=1:nconf
            for nw=1:Nw
                
                tmp = 28;
                if ~isempty(find(num_accSupA{feat_idx}(ia, :, nw) < conf(ic), 1, 'first' ))
                    tmp = find(num_accSupA{feat_idx}(ia, :, nw) < conf(ic), 1, 'first' );
                    
                    if tmp == 1
                        tmp = 0;
                    end
                end
                
                maxT_accSupA_withConfSupC{feat_idx}(ia, ic, nw) = tmp;
              
            end
        end
    end
    
end

%% plot 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
set(gcf,'units','normalized','outerposition',[0 0 1 1])

for feat_idx=1:feature_number
    
    N1 = size(num_accSupA{feat_idx}, 2);
    Nw = size(num_accSupA{feat_idx}, 3);
    
    for nw=1:Nw
        
        subplot(feature_number,Nw,(feat_idx-1)*Nw+nw)
        
        imagesc(maxT_accSupA_withConfSupC{feat_idx}(:, :, nw));
        set(gca,'YDir','normal')
        xlabel('thresh C');
        ylabel('thresh A');
        
        set(gca, 'XTick', 1:nconf);
        xticklabels = cellstr(num2str(conf'));
        set(gca, 'XTickLabel', xticklabels, 'FontSize', 15)        
        
        set(gca, 'YTick', 1:nacc);
        yticklabels = cellstr(num2str(acc'));
        set(gca, 'YTickLabel', yticklabels, 'FontSize', 15)        
        
        title({strrep(feature_names{feat_idx}, '_', ' ' ), 'max # objects for which acc>A with conf>C'}, 'FontSize', 20); 
        
        colormap(jet(N1))
        
        h = colorbar;
        %set(h, 'YTickLabel', strcat(cellstr(num2str((get(h, 'YTick')*100)')), '%'));
    end
end

%% plot 4 no imagesc %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
hold on
set(gcf,'units','normalized','outerposition',[0 0 1 1])

for feat_idx=1:feature_number
    
    Nw = size(num_accSupA{feat_idx}, 3);
    
    for nw=1:Nw
        
        subplot(feature_number,Nw,(feat_idx-1)*Nw+nw)
        cmap = jet(nacc);
        
        for ia=1:nacc
            plot(maxT_accSupA_withConfSupC{feat_idx}(ia, :, nw), conf, 'Color', cmap(ia,:), 'LineWidth', 2);
        end
        xlabel('max # objects for which acc>A with conf>C');
        ylabel('conf');
        
        grid on, box on
        
         set(gca, 'XTick', 2:(N1+1));
         xticklabels = cellstr(num2str((2:(N1+1))'));
%         for id=2:2:numel(xticklabels)
%             xticklabels{id} = [];
%         end
         set(gca, 'XTickLabel', xticklabels, 'FontSize', 15)        
         xlim([2 28])
         
          set(gca, 'YTick', conf(end:-1:1));
          yticklabels = cellstr(num2str(conf'));
          set(gca, 'YTickLabel', yticklabels, 'FontSize', 15)        
        
        title({strrep(feature_names{feat_idx}, '_', ' ' ), 'max # objects for which acc>A with conf>C'}, 'FontSize', 20); 
        
        legend(cellstr(num2str(acc')))
        %set(h, 'YTickLabel', strcat(cellstr(num2str((get(h, 'YTick')*100)')), '%'));
    end
end


figure
hold on
set(gcf,'units','normalized','outerposition',[0 0 1 1])

for feat_idx=1:feature_number
    
    Nw = size(num_accSupA{feat_idx}, 3);
    
    for nw=1:Nw
        
        subplot(feature_number,Nw,(feat_idx-1)*Nw+nw)
        cmap = jet(nacc);
        
        for ia=1:nacc
            plot(conf, maxT_accSupA_withConfSupC{feat_idx}(ia, :, nw), 'Color', cmap(ia,:), 'LineWidth', 2);
        end
        ylabel('max # objects for which acc>A with conf>C');
        xlabel('conf');
        
        grid on, box on
        
         set(gca, 'YTick', 2:(N1+1));
         yticklabels = cellstr(num2str((2:(N1+1))'));
%         for id=2:2:numel(xticklabels)
%             xticklabels{id} = [];
%         end
         set(gca, 'YTickLabel', yticklabels, 'FontSize', 15)        
         ylim([2 28])
         
          set(gca, 'XTick', conf(end:-1:1));
          xticklabels = cellstr(num2str(conf'));
          set(gca, 'XTickLabel', xticklabels, 'FontSize', 15)        
        
        title({strrep(feature_names{feat_idx}, '_', ' ' ), 'max # objects for which acc>A with conf>C'}, 'FontSize', 20); 
        
        legend(cellstr(num2str(acc')))
        %set(h, 'YTickLabel', strcat(cellstr(num2str((get(h, 'YTick')*100)')), '%'));
    end
end
