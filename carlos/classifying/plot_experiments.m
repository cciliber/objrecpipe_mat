function plot_experiments(e, params)

   curr_path=pwd;
   cd(params.save_path);
   
    filestr={};
    nRuns={};
    for i=1:numel(e)
       if strcmp(e{i}.feature_type,params.feature_type) && ...
          e{i}.max_train==params.training_set_size

          filestr{end+1}=[params.method '-' e{i}.name];
          nRuns{end+1}=1;
          
       end
        
    end
    
    fields ={'perf.ap','perf.acc'};
    plotopt.titles={[upper(params.feature_type) ' Accuracy'],[upper(params.feature_type) ' Precision']};

    fid_classes=fopen([params.class_path '/class_order.txt'],'r');
    read_classes=false;
    plotopt.class_names={};

    while~read_classes
        idx=numel(plotopt.class_names)+1;

        tmp_line=fgets(fid_classes);
        if(ischar(tmp_line))
            plotopt.class_names{idx}=tmp_line(1:end-1);
        else
            read_classes=true; 
        end
    end

    fclose(fid_classes);

    summary_plot(filestr,fields,nRuns,plotopt);

    summary_overall_plot(filestr,fields,nRuns,plotopt);
    
    cd(curr_path);
    
end
