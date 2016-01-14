

function [Acc] = tuple_rls(Xtr,Xts,nmax_per_class,starting_tuple,tuple_step,Acc)

    if nargin<4
        starting_tuple=1;
    end
    
    if nargin<5
        tuple_step = Inf;
    end


    %we expect a Xtr Xts to be cells divided by class
    
    
    d = size(Xtr{1},2);

    T = numel(Xtr);
    
    if nargin<6 || isempty(Acc)
        Acc = cell(T-1,1);
    end
    
    for t=1:T
       Xtr{t}((nmax_per_class+1):end,:)=[]; 
    end
    
    % set all test examples to the same number
%     min_n_tr=n_per_class;
%     min_n_ts=Inf;
%     for t=1:T
%         n_tr = size(Xtr{t},1);
%         if min_n_tr>n_tr
%             min_n_tr = n_tr;
%         end
%         
%         n_ts = size(Xts{t},1);
%         if min_n_ts>n_ts
%             min_n_ts = n_ts;
%         end
%     end
%     n_tr = min_n_tr;
%     n_ts = min_n_ts;
%     
%     
%     Xtr = cellfun(@(X)X(1:n_tr,:),Xtr,'UniformOutput',0);
%     Ytr_codes = kron(eye(T),ones(n_tr,1));
%     Xts = cellfun(@(X)X(1:n_ts,:),Xts,'UniformOutput',0);
%     Yts_codes = kron(eye(T),ones(n_ts,1));
%     
%     idx_n = 1:n_tr;
%     
    
            
    
    
    %increase the number of classes starting from binary problems
    for t=T
 
        %output codes matrix
        %Y = Ytr_codes(1:(n_tr*t),1:t);
        %[~,tuple_Yts] = max(Yts_codes(1:(n_ts*t),1:t),[],2);
        
        
        %subsample from the set of possible tuples
        %tuples_c = subsample_tuples(t,T,subsample_ratio,subsample_min,subsample_max);
        tuples_c = load_tuples(t);
        
        ending_tuple = starting_tuple+tuple_step-1;
        if ending_tuple>numel(tuples_c)
            ending_tuple = numel(tuples_c);
        end
        
        tuples_c = tuples_c(starting_tuple:ending_tuple);
        
        tmp_acc = struct('acc',[],'classes',[],'Ypred',[],'Ytrue',[]);
        
        %for each tuple perform the experiment
        for idx_tuple = 1:numel(tuples_c)
            fprintf('t = %d test n. %d/%d\n',t,idx_tuple,numel(tuples_c));
            %select the samples to be used for training
            X = cell2mat(Xtr(tuples_c{idx_tuple}));
            Y = cell(t,1);
            tuple_Yts = cell(t,1);
            for idx_t=1:t
                Y{idx_t} = idx_t*ones(size(Xtr{tuples_c{idx_tuple}(idx_t)},1),1);
                tuple_Yts{idx_t} = idx_t*ones(size(Xts{tuples_c{idx_tuple}(idx_t)},1),1);
            end
            
            tuple_Yts = cell2mat(tuple_Yts);
            Y = cell2mat(Y);
            
            %X = [X ones(size(X,1),1)];            
            
            tuple_Xts = cell2mat(Xts(tuples_c{idx_tuple}));
            %tuple_Xts = [tuple_Xts ones(size(tuple_Xts,1),1)];
            
            model = gurls_train(X,Y,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',0);
            Ypred = gurls_test(model,tuple_Xts);
            
            % Compute the confusion matrix
            acc = trace_confusion(tuple_Yts,Ypred);
            
            
            tmp_acc(idx_tuple).acc = acc;
            tmp_acc(idx_tuple).classes = tuples_c{idx_tuple};
            tmp_acc(idx_tuple).Ypred = tuples_c{idx_tuple}(Ypred);
            tmp_acc(idx_tuple).Ytrue = tuples_c{idx_tuple}(tuple_Yts);
            
        end
        
        
        fprintf('\n');
        
        if numel(tuples_c)>0
            Acc{t-1} = [Acc{t-1} tmp_acc];
        end   
        %[Acc{t-1}.acc]
 
    end
    
    
    
    
    
    
end
    




