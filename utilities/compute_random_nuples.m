function [nuples, objlist] = compute_random_nuples(Nobj, factor, trend, labels)

% generarion of nuples

x = double(2:Nobj);
yv = 1;
yp = double(round(nchoosek(Nobj, 2)/factor));

if strcmp(trend, 'constant')
    y = yp*ones(size(x));
elseif strcmp(trend, 'linear')
    y = yp + (yv - yp)/(x(end) - x(1))*(x - x(1));
elseif strcmp(trend, 'parabola')
    a = (yp - yv) / (x(1) - x(end))^2;
    b = - 2*a*x(end);
    c = yv + a*x(end)^2;
    y = a*x.^2 + b*x + c;
else
    error('Invalid trend.');
end

Nnuples = round(y);

nuples = cell(Nobj-1,1);
for no=2:Nobj-1
    
    while size(nuples{no-1}, 1)<Nnuples(no-1)
        nuples{no-1}(end+1,:) = randperm(Nobj,no);
        nuples{no-1}(end,:) = sort(nuples{no-1}(end,:));
        nuples{no-1} = unique(nuples{no-1}, 'rows');
    end
    
end
nuples{no} = 1:Nobj;

% labels assignment

objlist = cell(Nobj-1,1);
for no=2:Nobj-1
    
    objlist{no-1} = cell(Nnuples(no-1),1);
    for nu_idx=1:Nnuples(no-1)
        
        objlist{no-1}{nu_idx} = labels(nuples{no-1}(nu_idx,:));
    end
end
objlist{no} = cell(1);
objlist{no}{1} = labels;
