function y = create_output_codes(p)

    class_list={
        'banana_1'
        'coke'
        'santal'
        'box_blue'
        'box_brown'
        'kinder'
        'big_bread'
        'olives'
        'lemon_1'
        'pear_4'
        'pepper_red'
        'potato_1'
        'fruity'
        'muller'
        'chickpeas'        
    };


    reg=p.registry;
    y=zeros(length(class_list),length(reg));
    
    for i=1:length(reg)
        y(:,i)=strcmp(reg{i}{2},class_list);        
    end
    
end


