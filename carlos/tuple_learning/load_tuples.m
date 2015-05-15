function tuples = load_tuples(t,subsample)
    
    tuples = load('tuples');
    tuples = tuples.tuples{t-1};
    if nargin>1
        tuples((subsample+1):end)=[];
    end
end