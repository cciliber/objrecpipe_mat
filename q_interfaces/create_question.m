function question = create_question(setup_data, question_root_path, question_name, question_config_script)

    % This function produces all necessary information to run a network on a
    % specific set of datasets.

    
    % create/check the question struct path
    check_output_dir(question_root_path);
    
    % call the config file 
    run(question_config_script);
    
    

    %put everything in the question
    question = struct;
     
    question.question_dir = [exp_kind '_' question_name];
    question.question_struct_path = fullfile(question_root_path, question_name);
    
    question.setlist = setlist;

    new_create_sets(setup_data.DATA_DIR,...
            setup_data.dset, ...
            question.question_dir, ...
            question.setlist);
    
    save(question.question_struct_path,'question');

end

