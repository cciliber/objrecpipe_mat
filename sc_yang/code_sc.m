function beta = code_sc(feat, pyramid, gamma, dictionary, im_size, grid)
% Compute the linear spatial pyramid feature using sparse coding. 
%
% Inputs:
% feat          - local feature array extracted from the image, column-wise
% pyramid       - defines structure of pyramid 
% gamma         - sparsity regularization parameter
% dictionary    - sparse dictionary, column-wise
% imsize        - size of the image
% grid          - locations of each local feature
%
% Output:
% beta - multiscale max pooling feature
%
% Written by Jianchao Yang @ NEC Research Lab America (Cupertino)
% Mentor: Kai Yu, July 2008 - Revised May. 2010

dictionaryDim = size(dictionary, 2);
nSmp = size(feat, 2);

sc_codes = zeros(dictionaryDim, nSmp);

beta = 1e-4;
% compute the local feature for each local feature
A = dictionary'*dictionary + 2*beta*eye(dictionaryDim);
Q = -dictionary'*feat;

for l = 1:nSmp,
    sc_codes(:, l) = L1QP_FeatureSign_yang(gamma, A, Q(:, l));
end

sc_codes = abs(sc_codes);

pyramid_w = pyramid(1,:);
pyramid_h = pyramid(2,:);
            
nLevels = size(pyramid,2);
% spatial bins on each level
binsPerLevel = pyramid_w.*pyramid_h;
% total spatial bins
nBins = sum(binsPerLevel);
    
beta = zeros(dictionaryDim, nBins);
bId = 0;

for l = 1:nLevels,
   
    bin_w = im_size(2) / pyramid_w(l);
    bin_h = im_size(1) / pyramid_h(l);
   
    bin_x = ceil(grid(1,:) / bin_w);
    bin_y = ceil(grid(2,:) / bin_h);
    bin_idx = (bin_y - 1)*pyramid(1,l) + bin_x;

    for b = 1:binsPerLevel(l)     
        bId = bId + 1;
        indices = find(bin_idx == b);
        if isempty(indices),
            continue;
        end      
        beta(:, bId) = max(sc_codes(:, indices), [], 2);
    end
end

if bId ~= nBins,
    error('Index number error!');
end

beta = beta(:);
beta = beta./sqrt(sum(beta.^2));
