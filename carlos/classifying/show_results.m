function show_results(exp,y_p,params)


    fid_classes=fopen([params.class_path '/class_order.txt'],'r');
    read_classes=false;
    plotopt.class_names={};

    while~read_classes
        idx=numel(plotopt.class_names)+1;

        tmp_line=fgets(fid_classes);
        if(ischar(tmp_line))
            plotopt.class_names{idx}=tmp_line(1:end-1);
        else
            read_classes=true; 
        end
    end

    fclose(fid_classes);

    y=load(exp.yts);

    for i=1:1:size(y,1)

        img_path=sprintf('%s/%.8d.ppm',exp.yts(1:end-6),i-1);
        if~exist(img_path)
            continue;
        end
        
        I=imread(img_path);
        imshow(I);
        [M idx] = max(y(i,:));
        [M_p idx_p] = max(y_p(i,:));
        title(sprintf('class: %s - result: %s',plotopt.class_names{idx},plotopt.class_names{idx_p}));
        pause;
    end

end

