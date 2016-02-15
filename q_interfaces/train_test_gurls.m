function gurls_model = train_test_gurls(question,gurls_model,network,finetune_gurls_config_script)

    setup_data = setup_machine();
    
    run(train_test_gurls_config_script);    
    
    gurls_model = train_test_gurls_cat(setup_data,question,gurls_model,network,dset_dir);

    save(gurls_model.gurls_struct_path,'gurls');
    
end






