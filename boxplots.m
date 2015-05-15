
% matrixfp = zeros(339*25+28+1);

matrixfp = [];
grp = [];

for t=1:27
   
    tmpv = [dataforplot{t}.acc];
    matrixfp = [matrixfp  tmpv];
    
    grp = [grp t*ones(1,length(tmpv))];
            
end

figure(2), boxplot(matrixfp, grp, 'boxstyle', 'filled', 'symbol', '+', 'outliersize', 3, 'positions', 2:28);

fontsize = 15;
set(gca, 'FontSize', fontsize);

ylabel('Accuracy', 'FontSize', fontsize);
xlabel('# objects', 'FontSize', fontsize);

set(gca, 'XTick', 2:28);
ylim([0.6 1]);

xticklabels = (2:28)';
xticklabels = cellstr(num2str(xticklabels));
for id=2:2:numel(xticklabels)
    xticklabels{id} = [];
end
set(gca, 'XTickLabel', xticklabels, 'FontSize', fontsize);