function D = wass_dist(X,Y)

    [nx,dx] = size(X);
    [ny,dy] = size(Y);
   
    
    lx = linspace(0,1,dx)
    ly = linspace(0,1,dy)
    
    C =square_dist(lx,ly);
    
    D = zeros(nx,ny);
    
    for ix = 1:nx
        for iy = 1:ny
           D(ix,iy) = emd_mex(X(ix,:),Y(iy,:),C); 
        end 
    end
        

end





function d = square_dist(a,b)
    % SQUARE_DISTANCE - computes Euclidean SQUARED distance matrix
    %
    % E = distance(A,B)
    %
    %    A - (DxM) matrix 
    %    B - (DxN) matrix
    %
    % Returns:
    %    E - (MxN) Euclidean SQUARED distances between vectors in A and B
    %
    %
    if (nargin ~= 2)
       error('Not enough input arguments');
    end

    if (size(a,1) ~= size(b,1))
       error('A and B should be of same dimensionality');
    end

    aa=sum(a.*a,1); bb=sum(b.*b,1); ab=a'*b; 
    %d = sqrt(abs(repmat(aa',[1 size(bb,2)]) + repmat(bb,[size(aa,2) 1]) - 2*ab));
    d = (abs(repmat(aa',[1 size(bb,2)]) + repmat(bb,[size(aa,2) 1]) - 2*ab));

end
