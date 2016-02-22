

RES = results{selected_net}.RES;


selected_transf = [1 2 3 4 5];

selected_transf_test = selected_transf;
selected_transf_train = 1;


y = zeros(numel(selected_transf_test),numel(selected_transf_train));

idx_cat = 1;

for idx_test_transf = 1:numel(selected_transf_test)
    for idx_train_transf = 1:numel(selected_transf_train)
   
        
        tmp_avg_res = zeros(size(RES,2),1);
        
        for idx_res = 1:size(RES,2)
            tmp_avg_res(idx_res) = RES(1,idx_res,selected_transf_train(idx_train_transf)).Y_avg_struct.acc_new{3}(selected_transf_test(idx_test_transf));
        end
            
        y(idx_test_transf,idx_train_transf) = mean(tmp_avg_res);        

        
%         
%        display([idx_test_transf     mean(tmp_avg_res)]);
    end
end


% 
% figure(133);
figure;
title('Performance across modality');
bar(y)

axis([0 size(y,1)+1 0 1]);


%%


selected_transf = [1 2 3 4 5];

selected_transf_test = selected_transf;
selected_transf_train = 1;

y = zeros(numel(selected_transf_test),numel(selected_net));

legend_str = {};

for idx_RES = 1:numel(selected_net)

    legend_str{end+1} = network{selected_net(idx_RES)}.network_dir;
    
    RES = results{selected_net(idx_RES)}.RES;

    idx_cat = 1;

    for idx_test_transf = 1:numel(selected_transf_test)
        for idx_train_transf = 1:numel(selected_transf_train)


            tmp_avg_res = zeros(size(RES,2),1);

            for idx_res = 1:size(RES,2)
                tmp_avg_res(idx_res) = RES(1,idx_res,selected_transf_train(idx_train_transf)).Y_avg_struct.acc_new{3}(selected_transf_test(idx_test_transf));
            end

            y(idx_test_transf,idx_RES) = mean(tmp_avg_res);        


    %         
    %        display([idx_test_transf     mean(tmp_avg_res)]);
        end
    end
    
    
end




% 
% figure(133);
figure;
title('Performance across modality');
bar(y)
legend(legend_str);

axis([0 size(y,1)+1 0 1]);



