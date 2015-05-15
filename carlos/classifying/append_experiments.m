function e=append_experiments(e,train,test,dict)

    ptr=dictionary_creator_parameters;
    pts=dictionary_creator_parameters;

    ptr=set_folder_parameters(ptr,train.train,dict.prefix,dict.dictionary); 
    pts=set_folder_parameters(pts,test.test,dict.prefix,dict.dictionary); 

    ptr.y=[train.train '/Y.txt'];
    pts.y=[test.test '/Y.txt'];


    %hmax
    if~isfield(ptr,'ignore_hmax')
        i=numel(e)+1;   
        e{i}=struct;
        e{i}.Xtr=ptr.hmax.hist_path;
        e{i}.ytr=ptr.y;
        e{i}.Xts=pts.hmax.hist_path;
        e{i}.yts=pts.y;
        e{i}.feature_size=ptr.hmax.feature_size;
        e{i}.max_train=5000;
        e{i}.feature_type='hmax';
        e{i}.name=[train.prefix '-' ...
                   test.prefix '-' ...
                   dict.prefix '-' ...
                   e{i}.feature_type '-' ...
                   num2str(e{i}.max_train)];
        
        e{i+1}=e{i};
        e{i+1}.max_train=10000;
        e{i}.name=[train.prefix '-' ...
                   test.prefix '-' ...
                   dict.prefix '-' ...
                   e{i}.feature_type '-' ...
                   num2str(e{i}.max_train)];
    end
    
    %bow
    if~isfield(ptr,'ignore_bow')
        i=numel(e)+1;   
        e{i}=struct;
        e{i}.Xtr=ptr.bow.hist_path;
        e{i}.ytr=ptr.y;
        e{i}.Xts=pts.bow.hist_path;
        e{i}.yts=pts.y;
        e{i}.feature_size=ptr.bow.feature_size;
        e{i}.max_train=5000;
        e{i}.feature_type='bow';
        e{i}.name=[train.prefix '-' ...
                   test.prefix '-' ...
                   dict.prefix '-' ...
                   e{i}.feature_type '-' ...
                   num2str(e{i}.max_train)];
        
        e{i+1}=e{i};
        e{i+1}.max_train=10000;
        e{i+1}.name=[train.prefix '-' ...
                   test.prefix '-' ...
                   dict.prefix '-' ...
                   e{i+1}.feature_type '-' ...
                   num2str(e{i}.max_train)];    
    end
    
    %sc
    if~isfield(ptr,'ignore_sc')
        i=numel(e)+1;   
        e{i}=struct;
        e{i}.Xtr=ptr.sc.hist_path;
        e{i}.ytr=ptr.y;
        e{i}.Xts=pts.sc.hist_path;
        e{i}.yts=pts.y;
        e{i}.feature_size=ptr.sc.feature_size;
        e{i}.max_train=5000;
        e{i}.feature_type='sc';
        e{i}.name=[train.prefix '-' ...
                   test.prefix '-' ...
                   dict.prefix '-' ...
                   e{i}.feature_type '-' ...
                   num2str(e{i}.max_train)];
        
        e{i+1}=e{i};
        e{i+1}.max_train=10000;
        e{i+1}.name=[train.prefix '-' ...
                   test.prefix '-' ...
                   dict.prefix '-' ...
                   e{i+1}.feature_type '-' ...
                   num2str(e{i}.max_train)];   
    end
end