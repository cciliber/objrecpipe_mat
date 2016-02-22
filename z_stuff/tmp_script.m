
selected_day = 1;


selected_transformation = setup_data.dset.Transfs('TRANSL');


ntr = 10;

scores = [];
scores_big = [];
for idx_result = selected_result
    % Plot results

    ncats = numel(unique(results{idx_result}.labels_matrix(:,1)));
    
    Xtr = [];
    Ytr = [];
    Xts = [];
    Yts = [];
    for idx_cat = 1:ncats

        select_idx_cat = results{idx_result}.labels_matrix(:,1)==idx_cat;

        for idx_transf = 1:5

            select_idx_transf = results{idx_result}.labels_matrix(:,3)==idx_transf;

            select_idx_joint = (select_idx_transf.*select_idx_cat);

  
            if idx_transf == selected_transformation
                
                tmpXtr = results{idx_result}.feature_matrix(select_idx_joint==1,:);
                if ntr>0
                    tmpXtr = tmpXtr(1:ntr,:);
%                     tmpXtr = tmpXtr(randperm(ntr,size(tmpXtr)),:);
                end
                
                Xtr = [Xtr; tmpXtr];
                Ytr = [Ytr; idx_cat * ones( size(tmpXtr,1) , 1 )];

                
%                 Xtr = [Xtr; results{idx_result}.feature_matrix(select_idx_joint==1,:)];
%                 Ytr = [Ytr; idx_cat * ones( sum(select_idx_joint) , 1 )];
                
                
            else
                Xts = [Xts; results{idx_result}.feature_matrix(select_idx_joint==1,:)];
                Yts = [Yts; idx_cat * ones( sum(select_idx_joint) , 1 )];
            end

        end 
        
        display(idx_cat);
    end
    
    
    

    % learn and predict
    model = gurls_train(Xtr,Ytr);
    YpredRLS = gurls_test(model,Xts);
    
    [~,YpredRLS_class] = max(YpredRLS,[],2);  
    
    C = confusionmat(Yts_selected,YpredRLS_class);

    C = C./repmat(sum(C,2),1,size(C,2));

    scores(end+1) = trace(C)/size(C,1)
    
end


