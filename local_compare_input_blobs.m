cropmat = dlmread('/home/giulia/cuda-workspace/caffe_batch/build/crop_matt.txt');
figure, imagesc(cropmat)

cropcpp = dlmread('/home/giulia/cuda-workspace/caffe_batch/build/crop_cpp.txt');

cropcppreshape = zeros(227,227,3);

for c=1:3
    for h=1:227
        for w=1:227
            
            cropcppreshape(h,w,c) = cropcpp((c-1)*227*227 + (h-1)*227 + w);
            
        end
    end
end

figure, imagesc([cropcppreshape(:,:,1); cropcppreshape(:,:,2); cropcppreshape(:,:,3)])

diff = [cropcppreshape(:,:,1); cropcppreshape(:,:,2); cropcppreshape(:,:,3)] - cropmat;

%% 


featmattrain = caffe_train.Feat;
featmattest = caffe_test.Feat;
featmat = [featmattrain; featmattest];

feattxttrain = caffe_train.Feat;
feattxttest = caffe_test.Feat;
feattxt = [feattxttrain; feattxttest];

difftrain = featmattrain - feattxttrain;
difftest = featmattest - feattxttest;

max(max(difftrain))

max(max(difftest))


















