% The SUN database has been annotated with objects and parts. This script
% dowloads the latest set of annotations and provides statistics about
% parts.

% 1) Download a copy of the SUN database
% This will take a while. Make sure you have around 50Gb available

yourpathimages = 'SUNDATABASE/Images';
yourpathannotations = 'SUNDATABASE/Annotations';
SUNinstall(yourpathimages, yourpathannotations)

% 2) create the index. You can jump into this step if you have already
% downloaded the database. 
%[D, folder, HOMEIMAGES, HOMEANNOTATIONS] = SUNdatabase('k/kitchen');
[D, folder, HOMEIMAGES, HOMEANNOTATIONS] = SUNdatabase;


% 3) get parts
[Dwithparts, j] = LMfindAnnotatedParts(D);

[objectPartStatistics] = LMpartstatistics(Dwithparts);

[Nimages, NimagesFullyAnnotated, NumberOfAnnotatedObjects, NumberOfAnnotatedObjectsWithParts, NumberOfParts] = SUNstats(D);



LMdbshowobjectparts(D, i);


% select images with people and gaze
[D, folder, HOMEIMAGES, HOMEANNOTATIONS] = SUNdatabase;
[~,j1] = LMquery(D, 'object.name', 'person');
[~,j2] = LMquery(D, 'object.name', 'gaze');
j = intersect(j1,j2);
Dpeople = LMquery(D(j), 'object.name', 'person,gaze');
LMdbshowscenes(Dpeople(1:30), HOMEIMAGES);

