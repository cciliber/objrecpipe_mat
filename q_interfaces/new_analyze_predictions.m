function results = new_analyze_predictions(setup_data, experiment, results)

acc_dimensions = results.acc_dimensions;

% temporary ?
trainval_prefixes = {'train_','val_'};
trainval_sets = [1, 2];
eval_set = numel(question.setlist.obj_lists_all{1});


%% Setup the IO root directories

% input registries
input_dir_regtxt_root = fullfile(setup_data.DATA_DIR, 'iCubWorldUltimate_registries', 'categorization');
check_input_dir(input_dir_regtxt_root);

% root location of the predictions (and of the output)
[~,dset_name] = fileparts(experiment.dset_dir);
exp_dir = fullfile(setup_data.DATA_DIR, [dset_name '_experiments'], 'categorization');
check_input_dir(exp_dir);

check_output_dir(fullfile(exp_dir, 'figs/fig'));
check_output_dir(fullfile(exp_dir, 'figs/png'));
                    
%% Load linked information 

% about the network tested (network)
load(experiment.network_struct_path);

if isfield(network, 'network_dir')
    network.network_dir;
end

% abut the subset of the dset considered (question)
load(experiment.question_struct_path);

cat_idx_all = question.setlist.cat_idx_all;
obj_lists_all = question.setlist.obj_lists_all;
transf_lists_all = question.setlist.transf_lists_all;
day_mappings_all = question.setlist.day_mappings_all;
day_lists_all = question.setlist.day_lists_all;
camera_lists_all = question.setlist.camera_lists_all;


%% For each experiment, go!

for icat=1:length(cat_idx_all)
    
    cat_idx = cat_idx_all{icat};
    
    for iobj=1:length(obj_lists_all)
        
        obj_list = obj_lists_all{iobj}{eval_set};
        
        for itransf=1:length(transf_lists_all)
            
            transf_list = transf_lists_all{itransf}{eval_set};
            
            for iday=1:length(day_lists_all)
                 
                day_list = day_lists_all{iday}{eval_set};
                day_mapping = day_mappings_all{iday}{eval_set};
                
                for icam=1:length(camera_lists_all)
                    
                    camera_list = camera_lists_all{icam}{eval_set};
                    
                    %% Create the test set name
                    set_name = [strrep(strrep(num2str(obj_list), '   ', '-'), '  ', '-') ...
                        '_tr_' strrep(strrep(num2str(transf_list), '   ', '-'), '  ', '-') ...
                        '_day_' strrep(strrep(num2str(day_mapping), '   ', '-'), '  ', '-') ...
                        '_cam_' strrep(strrep(num2str(camera_list), '   ', '-'), '  ', '-')];
                    
                    if ~isempty(network.mapping)
                        
                        %% Create the train val folder name
                        set_names = cell(length(trainval_sets),1);
                        for iset=trainval_sets
                            
                            set_names{iset} = [strrep(strrep(num2str(obj_lists_all{iobj}{iset}), '   ', '-'), '  ', '-') ...
                                '_tr_' strrep(strrep(num2str(transf_lists_all{itransf}{iset}), '   ', '-'), '  ', '-') ...
                                '_day_' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', '-'), '  ', '-') ...
                                '_cam_' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', '-'), '  ', '-')];
                            
                            set_names_4figs{iset} = [trainval_prefixes{iset}(1:(end-1)) ': ' ...
                                strrep(strrep(num2str(obj_lists_all{iobj}{iset}), '   ', ', '), '  ', ', ')];
                                tmp = transf_names(transf_lists_all{itransf}{iset});
                                tmp = cell2mat(strcat(tmp(:), ' ')');
                            set_names_4figs{iset} = [set_names_4figs{iset} ...
                                ', tr ' tmp ...
                                ', day ' strrep(strrep(num2str(day_mappings_all{iday}{iset}), '   ', ', '), '  ', ', ') ...
                                ', cam ' strrep(strrep(num2str(camera_lists_all{icam}{iset}), '   ', ', '), '  ', ', ')];
                        end
                        trainval_dir = cell2mat(strcat(trainval_prefixes(:), set_names(:), '_')');
                        trainval_dir = trainval_dir(1:end-1);
                    
                    else
                        trainval_dir = '';
                    end
                    
                    %% Assign IO directories
                    
                    dir_regtxt_relative = fullfile(['Ncat_' num2str(length(cat_idx))], strrep(strrep(num2str(cat_idx), '   ', '-'), '  ', '-'));
                    dir_regtxt_relative = fullfile(dir_regtxt_relative, question.question_dir);
                    
                    input_dir_regtxt = fullfile(input_dir_regtxt_root, dir_regtxt_relative);
                    check_input_dir(input_dir_regtxt);
                    
                    if isfield(network, 'network_dir')
                        output_dir = fullfile(exp_dir, caffe_model_name, dir_regtxt_relative, trainval_dir, network.mapping, network.network_dir);
                    else
                        output_dir = fullfile(exp_dir, caffe_model_name, dir_regtxt_relative, trainval_dir, network.mapping);
                    end
                    check_output_dir(output_dir);

                    check_output_dir(fullfile(output_dir, 'figs/fig'));
                    check_output_dir(fullfile(output_dir, 'figs/png'));
                    
                    %% Load the registry REG and the true labels Y
                     
                    fid = fopen(fullfile(input_dir_regtxt, [set_name '_Y.txt']));
                    input_registry = textscan(fid, '%s %d'); 
                    fclose(fid);
                    Y = input_registry{2};
                    REG = input_registry{1}; 
                    if isempty(network.mapping) && question.create_imnetlabels
                        fid = fopen(fullfile(input_dir_regtxt, [set_name '_Yimnet.txt']));
                        input_registry = textscan(fid, '%s %d'); 
                        fclose(fid);
                        Yimnet = input_registry{2};
                    end
                    clear input_registry;

                    %% Load the predictions Ypred
                    
                    Y_avg_struct = load(fullfile(output_dir_y, ['Yavg_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                    if isempty(network.mapping) 
                        Y_avg_sel_struct = load(fullfile(output_dir_y, ['Yavg_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C'); 
                    end
                    
                    if NCROPS>1
                       Y_central_struct = load(fullfile(output_dir_y, ['Ycentral_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        if isempty(network.mapping) 
                            Y_central_sel_struct = load(fullfile(output_dir_y, ['Ycentral_sel_' set_name '.mat'] ), 'Ypred', 'acc', 'acc_xclass', 'C');
                        end
                    end

                    %% Organize Y and Ypred in cell arrays and compute accuracies

                    if isempty(network.mapping) 
                        if question.setlist.create_imnetlabels
                            Y_avg_struct.Y = Yimnet;
                        else
                            warning('mapping is empty but Yimnet not found: skipping accuracy for Ypred_avg...');
                        end
                    else
                        Y_avg_struct.Y = Y; 
                    end 
                    Y_avg_struct = putYinCell(setup_data.dset, REG, Y_avg_struct);
                    Y_avg_struct.A{iacc} = computeAcc(Y_avg_struct.Y, Yavg_struct.Ypred, acc_dimensions);
                    
                    if isempty(network.mapping)
                        Y_avg_sel_struct.Y = Y;
                        Y_avg_sel_struct = putYinCell(setup_data.dset, REG, Y_avg_sel_struct);
                        Y_avg_sel_struct = computeAcc(Y_avg_sel_struct.Y, Y_avg_sel_struct.Ypred, acc_dimensions);
                    end    
                    
                    if NCROPS>1
                        
                        if isempty(network.mapping)
                            if question.setlist.create_imnetlabels
                                Y_central_struct.Y = Yimnet;
                            else
                                warning('... and for Ypred_central...');
                            end
                        else
                            Y_central_struct.Y = Y;
                        end   
                        Y_central_struct = putYinCell(setup_data.dset, REG, Y_central_struct);
                        Y_central_struct = computeAcc(Y_central_struct.Y, Y_central_struct.Ypred, acc_dimensions);
                        
                        if isempty(network.mapping) 
                            Y_central_sel_struct.Y = Y;
                            Y_central_sel_struct = putYinCell(setup_data.dset, REG, Y_central_sel_struct);
                            Y_central_sel_struct = computeAcc(Y_central_sel_struct.Y, Y_central_sel_struct.Ypred, acc_dimensions);
                        end
                        
                    end                       
                    
                end
            end
        end
    end
end

%% Store all accuracies together

acc_global = -ones(length(cat_idx_all), length(obj_lists_all));
acc_all = cell(length(cat_idx_all), length(obj_lists_all), length(transf_lists_all), length(day_lists_all), length(camera_lists_all));



%% frameORinst

tobeplotted = [acc_all{1, :, 1, 1, 1}];
tobeplotted = tobeplotted(3,:)';

d1 = zeros(length(tobeplotted),1);
d2 = zeros(length(tobeplotted),1);
cmap = jet(length(tobeplotted));

for itrain=1:length(tobeplotted) 
    d1(itrain, :) = tobeplotted{itrain}(1, 1:2:end);
    d2(itrain, :) = tobeplotted{itrain}(1, 2:2:end);
end

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(2, d1(itrain, :), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
    
    title('day 1')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 3]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);
    h = gca;
    h.XTick = 2;
    
    h.XTickLabel = 'TRANSL';
    
    subplot(1,2,2)
    hold on
    grid on
    
    plot(2, d2(itrain,:), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
   
    title('day 2')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 3]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 2;
    
    h.XTickLabel = 'TRANSL';
    
end

legend({'1:3', '1:7 (same dim)'});

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_1';
%figname = 'framesORtransf_1';
figname = 'framesORinst_1';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')
                    
figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:1
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:length(tobeplotted), d1(:, 1), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
    
    title('day 1')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 2]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:2;
    
    h.XTickLabel = {'1:3', '1:7 (same)'};
    h.XTickLabelRotation = 45; 
    
    subplot(1,2,2)
    hold on
    grid on
   
    plot(1:length(tobeplotted), d2(:, 1), 'o', 'MarkerFace', cmap(itrain,:), 'MarkerEdge', cmap(itrain,:));
    
    title('day 2')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 2]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:2;
    
    h.XTickLabel = {'1:3', '1:7 (same)'};
    h.XTickLabelRotation = 45;
    
end

legend('TRANSL');

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_2';
%figname = 'framesORtransf_2';
figname = 'framesORinst_2';

saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

subplot(1,2,1)
imagesc(d1, [min(min([d1 d2])) max(max([d1 d2]))]);
title('day 1')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1;
h.XTickLabel = {'TRANSL'};
h.YTick = 1:2;
h.YTickLabel = {'1:3', '1:7 (same)'};
colormap(jet);

subplot(1,2,2)
imagesc(d2, [min(min(d2)) max(max(d1))]);
title('day 2')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1;
h.XTickLabel = {'TRANSL'};
h.YTick = 1:2;
h.YTickLabel = {'1:3', '1:7 (same)'};
colormap(jet);
colorbar

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_3';
%figname = 'framesORtransf_3';
figname = 'framesORinst_3';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

%% frameORtransf

tobeplotted = [acc_all{1, 1, :, 1, 1}];
tobeplotted = tobeplotted(3,:)';

d1 = zeros(length(tobeplotted),Ntransfs);
d2 = zeros(length(tobeplotted),Ntransfs);
cmap = jet(length(tobeplotted));

for itrain=1:length(tobeplotted) 
    d1(itrain, :) = tobeplotted{itrain}(1, 1:2:end);
    d2(itrain, :) = tobeplotted{itrain}(1, 2:2:end);
end

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(itrain, :), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);
    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
    subplot(1,2,2)
    hold on
    grid on
    
    plot(1:Ntransfs, d2(itrain,:), 'Color', cmap(itrain,:), 'LineWidth', 2);
   
    title('day 2')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
end

legend({'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'});

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_1';
figname = 'framesORtransf_1';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')
                    
figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
    h.XTickLabelRotation = 45; 
    
    subplot(1,2,2)
    hold on
    grid on
   
    plot(1:Ntransfs, d2(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 2')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
    h.XTickLabelRotation = 45;
    
end

legend(transf_names);

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_2';
figname = 'framesORtransf_2';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

subplot(1,2,1)
imagesc(d1, [min(min([d1 d2])) max(max([d1 d2]))]);
title('day 1')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
colormap(jet);

subplot(1,2,2)
imagesc(d2, [min(min(d2)) max(max(d1))]);
title('day 2')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = {'TR', 'TR + SC', 'TR + SC + ROT2D', 'TR + SC + ROT2D + ROT3D', 'TR + SC +ROT2D + ROT3D + MIX'};
colormap(jet);
colorbar

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
%figname = 'generalization_transf_3';
figname = 'framesORtransf_3';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

%% Generalization across transformations

tobeplotted = [acc_all{1, 1, :, 1, 1}];
tobeplotted = tobeplotted(3,:)';

d1 = zeros(length(tobeplotted),Ntransfs);
d2 = zeros(length(tobeplotted),Ntransfs);
cmap = jet(length(tobeplotted));

for itrain=1:length(tobeplotted) 
    d1(itrain, :) = tobeplotted{itrain}(1, 1:2:end);
    d2(itrain, :) = tobeplotted{itrain}(1, 2:2:end);
end


figure
bar(d2');

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(itrain, :), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);
    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
    subplot(1,2,2)
    hold on
    grid on
    
    plot(1:Ntransfs, d2(itrain,:), 'Color', cmap(itrain,:), 'LineWidth', 2);
   
    title('day 2')
    
    xlabel('test set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
end

legend(transf_names);

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
figname = 'generalization_transf_1';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')
                    
figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

for itrain=1:length(tobeplotted)
    
    subplot(1,2,1)
    hold on
    grid on
    
    plot(1:Ntransfs, d1(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 1')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
    subplot(1,2,2)
    hold on
    grid on
   
    plot(1:Ntransfs, d2(:, itrain), 'Color', cmap(itrain,:), 'LineWidth', 2);
    
    title('day 2')
    
    xlabel('training set');
    ylabel('accuracy');
    xlim([1 Ntransfs]);
    ylim([min(min([d1 d2])) max(max([d1 d2]))]);

    h = gca;
    h.XTick = 1:Ntransfs;
    
    h.XTickLabel = transf_names;
    
end

legend(transf_names);

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
figname = 'generalization_transf_2';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

figure
scrsz = get(groot,'ScreenSize');
set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

subplot(1,2,1)
imagesc(d1, [min(min([d1 d2])) max(max([d1 d2]))]);
title('day 1')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = transf_names;
colormap(jet);

subplot(1,2,2)
imagesc(d2, [min(min(d2)) max(max(d1))]);
title('day 2')
ylabel('training set');
xlabel('test set');
h = gca;
h.XTick = 1:Ntransfs;
h.XTickLabel = transf_names;
h.YTick = 1:Ntransfs;
h.YTickLabel = transf_names;
colormap(jet);
colorbar

output_dir = '/data/giulia/ICUBWORLD_ULTIMATE/prove';
figname = 'generalization_transf_3';
saveas(gcf, fullfile(output_dir, [figname '.fig']));
set(gcf,'PaperPositionMode','auto')
print(fullfile(output_dir, [figname '.png']),'-dpng','-r0')

% tobeplotted = zeros(length(cat_idx_all), length(obj_lists_all), length(transf_lists{3}));
% for icat=1:length(cat_idx_all)
%     for iobj=1:length(obj_lists_all)
%         for idxt=1:length(transf_lists{3})
%             
%             tobeplotted(icat, iobj, idxt) = acc_all{icat, iobj}{5}(1, (idxt-1)*length(day_mappings{3})*length(camera_lists{3})+1);
%             
%         end
%     end
% end
% 
% top = max(max(max(tobeplotted))) ;
% bottom = min(min(min(tobeplotted))) ;
% 
% cmap = jet(length(obj_lists_all));
% figure
% scrsz = get(groot,'ScreenSize');
% set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
% 
% for idxt=1:length(transf_lists{3})
%     
%     subplot(1, length(transf_lists{3}), idxt)
%     hold on
%     for iobj=1:length(obj_lists_all)
%         plot(cellfun(@length, cat_idx_all), squeeze(tobeplotted(:, iobj, idxt)) , '-o', 'Color', cmap(iobj, :), 'MarkerEdgeColor', cmap(iobj, :), 'MarkerFaceColor', cmap(iobj, :));
%     end
%     ylim([bottom top])
%     title(transf_names(transf_lists{3}(idxt)))
%     set(gca, 'XTick', cellfun(@length, cat_idx_all));
% end
% 
% lgnd = cell(length(obj_lists_all), 1);
% for iobj=1:length(obj_lists_all)
%     
%     obj_lists = obj_lists_all{iobj};
%     
%     if strcmp(mapping, 'none') || strcmp(mapping, 'select')
%         lgnd{iobj} = strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-');
%     else
%         lgnd{iobj} = '';
%         for sidx=1:Nsets
%             lgnd{iobj} = [lgnd{iobj} ' ' strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
%         end
%     end
% end
% 
% legend(lgnd);
% 
% stringtitle = {[experiment ', ' mapping ', ' accum_method]};
% 
% suptitle(stringtitle);
% 
% figname = ['acc1_' mapping '_' accum_method];
% 
% saveas(gcf, fullfile(output_dir_root, 'figs/fig', [figname '.fig']));
% set(gcf,'PaperPositionMode','auto')
% print(fullfile(output_dir_root, 'figs/png', [figname '.png']),'-dpng','-r0')
% 
% 
% 
% 
% 
% 
% %% Plot all experiments together
% 
% tobeplotted = zeros(length(cat_idx_all), length(obj_lists_all), length(transf_lists{3}));
% for icat=1:length(cat_idx_all)
%     for iobj=1:length(obj_lists_all)
%         for idxt=1:length(transf_lists{3})
%             
%             tobeplotted(icat, iobj, idxt) = acc_all{icat, iobj}{5}(1, (idxt-1)*length(day_mappings{3})*length(camera_lists{3})+1);
%             
%         end
%     end
% end
% 
% top = max(max(max(tobeplotted))) ;
% bottom = min(min(min(tobeplotted))) ;
% 
% cmap = jet(length(obj_lists_all));
% figure
% scrsz = get(groot,'ScreenSize');
% set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
% 
% for idxt=1:length(transf_lists{3})
%     
%     subplot(1, length(transf_lists{3}), idxt)
%     hold on
%     for iobj=1:length(obj_lists_all)
%         plot(cellfun(@length, cat_idx_all), squeeze(tobeplotted(:, iobj, idxt)) , '-o', 'Color', cmap(iobj, :), 'MarkerEdgeColor', cmap(iobj, :), 'MarkerFaceColor', cmap(iobj, :));
%     end
%     ylim([bottom top])
%     title(transf_names(transf_lists{3}(idxt)))
%     set(gca, 'XTick', cellfun(@length, cat_idx_all));
% end
% 
% lgnd = cell(length(obj_lists_all), 1);
% for iobj=1:length(obj_lists_all)
%     
%     obj_lists = obj_lists_all{iobj};
%     
%     if strcmp(mapping, 'none') || strcmp(mapping, 'select')
%         lgnd{iobj} = strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-');
%     else
%         lgnd{iobj} = '';
%         for sidx=1:Nsets
%             lgnd{iobj} = [lgnd{iobj} ' ' strrep(strrep(num2str(obj_lists{sidx}), '   ', '-'), '  ', '-')];
%         end
%     end
% end
% 
% legend(lgnd);
% 
% stringtitle = {[experiment ', ' mapping ', ' accum_method]};
% 
% suptitle(stringtitle);
% 
% figname = ['acc1_' mapping '_' accum_method];
% 
% saveas(gcf, fullfile(output_dir_root, 'figs/fig', [figname '.fig']));
% set(gcf,'PaperPositionMode','auto')
% print(fullfile(output_dir_root, 'figs/png', [figname '.png']),'-dpng','-r0')






end