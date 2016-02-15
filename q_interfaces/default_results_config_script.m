
% acc_dimensions is a 
% cell array containing the dimensions in the data
% that we want to average on in the computation of the accuracy
% 1: category
% 2: object
% 3: transf
% 4: day
% 5: cam

Ndims = 5;

% acc_dimensions can be computed in the following way:

% init, based on number of accuracies that we want
Nacc = 8;
acc_dimensions = cell{Nacc,1};

% assign one by one
% keep empty the dimensions that do not matter in the comp of the accuracy

% accuracy
acc_dimensions{1} = 1:Ndims;

% accuracy xCat xObj xTr xDay xCam
acc_dimensions{2} = [];

% accuracy xCat xObj xTr xDay
acc_dimensions{3} = 5;

% accuracy xCat xObj xTr
acc_dimensions{4} = [4 5];

% accuracy xCat xTr
acc_dimensions{5} = [2 4 5];

% accuracy xCat xTr xDay xCam
acc_dimensions{6} = 2;

% accuracy xTr xDay xCam
acc_dimensions{7} = [1 2];

% accuracy xTr
acc_dimensions{8} = [1 2 4 5];

