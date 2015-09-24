function rawdata = filter_allys_structversion(rawdata, windows, acc_method)

T = size(rawdata,1);

for t=1:T
    
    if isempty(rawdata{t})
        break;
    end
    
    nsubsamples = length([rawdata{t}.acc]);
    
    for s=1:nsubsamples
        
        yclass_pred = rawdata{t}(s).Ypred;
        yclass_true = rawdata{t}(s).Ytrue;
        
        %nsamples = length(yclass_pred);
        nclasses = length(unique(yclass_true));
        
        idclasses = rawdata{t}(s).classes;
        for ii=1:nclasses
            yclass_pred(yclass_pred==idclasses(ii))=ii;
            yclass_true(yclass_true==idclasses(ii))=ii;
        end
        
        I = eye(nclasses);
        y_true = I(yclass_true,:);
    
        %y_true = -ones(nsamples, nclasses);
        %y_indices = sub2ind(size(y_true), 1:nsamples', yclass_true');
        %y_true(y_indices) = 1;
        
        [y_true_mode, y_pred_mode, acc_mode, ~, ~] = filter_y_structversion(y_true, yclass_pred, windows, acc_method);
        
%         for ii=1:nclasses
%             for w=1:length(windows)
%                 y_true_mode{w}(y_true_mode{w}==ii) = idclasses(ii);
%                 y_pred_mode{w}(y_pred_mode{w}==ii) = idclasses(ii);
%             end
%         end
        
        %rawdata{t}(s).Ytrue_mode = y_true_mode;
        %rawdata{t}(s).Ypred_mode = y_pred_mode;
        if size(acc_mode,1)>1
            rawdata{t}(s).acc_mode_perclass = acc_mode;
        else
            rawdata{t}(s).acc_mode = acc_mode;
        end
        
    end
    
    disp(['t ' num2str(t)]);
end
