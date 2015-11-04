function D_gpu = SquareDist_gpu(X1_gpu, X2_gpu)
    
n = size(X1,1);
    m = size(X2,1);

    sq1 = sum(X1.*X1,2);
    sq2 = sum(X2.*X2,2);
    
    D_gpu = sq1*ones([1,m], 'double', 'gpuArray') + ones([n,1], 'double', 'gpuArray')*sq2' - 2*(X1*X2');
end
