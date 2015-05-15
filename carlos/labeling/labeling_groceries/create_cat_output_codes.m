function y = create_cat_output_codes(p)

    cat_list={
        'bananas'
        'bottles'
        'boxes'
        'bread'
        'cans'
        'lemons'
        'potatos'
        'pears'
        'peppers'
        'yogurt'       
    };


    reg=p.registry;
    y=zeros(length(cat_list),length(reg));
    
    for i=1:length(reg)
        y(:,i)=strcmp(reg{i}{1},cat_list);        
    end
    
end


