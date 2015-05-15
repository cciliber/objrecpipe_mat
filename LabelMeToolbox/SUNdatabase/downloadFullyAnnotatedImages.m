% The SUN database has been annotated with objects and parts. This script
% dowloads the latest set of annotations and provides statistics about
% parts.

% 1) Download a copy of the SUN database
% This will take a while. Make sure you have around 50Gb available
[D, folder, HOMEIMAGES, HOMEANNOTATIONS] = SUNdatabase;

relativearea = LMlabeledarea(D);
good = find(relativearea>.9);

disp(sprintf('There are %d objects', sum(LMcountobject(D(good)))))


yourpathimages = 'SUNDATABASE_objects/Images';
yourpathannotations = 'SUNDATABASE_objects/Annotations';

% simplify folder
for i = 1:length(D)
    D(i).annotation.folder = strrep(D(i).annotation.folder, 'users/antonio/static_sun_database', '');
end

% Add cropped tag
D = addcroplabel(D);

% download
HOMEANNOTATIONS = 'http://labelme.csail.mit.edu/Annotations/users/antonio/static_sun_database';
HOMEIMAGES = 'http://labelme.csail.mit.edu/Images/users/antonio/static_sun_database';

LMinstall(D, yourpathimages, yourpathannotations, HOMEIMAGES, HOMEANNOTATIONS)

% make sure folder names are coherent
ADMINrenamefolder(destAnnotations);


