function general_handler_for10()

    
    setup_mail_matlab;
    
    OBJREC_DIR = '/data/giulia/REPOS/objrecpipe_mat';
    addpath(genpath(OBJREC_DIR));

    TEST_DIR = '/data/giulia/REPOS/objrecpipe_mat/test_objrecpipe_mat';

    ANALYSIS = 'carlo_tests';

    CONFIG_PATH = fullfile(TEST_DIR, ANALYSIS, 'config');
    
    STRUCT_PATH = fullfile(TEST_DIR, ANALYSIS, 'structs');
    
    
    

    status = struct;
    status.name = 'all_reduce_10';
    status.revive_count = 0;
    status.delta_max_revives = 10;
    status.max_revives = status.revive_count + status.delta_max_revives;
    
    status.log = {'Starting'};
    
    status.idx_config = 1;
    
    status.done = false;
    
    status.STATUS_PATH = fullfile(TEST_DIR, ANALYSIS, 'status',status.name);
    
    
    
    check_output_dir(status.STATUS_PATH);
    save(fullfile(status.STATUS_PATH,'status_0'));
    
    while ~status.done
    
        status = test_function(status);
       
    end
    
    
    if status.done    
        sendmail({'cciliber@gmail.com'},'Finished!','All done!',{});
    else
        sendmail({'cciliber@gmail.com'},'Exit','Not completely finished',{});
    end



end




function status = test_function(status)

    load(fullfile(status.STATUS_PATH,sprintf('status_%d',status.revive_count)));

    if status.revive_count > status.max_revives
        status.idx_config = status.idx_config + 1;
        status.max_revives = status.revive_count + status.delta_max_revives;
    end


    try        
        
        if ~exist('setup_data')
            setup_data = setup_machine();
        end
        
        
        % creat the networks
        if ~exist('create_new_networks')
           
            network_config_file_list = dir(fullfile(CONFIG_PATH, 'network'));
            network = {};
            for ff=1:numel(network_config_file_list)
                if network_config_file_list(ff).name(1)~='.'
                    network_config_file = fullfile(CONFIG_PATH, 'network', network_config_file_list(ff).name);
                    network{end+1} = create_network(fullfile(STRUCT_PATH, 'network'), network_config_file_list(ff).name(1:end-2), network_config_file);
                end
            end
            
            create_new_networks = false;
            
        end
        

       
        
        config_file_list = dir(fullfile(CONFIG_PATH, 'all_reduce_10'));
 
        % count the number of legal files
        eliminate_idx = [];
        for idx_list = 1:numel(config_file_list)
            if strcmp(config_file_list(idx_list).name(1),'.') || strcmp(config_file_list(idx_list).name(end),'~')
                eliminate_idx(end+1) = idx_list;
            end
        end
        
        config_file_list(eliminate_idx) = [];
        
        
        
        while status.idx_config <= numel(config_file_list)
            
            
            config_filename = config_file_list(status.idx_config).name(1:(end-2));
            config_file = fullfile(CONFIG_PATH, 'all_reduce_10', config_filename);
            
            
            if ~exist('create_new_question')
            
           
                % Create and save question (the registries)
                question = create_question(fullfile(STRUCT_PATH, 'question'), config_filename, config_file);
        
                
                
                create_new_question = false; 
            end            
            
            
            if ~exist('perform_finetuning')
                

                % Finetune;

                for ff=1:numel(network)
                    network{ff} = finetune_network(question, network{ff}, config_file);
                end

                
                perform_finetuning = false;
            end
            
            
            
            if ~exist('perform_experiment')
                
                % Predict and save experiment
                experiment_config_filename = 'cc256_caffenet_withfeatures';
                experiment = {};
                for ff=1:numel(network)
                    experiment_name = [experiment_config_filename '_' question.question_dir '_' network{ff}.network_dir];
                    experiment{ff} = experiment_network(fullfile(STRUCT_PATH, 'experiment'), experiment_name, question, network{ff}, config_file);
                    close;
                end
            
                perform_experiment = false;
            end
            
            
            
            if ~exist('compute_results')
                
                result = {};
                for ff=1:numel(network)
                    result{ff} = t_sne_experiment(fullfile(STRUCT_PATH, 'results'), ['results_' config_filename], experiment{ff}, config_file);
                end
                display('done');
               
                compute_results = false;
                
            end
            
            
            
            
            
            if ~exist('perform_rls')
               
                days = [1,2,-1];
                n_trains = [10, 50, -1];
                
                list_classes = {1:15 1:10 11:15};

                scores = zeros(numel(list_classes),numel(days),numel(n_trains),numel(result));
                
                for idx_list_classes = 1:numel(list_classes)
                
                    selected_list_classes = list_classes{idx_list_classes};
                                         
                    for idx_day = 1:numel(days)

                        selected_day = days(idx_day);

                        for idx_ntr = 1:numel(n_trains)


                            ntr = n_trains(idx_ntr);

                            selected_transformation = setup_data.dset.Transfs('TRANSL');


                            for idx_result = 1:numel(result)

                                
                                ncats = numel(unique(selected_list_classes));
                               
                                
                                if selected_day>0
                                    select_idx_day = result{idx_result}.labels_matrix(:,4)==selected_day;
                                else
                                    select_idx_day = ones(size(result{idx_result}.labels_matrix,1),1);
                                end


                                Xtr = [];
                                Ytr = [];
                                Xts = [];
                                Yts = [];
                                for idx_cat = 1:ncats

                                    select_idx_cat = result{idx_result}.labels_matrix(:,1)==selected_list_classes(idx_cat);

                                    for idx_transf = 1:5

                                        select_idx_transf = result{idx_result}.labels_matrix(:,3)==idx_transf;


                                        select_idx_joint = (select_idx_transf.*select_idx_cat.*select_idx_day);



                                        if idx_transf == selected_transformation

                                            tmpXtr = result{idx_result}.feature_matrix(select_idx_joint==1,:);
                                            if ntr>0 && size(tmpXtr,1)>0
                                                tmpXtr = tmpXtr(randperm(size(tmpXtr,1),ntr),:);
                                            end

                                            Xtr = [Xtr; tmpXtr];
                                            Ytr = [Ytr; idx_cat * ones( size(tmpXtr,1) , 1 )];

                                        else
                                            Xts = [Xts; result{idx_result}.feature_matrix(select_idx_joint==1,:)];
                                            Yts = [Yts; idx_cat * ones( sum(select_idx_joint) , 1 )];
                                        end

                                    end 
                                end




                                % learn and predict
                                model = gurls_train(Xtr,Ytr);
                                YpredRLS = gurls_test(model,Xts);

                                [~,YpredRLS_class] = max(YpredRLS,[],2);  

                                C = confusionmat(Yts,YpredRLS_class);

                                C = C./repmat(sum(C,2),1,size(C,2));

                                scores(idx_list_classes,idx_day,idx_ntr,idx_result) = trace(C)/size(C,1);



                                clear Xtr Xts Ytr Yts;
                                clear model;

                            end




                        end

                    end
                    
                end
                
                
                check_output_dir(fullfile(STRUCT_PATH,'rls'));
                save(fullfile(STRUCT_PATH,'rls',config_filename),'scores','-v7.3');

                sendmail({'cciliber@gmail.com'},['results ' config_filename],mat2str(reshape(scores,numel(days)*numel(n_trains),[])),{fullfile(STRUCT_PATH,'rls',[config_filename '.mat'])});
               
                perform_rls = false;
               
            end
            
                
            
            
            
            
 % ####################################################### END   
 
            % clean up stuff
            
            clear create_new_question;
            clear perform_finetuning;
            clear perform_experiment;
            clear compute_results;
            clear perform_rls;
            
            
            clear question;
            clear experiment;
            clear result;
            
            
            status.idx_config = status.idx_config + 1;
        end
        

        
        
        
        
        
    catch error_struct
        
        status.log{end+1} = error_struct.message;
        
        status.error_log = error_struct;
        
        status.revive_count = status.revive_count + 1;
        
        save(fullfile(status.STATUS_PATH,sprintf('status_%d',status.revive_count)),'-v7.3');

        
        sendmail({'cciliber@gmail.com'},['Error!'],status.log{end},{fullfile(status.STATUS_PATH,sprintf('status_%d.mat',status.revive_count))});

        
        return;
    end


    status.done = true;
    

end



