function iros_phow(day)

% Performs the Object Recognition test with PHOW features using VL_FEAT
% package

if nargin<1
    day = 'lun';
end


conf.rootDir = '/data/DATASETS/iCubWorld30';
conf.pathList = '/data/DATASETS/iCubWorld30_experiments/Xy_IROS15_caffe_meanimnet_ccrop';

conf.day = day;

switch conf.day
    
    case 'lun'
        conf.day_folder = 'lunedi22';
     
    case 'mar'
        conf.day_folder = 'martedi23';
        
    case 'mer'
        conf.day_folder = 'mercoledi24';
        
    case 'ven'
        conf.day_folder = 'venerdi26';

end

conf.dataDir = './data/phow';

conf.numWords = 600 ;
conf.numSpatialX = [2 4] ;
conf.numSpatialY = [2 4] ;
conf.quantizer = 'kdtree' ;

conf.phowOpts = {'Step', 3} ;
conf.clobber = false ;
conf.prefix = conf.day ;
conf.randSeed = 1 ;

conf.numDictTrain = 0.2;

conf.tinyProblem = false;
if conf.tinyProblem
  conf.prefix = 'tiny' ;
  conf.numClasses = 5 ;
  conf.numSpatialX = 2 ;
  conf.numSpatialY = 2 ;
  conf.numWords = 300 ;
  conf.phowOpts = {'verbose',false,'sizes',[4 8 16 32],'step',4,'color','rgb','fast',true};
  %conf.phowOpts = {'Verbose', 2, 'Sizes', 7, 'Step', 5} ;
end

conf.vocabPath = fullfile(conf.dataDir, [conf.prefix '-vocab.mat']) ;
conf.histPath = fullfile(conf.dataDir, [conf.prefix '-hists.mat']) ;
conf.modelPath = fullfile(conf.dataDir, [conf.prefix '-model.mat']) ;
conf.resultPath = fullfile(conf.dataDir, [conf.prefix '-result']) ;

randn('state',conf.randSeed) ;
rand('state',conf.randSeed) ;
vl_twister('state',conf.randSeed) ;


% --------------------------------------------------------------------
%                                                           Setup data
% --------------------------------------------------------------------


conf.rootDirTrain = fullfile(conf.rootDir,'train',conf.day_folder);
conf.rootDirTest = fullfile(conf.rootDir,'test',conf.day_folder);

pathListTrain = fullfile(conf.pathList,['train_' conf.day '.txt']);
pathListTest = fullfile(conf.pathList,['test_' conf.day '.txt']);

Ytr = load(fullfile(conf.pathList,['Ytr_' conf.day]));
Ytr = Ytr.y;
Yts = load(fullfile(conf.pathList,['Yte_' conf.day]));
Yts = Yts.y;


conf.fileListTrain = textread(pathListTrain,'%s');
conf.fileListTest = textread(pathListTest,'%s');

conf.numDictTrain = ceil(conf.numDictTrain*numel(conf.fileListTrain));

model_phow.phowOpts = conf.phowOpts ;
model_phow.numSpatialX = conf.numSpatialX ;
model_phow.numSpatialY = conf.numSpatialY ;
model_phow.quantizer = conf.quantizer ;
model_phow.vocab = [] ;


% --------------------------------------------------------------------
%                                                     Train vocabulary
% --------------------------------------------------------------------


% Get some PHOW descriptors to train the dictionary
selTrainFeats = vl_colsubset(1:numel(conf.fileListTrain), conf.numDictTrain) ;
descrs = {} ;
%parfor ii = 1:length(selTrainFeats)
for ii = 1:length(selTrainFeats)
tmp_path = fullfile(conf.rootDirTrain,conf.fileListTrain{selTrainFeats(ii)});
im = imread([tmp_path '.ppm']);
im = standarizeImage(im) ;
[~, descrs{ii}] = vl_phow(im, model_phow.phowOpts{:}) ;
end

descrs = vl_colsubset(cat(2, descrs{:}), 10e4) ;
descrs = single(descrs);

% Quantize the descriptors to get the visual words
vocab = vl_kmeans(descrs, conf.numWords, 'verbose', 'algorithm', 'elkan', 'MaxNumIterations', 50) ;
save(conf.vocabPath, 'vocab') ;

% load(conf.vocabPath) ;

model_phow.vocab = vocab ;

if strcmp(model_phow.quantizer, 'kdtree')
  model_phow.kdtree = vl_kdtreebuild(vocab) ;
end



% --------------------------------------------------------------------
%                                          Train - Compute spatial histograms
% --------------------------------------------------------------------

hists = {} ;
%parfor ii = 1:length(conf.fileListTrain)
for ii = 1:length(conf.fileListTrain)
fprintf('Processing %s (%.2f %%)\n', conf.fileListTrain{ii}, 100 * ii / length(conf.fileListTrain)) ;
tmp_path = fullfile(conf.rootDirTrain,conf.fileListTrain{ii});
im = imread([tmp_path '.ppm']);
hists{ii} = getImageDescriptor(model_phow, im);
end

hists = cat(2, hists{:});
save(conf.histPath, 'hists');

%load(conf.histPath) ;


% --------------------------------------------------------------------
%                                                 Train - Compute feature map
% --------------------------------------------------------------------

Xtr = vl_homkermap(hists, 1, 'kchi2', 'gamma', .5)';
feat = Xtr';

save(['Xtr_' conf.day],'feat');
    
% --------------------------------------------------------------------
%                                          Test - Compute spatial histograms
% --------------------------------------------------------------------

hists = {} ;
%parfor ii = 1:length(conf.fileListTest)
for ii = 1:length(conf.fileListTest)
fprintf('Processing %s (%.2f %%)\n', conf.fileListTest{ii}, 100 * ii / length(conf.fileListTest)) ;
tmp_path = fullfile(conf.rootDirTest,conf.fileListTest{ii});
im = imread([tmp_path '.ppm']);
hists{ii} = getImageDescriptor(model_phow, im);
end

hists = cat(2, hists{:});
save(conf.histPath, 'hists');

%load(conf.histPath) ;



% --------------------------------------------------------------------
%                                                 Test - Compute feature map
% --------------------------------------------------------------------

Xts = vl_homkermap(hists, 1, 'kchi2', 'gamma', .5)';

save(['Xts_' conf.day],'feat');


% --------------------------------------------------------------------
%                                                       Train/Test
% --------------------------------------------------------------------


model_gurls = gurls_train(Xtr,Ytr,'kernelfun','linear','nlambda',20,'nholdouts',5,'hoproportion',0.5,'partuning','ho','verbose',0);
Ypred = gurls_test(model_gurls,Xts);

% Compute the confusion matrix
[acc,confus] = trace_confusion(Yts,Ypred);

save(conf.resultPath,'acc','confus');









% -------------------------------------------------------------------------
function im = standarizeImage(im)
% -------------------------------------------------------------------------

im = im2single(im) ;
if size(im,1) > 480, im = imresize(im, [480 NaN]) ; end

% -------------------------------------------------------------------------
function hist = getImageDescriptor(model, im)
% -------------------------------------------------------------------------

im = standarizeImage(im) ;
width = size(im,2) ;
height = size(im,1) ;
numWords = size(model.vocab, 2) ;

% get PHOW features
[frames, descrs] = vl_phow(im, model.phowOpts{:}) ;

% quantize local descriptors into visual words
switch model.quantizer
  case 'vq'
    [~, binsa] = min(vl_alldist(model.vocab, single(descrs)), [], 1) ;
  case 'kdtree'
    binsa = double(vl_kdtreequery(model.kdtree, model.vocab, ...
                                  single(descrs), ...
                                  'MaxComparisons', 50)) ;
end

for i = 1:length(model.numSpatialX)
  binsx = vl_binsearch(linspace(1,width,model.numSpatialX(i)+1), frames(1,:)) ;
  binsy = vl_binsearch(linspace(1,height,model.numSpatialY(i)+1), frames(2,:)) ;

  % combined quantization
  bins = sub2ind([model.numSpatialY(i), model.numSpatialX(i), numWords], ...
                 binsy,binsx,binsa) ;
  hist = zeros(model.numSpatialY(i) * model.numSpatialX(i) * numWords, 1) ;
  hist = vl_binsum(hist, ones(size(bins)), bins) ;
  hists{i} = single(hist / sum(hist)) ;
end
hist = cat(1,hists{:}) ;
hist = hist / sum(hist) ;

% -------------------------------------------------------------------------
function [className, score] = classify(model, im)
% -------------------------------------------------------------------------

hist = getImageDescriptor(model, im) ;
psix = vl_homkermap(hist, 1, 'kchi2', 'gamma', .5) ;
scores = model.w' * psix + model.b' ;
[score, best] = max(scores) ;
className = model.classes{best} ;

% -------------------------------------------------------------------------
function [accuracy,confus] = trace_confusion(Ytrue,Ypred)
% -------------------------------------------------------------------------

if size(Ytrue,2)>1
    [~,Ytrue]=max(Ytrue,[],2); 
end

if size(Ypred,2)>1
    [~,Ypred]=max(Ypred,[],2); 
end

T = max(unique(Ytrue));    

idx = sub2ind([T, T], Ytrue, Ypred) ;
confus = zeros(T) ;
confus = vl_binsum(confus, ones(size(idx)), idx) ;

accuracy = mean(diag(confus)./sum(confus,2));






