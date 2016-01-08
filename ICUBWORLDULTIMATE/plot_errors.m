%% Visualize errors

fid = fopen('/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_centroid384_disp_finaltree_experiments/tuning/predictions/googlenet/categorization/Ncat_15/2-3-4-5-6-7-8-9-11-12-13-14-15-19-20/vgg_errors.txt');
predictions = textscan(fid, '%s \t %s %d %*[^\n]');
fclose(fid);

fid = fopen('/data/giulia/ICUBWORLD_ULTIMATE/iCubWorldUltimate_registries/categorization/Ncat_15/2-3-4-5-6-7-8-9-11-12-13-14-15-19-20/labels.txt');
labels = textscan(fid, '%s %d');
fclose(fid);

classes = labels{1};
labels = containers.Map(classes, labels{2});

ypred = predictions{3};
classpred = predictions{2};

classtrue = cellfun(@strsplit, predictions{1}, repmat({'/'}, length(predictions{1}),1), 'UniformOutput', 0);
classtrue = vertcat(classtrue{:});
classtrue = classtrue(:, 6);

ytrue = cell2mat(values(labels, classtrue));

Nclasses = length(classes);

wrong = ~cellfun(@strcmp, classtrue, classpred);
Nerrors = sum(wrong);
N = length(wrong);
acc = (N - Nerrors)/N;

% show misclassified frames

badImgs = find(wrong);
for ii=1:Nerrors
    
    I = imread(predictions{1}{badImgs(ii)});
    imshow(I);
    title(['true: ' classtrue{badImgs(ii)} ' - pred: ' classpred{badImgs(ii)}]) 
    k = waitforbuttonpress 
end

% histogram of the errors per class

errPerClass = zeros(Nclasses,1);
wrongPlotted = int32(wrong);

for cc=1:Nclasses

    wrongPerClass = strcmp(classes(cc), classtrue) & wrong==1;
    errPerClass(cc) = sum(wrongPerClass);
    
    wrongPlotted(wrongPerClass) = wrong(wrongPerClass)*cc;
    
end

imagesc(wrongPlotted)
cmap = jet(Nclasses);
colormap([0 0 0; cmap(randperm(Nclasses),:)]);
h = colorbar;
set( h, 'YDir', 'reverse' );

plot(1:Nclasses, errPerClass);
h = gca;
h.XTick = 1:Nclasses;
h.XTickLabel = classes;
h.XTickLabelRotation = 45;
xlim([1 Nclasses])

% conf matrix

[acc, C] = compute_accuracy(ytrue+1, ypred+1, 'carlo');
figure, imagesc(C);
set(gca, 'XTick', 1:Nclasses);
set(gca, 'YTick', 1:Nclasses);
set(gca, 'YTickLabel', classes)
set(gca, 'XTickLabel', classes, 'XTickLabelRotation', 45)
ylabel('true')
xlabel('pred')
grid on
colorbar
