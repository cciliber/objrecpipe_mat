function day_lists_all = create_day_list(day_mappings_all, days)

day_lists_all = cell(length(day_mappings_all),1);

for ee=1:length(day_mappings_all)
    
    day_mappings = day_mappings_all{ee};
    Nsets = length(day_mappings);
    day_lists = cell(1,Nsets);
    
    tmp = keys(days);
    for ii=1:Nsets
        for dd=1:length(day_mappings{ii})
            tmp1 = tmp(cell2mat(values(days))==day_mappings{ii}(dd))';
            tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
            day_lists{ii} = [day_lists{ii} tmp2];
        end
    end
    
    day_lists_all{ee} = day_lists;
    
end