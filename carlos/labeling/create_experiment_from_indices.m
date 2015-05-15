
function [X,y]=create_experiment_from_indices(p)

    X=p.input_codes(:,logical(p.indices)');
    y=p.output_codes(:,logical(p.indices)');
    
end