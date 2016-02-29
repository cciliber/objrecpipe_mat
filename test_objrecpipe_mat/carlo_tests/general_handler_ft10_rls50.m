function general_handler_ft10_rls50(start_revive)

    if nargin < 1
        start_revive = 0;
    end
    
    setup_mail_matlab;
    
    OBJREC_DIR = '/data/giulia/REPOS/objrecpipe_mat';
    addpath(genpath(OBJREC_DIR));

    TEST_DIR = '/data/giulia/REPOS/objrecpipe_mat/test_objrecpipe_mat';

    ANALYSIS = 'carlo_tests';

    CONFIG_PATH = fullfile(TEST_DIR, ANALYSIS, 'config');
    
    STRUCT_PATH = fullfile(TEST_DIR, ANALYSIS, 'structs');
    
    
    

    status = struct;
    status.name = 'ft10_rls50';
    status.revive_count = start_revive;
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
        

       
        
        config_file_list = dir(fullfile(CONFIG_PATH, 'ft10_rls50'));
 
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
            config_file = fullfile(CONFIG_PATH, 'ft10_rls50', config_filename);
            
            
            if ~exist('create_new_question')
            
           
                % Create and save question (the registries)
%                 question = create_question(fullfile(STRUCT_PATH, 'question'), config_filename, config_file);
        
                question = load(fullfile(STRUCT_PATH, 'question', config_filename));
                question = question.question;
                
                
                create_new_question = false; 
            end            
            
            
            
            
            if ~exist('perform_experiment')
                
                % Predict and save experiment
                experiment_config_filename = 'cc256_caffenet_withfeatures';
                experiment = {};
                for ff=1:numel(network)
                    experiment_name = [experiment_config_filename '_' question.question_dir '_' network{ff}.network_dir];
%                     experiment{ff} = experiment_network(fullfile(STRUCT_PATH, 'experiment'), experiment_name, question, network{ff}, config_file);
                    
                    experiment{ff} = load(fullfile(STRUCT_PATH, 'experiment', experiment_name));

                    close;
%                     
%                     try 
%                         sendmail({'cciliber@gmail.com'},[config_filename ' Extraction n. ' num2str(ff) ],'Done',{});
%                     catch
%                         sendmail({'cciliber@gmail.com'},['Error!'],['Unable to send Experiment log mail'],{});
%                     end
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
                
               
                days = [1,2];
                n_trains = [10];
                test_transformations = {'SCALE','ROT2D'};


                trasl_idx = setup_data.dset.Transfs('TRANSL');
                
                rot_idx = setup_data.dset.Transfs('ROT2D');
                
                scale_idx = setup_data.dset.Transfs('SCALE');
                
                
                if ~isfield(status,'scores')
                    status.scores = zeros(10,numel(result),numel(n_trains),numel(test_transformations),numel(days));
                end
                
                
                             
                for idx_day = 1:numel(days)
                    
                    selected_day = days(idx_day);
                   
                    for idx_ntr = 1:numel(n_trains)

                        ntr = n_trains(idx_ntr);
                        


                        for idx_result = 1:numel(result)
                            

                            ncats = 5;
                            
                            if selected_day>0
                                select_idx_day = result{idx_result}.labels_matrix(:,4)==selected_day;
                            else
                                select_idx_day = ones(size(result{idx_result}.labels_matrix,1),1);
                            end
                            

                            Xtr = [];
                            Ytr = [];
                            
                            Xts_rot = [];
                            Yts_rot = [];
                            
                            Xts_scale = [];
                            Yts_scale = [];
                            
                            
                            for idx_cat = 1:ncats

                                select_idx_cat = result{idx_result}.labels_matrix(:,1)==selected_list_classes(idx_cat);
                                
                                
                                for idx_obj = 1:n_obj_per_cat


                                    select_idx_obj = result{idx_result}.labels_matrix(:,2)==idx_obj;


                                    select_idx_transl = result{idx_result}.labels_matrix(:,3)==trasl_idx;
                                    select_idx_rot = result{idx_result}.labels_matrix(:,3)==rot_idx;
                                    select_idx_scale = result{idx_result}.labels_matrix(:,3)==scale_idx;


                                    select_idx_joint = (select_idx_transl.*select_idx_cat.*select_idx_day.*select_idx_obj);

                                    tmpXtr = result{idx_result}.feature_matrix(select_idx_joint==1,:);
                                    if ntr>0 && size(tmpXtr,1)>0
                                        tmpXtr = tmpXtr(randperm(size(tmpXtr,1),ntr),:);
                                    end

                                    Xtr = [Xtr; tmpXtr];
                                    Ytr = [Ytr; ((idx_cat-1)*n_obj_per_cat + idx_obj)  * ones( size(tmpXtr,1) , 1 )];



                                    select_idx_joint = (select_idx_rot.*select_idx_cat.*select_idx_day.*select_idx_obj);


                                    Xts_rot = [Xts_rot; result{idx_result}.feature_matrix(select_idx_joint==1,:)]; 
                                    Yts_rot = [Yts_rot; ((idx_cat-1)*n_obj_per_cat + idx_obj)  * ones( sum(select_idx_joint) , 1 )];

                                    select_idx_joint = (select_idx_scale.*select_idx_cat.*select_idx_day.*select_idx_obj);

                                    Xts_scale = [Xts_scale; result{idx_result}.feature_matrix(select_idx_joint==1,:)]; 
                                    Yts_scale = [Yts_scale; ((idx_cat-1)*n_obj_per_cat + idx_obj)  * ones( sum(select_idx_joint) , 1 )];

                                end
                                
                                
                                
                                
                            end
                                




                            % learn and predict
                            model = gurls_train(Xtr,Ytr);
                            
                            
                            YpredRLS = gurls_test(model,Xts_scale);
                            [~,YpredRLS_class] = max(YpredRLS,[],2);  
                            C = confusionmat(Yts_scale,YpredRLS_class);
                            C = C./repmat(sum(C,2),1,size(C,2));

                            status.scores(status.idx_config,idx_result,idx_ntr,1,idx_day) = trace(C)/size(C,1);

                            
                            
                            YpredRLS = gurls_test(model,Xts_rot);
                            [~,YpredRLS_class] = max(YpredRLS,[],2);  
                            C = confusionmat(Yts_rot,YpredRLS_class);
                            C = C./repmat(sum(C,2),1,size(C,2));

                            status.scores(status.idx_config,idx_result,idx_ntr,2,idx_day) = trace(C)/size(C,1);



                            clear Xtr Xts Ytr Yts;
                            clear model;

                        end


                        
                        
                    end
                    
                end
                
                scores = status.scores(1:status.idx_config,:,:,:,:);
                
                check_output_dir(fullfile(STRUCT_PATH,'rls'));
                save(fullfile(STRUCT_PATH,'rls',config_filename),'scores','-v7.3');

                sendmail({'cciliber@gmail.com'},['results' config_filename],'Check',{fullfile(STRUCT_PATH,'rls',[config_filename '.mat'])});
               
                perform_rls = false;
               
            end
            
            
            
            
                
            
            
            
            
 % ####################################################### END   
 
            % clean up stuff
            
            clear create_new_question;
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

        display(error_struct.message);
        
        try 
            sendmail({'cciliber@gmail.com'},['Error!'],status.log{end},{fullfile(status.STATUS_PATH,sprintf('status_%d.mat',status.revive_count))});
        catch
            sendmail({'cciliber@gmail.com'},['Error!'],['Unable to send Log'],{});
        end
        
        return;
    end


    status.done = true;
    

end
