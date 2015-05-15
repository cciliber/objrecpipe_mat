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

%% FILTERING PARAMETERS

%windows = [1:20 24:4:50];
%fps = 7.5;
windows = [1:20 25:5:55];
fps = 11;

dt_frame = 1/fps; % sec
temporal_windows = windows*dt_frame;
nwindows = length(windows);

%% PLOTTING PARAMETERS

%n1_tobeplotted = [2 7 14 28];
n1_tobeplotted = 7;

n2_tobeplotted = 1;
n3_tobeplotted = 1; % set to 1 if exp_folder = 'obj_rec_random_nuples'
% either n2 or n3 to be plotted must be a scalar

windows_leg = [round(1/33*100)/100; round(temporal_windows(:)*10)/10];

std_factor = 0.25;

w_tbp_newplots = [1 length(windows)];
Nw = length(w_tbp_newplots);

%% CONVERT FORMAT CELL ARRAYS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
                
                cell_newplots{feat_idx}{n1,nw}(n2) = cell_input{feat_idx}{n1}(n2).acc(w_tpb_newplots(nw));

            end
            
        end

    end
    
end
 
%% COMPUTE ACCURACIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mean_accuracy_over_classes = cell(feature_number, 1);
mean_accuracy_over_nuples = cell(feature_number, 1);
var_accuracy_over_nuples = cell(feature_number, 1);

if strcmp(classification_kind, 'obj_rec_intra_class')
    mean_accuracy_over_nuples_perclass = cell(feature_number, 1);
    var_accuracy_over_nuples_perclass = cell(feature_number, 1);
elseif strcmp(classification_kind, 'categorization')
    mean_accuracy_over_nuples_perclass = cell(feature_number, 1);
    var_accuracy_over_nuples_perclass = cell(feature_number, 1);
end

for feat_idx=1:length(feature_names)

    % compute mean accuracies over nuples

    loaded_ys = load(fullfile(working_folder, feature_names{feat_idx}, filtered_ys_filename));
    cell_input = loaded_ys.cell_output;
    
    N1 = length(cell_input);
    
    mean_accuracy_over_classes{feat_idx} = cell(N1,1);
    mean_accuracy_over_nuples{feat_idx} = zeros(N1, nwindows+1);
    var_accuracy_over_nuples{feat_idx} = zeros(N1, nwindows+1);

    if strcmp(classification_kind, 'obj_rec_intra_class')
        % in this case N3 should be equal to Ncat for each n1
        mean_accuracy_over_nuples_perclass{feat_idx} = zeros(N1, Ncat, nwindows+1); 
        var_accuracy_over_nuples_perclass{feat_idx} = zeros(N1, Ncat, nwindows+1);
    end
    
    % extract accuracy information from cell array of results
    for n1=1:N1
        
        [N2, N3] = size(cell_input{n1});   
        
        mean_accuracy_over_classes{feat_idx}{n1} = zeros(N2, N3, nwindows+1);
        
        for n2=1:N2
            for n3=1:N3 
                if isfield(cell_input{n1}{n2, n3}, 'accuracy_mode_perclass')
                    mean_accuracy_over_classes{feat_idx}{n1}(n2, n3, :) = [mean(cell_input{n1}{n2, n3}.accuracy); mean(cell_input{n1}{n2, n3}.accuracy_mode_perclass,1)'];
                else
                    mean_accuracy_over_classes{feat_idx}{n1}(n2, n3, :) = [mean(cell_input{n1}{n2, n3}.accuracy); cell_input{n1}{n2, n3}.accuracy_mode'];
                end
            end
        end
        
        if strcmp(classification_kind, 'categorization') && n1==N1
            mean_accuracy_over_nuples_perclass{feat_idx} = zeros(Ncat, nwindows);
            var_accuracy_over_nuples_perclass{feat_idx} = zeros(Ncat, nwindows);
        end
        
        for w_tbp_newplots=1:nwindows+1
            
            mean_accuracy_over_nuples{feat_idx}(n1, w_tbp_newplots) = mean2(squeeze(mean_accuracy_over_classes{feat_idx}{n1}(:,:,w_tbp_newplots)));
            var_accuracy_over_nuples{feat_idx}(n1, w_tbp_newplots) = std2(squeeze(mean_accuracy_over_classes{feat_idx}{n1}(:,:,w_tbp_newplots)));
           
            if strcmp(classification_kind, 'obj_rec_intra_class')
                for n3=1:N3
                    mean_accuracy_over_nuples_perclass{feat_idx}(n1, n3, w_tbp_newplots) = mean(squeeze(mean_accuracy_over_classes{feat_idx}{n1}(:,n3,w_tbp_newplots)));
                    var_accuracy_over_nuples_perclass{feat_idx}(n1, n3, w_tbp_newplots) = std(squeeze(mean_accuracy_over_classes{feat_idx}{n1}(:,n3,w_tbp_newplots)));
                end
            elseif strcmp(classification_kind, 'categorization') && n1==N1 && w_tbp_newplots<nwindows+1
                for idx_cat=1:Ncat
                    tmp = cell2mat(cell_input{N1});
                    tmp = cat(3, tmp.accuracy_mode_perclass);
                    mean_accuracy_over_nuples_perclass{feat_idx}(idx_cat, w_tbp_newplots) = mean( tmp(idx_cat, w_tbp_newplots, :) );
                    var_accuracy_over_nuples_perclass{feat_idx}(idx_cat, w_tbp_newplots) = mean( tmp(idx_cat, w_tbp_newplots, :) );
                end
            end
            
        end
        
    end
    
end

% plot

for feat_idx=1:length(feature_names)
   
    % ys
    
    loaded_ys = load(fullfile(working_folder, feature_names{feat_idx}, filtered_ys_filename));
    cell_input = loaded_ys.cell_output;
    
    for n1=n1_tobeplotted
        
        figure(n1)
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
        
        subplot(1,length(feature_names),feat_idx)
        nsamples = size(cell_input{n1-1}{n2_tobeplotted, n3_tobeplotted}.y, 1);
        
        plotted_mat = zeros(nsamples, nwindows+2);
        plotted_mat(:,1) = cell_input{n1-1}{n2_tobeplotted, n3_tobeplotted}.ypred;
        plotted_mat(:,end) = cell_input{n1-1}{n2_tobeplotted, n3_tobeplotted}.y;
        
        for idx_wndw=1:nwindows
            ypred_mode = cell_input{n1-1}{n2_tobeplotted, n3_tobeplotted}.ypred_mode{idx_wndw};
            plotted_mat(:,1+idx_wndw) = ypred_mode(:);
            
        end
        
        imagesc(plotted_mat);
        colormap(jet(n1+1));
        colorbar_labels = '0 pad'; 
        colorbar_labels = [colorbar_labels; cell_input{n1-1}{n2_tobeplotted, n3_tobeplotted}.experiment];
        if (feat_idx==length(feature_names))
            h = colorbar('YLim', [0 n1], 'YTick', (0.5+[0; unique(plotted_mat(:,end))])*n1/(n1+1), 'YTickLabel', colorbar_labels);
            set(h, 'FontSize', 13.5);
            set( h, 'YDir', 'reverse' );
        end
        set(gca, 'XTick', 1:(nwindows+1));
        xticklabels = cellstr(num2str(windows_leg));
        for id=2:4:numel(xticklabels)
            xticklabels{id} = [];
            xticklabels{id+1} = [];
            xticklabels{id+2} = [];
        end
        xticklabels{end} = num2str(windows_leg(end));
        set(gca, 'XTickLabel', xticklabels, 'FontSize', 15);
        ylabel('samples', 'FontSize', 20);
        xlabel('time window [s]', 'FontSize', 20);
        title(strrep(feature_names{feat_idx}, '_', ' ' ), 'FontSize', 20);
    end
    
    % accuracies 
    
    figure(1)
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
    
    subplot(1,length(feature_names),feat_idx)
    
    set(0,'DefaultAxesColorOrder',jet(nwindows+1))
    plot(2:N1+1, squeeze(mean_accuracy_over_nuples{feat_idx}));
    if (feat_idx==1)
        legend(strcat(cellstr(num2str(windows_leg)), 's'), 'Location', 'Best', 'FontSize', 13.5);
    end
    
    wndw_idx = 1;
%     for wndw_idx=1:nwindows+1
         errorfill(2:N1+1, mean_accuracy_over_nuples{feat_idx}(:, wndw_idx)', var_accuracy_over_nuples{feat_idx}(:, wndw_idx)'*std_factor);
%     end

    hold on
    plot(2:N1+1, squeeze(mean_accuracy_over_nuples{feat_idx}));
    grid on, box on
    xlabel('classes', 'FontSize', 20);
    set(gca, 'XTick', 2:N1+1);
    xticklabels = (2:N1+1)';
    xticklabels = cellstr(num2str(xticklabels));
    for id=2:2:numel(xticklabels)
        xticklabels{id} = [];
    end
    set(gca, 'XTickLabel', xticklabels);
    set(gca, 'FontSize', 15);
    if (feat_idx==1)
        ylabel('accuracy (mean over classes)', 'FontSize', 20);
    end
    if (feat_idx==2)
        yticklabels = cellstr(get(gca, 'YTickLabel'));
        for id=1:numel(yticklabels)
            yticklabels{id} = [];
        end
        set(gca, 'YTickLabel', yticklabels);
    end
    
    xlim([2 N1+1]);
    ylim([0 1]);
    title(strrep(feature_names{feat_idx}, '_', ' ' ), 'FontSize', 20);
    
    if strcmp(classification_kind, 'obj_rec_intra_class')

        for n3=1:N3
            
            figure(max(n1_tobeplotted) + n3)
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
        
            subplot(1,length(feature_names),feat_idx)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            set(0,'DefaultAxesColorOrder',jet(nwindows+1))
            plot(2:N1+1, squeeze(mean_accuracy_over_nuples_perclass{feat_idx}(:,n3,:)));
            if (feat_idx==1)
                legend(strcat(cellstr(num2str(windows_leg)), 's'), 'Location', 'Best', 'FontSize', 13.5);
            end
            
            wndw_idx = 1;
            % for wndw_idx=1:nwindows+1
            errorfill(2:N1+1, mean_accuracy_over_nuples_perclass{feat_idx}(:, n3, wndw_idx)', var_accuracy_over_nuples_perclass{feat_idx}(:, n3, wndw_idx)'*std_factor);
            % end
            
            hold on
            plot(2:N1+1, squeeze(mean_accuracy_over_nuples_perclass{feat_idx}(:,n3,:)));
            grid on, box on
            xlabel('classes', 'FontSize', 20);
            set(gca, 'XTick', 2:N1+1);
            xticklabels = (2:N1+1)';
            xticklabels = cellstr(num2str(xticklabels));
            for id=2:2:numel(xticklabels)
                xticklabels{id} = [];
            end
            set(gca, 'XTickLabel', xticklabels);
            set(gca, 'FontSize', 15);
            if (feat_idx==1)
                ylabel('accuracy (mean over classes)', 'FontSize', 20);
            end
            if (feat_idx==2)
                yticklabels = cellstr(get(gca, 'YTickLabel'));
                for id=1:numel(yticklabels)
                    yticklabels{id} = [];
                end
                set(gca, 'YTickLabel', yticklabels);
            end
            
            xlim([2 N1+1]);
            ylim([0 1]);
            title({strrep(feature_names{feat_idx}, '_', ' ' ); cat_names{n3}}, 'FontSize', 20);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        end
        
    elseif strcmp(classification_kind, 'categorization')
        
            figure(max(n1_tobeplotted) + 1)
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
            
            subplot(1,length(feature_names),feat_idx)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            set(0,'DefaultAxesColorOrder',jet(nwindows+1))
            plot(1:Ncat, mean_accuracy_over_nuples_perclass{feat_idx});
            if (feat_idx==1)
                legend(strcat(cellstr(num2str(windows_leg)), 's'), 'Location', 'Best', 'FontSize', 13.5);
            end
            
            wndw_idx = 1;
            % for wndw_idx=1:nwindows+1
            errorfill(1:Ncat, mean_accuracy_over_nuples_perclass{feat_idx}(:, wndw_idx)', var_accuracy_over_nuples_perclass{feat_idx}(:, wndw_idx)'*std_factor);
            % end
            
            hold on
            plot(1:Ncat, mean_accuracy_over_nuples_perclass{feat_idx});
            grid on, box on
            xlabel('classes', 'FontSize', 20);
            set(gca, 'XTick', 1:Ncat);
            %xticklabels = (1:Ncat)';
            %xticklabels = cellstr(num2str(xticklabels));
            %for id=2:2:numel(xticklabels)
            %    xticklabels{id} = [];
            %end
            xticklabels = cat_names;
            set(gca, 'XTickLabel', xticklabels);
            set(gca, 'XTickLabelRotation', 45);
            set(gca, 'FontSize', 15);
            if (feat_idx==1)
                ylabel('accuracy (mean over classes)', 'FontSize', 20);
            end
            if (feat_idx==2)
                yticklabels = cellstr(get(gca, 'YTickLabel'));
                for id=1:numel(yticklabels)
                    yticklabels{id} = [];
                end
                set(gca, 'YTickLabel', yticklabels);
            end
            
            xlim([1 Ncat]);
            ylim([0 1]);
            title(strrep(feature_names{feat_idx}, '_', ' ' ), 'FontSize', 20);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end
    
end

% save figures

h = figure(1);
saveas(h, fullfile(figures_dir, [figure_name_prefix 'filtered_acc.fig']));
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
% set(gca,'InvertHardcopy','off')
print(h, '-dpdf', fullfile(figures_dir, [figure_name_prefix 'filtered_acc.pdf']));
print(h, '-dpng', fullfile(figures_dir, [figure_name_prefix 'filtered_acc.png']));

for n1=n1_tobeplotted
    
    saveas(figure(n1), fullfile(figures_dir, [figure_name_prefix 'filtered_ypred_nc_' num2str(n1) '_nu_' num2str(n2_tobeplotted) '.fig']));
    h = figure(n1);
    set(h,'PaperOrientation','landscape');
    set(h,'PaperUnits','normalized');
    set(h,'PaperPosition', [0 0 1 1]);
    % set(gca,'InvertHardcopy','off')
    print(h, '-dpdf', fullfile(figures_dir, [figure_name_prefix 'filtered_ypred_nc_' num2str(n1) '_nu_' num2str(n2_tobeplotted) '.pdf']));
    print(h, '-dpng', fullfile(figures_dir, [figure_name_prefix 'filtered_ypred_nc_' num2str(n1) '_nu_' num2str(n2_tobeplotted) '.png']));
end

if strcmp(classification_kind, 'obj_rec_intra_class')
    for n3=1:N3
        
        saveas(figure(max(n1_tobeplotted) + n3), fullfile(figures_dir, [figure_name_prefix 'filtered_acc_' cat_names{n3} '.fig']));
        h = figure(max(n1_tobeplotted) + n3);
        set(h,'PaperOrientation','landscape');
        set(h,'PaperUnits','normalized');
        set(h,'PaperPosition', [0 0 1 1]);
        % set(gca,'InvertHardcopy','off')
        print(h, '-dpdf', fullfile(figures_dir, [figure_name_prefix 'filtered_acc_' cat_names{n3} '.pdf']));
        print(h, '-dpng', fullfile(figures_dir, [figure_name_prefix 'filtered_acc_' cat_names{n3}  '.png']));
    end
    
elseif strcmp(classification_kind, 'categorization')
    h = figure(max(n1_tobeplotted) + 1);
    saveas(h, fullfile(figures_dir, [figure_name_prefix 'filtered_acc_perclass.fig']));
    set(h,'PaperOrientation','landscape');
    set(h,'PaperUnits','normalized');
    set(h,'PaperPosition', [0 0 1 1]);
    % set(gca,'InvertHardcopy','off')
    print(h, '-dpdf', fullfile(figures_dir, [figure_name_prefix 'filtered_acc_perclass.pdf']));
    print(h, '-dpng', fullfile(figures_dir, [figure_name_prefix 'filtered_acc_perclass.png']));
end