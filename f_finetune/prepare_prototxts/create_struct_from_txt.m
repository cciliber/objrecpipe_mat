function [s, fnames] = create_struct_from_txt(f, delimiter)
%%% Create a struct from a .txt with a list of 
% 'field_name delimiter field_value' in each line 

fid = fopen(f);

what = textscan(fid, '%s');

fclose(fid);

fnames = what{1};
fvalues = what{2};

for ii=1:length(fnames)
    s.(fnames{ii}) = fvalues{ii};
end