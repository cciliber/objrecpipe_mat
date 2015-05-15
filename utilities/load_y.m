function [y, n, nclasses] = load_y(y_path)

[y_dir, ~, y_ext] = fileparts(y_path);
check_input_dir(y_dir);

if strcmp(y_ext,'.bin')
    
    fid = fopen(y_path, 'r', 'L');
    if (fid==-1)
        fprintf(2, 'Cannot open file: %s', y_path);
    end
    % column major order
    % format for Unix systems (i.e., L, big endian)
    n = fread(fid, 1, 'double');
    nclasses = fread(fid, 1, 'double');
    y = fread(fid, [n nclasses], 'double');
    fclose(fid);
    
elseif strcmp(y_ext,'.mat')
    
    input = load(y_dir, 'n', 'nclasses', 'y');
    nclasses = input.nclasses;
    n = input.n;
    y = input.y;
    
else
    error('Error! Invalid extension.');
end