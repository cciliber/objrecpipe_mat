function Ypred = train_and_predict(Xtr,Ytr,Xts,opt_path)
    
    if nargin<4
        opt_path = 'gurls_tmp_exp';
    end
    
    [n,d] = size(Xtr);
    
    % GURLS setup
    Gurls_ROOT = getenv('Gurls_DIR');
    Gurls_ROOT = Gurls_ROOT(1:end-5)
    run(fullfile(Gurls_ROOT,'gurls/utils/gurls_install.m'));

    opt = defopt(opt_path);

    opt.paramsel.hoperf = @perf_macroavg;
    opt.hoproportion = 0.5;
    opt.nlambda = 20;
    
    opt.kernel.type = 'linear';

    if n<d
        opt.seq = {'kernel:linear','split:ho', 'paramsel:hodual', 'rls:dual', 'pred:dual'};
        opt.process{1} = [2,2,2,2,0];
        opt.process{2} = [3,3,3,3,2];

    else
        opt.seq = {'split:ho','paramsel:hoprimal','rls:primal','pred:primal'}; 
        opt.process{1} = [2,2,2,0]; 
        opt.process{2} = [3,3,3,2]; 
    end
    
    
    % train
    Xm = mean(Xtr,1);
    Xtr = Xtr - ones(size(Xtr,1),1)*Xm;
    gurls (Xtr, Ytr, opt, 1);

    % predict
    Xts = Xts - ones(size(Xts,1),1)*Xm;
    opt = gurls (Xts,[], opt, 2);    
    Ypred = opt.pred;

end