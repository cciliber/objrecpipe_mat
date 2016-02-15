                    
                    
%                     %% Ypred01
%                     
%                     Nplots = length(cat_idx);
%                     Ncols = min(Nplots, 5);
%                     Nrows = ceil(Nplots/Ncols);
%                     
%                     for idxt=1:length(transf_list)
%                         for idxd=1:length(day_mapping)
%                             for idxe=1:length(camera_list)
%                                 
%                                 it = opts.Transfs(transf_names{transf_list(idxt)});
%                                 ie = opts.Cameras(camera_names{camera_list(idxe)});
%                                 id = opts.Days(day_names{day_mapping(idxd)});
%                                 
%                                 figure( (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe )
%                                 scrsz = get(groot,'ScreenSize');
%                                 set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
%                                 
%                                 for cc=1:Nplots
%                                     
%                                     OO = [Ypred_01{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
%                                     hh = subplot(Nrows, Ncols, cc);
%                                     
%                                     maxW = 1;
%                                     for oo=obj_list
%                                         W = length(OO{oo});
%                                         if W>maxW
%                                             maxW = W;
%                                         end
%                                     end
%                                     
%                                     AA = -ones(length(obj_list), maxW);
%                                     for oo=1:length(obj_list)
%                                         AA(oo, 1:length(OO{obj_list(oo)})) = OO{obj_list(oo)};
%                                     end
%                                     
%                                     imagesc(AA)
%                                     title(cat_names{cat_idx(cc)})
%                                     cmapcomplete = [0 0 0; 1 0 0; 1 1 1]; % -1, 0, 1
%                                     AAvalues = unique(AA);
%                                     if length(AAvalues)<3
%                                         if max(AAvalues)==0
%                                             cmapcomplete(3,:) = [];
%                                         end
%                                         if min(AAvalues)==0
%                                             cmapcomplete(1,:) = [];
%                                         end
%                                         if ~sum(AAvalues==0)
%                                             cmapcomplete(2,:) = [];
%                                         end
%                                     end
%                                     colormap(hh, cmapcomplete);
%                                     
%                                     %ylim([0.5 length(obj_list)+0.5]);
%                                     set(gca, 'YTick', 1:length(obj_list));
%                                     set(gca, 'YTickLabel', cellstr(num2str(obj_list(:)))');
%                                     
%                                 end
%                                 
%                                 stringtitle = {[experiment ', ' mapping ': tr ' transf_names{transf_list(idxt)} ', day ' num2str(day_mapping(idxd)) ', cam ' num2str(camera_list(idxe))]};
%                                 if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
%                                     %stringtitle{end+1} = [set_names_4figs{1} ' - ' set_names_4figs{2}];
%                                     stringtitle{end+1} = set_names_4figs{1};
%                                 end
%                                 if strcmp(mapping, 'NN')
%                                     stringtitle{end} = [stringtitle{end} ' - K = ' num2str(K(icat, iobj))];
%                                 end
%                                 
%                                 suptitle(stringtitle);
%                                 
%                                 figname = ['Ypred01_' mapping '_'];
%                                 figname = [figname strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-')];
%                                 figname = [figname '_tr_' num2str(transf_list(idxt))];
%                                 figname = [figname '_day_' num2str(day_mapping(idxd))];
%                                 figname = [figname '_cam_' num2str(camera_list(idxe))];
%                                 if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
%                                     figname = [figname '_' trainval_prefixes{eval_set}];
%                                     figname = [figname set_names{1} '_' set_names{2}];
%                                 end
%                                 
%                                 saveas(gcf, fullfile(output_dir, 'figs/fig', [figname '.fig']));
%                                 set(gcf,'PaperPositionMode','auto')
%                                 print(fullfile(output_dir, 'figs/png', [figname '.png']),'-dpng','-r0')
%                             end
%                         end
%                     end
%                     
%                     close all
%                     
%                     %% Ypred_4plots, Ytrue_4plots, Ypred_mode, Ypred_avg
%                     
%                     Nplots = length(cat_idx);
%                     Ncols = min(Nplots, 5);
%                     Nrows = ceil(Nplots/Ncols);
%                     
%                     for idxt=1:length(transf_list)
%                         for idxd=1:length(day_mapping)
%                             for idxe=1:length(camera_list)
%                                 
%                                 it = opts.Transfs(transf_names{transf_list(idxt)});
%                                 ie = opts.Cameras(camera_names{camera_list(idxe)});
%                                 id = opts.Days(day_names{day_mapping(idxd)});
%                                 
%                                 figure( (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe )
%                                 scrsz = get(groot,'ScreenSize');
%                                 set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
%                                 
%                                 for cc=1:length(cat_idx)
%                                     
%                                     OO = [Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
%                                     
%                                     TT = Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie);
%                                     MODE = [Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
%                                     if compute_avg
%                                         AVG = [Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie)];
%                                     end
%                                     
%                                     hh1 = subplot(Nrows, 2*Ncols, 2*cc-1);
%                                     
%                                     maxW = 1;
%                                     for oo=obj_list
%                                         W = length(OO{oo});
%                                         if W>maxW
%                                             maxW = W;
%                                         end
%                                     end
%                                     
%                                     AA = -ones(length(obj_list), maxW);
%                                     for oo=1:length(obj_list)
%                                         AA(oo, 1:length(OO{obj_list(oo)})) = OO{obj_list(oo)};
%                                     end
%                                     
%                                     imagesc(AA, [-1 Nlbls-1])
%                                     title(cat_names{cat_idx(cc)})
%                                     cmap = colormap(hh1, [0 0 0; jet(double(Nlbls))]);
%                                     %ylim([0.5 length(obj_list)+0.5]);
%                                     set(gca, 'YTick', 1:length(obj_list));
%                                     set(gca, 'YTickLabel', cellstr(num2str(obj_list(:)))');
%                                     
%                                     hh2 = subplot(Nrows, 2*Ncols, 2*cc);
%                                     
%                                     if compute_avg
%                                         AA = -ones(length(obj_list), 3);
%                                     else
%                                         AA = -ones(length(obj_list), 2);
%                                     end
%                                     for oo=1:length(obj_list)
%                                         AA(oo, 1) = TT(obj_list(oo));
%                                         AA(oo, 2) = MODE{obj_list(oo)};
%                                         if compute_avg
%                                             AA(oo, 3) = AVG{obj_list(oo)};
%                                         end
%                                     end
%                                     
%                                     imagesc(AA, [0 Nlbls-1])
%                                     title(cat_names{cat_idx(cc)})
%                                     colormap(hh2, cmap(2:end, :));
%                                     %ylim([0.5 length(obj_list)+0.5]);
%                                     set(gca, 'YTick', 1:length(obj_list));
%                                     ax = get(gca, 'Position');
%                                     ax(3) = ax(3)/2;
%                                     set(gca, 'Position', ax);
%                                     set(gca, 'YTickLabel', cellstr(num2str(obj_list(:)))');
%                                     if compute_avg
%                                         set(gca, 'XTickLabel', {'true', 'mode', 'avg'});
%                                     else
%                                         set(gca, 'XTickLabel', {'true', 'mode'});
%                                     end
%                                     
%                                 end
%                                 
%                                 stringtitle = {[experiment ', ' mapping ': tr ' transf_names{transf_list(idxt)} ', day ' num2str(day_mapping(idxd)) ', cam ' num2str(camera_list(idxe))]};
%                                 if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
%                                      %stringtitle{end+1} = [set_names_4figs{1} ' - ' set_names_4figs{2}];
%                                      stringtitle{end+1} = set_names_4figs{1};
%                                 end
%                                 if strcmp(mapping, 'NN')
%                                     stringtitle{end} = [stringtitle{end} ' - K = ' num2str(K(icat, iobj))];
%                                 end
%                                 
%                                 suptitle(stringtitle);
%                                 
%                                 if use_imnetlabels
%                                     figname = ['Ypredimnet_' mapping '_'];
%                                 else
%                                     figname = ['Ypred_' mapping '_'];
%                                 end
%                                 figname = [figname strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-')];
%                                 figname = [figname '_tr_' num2str(transf_list(idxt))];
%                                 figname = [figname '_day_' num2str(day_mapping(idxd))];
%                                 figname = [figname '_cam_' num2str(camera_list(idxe))];
%                                 if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
%                                     figname = [figname '_' trainval_prefixes{eval_set}];
%                                     figname = [figname set_names{1} '_' set_names{2}];
%                                 end
%                                 
%                                 saveas(gcf, fullfile(output_dir, 'figs/fig', [figname '.fig']));
%                                 set(gcf,'PaperPositionMode','auto')
%                                 print(fullfile(output_dir, 'figs/png', [figname '.png']),'-dpng','-r0')
%                             end
%                         end
%                     end
%                     
%                     close all