function [y_filt_class, ypred_filt_class, acc_filt] = filter_y_slow(y, ypred, windows)

[~, y_class] = max(y, [], 2);
[~, ypred_class] = max(ypred, [], 2); 
      
n_classes = size(y,2); % or length(classes)

n_windows = length(windows);

y_filt_class = cell(n_windows, 1);
ypred_filt_class = cell(n_windows, 1);
acc_filt = cell(3, n_windows, 1);

[classes, iy, ~] = unique(y_class); % [C,ia,ic]=unique(A); C = A(ia) A = C(ic)

for idx_window=1:n_windows
    
    % filter each class with fixed window 
    
    w = windows(idx_window);
    halfw = (w-1)/2;
    y_filt_class{idx_window} = zeros(size(y_class));
    ypred_filt_class{idx_window} = zeros(size(ypred_class));
    
    for idx_class=1:n_classes-1
       % pad with 0 the first halfw positions (hp: classes idxs start from 1)
       y_filt_class{idx_window}(iy(idx_class):(iy(idx_class+1)-1)) = nl_causal_digital_filt(y_class(iy(idx_class):(iy(idx_class+1)-1)), w, @mode, 0);
       ypred_filt_class{idx_window}(iy(idx_class):(iy(idx_class+1)-1)) = nl_causal_digital_filt(ypred_class(iy(idx_class):(iy(idx_class+1)-1)), w, @mode, 0);
    end
    y_filt_class{idx_window}(iy(n_classes):end) = nl_causal_digital_filt(y_class(iy(n_classes):end), w, @mode, 0);
    ypred_filt_class{idx_window}(iy(n_classes):end) = nl_causal_digital_filt(ypred_class(iy(n_classes):end), w, @mode, 0);
       
    % compute accuracy
    
    % temporarily delete padded 0s 
    y_filt_class_tmp =  y_filt_class{idx_window};
    ypred_filt_class_tmp =  ypred_filt_class{idx_window};
    y_filt_class_tmp(y_filt_class_tmp==0) = [];
    ypred_filt_class_tmp(ypred_filt_class_tmp==0) = [];
    
    frames_per_class = hist(y_filt_class_tmp, classes);
    n_frames = size(y_filt_class_tmp,1); % or sum(frames_per_class)
    
    % method 1
    y_filt = -ones(n_frames, n_classes);
    ypred_filt = -ones(n_frames, n_classes);
    y_indices = sub2ind(size(y_filt), 1:n_frames, y_filt_class_tmp');
    ypred_indices = sub2ind(size(ypred_filt), 1:n_frames, ypred_filt_class_tmp');
    y_filt(y_indices) = 1;
    ypred_filt(ypred_indices) = 1;
    
    acc_filt{1, idx_window} = mean(sum(ypred_filt==y_filt, 1)/n_frames);
    
    % method 2
    
    C = accumarray([y_filt_class_tmp,ypred_filt_class_tmp],ones(n_frames,1),[n_classes,n_classes]);
    acc_filt{2, idx_window} = sum(diag(C)) / sum(C(:));
    
    % method 3
    
    acc = zeros(1, n_classes);
    for i = 1:n_classes,
        acc(i) = sum((y_filt_class_tmp == i) & (ypred_filt_class_tmp == i))/(sum(y_filt_class_tmp == i) + eps);
    end 
    acc_filt{3, idx_window} = mean(acc);

end

% for idx_window=1:n_windows
%       
%     % filter
%     
%     w = windows(idx_window);
%     halfw = (w-1)/2;
%     y_filt_class{idx_window} = colfilt(y_class, [w 1], 'sliding', @mode);
%     ypred_filt_class{idx_window} = colfilt(ypred_class, [w 1], 'sliding', @mode);
%     
%     y_filt_class{idx_window}(1:halfw) = [];
%     y_filt_class{idx_window}(end:-1:(end-halfw+1)) = [];
%     ypred_filt_class{idx_window}(1:halfw) = [];
%     ypred_filt_class{idx_window}(end:-1:(end-halfw+1)) = [];
%     
%     % accuracy
%     
%     n_frames = size(y,1)-(w-1);
%     y_filt = -ones(n_frames, n_classes);
%     ypred_filt = -ones(n_frames, n_classes);
%     
%     y_indices = sub2ind(size(y_filt), 1:n_frames, y_filt_class{idx_window}');
%     ypred_indices = sub2ind(size(ypred_filt), 1:n_frames, ypred_filt_class{idx_window}');
%     
%     y_filt(y_indices) = 1;
%     ypred_filt(ypred_indices) = 1;
%     
%     acc_filt{idx_window} = sum(ypred_filt==y_filt, 1)/n_frames;
% end

end

