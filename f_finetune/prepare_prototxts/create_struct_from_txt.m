function s = create_struct_from_txt(f_types, f_values)
%%% Create a struct from a .txt with a list of 
% 'field_name delimiter field_value' in each line 

fid = fopen(f_types);
what = textscan(fid, '%s %s');
fnames = cellfun(@(x) x(1:end-1), what{1}, 'UniformOutput', 0);
ftypes = what{2};
fclose(fid);

fvalues = cell(length(fnames),1);
fid = fopen(f_values);
ii = 1;
tline = fgetl(fid);
while ischar(tline)
    fvalues{ii} = textscan(tline, ['%s ' ftypes{ii}]);
    if iscell(fvalues{ii}{2})
        fvalues(ii) = fvalues{ii}{2};
    else
        fvalues{ii} = fvalues{ii}{2};
    end
    ii = ii+1;
    tline = fgetl(fid);
end
fclose(fid);

for ii=1:length(fnames)
    s.(fnames{ii}) = fvalues{ii};
end

% don't know if it is necessary
orderfields(s, fnames);