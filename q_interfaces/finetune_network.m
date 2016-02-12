function network = finetune_network(question,network,finetune_config_script)

    setup_data = setup_machine();
    
    run(finetune_config_script);
        
    network = new_finetune_cat(setup_data,question,network,dset_dir);

    save(network.network_struct_path,'network');
    
end







