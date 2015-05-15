classdef MyDataset < Features.GenericFeature
    
    properties

        TimestampImages
        TimestampImagesPath
        
        TimestampBlobs 
        TimestampBlobsPath
        
        BlobImageAuto
        BlobImageAutoPath
        
        BlobImageManual
        BlobImageManualPath
        
        ImageCount
        
        Ext
    end
    
    methods
        
        function obj = MyDataset(ext)
            
            obj = obj@Features.GenericFeature();
            obj.Ext = ext;
             
        end

        function downsample(object, in_rootpath, in_registry_path, objlist, out_registry_path, factor, out_rootpath)
       
            if isempty(in_registry_path)
                object.assign_registry_and_tree_from_folder(in_rootpath, objlist, out_registry_path);
            else
                object.assign_registry_and_tree_from_file(in_registry_path, objlist, out_registry_path);
            end
           
            object.reproduce_tree(out_rootpath);
            
            for img_idx=1:object.ExampleCount
                if mod(img_idx,factor)==0
                    copyfile(fullfile(in_rootpath, [object.Registry{img_idx} object.Ext]), fullfile(out_rootpath, [object.Registry{img_idx} object.Ext]));
                    disp(object.Registry{img_idx});
                end
            end  
            
        end
        
        function segment_30(object, in_path, out_path, time_img_path, time_info_path, blob_img_path, box_size)
     
            % read 'imgs.log' and create cell array
            
            time_img_fid = fopen(time_img_path,'r');
            if (time_img_fid==-1)
                error('Error! Please provide a valid path for datalogs file');
            end
           
            if isunix
                [~,img_count] = system(['wc -l < ' time_img_path]);
                img_count = str2num(img_count);
            elseif ispc
                [~,img_count] = system(['find /v /c "&*fake&*" "' time_img_path '"']);
                last_space = strfind(img_count,' ');
                img_count = str2num(img_count((last_space(end)+1):(end-1)));
            end
            
            object.TimestampImages = textscan(time_img_fid, '%d %f %s', img_count);
            object.TimestampImages(1) = [];
            
            fclose(time_img_fid);
                        
            % read 'imginfos.log' and create cell array
            
            time_info_fid = fopen(time_info_path,'r');
            if (time_info_fid==-1)
                error('Error! Please provide a valid path for datalogs file');
            end

            if isunix
                [~,blob_count] = system(['wc -l < ' time_info_path]);
                blob_count = str2num(blob_count);
            elseif ispc
                [~,blob_count] = system(['find /v /c "&*fake&*" "' time_info_path '"']);
                last_space = strfind(blob_count,' ');
                blob_count = str2num(blob_count((last_space(end)+1):(end-1)));
            end
            
            object.TimestampBlobs = textscan(time_img_fid, '%d %f %d %d %d %s', blob_count);
            object.TimestampBlobs(1) = [];
     
            fclose(time_info_fid); 
            
            % write 'blob_img.txt' to associate image and blob
            
            blob_img_fid = fopen(blob_img_path,'w');
            if (blob_img_fid==-1)
                error('Error! Please provide a valid path for datalogs file');
            end
            
            if img_count~=blob_count
                disp('Different number of lines!');
            end
            
            figure
            for img_idx=1:img_count
                
                img_name = object.TimestampImages{2}{img_idx};
                img_t = object.TimestampImages{1}(img_idx);
                
                class_name = object.TimestampBlobs{5}{img_idx};
                img_x = object.TimestampBlobs{2}(img_idx);
                img_y = object.TimestampBlobs{3}(img_idx);
                class_t = object.TimestampBlobs{1}(img_idx);
                
                if (img_t==class_t)
                    
%                      if ~isdir(fullfile(path, class_name))
%                          mkdir(fullfile(path, class_name));
%                      end
%                      movefile(fullfile(path, img_name), fullfile(path, class_name));

                    if ~isdir(fullfile(out_path, class_name))
                        mkdir(fullfile(out_path, class_name));
                    end

                    if exist(fullfile(in_path, class_name, img_name), 'file')
                        
                        img_info = imfinfo(fullfile(in_path, class_name, img_name));
                        
                        if isempty(imformats(img_info.Format))
                            error('Invalid image format.');
                        end
                        
                        I = imread(fullfile(in_path, class_name, img_name));
                        
                        radius = min(box_size,img_x-1);
                        radius = min(radius,img_y-1);
                        radius = min(radius,size(I,2)-img_x);
                        radius = min(radius,size(I,1)-img_y);
                        
                        if radius>10
                            
                            radius2 = radius*2+1;
                            
                            cx = img_x - radius;
                            cy = img_y - radius;
                            w = radius2;
                            h = radius2;
                            
                            rectShape = [cx, cy, w, h];
                            croppedI = imcrop(I,rectShape);
                            
                            imshow(croppedI);
                            imwrite(croppedI, fullfile(out_path, class_name, img_name), img_info.Format);
                            
                            fprintf(blob_img_fid, '%f %d %d %d %s\n', img_t, img_x, img_y, radius, fullfile(class_name, img_name));
                            
                        else
                            disp(['skipped image ' fullfile(in_path, class_name, img_name) ': radius small']);
                        end
                    else
                        disp(['skipped image ' fullfile(in_path, class_name, img_name) ': not exist']);
                    end
                else
                   disp(['skipped image ' fullfile(in_path, class_name, img_name) ': image and blob not correspond']);
                end
                
            end
            
            fclose(blob_img_fid);

        end
 
        function init_raw_20(object, path, time_img_path, time_blob_path)
            
            % Init members
            object.RootPath = path; 
            
            object.Tree = struct('name', {}, 'subfolder', {}); 
            object.ImageCount = cell(2,1); % left and right image numbers
            object.ImageCount{1,1} = 0;
            object.ImageCount{2,1} = 0;
            
            % dataset fields
            [path, name, ext] = fileparts(time_img_path);
            object.TimestampImagesPath{1,1} = fullfile(path, [name '_left' ext]);
            object.TimestampImagesPath{1,2} = fullfile(path, [name '_right' ext]);
            
            time_img_fid{1,1} = fopen(object.TimestampImagesPath{1,1},'w');
            if (time_img_fid{1,1}==-1)
                error('Error! Please provide a valid path for datalogs file');
            end
            time_img_fid{1,2} = fopen(object.TimestampImagesPath{1,2},'w');
            if (time_img_fid{1,2}==-1)
                error('Error! Please provide a valid path for datalogs file');
            end
            
            object.TimestampImages = cell(2, 2); % time + image_path for left/right images
            
            [path, name, ext] = fileparts(time_blob_path);
            object.TimestampBlobsPath{1,1} = fullfile(path, [name '_left' ext]);
            object.TimestampBlobsPath{1,2} = fullfile(path, [name '_right' ext]);
            
            time_blob_fid{1,1} = fopen(object.TimestampBlobsPath{1,1},'w');
            if (time_blob_fid{1,1}==-1)
                error('Error! Please provide a valid path for datalogs file');
            end
            time_blob_fid{1,2} = fopen(object.TimestampBlobsPath{1,2},'w');
            if (time_blob_fid{1,2}==-1)
                error('Error! Please provide a valid path for datalogs file');
            end
            
            object.TimestampBlobs = cell(2,3); % time + blob + folder_path for left/right images
         
            % explore folders creating .Tree, registry file and .Registry
            object.Tree = init_raw_recursive_20(object, time_img_fid, time_blob_fid, '', object.Tree);
            
            fclose(time_img_fid{1});
            fclose(time_blob_fid{1});     
            fclose(time_img_fid{2});
            fclose(time_blob_fid{2});  
        end
        function current_level = init_raw_recursive_20(obj, time_img_fid, time_blob_fid, current_path, current_level)
            
            % get the listing of files at the current level
            files = dir(fullfile(obj.RootPath, current_path));
            
            for idx_file = 1:size(files)
                
                % for each folder, create its duplicate in the sift hierarchy
                % then get inside it and repeat 'explore_next_level' recursively
                if (files(idx_file).name(1)~='.')
                    
                    if (files(idx_file).isdir)
                        
                        tmp_path = current_path;
                        current_path = fullfile(current_path, files(idx_file).name);
                        
                        current_level(length(current_level)+1).name = files(idx_file).name;
                        current_level(length(current_level)).subfolder = struct('name', {}, 'subfolder', {});
                        current_level(length(current_level)).subfolder = init_raw_recursive(obj, time_img_fid, time_blob_fid, current_path, current_level(length(current_level)).subfolder);
                        
                        % fall back to the previous level
                        current_path = tmp_path;
                        
                    else
                        
                        % for each image put its path in the registry file
                        file_src = fullfile(current_path, files(idx_file).name);
                        [file_path, file_name, file_ext] = fileparts(file_src);
                        if ~isempty(obj.Ext) % if it is specified
                            % with the specified extension
                            file_ext = obj.Ext;
                            file_src = fullfile(file_path, file_name, file_ext);
                        end
                        
                        [upper_path, current_folder] = fileparts(current_path);
                        
                        % keep track of the left/right eye
                        % start from the asssumption that the tree is
                        % .../left-right/image-blob
                        [~, eye] = fileparts(upper_path);
                        
                        if strcmp(eye, 'left')
                            eye = uint8(1);
                        elseif strcmp(eye, 'right')
                            eye = uint8(2);
                        else
                            error('Invalid tree (expected: .../left-right/image .../left-right/blob)');
                        end
    
                        % read the data.log file and load its content
                        if (strcmp([file_name file_ext], 'data.log'))
                            
                            fid = fopen(fullfile(obj.RootPath, file_src));
                            
                            if isunix
                                [~,line_count] = system(['wc -l < ' fullfile(obj.RootPath, file_src)]);
                                line_count = str2num(line_count);
                            elseif ispc
                                [~,line_count] = system(['find /v /c "&*fake&*" "' fullfile(obj.RootPath, file_src) '"']);
                                last_space = strfind(line_count,' ');
                                line_count = str2num(line_count((last_space(end)+1):(end-1)));
                            end

                            if strcmp(current_folder, 'blob')
                                % keep only the first bounding box
                                parsed_data = textscan(fid, '%d %f (%d %d %d) %*[^\n]', line_count);
                                obj.TimestampBlobs{eye,1}((end+1):(end+line_count),:) = parsed_data{2};
                                obj.TimestampBlobs{eye,2}((end+1):(end+line_count),:) = [parsed_data{3} parsed_data{4} parsed_data{5}];
                                obj.TimestampBlobs{eye,3}((end+1):(end+line_count),:) = repmat({current_path}, line_count, 1);
                                % print the last read values (line_count)
                                for line_idx=(line_count-1):-1:0
                                    fprintf(time_blob_fid{1,eye}, '%f %d %d %d %s\n', obj.TimestampBlobs{eye,1}(end-line_idx), obj.TimestampBlobs{eye,2}(end-line_idx, 1), obj.TimestampBlobs{eye,2}(end-line_idx, 2), obj.TimestampBlobs{eye,2}(end-line_idx, 3), obj.TimestampBlobs{eye,3}{end-line_idx});
                                end    
                                
                            elseif strcmp(current_folder, 'image')
                                parsed_data = textscan(fid, '%d %f %s', line_count);
                                obj.TimestampImages{eye,1}((end+1):(end+line_count),:) = parsed_data{2}; 
                                obj.TimestampImages{eye,2}((end+1):(end+line_count),:) = strcat([current_path filesep], parsed_data{3});
                                % print the last read values (line_count)
                                for line_idx=(line_count-1):-1:0
                                    fprintf(time_img_fid{1,eye}, '%f %s\n', obj.TimestampImages{eye,1}(end-line_idx), obj.TimestampImages{eye,2}{end-line_idx});
                                end    
                            end
 
                            fclose(fid);
    
                        elseif (~strcmp([file_name file_ext], 'info.log'))
                            obj.ImageCount{eye,1} = obj.ImageCount{eye,1} + 1;
                        end
                    end
                end
            end
        end

        function segment_dataset(object, modality_user, time_window, box_size, in_rootpath, out_rootpath, out_blobimg_path)
            
            object.assign_registry_and_tree_from_folder(in_rootpath, [], []);


            object.reproduce_tree(out_rootpath);
            
            fid = fopen(out_blobimg_path,'w');
            if (fid==-1)
                error('Error! Please provide a valid path for output blobs');
            end
            
            if sum(strcmp(modality_user, 'manual') || strcmp(modality_user, 'auto+manual'))
                
                fig_handle = figure;
                
                handles = guidata(fig_handle);
                
                % store info on rectangle shape and color
                handles.halfw = box_size;
                handles.halfh = box_size;
                handles.rectColor = [0 1 0];
                handles.rectHandle = [];
                
                % store modality
                handles.modality = modality_user;
                
                guidata(fig_handle, handles);
                
                % set callback for key press on figure
                set(fig_handle,'KeyPressFcn',@object.getKeyPressOnFigure);

            elseif strcmp(modality_user, 'auto')
              
                fig_handle = struct;
                
                fig_handle.halfw = box_size;
                fig_handle.halfh = box_size;
                
            end
            
            if strcmp(modality_user, 'manual')
                
                set(fig_handle, 'WindowButtonMotionFcn', @object.drawBlob, 'Interruptible', 'off', 'BusyAction', 'cancel');
                %set(fig_handle, 'WindowButtonMotionFcn', @object.drawBlob, 'Interruptible', 'off', 'BusyAction', 'queue');
                
                object.BlobImageManual = cell(2,1); % blob + image_path
                
                object.BlobImageManual{1} = cell(object.ExampleCount,1);
                object.BlobImageManual{2} = zeros(object.ExampleCount,3);
                
                object.BlobImageManualPath = out_blobimg_path;
                
            elseif sum(strcmp(modality_user, 'auto') || strcmp(modality_user, 'auto+manual'))
                
                object.BlobImageAuto = cell(2,2); % blob + image_path for left and right eye
                
                object.BlobImageAuto{eye_idx,1} = cell(object.ImageCount{eye_idx,1},1);
                object.BlobImageAuto{eye_idx,2} = zeros(object.ImageCount{eye_idx,1},3);
                
                object.BlobImageAutoPath = out_blobimg_path;
            end

            if sum(strcmp(modality_user, 'manual') || strcmp(modality_user, 'auto+manual'))
                
                % ask the user to insert an output directory for the first time
                in_relative_path = object.Registry{1};
                [im_path, im_name, im_ext] = fileparts(in_relative_path);
                
                handles = guidata(fig_handle);
                
                handles.outputPath = fullfile(object.RootPath, im_path);
                handles.outputDir = [];
                handles.outputDir = object.changeOutputDir(handles.outputPath, handles.outputDir);
                
                guidata(fig_handle, handles);
                
            end
            
            for idx_img = 1:object.ExampleCount
                
                in_relative_path = object.Registry{idx_img};
                img_src = fullfile(object.RootPath, [in_relative_path object.Ext]);
                
                if sum(strcmp(modality_user, 'auto') || strcmp(modality_user, 'auto+manual'))
                    
                    t_img = object.TimestampImages{eye_idx,1}(idx_img);
                    
                    if idx_img==1
                        t_diff = object.TimestampBlobs{eye_idx,1} - t_img;
                        [t_blob, start_idx_blob] = min(abs(t_diff));
                    else
                        end_idx_blob = min(start_idx_blob + time_window, length(object.TimestampBlobs{eye_idx,1}));
                        t_diff = object.TimestampBlobs{eye_idx,1}(start_idx_blob:end_idx_blob) - t_img;
                        flag = 1;
                        if t_diff(1)<0 && t_diff(end)>=0
                            [t_blob, idx_blob] = min(abs(t_diff));
                            start_idx_blob = start_idx_blob + idx_blob;
                            flag = 0;
                        end
                        if t_diff(1)>=0
                            flag = 0;
                        end
                        while (t_diff(end)<0 && end_idx_blob<length(object.TimestampBlobs{eye_idx,1}))
                            start_idx_blob = end_idx_blob;
                            end_idx_blob = min(start_idx_blob + time_window, length(object.TimestampBlobs{eye_idx,1}));
                            t_diff = object.TimestampBlobs{eye_idx,1}(start_idx_blob:end_idx_blob) - t_img;
                            if t_diff(1)<0 && t_diff(end)>=0
                                [t_blob, idx_blob] = min(abs(t_diff));
                                start_idx_blob = start_idx_blob + idx_blob;
                                flag = 0;
                                break;
                            end
                            if t_diff(1)>=0
                                flag = 0;
                                break;
                            end
                        end
                        if flag
                            start_idx_blob = end_idx_blob;
                        end
                    end
                    
                    blob_img = object.TimestampBlobs{eye_idx,2}(start_idx_blob, :);
                    
                    object.BlobImageAuto{eye_idx,1}{idx_img} = in_relative_path;
                    object.BlobImageAuto{eye_idx,2}(idx_img,:) = blob_img;
                    
                elseif strcmp(modality_user, 'manual')
                    
                    blob_img = [];
                    
                end
                
                if sum(strcmp(modality_user, 'manual') || strcmp(modality_user, 'auto+manual'))
                    
                    [im_path, im_name, ~] = fileparts(in_relative_path);
                    
                    handles = guidata(fig_handle);
                    
                    handles.outputPath = fullfile(out_rootpath, im_path);
                    img_dst = fullfile(handles.outputPath, handles.outputDir, [im_name object.Ext]);
                    
                    guidata(fig_handle, handles);
                    
                elseif strcmp(modality_user, 'auto')
                    
                    img_dst = fullfile(object.RootPath, in_relative_path);
                    
                end
                
                [blob_img, quit] = segment_image(object, modality_user, blob_img, img_src, img_dst, fig_handle);
                
                if quit==1
                    break;
                end
                
                if quit==0
                    
                    if strcmp(modality_user,'manual')
                        
                        object.BlobImageManual{2}(idx_img,:) = blob_img;
                        object.BlobImageManual{1}{idx_img} = in_relative_path;
                        
                    elseif sum(strcmp(modality_user,'auto+manual') || strcmp(modality_user,'auto'))
                        
                        object.BlobImageAuto{eye_idx,2}(idx_img,:) = blob_img;
                        object.BlobImageAuto{eye_idx,1}{idx_img} = in_relative_path;
                    end
                    
                    fprintf(fid, '%s %d %d %d\n', in_relative_path, blob_img(1), blob_img(2), blob_img(3));
                    
                end
                
                disp([num2str(idx_img) '/' num2str(object.ExampleCount)]);
                
            end
           
            if sum(strcmp(modality_user,'auto+manual') || strcmp(modality_user,'manual'))
                close(fig_handle); 
            end
            
            % close output file
            fclose(fid);

        end

        function clean_and_label_dataset(object, eye, prev_object)
            
            if strcmp(eye,'left')
                eye_idx = 1;
            elseif strcmp(eye, 'right')
                eye_idx = 2;
            end
            
            if isempty(prev_object.RootPath)
                error('Error! Missing RootPath in previous object for loading features.');
            end
            
            scnsize = get(0,'ScreenSize');
            figpos = [scnsize(3)/4 scnsize(4)/4 scnsize(3)/2 scnsize(4)/2];
            fig_handle = figure('Position', figpos);
          
            handles = guidata(fig_handle);
            
            handles.table_data = cell(20,7); 
         
            tablepos = [figpos(3)/8 figpos(4)/8 figpos(3)*3/4 figpos(4)*3/4];
            columnname = {'start idx', 'end idx', 'img #', 'folder name', 'start idx', 'end idx', 'img #'};
            columnformat = {'numeric', 'numeric', 'numeric', 'char', 'numeric', 'numeric', 'numeric'};
            columnwidth = {95};
            columneditable =  [true true false true true true false]; 
            
            table_handle = uitable('Parent',fig_handle,'Data',handles.table_data,...
            'Position', tablepos, ...
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnWidth', columnwidth,...
            'ColumnEditable', columneditable,...
            'RowName',[],...
            'CellEditCallback', @object.table_cell_edit);
        
            guidata(fig_handle, handles);
        end
        
        function table_cell_edit(object, tableHandle, eventData)
 
            %eventData.NewData 
            
            if ~isempty(eventData.Error)
                msgbox(eventData.Error);
            end
            
            handles = guidata(tableHandle);
            
            handles.table_data = get(tableHandle,'Data');
            if sum(eventData.Indices(2)==[1 2 5 6])
                parity = mod(eventData.Indices(2),2);
                col_modified = eventData.Indices(2)+parity+1;
                end_idx = handles.table_data{eventData.Indices(1),col_modified-1};
                if isempty(end_idx)
                    end_idx = 0;
                end
                start_idx = handles.table_data{eventData.Indices(1),col_modified-2};
                if isempty(start_idx)
                    start_idx = 0;
                end
                handles.table_data{eventData.Indices(1),col_modified} = end_idx-start_idx+1; 
                set(tableHandle,'Data',handles.table_data); 
            end
            
            guidata(tableHandle, handles);
        end
        
        function [blob, quit] = segment_image(obj, mod_user, blob, src, dst, figHandle)
          
            img_info = imfinfo(src);
            
            if isempty(imformats(img_info.Format))
                error('Invalid image format.');
            end
            I = imread(src);
            
            if sum(strcmp(mod_user,'auto+manual') || strcmp(mod_user,'manual'))
                
                figure(figHandle);
                
                imgHandle = imshow(I);
                
                % show pixel coordinates
                % pxinfoHandle = impixelinfoval(figHandle,imgHandle);
                
                % set callback for mouse click
                set(imgHandle,'ButtonDownFcn',@obj.checkBlob);
                
                % conditions for the callbacks to work
                % if 'HitTest' is 'on' the click is on the IMAGE object
                % and not on the UNDERLYING AXES
                set(imgHandle,'HitTest','on');
                pan off, zoom off
                % set hold to on to draw the rectangle on the image
                hold on
                
                % retrieve data
                handles = guidata(imgHandle);
                
                % init modality
                handles.modality = mod_user;
                
                if strcmp(mod_user, 'auto+manual')
                    
                    % disable the callback
                    set(figHandle, 'WindowButtonMotionFcn', '');
                    
                end
                
                % init Blob
                handles.Blob = blob;
                
                % init Quit
                handles.Quit = 0;
                quit = 0;
                
                % store data
                guidata(imgHandle,handles);
                
                % show initial rectangle in the middle
                obj.drawBlob(imgHandle, []);
                
                % block execution until uiresume is called
                % in checkBlob or in getKeyPressOnFigure
                uiwait(figHandle);
                
                % retrieve data
                handles = guidata(imgHandle);
                
                if handles.Quit==0
                    
                    % return blob
                    blob = int32(handles.Blob);
                    
                    % crop the image (if I am here the blob is valid)
                    x = blob(1)- handles.halfw;
                    y = blob(2) - handles.halfh;
                    w = 2*handles.halfw + 1;
                    h = 2*handles.halfh + 1;
                    
                    rectShape = [x, y, w, h];
                    croppedI = imcrop(I,rectShape);
                    
                    % save the cropped image
                    imwrite(croppedI, dst, img_info.Format);
                    
                end
                
                % return quit signal
                quit = handles.Quit;
                
            elseif strcmp(mod_user, 'auto')
                
                % crop the image (if I am here the blob is valid) 
                halfw = figHandle.halfw;
                halfh = figHandle.halfh;
                w = 2*halfw + 1;
                h = 2*halfh + 1;
                
                xLimits = [1 size(I,2)];
                yLimits = [1 size(I,1)];
                xcoord = blob(1);
                ycoord = blob(2);       
                if (xcoord > min(xLimits) && xcoord < max(xLimits) && ycoord > min(yLimits) && ycoord < max(yLimits))
                    
                    % compute blob
                    x = xcoord - halfw;
                    y = ycoord - halfh;
                    bounding_box = [x,y,w,h];  
                    
                    croppedI = imcrop(I,bounding_box);
                
                    % save the cropped image
                    imwrite(croppedI, dst, img_info.Format);
                
                    quit = 0;
                    
                else 
                    message = sprintf('Automatic segmentation: blob center out of image!\n%s: saving original image.', dst);
                    disp(message);
                end
   
            end

        end

        function drawBlob(object, currHandle, eventData)
            
            if ~isempty(imhandles(currHandle))
                
                handles = guidata(currHandle);
                
                % retrieve rectangle properties
                halfw = handles.halfw;
                halfh = handles.halfh;
                w = 2*halfw + 1;
                h = 2*halfh + 1;
                rectColor = handles.rectColor;

                % retrieve image size
                xLimits = ceil(get(gca, 'xlim'));
                yLimits = ceil(get(gca, 'ylim'));
                
                if strcmp(handles.modality, 'manual')
                    
                    % delete previous blob
                    handles.Blob = [];
                    
                    % retrieve coordinates
                    coordinates = get(gca,'CurrentPoint');
                    xcoord = coordinates(1,1);
                    ycoord = coordinates(1,2);
                    
                elseif strcmp(handles.modality, 'auto+manual')
                
                    xcoord = handles.Blob(1);
                    ycoord = handles.Blob(2);
                end
                
                % if coordinates are valid
                if (xcoord > min(xLimits) && xcoord < max(xLimits) && ycoord > min(yLimits) && ycoord < max(yLimits))
                    
                    if strcmp(handles.modality, 'manual')
                        % create new blob
                        handles.Blob = [xcoord, ycoord, (w+1)*(h+1)];
                    end
                    
                    x = xcoord - halfw;
                    y = ycoord - halfh;
                    rectShape = [x, y, w, h];
                    
                    % draw rectangle (eventually deleting previous one)
                    if isempty(handles.rectHandle) || ~isfield(handles, 'rectHandle')
                        handles.rectHandle = rectangle('Position',rectShape,'EdgeColor',rectColor, 'EraseMode', 'xor');
                    else
                        set(handles.rectHandle, 'Position',rectShape,'EdgeColor',rectColor);
                    end
                    
                end

                guidata(currHandle, handles);
                
            end
                
        end
        
        function checkBlob(object, imgHandle, eventData)
                 
            handles = guidata(imgHandle);
            
            if ~isempty(handles.Blob)
  
                % resume execution...
                uiresume(imgcf);    
                
                % ...to save and step to next image
                handles.Quit = 0;
                
                guidata(imgHandle, handles);
            end

        end
          
        function getKeyPressOnFigure(object, figHandle, eventData)
            
            handles = guidata(figHandle);
            
            if (eventData.Character == 'q')
                
                % resume execution...
                uiresume(figHandle);
                
                % ...to quit
                msgbox('Ciao :)');
                handles.Quit = 1;

            end
            
            if (eventData.Character == 'd')
                
                % resume execution...
                uiresume(figHandle);
                
                % ...to jump on next image
                handles.Quit = 2;
                
            end
            
            if (eventData.Character == 'c')
                
                handles.outputDir = object.changeOutputDir(handles.outputPath, handles.outputDir);

            end
            
            if strcmp(handles.modality, 'auto+manual') && strcmp(eventData.Key,'return')
                
                set(figHandle, 'WindowButtonMotionFcn', @object.drawBlob, 'Interruptible', 'off', 'BusyAction', 'cancel');
                %set(figHandle, 'WindowButtonMotionFcn', @object.drawBlob, 'Interruptible', 'off', 'BusyAction', 'queue');
                
                handles.modality = 'manual';
                
            end
            
            guidata(figHandle, handles);
            
        end

        function currentDir = changeOutputDir(object, path, oldDir)
            
            prompt = 'Enter directory name:';
            name = path;
            numlines = 1;
            newDir = inputdlg(prompt, name, numlines);
            
            % build new output path
            % if the user press Cancel, dirName is []
            % in this case, the output path is preserved
            if isempty(newDir)
                currentDir = oldDir;
                return;
            else
                currentDir = newDir;
            end
            
            currentDir = char(currentDir);
            currentPath = fullfile(path, currentDir);
            
            while isdir(currentPath)
                
                prompt = 'Directory already exists: do you want to write there?';
                yncButton = questdlg(prompt, name, 'Yes', 'No', 'No');
                
                if strcmp(yncButton, 'Yes')
                    
                    break;
                    
                elseif strcmp(yncButton, 'No')
                    
                    isDigit = isstrprop(currentDir(end), 'digit');
                    if isDigit
                        counter = str2double(currentDir(end)) + 1;
                        defaultanswer = {[currentDir(1:(end-1))  num2str(counter)]};
                    else
                        counter = 1;
                        defaultanswer = {[currentDir '_' num2str(counter)]};
                    end
                    
                    prompt = 'Enter directory name:';
                    newDir = inputdlg(prompt, name, numlines, defaultanswer);
                    
                    % build new output path
                    % if the user press Cancel, dirName is []
                    % in this case, the output path is preserved
                    if isempty(newDir)
                        currentDir = oldDir;
                        return;
                    else
                        currentDir = newDir;
                    end
                    
                    currentDir = char(currentDir);
                    currentPath = fullfile(path, currentDir);
                    
                end
                
            end
            
            if ~isdir(currentPath)
                mkdir(currentPath);
            end
            
        end

    end
end

