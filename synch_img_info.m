function ass_cell = synch_img_info(t_imgs, cols_imgs, t_infos, cols_infos, time_window, subtract_Tstart)

%% subtract common reference time

if subtract_Tstart 
    
    Tstart = min(min(t_imgs{1}), min(t_infos{1}));

    t_imgs{1} = t_imgs{1} - Tstart;
    t_infos{1} = t_infos{1} - Tstart;

end
%% associate

img_count = length(t_imgs{1});

ass_cell = cell(1, length(cols_imgs)+length(cols_infos));

for idx_img = 1:img_count
    
    t_image = t_imgs{1}(idx_img);
    
    if idx_img==1
        t_diff = t_infos{1} - t_image;
        [min_diff, start_idx_vector] = min(abs(t_diff));
    else
        end_idx_vector = min(start_idx_vector + (time_window-1), length(t_infos{1}));
        t_diff = t_infos{1}(start_idx_vector:end_idx_vector) - t_image;
        flag = 1;
        if t_diff(1)<0 && t_diff(end)>=0
            [min_diff, idx_vector] = min(abs(t_diff));
            start_idx_vector = (start_idx_vector-1) + idx_vector;
            flag = 0;
        end
        if t_diff(1)>=0
            flag = 0;
        end
        while (t_diff(end)<0 && end_idx_vector<length(t_infos{1}))
            start_idx_vector = end_idx_vector + 1;
            end_idx_vector = min(start_idx_vector + time_window, length(t_infos{1}));
            t_diff = t_infos{1}(start_idx_vector:end_idx_vector) - t_image;
            if t_diff(1)<0 && t_diff(end)>=0
                [min_diff, idx_vector] = min(abs(t_diff));
                start_idx_vector = start_idx_vector + idx_vector;
                flag = 0;
                break;
            end
            if t_diff(1)>=0
                flag = 0;
                break;
            end
        end
        if flag
            start_idx_vector = end_idx_vector;
        end
    end
    
    %% fill the association data structure
    
    for ii=1:length(cols_imgs)
        ass_cell{ii}(idx_img,1) = t_imgs{cols_imgs(ii)}(idx_img);
    end
    
    for ii=1:length(t_infos)
        ass_cell{ii+length(cols_imgs)}(idx_img,1) = t_infos{cols_infos(ii)}(start_idx_vector);
    end
    
end
