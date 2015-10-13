function [ass_cell, skipping_idxs] = associate_img_info(t_imgs, t_infos, time_window)

%% subtract common reference time

Tstart = min(min(t_imgs{1}), min(t_infos{1}));

t_imgs{1} = t_imgs{1} - Tstart;
t_infos{1} = t_infos{1} - Tstart;

%% store the skipping signals and clear info cell array

skipping_idxs = find(t_infos{2}==-1);
skipping_timestamps = t_infos{1}(skipping_idxs);
for ii=1:length(t_infos)
    t_infos{ii}(skipping_idxs) = [];
end

%% associate!

img_count = length(t_imgs{1});

ass_cell = cell(1, 2+length(t_infos));

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
            start_idx_vector = end_idx_vector;
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
    
    ass_cell{1}(idx_img,1) = t_imgs{2}(idx_img);
    ass_cell{2}(idx_img,1) = t_imgs{1}(idx_img);
    
    for ii=1:length(t_infos)
        ass_cell{ii+2}(idx_img,1) = t_infos{ii}(start_idx_vector);
    end
    
end

%% clear from spurious images

skipping_idxs = find(cellfun(@isempty, strfind(ass_cell{end}, '_')));
for ii=1:length(ass_cell)
    ass_cell{ii}(skipping_idxs) = [];
end

%% return the skipping points

if (length(skipping_timestamps)>0)
    skipping_idxs = zeros(length(skipping_timestamps),1);
    for ii=1:length(skipping_timestamps)
        [foo, skipping_idxs(ii)] = min(abs(ass_cell{3}-skipping_timestamps(ii)));
        if ass_cell{3}(skipping_idxs(ii))-skipping_timestamps(ii)>0
           skipping_idxs(ii) = skipping_idxs(ii) - 1;
        end
    end
else
    skipping_idxs = [];
end