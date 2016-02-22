
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
% keep empty the dimensions that do not matter in the comp of the accuracy

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% accuracy
acc_dimensions{1} = 1:Ndims;

% accuracy xCat xObj xTr xDay xCam
acc_dimensions{2} = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


feat_name = 'fc7';

% accuracy xCat xObj xTr
%acc_dimensions{end+1} = [4 5];

% accuracy xCat xTr
%acc_dimensions{end+1} = [2 4 5];

% accuracy xTr xDay xCam
%acc_dimensions{end+1} = [1 2];

% accuracy xTr
%acc_dimensions{end+1} = [1 2 4 5];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% accuracy xObj xTr xDay xCam
acc_dimensions{end+1} = 1;

% accuracy xCat xTr xDay xCam
%acc_dimensions{end+1} = 2;

% accuracy xCat xObj xDay xCam
acc_dimensions{end+1} = 3;

% accuracy xCat xObj xTr xCam
%acc_dimensions{end+1} = 4;

% accuracy xCat xObj xTr xDay
%acc_dimensions{end+1} = 5;














