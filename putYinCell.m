function res_struct = putYinCell(dset, REG_array, res_struct)



Ncat = dset.Ncat;
NobjPerCat = dset.NobjPerCat;
Ntransfs = dset.Ntransfs;
Ndays = dset.Ndays;
Ncameras = dset.Ncameras;


Ypred_array = res_struct.Ypred;
Y_array = res_struct.Y;


res_struct.Y = cell(Ncat, NobjPerCat, Ntransfs, Ndays, Ncameras);

res_struct.Ypred = cell(Ncat, NobjPerCat, Ntransfs, Ndays, Ncameras);
%res_struct.Ypred_01 = cell(Ncat, NobjPerCat, Ntransfs, Ndays, Ncameras);

res_struct.Ypred_filtered = cell(Ncat, NobjPerCat, Ntransfs, Ndays, Ncameras);
%res_struct.Ypred01_filtered = cell(Ncat, NobjPerCat, Ntransfs, Ndays, Ncameras);


%% Parse the registry
dirlist = cellfun(@fileparts, REG_array, 'UniformOutput', false);
[dirlist, ia, ic] = unique(dirlist, 'stable'); % [C,ia,ic] = unique(A) % C = A(ia) % A = C(ic)
dirlist_splitted = regexp(dirlist, '/', 'split');
dirlist_splitted = vertcat(dirlist_splitted{:});

%% Get number of frames per directory
Ndirs = numel(dirlist);
Nframes = zeros(Ndirs,1);
for ii=1:length(dirlist)
    Nframes(ii) = sum(ic==ii);
end

%% And its range of indices in the Y arrays
startend = zeros(Ndirs+1,1);
startend(2:end) = cumsum(Nframes);

%% For each directory put the predictions in the correct cell

for ii=1:length(dirlist)
    
    
    cat = dirlist_splitted{ii,1};
    obj = str2double(dirlist_splitted{ii,1}(regexp(dirlist_splitted{ii,2}, '\d'):end));
    transf = dirlist_splitted{ii,3};
    day = dirlist_splitted{ii,4};
    cam = dirlist_splitted{ii,5};
    
    
    idx_start = startend(ii)+1;
    idx_end = startend(ii+1);
    
    
    ytrue = Y_array(idx_start:idx_end);
    ypred = Ypred_array(idx_start:idx_end);
    ypred_filtered = mode(ypred);
    
    res_struct.Y{dset.Cat{cat}, obj, dset.Transfs(transf), dset.Days(day), dset.Cameras(cam)} = ytrue(1);
    
    res_struct.Ypred{dset.Cat{cat}, obj, dset.Transfs(transf), dset.Days(day), dset.Cameras(cam)} = ypred;
    %res_struct.Ypred01{dset.Cat{cat}, obj, dset.Transfs(transf), dset.Days(day), dset.Cameras(cam)} = (ytrue==ypred);
    
    res_struct.Ypred_filtered{dset.Cat{cat}, obj, dset.Transfs(transf), dset.Days(day), dset.Cameras(cam)} = ypred_filtered;
    %res_struct.Ypred01_filtered{dset.Cat{cat}, obj, dset.Transfs(transf), dset.Days(day), dset.Cameras(cam)} = (ytrue(1)==);
    
end