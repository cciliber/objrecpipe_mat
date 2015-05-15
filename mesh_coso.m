function mesh_coso()


xaxis = 0.0:0.001:1.0;
yaxis = 1.0:-0.001:0.0;
[x,y] = meshgrid(xaxis,yaxis);

n = 5;
data = rand(n,2);
%data = [0.1 0.5; 0.9 0.5];

sigma = 0.01;

D = square_distance(data',[x(:),y(:)]');

z = sum(exp(-D/sigma),1);
z = reshape(z,size(x,1),size(y,1));

close all
figure
imagesc(z);
%surf(x,y,z);

data

end



function d = square_distance(a,b)
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

