function network = finetune_network(setup_data, question, network, finetune_config_script)

    if isempty(network.mapping)
        return;
    end

    run(finetune_config_script);
    
    network.tuning_round = tuning_round;
    
    % output root
    if ~isempty(network.network_dir) && tuning_round>1
        output_dir_root = fileparts(fileparts(network.net_weights));
    else
        output_dir_root = fullfile([dset_dir '_experiments'], network.caffestuff.network_kind);
    end
    
    network = new_finetune(setup_data, question, network, dset_dir, output_dir_root, Ntrials);

    save(network.network_struct_path,'network');
    
end







