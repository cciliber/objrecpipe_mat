function question = create_question(question_root_path,question_name,question_config_script)

    % This function produces all necessary information to run a network on a
    % specific set of datasets.

    
    % create/check the question struct path
    check_output_dir(question_root_path);
    
    % setup the machine parameters as usual
    setup_data = setup_machine();
    
    
    
    % call the config file 
    run(question_config_script);
    
    

    %put everything in the question
    question = struct;
     
    question.question_dir = question_name;
    question.question_struct_path = fullfile(question_root_path,question_name);
    
    question.setlist = setlist;

    wrapper_create_sets_cat(setup_data,question);
    

    save(question.question_struct_path,'question');

end


function wrapper_create_sets_cat(setup_data,question)

    % create the question!
    new_create_sets_cat(setup_data.DATA_DIR,...
        setup_data.dset, ...
        question.question_dir, ...
        question.setlist);


end

