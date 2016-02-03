day_lists_all = cell(length(day_mappings_all),1);
for ee=1:length(day_mappings_all)
    day_mappings = day_mappings_all{ee};
    day_lists = [];
    tmp = keys(opts.Days);
    for dd=1:length(day_mappings)
        tmp1 = tmp(cell2mat(values(opts.Days))==day_mappings(dd))';
        tmp2 = str2num(cellfun(@(x) x(4:end), tmp1))';
        day_lists = [day_lists tmp2];
    end
    
    day_lists_all{ee} = day_lists;
end