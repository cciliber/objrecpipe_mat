function network = create_network(network_root_path,network_name,network_config_script) 
  
    if nargin<3
        error('Provide configuration scrip!');
    end

    % create/check the question struct path
    check_output_dir(network_root_path);
    
    % setup the machine parameters as usual
    setup_data = setup_machine();
    
    
    
    
    % call the config file 
    run(network_config_script);
    
    
    

    %put everything in the question
    network = struct;
    
    network.mapping = mapping;
    
    if ~isempty(mapping)
        network.network_dir = network_name;
    end
    
    network.network_struct_path = fullfile(network_root_path,network_name);

    
    
    
    if ~isempty(network.mapping)
       
        if strcmp(caffestuff.net_name, 'caffenet')

            % net definition
            caffestuff.net_model_template = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'train_val_template.prototxt');
            caffestuff.net_model_struct_types = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'train_val_struct_types.txt');
            caffestuff.net_model_struct_values = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'train_val_struct_values.txt');

            % net initialization 
            trainval_params = create_struct_from_txt(caffestuff.net_model_struct_types, caffestuff.net_model_struct_values);        


            % deploy definition
            caffestuff.deploy_model_template = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'deploy_template.prototxt');
            caffestuff.deploy_model_struct_types = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'deploy_struct_types.txt');
            caffestuff.deploy_model_struct_values = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'deploy_struct_values.txt');

            % deploy initialization
            deploy_params = create_struct_from_txt(caffestuff.deploy_model_struct_types, caffestuff.deploy_model_struct_values);              

            % solver definition
            caffestuff.solver_template = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'solver_template.prototxt');
            caffestuff.solver_struct_types = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'solver_struct_types.txt');
            caffestuff.solver_struct_values = fullfile(setup_data.template_prototxts_path, caffestuff.net_name, 'solver_struct_values.txt');

            % solver initialization
            solver_params = create_struct_from_txt(caffestuff.solver_struct_types, caffestuff.solver_struct_values);         

            trainval_params.fc8_lr_mult_W = fc8_final_W/base_lr;
            trainval_params.fc8_lr_mult_b = fc8_final_b/base_lr;

            trainval_params.fc8_name = fc8_name;
            trainval_params.fc8_top = fc8_name;
            trainval_params.accuracy_bottom = fc8_name;
            trainval_params.loss_bottom = fc8_name;
            
     
            



            if exist('fc7_name', 'var')

                trainval_params.fc7_lr_mult_W = fc7_final_W/base_lr;
                trainval_params.fc7_lr_mult_b = fc7_final_b/base_lr;

                trainval_params.fc7_name = fc7_name;
                trainval_params.fc7_top = fc7_name;
                trainval_params.relu7_bottom = fc7_name;
                trainval_params.relu7_top = fc7_name;
                trainval_params.drop7_bottom = fc7_name;
                trainval_params.drop7_top = fc7_name;
                trainval_params.fc8_bottom = fc7_name;

                           
            end

            if exist('fc6_name', 'var')

                trainval_params.fc6_lr_mult_W = fc6_final_W/base_lr;
                trainval_params.fc6_lr_mult_b = fc6_final_b/base_lr;

                trainval_params.fc6_name = fc6_name;
                trainval_params.fc6_top = fc6_name;
                trainval_params.relu6_bottom = fc6_name;
                trainval_params.relu6_top = fc6_name;
                trainval_params.drop6_bottom = fc6_name;
                trainval_params.drop6_top = fc6_name;
                trainval_params.fc7_bottom = fc6_name;


            end

            if exist('drop7_dropout_ratio', 'var')
                trainval_params.drop7_dropout_ratio = drop7_dropout_ratio;
            end

            if exist('drop6_dropout_ratio', 'var')   
                trainval_params.drop6_dropout_ratio = drop6_dropout_ratio;
            end



            % assign trainval_params to deploy_params   
            fnames = fieldnames(deploy_params);
            for ii=1:length(fnames)
                if isfield(trainval_params, fnames{ii})
                    deploy_params.(fnames{ii}) = trainval_params.(fnames{ii});
                else
                    warning('Field not present in trainval: %s. Are you assigning it separately?', fnames{ii});
                end
            end
            deploy_params.prob_bottom = deploy_params.fc8_top;


            % fill the solver informations
            solver_params.base_lr = base_lr;

        end



        network.trainval_params     = trainval_params;
        network.deploy_params       = deploy_params;
        network.solver_params       = solver_params;



        % update the caffestuff
        network.setup_caffemodel = @internal_setup_caffemodel;

        caffestuff.net_weights = caffestuff.original_net_weights;
        
    else
        % setup only once the caffestuff
        caffestuff = internal_setup_caffemodel(setup_data.caffe_dir, caffestuff, mapping);
        
        % just do nothing
        %network.setup_caffemodel = @(net_dir, caffestuff) caffestuff;
        
        network.network_dir = '';
        
    end

    network.caffestuff = caffestuff;
    
    save(network.network_struct_path,'network');


end










function caffestuff = internal_setup_caffemodel(net_dir, caffestuff, mapping, model_dirname)

    if isempty(mapping)

        if strcmp(caffestuff.net_name, 'caffenet')

            % model dir
            caffestuff.net_dir = fullfile(net_dir, 'models/bvlc_reference_caffenet/');

            % net weights
            caffestuff.net_weights = fullfile(caffestuff.net_dir, 'bvlc_reference_caffenet.caffemodel');

            % net definition
            caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');

            % mean data: mat file already in W x H x C with BGR channels
            caffestuff.mean_path = fullfile(net_dir, 'matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
            d = load(caffestuff.mean_path);
            caffestuff.mean_data = d.mean_data;

        elseif strcmp(caffestuff.net_name, 'googlenet_caffe')

            % model dir
            caffestuff.net_dir = fullfile(net_dir, 'models/bvlc_googlenet/');

            % net weights
            caffepaths.net_weights = fullfile(caffestuff.net_dir, 'bvlc_googlenet.caffemodel');

            % net definition
            caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');

            % mean data
            caffestuff.mean_data = [104 117 123];

        elseif strcmp(caffestuff.net_name, 'googlenet_paper')

            % model dir
            caffestuff.net_dir = fullfile(net_dir, 'models/bvlc_googlenet/');

            % net weights
            caffestuff.net_weights = fullfile(caffestuff.net_dir, 'bvlc_googlenet.caffemodel');

            % net definition
            caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');

            % mean data
            caffestuff.mean_data = [104 117 123];

        elseif strcmp(caffestuff.net_name, 'vgg16')

            % model dir
            caffestuff.net_dir = fullfile(net_dir, 'models/VGG/VGG_ILSVRC_16');

            % net weights
            caffestuff.net_weights = fullfile(caffestuff.net_dir, 'VGG_ILSVRC_16_layers.caffemodel');

            % net definition
            caffepaths.net_model = fullfile(caffestuff.net_dir, 'VGG_ILSVRC_16_layers_deploy.prototxt');

            % mean data
            caffestuff.mean_data = [103.939 116.779 123.68];

        else

            error('Net unknown!');

        end

    elseif strcmp(mapping, 'tuning')

        % model dir
        caffestuff.net_dir = fullfile(net_dir, mapping, model_dirname, 'model');

        % net weights
        caffestuff.net_weights = fullfile(caffestuff.net_dir, 'best_model.caffemodel');

        % net definition
        caffestuff.net_model = fullfile(caffestuff.net_dir, 'deploy.prototxt');

        % mean data: mat file already in W x H x C with BGR channels
        caffestuff.mean_path = fullfile(caffestuff.net_dir, 'train_mean.binaryproto');
        caffestuff.mean_data = caffe.io.read_mean(caffestuff.mean_path);

    else

        error('Mapping unknown!')

    end
    
    
end


