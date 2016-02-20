function experiment = experiment_network(experiment_root_path, experiment_name, question, network, experiment_config_script)

    setup_data = setup_machine();
    
    if nargin<4
        default_experiment_network_config;
    else
        run(experiment_config_script);
    end
    
    check_output_dir(experiment_root_path);
    
    experiment = struct;
  
    experiment.experiment_struct_path = fullfile(experiment_root_path, experiment_name);
    
    % pointer to the image set used for the experiment
    experiment.dset_dir = dset_dir;
    
    % whether we want to extract features
    experiment.extract_features = extract_features;
    
    % which features we want to extract    
    experiment.feat_names = feat_names;
    
    % whether to save only the features of the central crop
    % it is used only if NCROPS>1 
    % (depending on network.caffestuff.preprocessing defined in the config)
    experiment.save_only_central_feat = save_only_central_feat;
        
    %% Setup preprocessing
    
    prep = network.caffestuff.preprocessing;
    prep.NCROPS_grid = (prep.GRID.nodes*prep.GRID.nodes+mod(prep.GRID.nodes+1,2)+prep.GRID.resize)*(prep.GRID.mirror+1);
    
    if ~isempty(prep.OUTER_GRID)
        prep.NCROPS_scale = prep.NCROPS_grid*prep.OUTER_GRID;
    else
        prep.NCROPS_scale = prep.NCROPS_grid;
    end
    
    if ~isfield(prep, 'SCALING')
        prep.centralscale = 1;
        prep.NSCALES = 1;
    elseif size(prep.SCALING.scales,1)==1
        prep.centralscale = 1;
        prep.NSCALES = 1;
    else
        prep.centralscale = prep.SCALING.centralscale;
        prep.NSCALES = size(prep.SCALING.scales, 1);
    end
    
    prep.central_score_idx = (prep.centralscale-1)*prep.NCROPS_scale;
    
    if ~isempty(prep.OUTER_GRID)
        prep.central_score_idx = prep.central_score_idx + prep.NCROPS_grid*(prep.OUTER_GRID-1)/2;
    end
    
    if mod(prep.GRID.nodes, 2)
        prep.central_score_idx = prep.central_score_idx + ceil(prep.GRID.nodes*prep.GRID.nodes/2);
    else
        prep.central_score_idx = prep.central_score_idx + prep.GRID.nodes*prep.GRID.nodes+1;
    end
    
    prep.NCROPS = prep.NCROPS_scale*prep.NSCALES;
    
    prep.max_bsize = round(500/prep.NCROPS);
    
    network.caffestuff.preprocessing = prep;
    
    
    experiment.prep = prep;
    
    %% Go!
    
    new_extract_feat_and_pred_cat(setup_data, question, network, experiment);
    
    %% Keep track of which question and which network have been tested
    
    experiment.question_struct_path = question.question_struct_path;
    
    experiment.network_struct_path = network.network_struct_path;
    %save(experiment.network_struct_path, 'network'); 
  
    save(experiment.experiment_struct_path, 'experiment');
    
    
end



