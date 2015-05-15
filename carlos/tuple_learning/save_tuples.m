function save_tuples(T)

    subsample_ratio = 1;
    subsample_min = nchoosek(T,2);
    subsample_max = nchoosek(T,2);
    
    
    tuples = cell(T-1,1);
    for t=2:T
        t
        tuples{t-1}=sample_tuples(t,T,subsample_ratio,subsample_min,subsample_max);   
    end
    

    save('tuples.mat','tuples');

end