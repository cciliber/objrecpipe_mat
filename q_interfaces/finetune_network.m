function network = finetune_network(network,question,finetune_config)

    setup_data = setup_machine();
    
    run(finetune_config);
        
    network = new_finetune_cat(setup_data,question,network,dset_dir);

    save(network.network_struct_path,'network');
    
end







