function D = SquareDist(X1, X2)
    
    n = size(X1,1);
    m = size(X2,1);

    D = sum(X1.*X1,2)*ones(1,m) + ones(n,1)*(sum(X2.*X2,2)') - 2*(X1*X2');
end
