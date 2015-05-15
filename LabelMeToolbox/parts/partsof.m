function D = partsof(D,name,parts,thresh)
% Finds the parts of an object and modifies the database structure D so
% that parts point to the object to which it belongs.  To find the parts
% of a "car", do the following:
%
% D = partsof(D,'car');
%
% If object j in image i is a part of a car, then
% D(i).annotation.object(j).partof will be set to the ID of the car to
% which it belongs in the image.

if nargin < 4
    thresh = 0.5;
end
counter_partsadded = 0;

[~,jj] = LMquery(D,'object.name',[name ',' parts]);

for ii = 1:length(jj)
    jo = LMobjectindex(D(jj(ii)).annotation,name);
    jp = LMobjectindex(D(jj(ii)).annotation,parts);
    M = zeros(length(jo),length(jp));
    for kk = 1:length(jo)
        for ll = 1:length(jp)
            M(kk,ll) = 0;
            [XXo,YYo] = getLMpolygon(D(jj(ii)).annotation.object(jo(kk)).polygon);
            [XXp,YYp] = getLMpolygon(D(jj(ii)).annotation.object(jp(ll)).polygon);

            ro = [min(XXo) min(YYo) max(XXo) max(YYo)];
            rp = [min(XXp) min(YYp) max(XXp) max(YYp)];

            if rect_intersect(ro,rp) >= thresh
                Ao = polyarea(XXo,YYo);
                Ap = polyarea(XXp,YYp);
                if Ao > Ap
                    M(kk,ll) = int_area(XXo,YYo,XXp,YYp)/Ap;
                end
            end
        end
    end
    
    [part_score,ind_object] = max(M,[],1);
    
    %
    % 
    
    for kk = 1:length(ind_object)
        if part_score(kk) >= thresh

            ids = getID(D(jj(ii)).annotation);
            
            object_id = ids(jo(ind_object(kk)));
            part_id = ids(jp(kk));

            D(jj(ii)).annotation = addpart_i_to_object_j(D(jj(ii)).annotation, part_id, object_id);
            
            counter_partsadded = counter_partsadded+1;
        end
    end
end



fprintf('There have been %d parts added. \n', counter_partsadded)

function annotation = addpart_i_to_object_j(annotation,part_id,object_id)


[ids] = getID(annotation);

% transform ids into indices:
i = find(ids==part_id);
j = find(ids==object_id);


if isfield(annotation.object, 'parts') && isfield(annotation.object(j).parts, 'ispartof') && ~isempty(annotation.object(j).parts.ispartof)
    % if there are already some parts:
    disp('This object has already parts')
    return
else
    % if there are no other parts
    annotation.object(i).parts.ispartof = num2str(object_id);
end

if isfield(annotation.object, 'parts') && isfield(annotation.object(j).parts, 'hasparts') && ~isempty(annotation.object(j).parts.hasparts)
    % if there are already some parts:
    annotation.object(j).parts.hasparts = [annotation.object(j).parts.hasparts ',' num2str(part_id)];
else
    % if there are no other parts
    annotation.object(j).parts.hasparts = num2str(part_id);
end



function [v] = getID(annotation)

if isfield(annotation,'object') && isfield(annotation.object(1),'id')
    %v = str2double({annotation.object(:).id});
    v = [annotation.object(:).id];
    %j = find(~isnan(v));
    %v = v(j);
    if length(v) ~= length(unique(v))
        error('WARNING: getID(): There are duplicate IDs!');
    end
else
    v = [];
    %j = [];
end

function tt = rect_intersect(ro,rp)
% min_x,min_y,max_x,max_y

tt = 0;
wo = ro(3)-ro(1);
ho = ro(4)-ro(2);
wp = rp(3)-rp(1);
hp = rp(4)-rp(2);
if (wp*hp) > 0
    tt = rectint([ro(1) ro(2) wo ho],[rp(1) rp(2) wp hp]) / (wp*hp);
end
