function iros_bow(day)

% Performs the Object Recognition test with PHOW features using VL_FEAT
% package

if nargin<1
    day = 'lun';
end


conf.rootDir = '/data/DATASET/iCubWorld30';
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

conf.dataDir = './data/bow';
conf.cacheDir = ['./cache/bow/' day];

vl_xmkdir(conf.dataDir) ;
vl_xmkdir(conf.cacheDir) ;


conf.prefix = day ;
conf.randSeed = 1 ;

conf.numDictTrain = 5000;

conf.encoderOpts = {...
  'type', 'bovw', ...
  'numWords', 4096, ...
  'layouts', {'1x1'}, ...
  'geometricExtension', 'xy', ...
  'numPcaDimensions', 100, ...
  'whitening', true, ...
  'whiteningRegul', 0.01, ...
  'renormalize', true, ...
  'extractorFn', @(x) getDenseSIFT(x, ...
                                   'step', 4, ...
                                   'scales', 2.^(0:-.5:-3))};





conf.vocabPath = fullfile(conf.dataDir, [conf.prefix '-vocab.mat']) ;
conf.histPath = fullfile(conf.dataDir, [conf.prefix '-hists.mat']) ;
conf.modelPath = fullfile(conf.dataDir, [conf.prefix '-model.mat']) ;
conf.resultPath = fullfile(conf.dataDir, [conf.prefix '-result']) ;

conf.encoderPath = fullfile(conf.dataDir, [conf.prefix '-encoder']) ;

conf.featuresPathTrain = fullfile(conf.dataDir, ['Xtr_' conf.day]) ;
conf.featuresPathTest = fullfile(conf.dataDir, ['Xte_' conf.day]) ;


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


if conf.numDictTrain<=1.0
    conf.numDictTrain = ceil(conf.numDictTrain*numel(conf.fileListTrain));
end


model_feat.encoderOpts = conf.encoderOpts;


% --------------------------------------------------------------------
%                                                     Train vocabulary
% --------------------------------------------------------------------


% Get some images to train the dictionary
selTrainFeats = vl_colsubset(1:numel(conf.fileListTrain), conf.numDictTrain);

encoder = trainEncoder(fullfile(conf.rootDirTrain,conf.fileListTrain(selTrainFeats)), ...
                         model_feat.encoderOpts{:});

save(conf.encoderPath, '-struct', 'encoder') ;           
          


% --------------------------------------------------------------------
%                                          Train - Compute spatial histograms
% --------------------------------------------------------------------


descrs = encodeImage(encoder, fullfile(conf.rootDirTrain,conf.fileListTrain), ...
  'cacheDir', conf.cacheDir) ;


% --------------------------------------------------------------------
%                                                 Train - Compute feature map
% --------------------------------------------------------------------

Xtr = descr';
feat = Xtr';

save(conf.featuresPathTrain,'feat');
    
% --------------------------------------------------------------------
%                                          Test - Compute spatial histograms
% --------------------------------------------------------------------

descrs = encodeImage(encoder, fullfile(conf.rootDirTest,conf.fileListTest), ...
  'cacheDir', conf.cacheDir) ;

% --------------------------------------------------------------------
%                                                 Test - Compute feature map
% --------------------------------------------------------------------

Xts = descr';
feat = Xts';

save(conf.featuresPathTest,'feat');


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
