function general_handler()

    log_path = 'run_pipe_log.txt';

    setup_mail_matlab;
    recipients = {'giu.pasquale@gmail.com','cciliber@gmail.com'};
    
    
    save('current_status_0');

    max_n_revives = 10;
    
    status = struct;
    status.done = false;
    status.current_revive = 0;
    
    status.log = {'Starting'};
    

    while ~status.done
    
        fid = fopen(log_path,'a');
        fprintf(fid,'\n\n%s\n',status.log{end});
        fclose(fid);
        
        status = internal_run_pipe(status);
    
        mailtext = [char(status.log) repmat(10, numel(status.log), 1)]';

        sendmail(recipients,...
            'run_pipe REPORT: Error',...
            mailtext(:)',...
            {sprintf('current_status_%d.mat',status.current_revive)}...
        );

        
        if status.current_revive > max_n_revives
            status.log{end+1} = 'Maximum number of revives reached. Shutting Down'; 
            break;
        end
        
      
        
    
    end
    

    fid = fopen(log_path,'a');
    fprintf(fid,'%s\n',status.log{end});
    fclose(fid);

    mailtext = [char(status.log) repmat(10, numel(status.log), 1)]';

    
    mail_subject = 'run_pipe REPORT: Success';
    if status.current_revive > max_n_revives
        mail_subject = 'run_pipe REPORT: Error, Shutting down';
    end
    
    sendmail(recipients,...
        mail_subject,...
        mailtext(:)',...
        {sprintf('current_status_%d.mat',status.current_revive)}...
    );


end





function status = internal_run_pipe(status)

%%
    load(sprintf('current_status_%d',status.current_revive));


    try
        if ~exist('STRUCT_PATH')


            %% Core code
            OBJREC_DIR = '/data/giulia/REPOS/objrecpipe_mat';
            addpath(genpath(OBJREC_DIR));

            %% Test code 
            TEST_DIR = '/data/giulia/REPOS/test_objrecpipe_mat';


            %% Analysis
            ANALYSIS = 'invariance';


            %% Config files
            CONFIG_PATH = fullfile(TEST_DIR, ANALYSIS, 'config');
            %% Struct files
            STRUCT_PATH = fullfile(TEST_DIR, ANALYSIS, 'structs');

           
        end


        if ~exist('question')

            %% Create and save question (the registries)
            question_config_filename = 'id15obj_10trials_tune2transf';
            question_config_file = fullfile(CONFIG_PATH, 'question', question_config_filename);
            question = create_question(fullfile(STRUCT_PATH, 'question'), question_config_filename, question_config_file);

        end
        
        
        
        
        
        %% Create and save network
        
        if ~exist('initial_network_ff')           
            initial_network_ff = 1;
            
            network_config_file_list = dir(fullfile(CONFIG_PATH, 'network'));
            network = {};
        end
        
        for ff=1:numel(network_config_file_list)
            
            if ff >= initial_network_ff
                if network_config_file_list(ff).name(1)~='.'
                    network_config_file = fullfile(CONFIG_PATH, 'network', network_config_file_list(ff).name);
                    network{end+1} = create_network(fullfile(STRUCT_PATH, 'network'), network_config_file_list(ff).name, network_config_file);
                    
                end
                
                initial_network_ff = initial_network_ff + 1;
            end
            
        end

        %% Finetune!
        
        if ~exist('initial_finetune_ff')           
            initial_finetune_ff = 1;
            
            finetune_config_filename = 'cc256';
            finetune_config_file = fullfile(CONFIG_PATH, 'finetune', finetune_config_filename);            
        end
        
        
        for ff=1:numel(network)
            if ff >= initial_finetune_ff
            
                network{ff} = finetune_network(question, network{ff}, finetune_config_file);

                initial_finetune_ff = initial_finetune_ff + 1;
            end
        
        end

        %% Predict!
        
        if ~exist('initial_experiment_ff')           
            initial_experiment_ff = 1;
            
            experiment_config_filename = 'cc256_caffenet_withfeatures';
            experiment_config_file = fullfile(CONFIG_PATH, 'experiment', experiment_config_filename);
            experiment = {};            
        end
        
        for ff=1:numel(network)
             if ff >= initial_experiment_ff
                experiment{ff} = experiment_network(fullfile(STRUCT_PATH, 'experiment'), experiment_config_filename, question, network{ff}, experiment_config_file);
                
                initial_experiment_ff = initial_experiment_ff + 1;
             end
        end

        %% Analyze!
        results_config_filename = 'ciao';
        results_config_file = fullfile(CONFIG_PATH, 'results', experiment_config_filename);
        results = {};
        for ff=1:numel(network)
            results{ff} = analyze_experiment(fullfile(STRUCT_PATH, 'results'), results_config_filename, experiment{ff}, results_config_file);
        end

    catch err
        
        status.log{end+1} = ['Error: ', err.message];

        status.current_revive = status.current_revive + 1;
        
        save(sprintf('current_status_%d',status.current_revive));
        
        
        return;
    end
        
    
    status.done = true;
    status.log{end+1} = 'Finished!';



end










