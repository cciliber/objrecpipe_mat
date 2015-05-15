
function [X,y]=create_experiment(p)

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

    fSize=p.feature_size;
    
    if(strcmp(p.demo,'mix'))
        nGain=2;
    else
        nGain=1;
    end
    
    X=zeros(fSize,length(class_list)*nGain*200);
    y=zeros(length(class_list)*nGain*200,length(class_list));
    cnt=1;
    
    for i=1:length(reg)

        %if the class is not in the active set, continue
        if sum(strcmp(reg{i}{2},class_list))==0
            continue;
        end

        
        if(strcmp(p.demo,'mix') || strcmp(p.demo,reg{i}{3}))
            X(:,cnt)=p.codes(:,i);
            y(cnt,:)=strcmp(reg{i}{2},class_list);
            cnt=cnt+1;
        end       
        
        
    end
    
    idx=ones(p.nSamples,1);
    idx=[idx; zeros(200-p.nSamples,1)];   
    
    if(strcmp(p.sample,'random'))        

        idx=idx(randperm(length(idx)));        

    end
        
        
    idx=repmat(idx,nGain*length(class_list),1);        
            
    X=X(:,logical(idx));
    y=y(logical(idx),:);        

end