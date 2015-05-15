function [y_filt_class, ypred_filt_class, acc_filt, y_filtered_mat, ypred_filtered_mat] = filter_y(y, ypred, windows, acc_method)
    

    [~, y_class] = max(y, [], 2);
    [~, ypred_class] = max(ypred, [], 2); 

    
    
    [n_samples,n_classes] = size(y);

    
    I = eye(n_classes);
    ypred = I(ypred_class,:);
    
    
    
    n_windows = length(windows);

    y_filt_class = cell(n_windows, 1);
    ypred_filt_class = cell(n_windows, 1);
    if strcmp(acc_method, 'gurls_perclass')
        acc_filt = zeros(n_classes, n_windows);
    else
        acc_filt = zeros(1, n_windows);
    end

    [classes, iy, ~] = unique(y_class); % [C,ia,ic]=unique(A); C = A(ia) A = C(ic)

    % just imagesc these two matrices to see how labels are filtered
    y_filtered_mat = zeros(n_samples,n_windows);
    ypred_filtered_mat = zeros(n_samples,n_windows);


    % for each window size
    for idx_window=1:n_windows

        w = windows(idx_window);
        
        y_filtered = conv2(y,ones(w,1));
        y_filtered = y_filtered(1:n_samples,:);
        %y_filtered((end-w+2):end,:) = [];        
        [~,y_filtered_idx] = max(y_filtered,[],2);
        
        ypred_filtered = conv2(ypred,ones(w,1));
        ypred_filtered = ypred_filtered(1:n_samples,:);
        %ypred_filtered((end-w+2):end,:) = [];
        [~,ypred_filtered_idx] = max(ypred_filtered,[],2);
        
        % create the zero-indexing matrix
        zero_indices = repmat(iy,1,w-1) + repmat(1:(w-1),n_classes,1)-1;
        zero_indices = zero_indices';
        zero_indices = zero_indices(:);
        
        if length(zero_indices)>n_samples
            zero_indices = zero_indices(1:n_samples);
        end
        
        y_filtered_idx(zero_indices)=0;
        ypred_filtered_idx(zero_indices)=0;
        
        y_filtered_mat(:,idx_window) = y_filtered_idx;
        ypred_filtered_mat(:,idx_window) = ypred_filtered_idx;
        
        y_filt_class{idx_window} = y_filtered_idx;
        ypred_filt_class{idx_window} = ypred_filtered_idx;

        
        %tmp stuff
        nopad_y_filtered_idx = y_filtered_idx;
        nopad_y_filtered_idx(nopad_y_filtered_idx==0)=[];
        nopad_ypred_filtered_idx = ypred_filtered_idx;
        nopad_ypred_filtered_idx(nopad_ypred_filtered_idx==0)=[];
        
        n_nopad_frames = length(nopad_y_filtered_idx);
           
        if strcmp(acc_method, 'carlo')
        
            C = accumarray([nopad_y_filtered_idx,nopad_ypred_filtered_idx],ones(n_nopad_frames,1),[n_classes,n_classes]);
            acc_filt(idx_window) = sum(diag(C)) / sum(C(:));

        elseif strncmp(acc_method, 'gurls', 5)
    
            acc = zeros(1,n_classes);
            for i = 1:n_classes,
                acc(i) = sum((nopad_y_filtered_idx == i) & (nopad_ypred_filtered_idx == i))/(sum(nopad_y_filtered_idx == i) + eps);
            end 
            if strcmp(acc_method, 'gurls_perclass')
                acc_filt(:, idx_window) = acc;
            else
                acc_filt(idx_window) = mean(acc);
            end
        end
        
    end

end










