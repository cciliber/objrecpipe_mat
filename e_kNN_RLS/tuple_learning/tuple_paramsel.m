function [best_W] = tuple_paramsel(X,Y,Xva,Yva,nlambda)

    [n,d] = size(X);
    if nargin<5
        nlambda = 20;
    end
    
    
    if n>d
        C = X'*X;
        XY = X'*Y;
        eigvals = eig(C);
        lmax = max(eigvals);
        lmin = lmax*1e-8;
        powers = linspace(0,1,nlambda);
        lambdas = lmin.*(lmax/lmin).^(powers);  
        lambdas = lambdas/n;
        
        best_W=[];
        best_err = Inf;
        for idx_l=1:numel(lambdas)
            l = lambdas(idx_l);
            R = chol(C+l*eye(d));
            W = R\(R'\XY);
            
            [~,Ypred] =  max(Xva*W,[],2);
            tmp_err = 1-trace_confusion(Yva,Ypred);
            if tmp_err<best_err
                best_err = tmp_err;
                best_W = W;
            end
            
        end
    else
        K = X*X';
        eigvals = eig(K);
        lmax = max(eigvals);
        lmin = 1e-5;
        powers = linspace(0,1,nlambda);
        lambdas = lmin.*(lmax/lmin).^(powers);  
        lambdas = lambdas/n;
        
        best_W=[];
        best_err = Inf;
        for idx_l=1:numel(lambdas)
            l = lambdas(idx_l);
            R = chol(K+l*eye(n));
            A = R\(R'\Y);
            W = X'*A;
            
            [~,Ypred] =  max(Xva*W,[],2);
            tmp_err = 1-trace_confusion(Yva,Ypred);
            if tmp_err<best_err
                best_err = tmp_err;
                best_W = W;
            end
            
        end
    end


end