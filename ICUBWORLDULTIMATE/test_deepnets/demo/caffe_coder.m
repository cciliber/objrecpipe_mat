
function caffe_coder(caffepaths, folder_path,true_category_name,categories_struct,desired_ext)

    if nargin < 4
        desired_ext = 'jpg';
    end

    list_files = dir(folder_path);
    
    
    correct_count = 0;
    correct_count1000 = 0;
    total_count = 0;
    
    log_struct = {};
    
    for idx_list = 1:numel(list_files)
       curr_file = list_files(idx_list).name;
       
       [~,~,ext] = fileparts(curr_file);
       
       if sum(strfind(ext,desired_ext)) > 0
           
           % call caffe demo
           [scores, best_category1000] = classification_demo(caffepaths, imread(fullfile(folder_path,curr_file)), 1);
           
           %select only the ten labels we are interested into
           selected_predicted_labels = scores(categories_struct.predictions_selector + 1);
           
           [~,best_category] = max(selected_predicted_labels);
            
           best_category_name = categories_struct.category_names{best_category};
           
           % keep the predictions for the log
           log_struct{end+1} = struct;
           log_struct{end}.path = curr_file;
           log_struct{end}.predicted = best_category_name;
           log_struct{end}.predicted1000 = best_category1000 - 1;
           
           if strcmp(true_category_name,best_category_name)
              correct_count = correct_count + 1; 
           end
           
           if (best_category1000-1) == categories_struct.predictions_selector( strcmp(categories_struct.category_names, true_category_name) )
               correct_count1000 = correct_count1000 + 1;
           end
           
           total_count = total_count + 1;
       end
        
    end
    
    
    fid_log = fopen(fullfile(folder_path,'scores.log'),'w');
    
    fprintf(fid_log,'\nTotal Accuracy: %f\n\n \nTotal Accuracy over 1000: %f\n\n',correct_count/total_count, correct_count1000/total_count);

    for idx_log = 1:numel(log_struct)
        fprintf(fid_log,'%s \t\t\t %s \t\t\t %d\n', log_struct{idx_log}.path, log_struct{idx_log}.predicted, log_struct{idx_log}.predicted1000);
    end
    
    fclose(fid_log);
    
    
end