function cell_output = filter_allys(cell_output, windows, acc_method)

N1 = size(cell_output,1);

for n1=1:N1
    
    [N2, N3] = size(cell_output{n1});
    
    for n2=1:N2
        for n3=1:N3
            
%             oldfield = 'ypred';
%             newfield = 'ypred_double';
%             cell_output{n1}{n2, n3}.(newfield) = cell_output{n1}{n2, n3}.(oldfield);
%             cell_output{n1}{n2, n3} = rmfield(cell_output{n1}{n2, n3},oldfield);             
            [~, cell_output{n1}{n2, n3}.ypred] = max(cell_output{n1}{n2, n3}.ypred_double, [], 2);

            y_class = cell_output{n1}{n2, n3}.y;
            nsamples = size(y_class,1);
            ypred_double = cell_output{n1}{n2, n3}.ypred_double;
            nclasses = size(ypred_double,2);
             
            y = -ones(nsamples, nclasses);
            y_indices = sub2ind(size(y), 1:nsamples, y_class');
            y(y_indices) = 1;
             
            [y_mode, ypred_mode, accuracy_mode, ~, ~] = filter_y(y, ypred_double, windows, acc_method);
            
            cell_output{n1}{n2, n3}.y_mode = y_mode;
            cell_output{n1}{n2, n3}.ypred_mode = ypred_mode;
            if size(accuracy_mode,1)>1
                cell_output{n1}{n2, n3}.accuracy_mode_perclass = accuracy_mode;
            else
                cell_output{n1}{n2, n3}.accuracy_mode = accuracy_mode;
            end
        end
    end
end