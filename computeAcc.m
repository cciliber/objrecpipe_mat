function [A, A_xclass, C] = computeAcc(cellY, cellYpred, nclasses, cells_sel, dimensions)


%% Check
Ydim = numel(size(cellY));
if Ydim~=numel(size(cellYpred))
    error('cellY and cellYpred have different dimensions!');
end
if Ydim~=numel(cells_sel)
    error('cellY and cells_sel have different dimensions!');
end
% then remember to check for every accuracy that the dimensions are < maxD

%% Assign number of elements per dimension
N = zeros(Ydim,1);
cells_pool = cell(Ydim,1);
for idim=1:dimY
    
    N(idim) = size(cells_sel,idim);
    cells_pool{idim} = ones(N(idim),1);
    
    if size(cellY,idim)~=size(cellYpred,idim)
        error('Sizes of cellY and cellYpred are not consistent!');
    end
    if sum(cells_sel{idim}>size(cellY,idim))
        error('cells_sel is out of Ys range!');
    end 
    
end

%% Allocate memory for the accuracies
Nacc = numel(dimensions);
A = cell(Nacc,1);
A_xclass = cell(Nacc,1);
C = cell(Nacc,1);

%% Go!

for iacc=1:Nacc
    
    % vector containing the dimensions to average on (:)
    dims_toaverage = dimensions{iacc};
    
    if sum(dims_toaverage>Ydim)
        error('dims_toaverage out of Y range!');
    end
    
    pool = cells_pool;
    if ~isempty(dims_toaverage)
        for idim=1:numel(dims_toaverage)
            pool{dims_toaverage{idim}} = N(dims_toaverage{idim});
        end
    end
   
    
    ypred = cellYpred(cells_sel{1}, cells_sel{2}, cells_sel{3}, cells_sel{4}, cells_sel{5});
    ypred = mat2cell(ypred, pool{1}, pool{2}, pool{3}, pool{4}, pool{5});
    
    y = cellY(cells_sel{1}, cells_sel{2}, cells_sel{3}, cells_sel{4}, cells_sel{5});
    y = mat2cell(y, pool{1}, pool{2}, pool{3}, pool{4}, pool{5});
    
    
    ypred = cellfun(@unroll, ypred, 'UniformOutput', 0);
    y = cellfun(@unroll, y, 'UniformOutput', 0);                
    
    
    [A, A_xclass, C] = cellfun(@trace_confusion, y, ypred, repmat({nclasses}, size(y)), 'UniformOutput', 0);
    
    size(A) = size(ypred) = pool{1}, pool{2}, pool{3}, pool{4}, pool{5}
    
    
    AA{1}((cc-1)*length(obj_list)+idxo,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe)
    
end

%     for cc=1:length(cat_idx)
%         for idxo=1:length(obj_list)
%             for idxt =1:length(transf_list)
%                 for idxd=1:length(day_mapping)
%                     for idxe=1:length(camera_list)
%                     
%                     ic = opts.Cat(cat_names{cat_idx(cc)});
%                     io = obj_list(idxo);
%                     it = opts.Transfs(transf_names{transf_list(idxt)});
%                     ie = opts.Cameras(camera_names{camera_list(idxe)});
%                     id = opts.Days(day_names{day_mapping(idxd)});
%                     
%                     
%                     ypred = Ypred{ic, io, it, id , ie};
%                     
%                     ytrue = Ytrue{ic, io, it, id , ie}; 
%                     ytrue = repmat(ytrue, length(ypred), 1);
%                     
%                     trace_confusion(ytrue, ypred, Nclasses);
%                     
%                     
%                     
%                     AA{1}((cc-1)*length(obj_list)+idxo,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = 
%                     
%                     
%                 end
%             end
%         end
%         
%     end
% end
% 
for i1=1:3
    for i2=1:4
        for i3=1:5
            for i4=1:6
                prova{i1,i2,i3,i4} = [i1 i2 i3 i4]';
            end
        end
    end
end
% 
% 
% 
% % accuracy frame-based xCat xObj xTr xDay
% for cc=1:length(cat_idx)
%     for idxo=1:length(obj_list)
%         for idxt =1:length(transf_list)
%             for idxd=1:length(day_mapping)
%                 
%                 io = obj_list(idxo);
%                 it = opts.Transfs(transf_names{transf_list(idxt)});
%                 id = opts.Days(day_names{day_mapping(idxd)});
%                 
%                 if strcmp(accum_method, 'none')
%                     ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
%                 elseif strcmp(accum_method, 'mode')
%                     ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
%                 elseif compute_avg && strcmp(accum_method, 'avg')
%                     ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :))];
%                 end
%                 ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, id , :));
%                 foo = ones(size(ytrue));
%                 nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
%                 ytrue = cellfun(@repmat, mat2cell(ytrue, foo), nfrxdir, mat2cell(foo, foo), 'UniformOutput', 0);
%                 
%                 ypred = cell2mat(ypred(:));
%                 ytrue = cell2mat(ytrue(:));
%                 
%                 rowidx = (cc-1)*length(obj_list)+idxo;
%                 colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+1;
%                 colidx2 = colidx1+(length(camera_list)-1);
%                 colidx = colidx1:colidx2;
%                 a = compute_accuracy(ytrue, ypred, 'gurls');
%                 AA{2}(rowidx,colidx) = repmat(a, 1, length(camera_list));
%                 
%                 
%             end
%         end
%     end
% end
% 
%                     % accuracy frame-based xCat xObj xTr
%                     for cc=1:length(cat_idx)
%                         for idxo=1:length(obj_list)
%                             for idxt =1:length(transf_list)
% 
%                                 io = obj_list(idxo);
%                                 it = opts.Transfs(transf_names{transf_list(idxt)});
% 
%                                 if strcmp(accum_method, 'none')
%                                     ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
%                                 elseif strcmp(accum_method, 'mode')
%                                     ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
%                                 elseif compute_avg && strcmp(accum_method, 'avg')
%                                     ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(io, it, :, :))];
%                                 end
%                                 ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(io, it, : , :));
% 
%                                 foo = ones(size(ytrue));
%                                 foo1 = ones(size(ytrue,1),1);
%                                 foo2 = ones(size(ytrue,2),1);
%                                 nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
%                                 ytrue = cellfun(@repmat, mat2cell(ytrue, foo1, foo2), nfrxdir, mat2cell(foo, foo1, foo2), 'UniformOutput', 0);
% 
%                                 ypred = cell2mat(ypred(:));
%                                 ytrue = cell2mat(ytrue(:));
% 
%                                 rowidx = (cc-1)*length(obj_list)+idxo;
%                                 colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
%                                 colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
%                                 colidx = colidx1:colidx2;
%                                 a = compute_accuracy(ytrue, ypred, 'gurls');
%                                 AA{3}(rowidx,colidx) = repmat(a, 1, length(camera_list)*length(day_mapping));
% 
%                             end
%                         end
%                     end
% 
%                     % accuracy frame-based xCat xTr
%                     for cc=1:length(cat_idx)
%                         for idxt =1:length(transf_list)
% 
%                             it = opts.Transfs(transf_names{transf_list(idxt)});
% 
%                             if strcmp(accum_method, 'none')
%                                 ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             elseif strcmp(accum_method, 'mode')
%                                 ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             elseif compute_avg && strcmp(accum_method, 'avg')
%                                 ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%                             end
% 
%                             ytrue = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
% 
%                             foo = ones(size(ytrue));
%                             foo1 = ones(size(ytrue,1),1);
%                             foo2 = ones(size(ytrue,2),1);
%                             foo3 = ones(size(ytrue,3),1);
%                             nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
%                             ytrue = cellfun(@repmat, mat2cell(ytrue, foo1, foo2, foo3), nfrxdir, mat2cell(foo, foo1, foo2, foo3), 'UniformOutput', 0);
% 
%                             ypred = cell2mat(ypred(:));
%                             ytrue = cell2mat(ytrue(:));
% 
%                             rowidx1 = (cc-1)*length(obj_list)+1;
%                             rowidx2 = rowidx1+length(obj_list)-1;
%                             rowidx = rowidx1:rowidx2;
%                             colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
%                             colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
%                             colidx = colidx1:colidx2;
%                             a = compute_accuracy(ytrue, ypred, 'gurls');
%                             AA{4}(rowidx,colidx) = repmat(a, length(obj_list), length(camera_list)*length(day_mapping));
% 
%                         end
%                     end
% 
% % accuracy frame-based xCat xTr xDay xCam
% for cc=1:length(cat_idx)
%     for idxt =1:length(transf_list)
%         for idxd=1:length(day_mapping)
%             for idxe=1:length(camera_list)
%                 
%                 it = opts.Transfs(transf_names{transf_list(idxt)});
%                 ie = opts.Cameras(camera_names{camera_list(idxe)});
%                 id = opts.Days(day_names{day_mapping(idxd)});
%                 
%                 if strcmp(accum_method, 'none')
%                     ypred = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
%                 elseif strcmp(accum_method, 'mode')
%                     ypred = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
%                 elseif compute_avg && strcmp(accum_method, 'avg')
%                     ypred = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
%                 end
%                 
%                 ytrue = squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie));
%                 
%                 foo = ones(size(ytrue));
%                 nfrxdir = cellfun(@length, ypred, 'UniformOutput', 0);
%                 ytrue = cellfun(@repmat, mat2cell(ytrue, foo), nfrxdir, mat2cell(foo, foo), 'UniformOutput', 0);
%                 
%                 ypred = cell2mat(ypred(:));
%                 ytrue = cell2mat(ytrue(:));
%                 
%                 rowidx1 = (cc-1)*length(obj_list)+1;
%                 rowidx2 = rowidx1+length(obj_list)-1;
%                 rowidx = rowidx1:rowidx2;
%                 a = compute_accuracy(ytrue, ypred, 'gurls');
%                 AA{2}(rowidx,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = repmat(a, length(obj_list), 1);
%                 
%             end
%         end
%     end
% end
% 
% % accuracy frame-based xTr xDay xCam
% for idxt =1:length(transf_list)
%     for idxd=1:length(day_mapping)
%         for idxe=1:length(camera_list)
%             
%             it = opts.Transfs(transf_names{transf_list(idxt)});
%             ie = opts.Cameras(camera_names{camera_list(idxe)});
%             id = opts.Days(day_names{day_mapping(idxd)});
%             
%             ypred = cell(length(cat_idx),1);
%             ytrue = cell(length(cat_idx),1);
%             for cc=1:length(cat_idx)
%                 
%                 if strcmp(accum_method, 'none')
%                     ypred{cc} = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
%                 elseif strcmp(accum_method, 'mode')
%                     ypred{cc} = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
%                 elseif compute_avg && strcmp(accum_method, 'avg')
%                     ypred{cc} = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id ,ie))];
%                 end
%                 
%                 ytrue{cc} = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, id, ie))];
%                 
%                 foo = ones(size(ytrue{cc}));
%                 nfrxdir = cellfun(@length, ypred{cc}, 'UniformOutput', 0);
%                 ytrue{cc} = cellfun(@repmat, mat2cell(ytrue{cc}, foo), nfrxdir, mat2cell(foo, foo), 'UniformOutput', 0);
%                 
%                 ypred{cc} = cell2mat(ypred{cc}(:));
%                 ytrue{cc} = cell2mat(ytrue{cc}(:));
%             end
%             
%             ypred = cell2mat(ypred);
%             ytrue = cell2mat(ytrue);
%             
%             rowidx1 = 1;
%             rowidx2 = rowidx1+length(obj_list)*length(cat_idx)-1;
%             rowidx = rowidx1:rowidx2;
%             a = compute_accuracy(ytrue, ypred, 'gurls');
%             AA{3}(rowidx,(idxt-1)*length(day_mapping)*length(camera_list)+(idxd-1)*length(camera_list)+idxe) = repmat(a, length(obj_list)*length(cat_idx), 1);
%             
%         end
%     end
% end
% 
% % accuracy frame-based xTr
% for idxt =1:length(transf_list)
%     
%     it = opts.Transfs(transf_names{transf_list(idxt)});
%     
%     ypred = cell(length(cat_idx),1);
%     ytrue = cell(length(cat_idx),1);
%     for cc=1:length(cat_idx)
%         
%         if strcmp(accum_method, 'none')
%             ypred{cc} = [squeeze(Ypred_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%         elseif strcmp(accum_method, 'mode')
%             ypred{cc} = [squeeze(Ypred_mode{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%         elseif compute_avg && strcmp(accum_method, 'avg')
%             ypred{cc} = [squeeze(Ypred_avg{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%         end
%         ytrue{cc} = [squeeze(Ytrue_4plots{opts.Cat(cat_names{cat_idx(cc)})}(:, it, :, :))];
%         
%         foo = ones(size(ytrue{cc}));
%         foo1 = ones(size(ytrue{cc},1),1);
%         foo2 = ones(size(ytrue{cc},2),1);
%         foo3 = ones(size(ytrue{cc},3),1);
%         nfrxdir = cellfun(@length, ypred{cc}, 'UniformOutput', 0);
%         ytrue{cc} = cellfun(@repmat, mat2cell(ytrue{cc}, foo1, foo2, foo3), nfrxdir, mat2cell(foo, foo1, foo2, foo3), 'UniformOutput', 0);
%         
%         ypred{cc} = cell2mat(ypred{cc}(:));
%         ytrue{cc} = cell2mat(ytrue{cc}(:));
%         
%     end
%     
%     ypred = cell2mat(ypred);
%     ytrue = cell2mat(ytrue);
%     
%     rowidx1 = 1;
%     rowidx2 = rowidx1+length(obj_list)*length(cat_idx)-1;
%     rowidx = rowidx1:rowidx2;
%     colidx1 = (idxt-1)*length(day_mapping)*length(camera_list)+1;
%     colidx2 = colidx1+length(camera_list)*length(day_mapping)-1;
%     colidx = colidx1:colidx2;
%     a = compute_accuracy(ytrue, ypred, 'gurls');
%     AA{7}(rowidx,colidx) = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping));
%     
% end
% 
% % accuracy frame-based
% 
% if strcmp(accum_method, 'none')
%     a = compute_accuracy(cell2mat(Y), cell2mat(Ypred), 'gurls');
% elseif strcmp(accum_method, 'mode')
%     
% elseif compute_avg && strcmp(accum_method, 'avg')
%     
% end
% 
% AA{8} = repmat(a, length(obj_list)*length(cat_idx), length(camera_list)*length(day_mapping)*length(transf_list));
% 
% %% plot and save
% 
% AA = cell(Nplots,1);
% for ii=1:Nplots
%     AA{ii} = zeros(length(cat_idx)*length(obj_list), length(transf_list)*length(camera_list)*length(day_mapping));
% end
% 
% Nplots = 3;
% Ncols = 3;
% Nrows =  ceil(Nplots/Ncols);
% 
% bottom = 1;
% top = 0;
% for ii=1:Nplots
%     bottom = min(bottom, min(min(AA{ii})));
%     top = max(top, max(max(AA{ii})));
% end
% 
% figure
% scrsz = get(groot,'ScreenSize');
% set(gcf, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
% 
% for ii=1:Nplots
%     subplot(Nrows, Ncols, ii)
%     imagesc(AA{ii}, [bottom top]);
%     %imagesc(AA{ii});
%     
%     set(gca, 'YTick', 1:length(cat_idx)*length(obj_list));
%     ytl = cat_names(cat_idx);
%     ytl = ytl(:)';
%     ytl = repmat(ytl, length(obj_list), 1);
%     ytl = strcat(ytl(:), repmat(strrep(cellstr(num2str(obj_list(:))), ' ' , ''), length(cat_idx), 1));
%     set(gca, 'YTickLabel', ytl);
%     set(gca, 'XTick', 1:length(camera_list)*length(day_mapping):length(transf_list)*length(camera_list)*length(day_mapping));
%     set(gca, 'XTickLabel', transf_names(transf_list));
%     
% end
% colormap(jet);
% colorbar
% 
% stringtitle = {['categorization' ', ' mapping ', ' accum_method]};
% if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
%     %stringtitle{end+1} = [set_names_4figs{1} ' - ' set_names_4figs{2}];
%     stringtitle{end+1} = set_names_4figs{1};
% end
% if strcmp(mapping, 'NN')
%     stringtitle{end} = [stringtitle{end} ' - K = ' num2str(K(icat, iobj))];
% end
% 
% suptitle(stringtitle);
% 
% figname = ['acc_' mapping '_' accum_method '_'];
% figname = [figname strrep(strrep(num2str(obj_lists{eval_set}), '   ', '-'), '  ', '-')];
% if ~strcmp(mapping, 'none') && ~strcmp(mapping, 'select')
%     figname = [figname '_' trainval_prefixes{eval_set}];
%     figname = [figname set_names{1} '_' set_names{2}];
% end
% 
% saveas(gcf, fullfile(output_dir, 'figs/fig', [figname '.fig']));
% set(gcf,'PaperPositionMode','auto')
% print(fullfile(output_dir, 'figs/png', [figname '.png']),'-dpng','-r0')
% 
% acc_all{icat, iobj, itransf, iday, icam} = AA;