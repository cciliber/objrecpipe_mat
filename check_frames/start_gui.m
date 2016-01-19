function start_gui (dset_in_root, dset_out_root, cat, obj, tr, day_list, modality)

for dd=1:length(day_list)
    
    day = day_list{dd};
    
    in_dir = fullfile( dset_in_root, cat, obj, tr, day);
    out_dir = fullfile( dset_out_root, cat, obj, tr, day);
    
    fid = fopen(fullfile(in_dir, 'img_info_LR.txt'));
    if fid==-1
        continue
    end
    
    % (imgR_path, imgR_t, bbR_t, bbR_cx, bbR_cy, imgL_path, imgL_t, bbL_t, bbL_cx, bbL_cy, bbL_pxN, bbL_tlx, bbL_tly, bbL_w, bbL_h)
    infolist = textscan(fid, '%s %.6f %.6f %d %d %s %.6f %.6f %d %d %d %d %d %d %d\n');
    fclose(fid);
    
    % take data from infolist
    
    imgR_path = cellfun(@(x) [x(1:end-4) '.jpg'], infolist{1}, 'UniformOutput', 0);
    bbR_cx = infolist{4};
    bbR_cy = infolist{5};
    
    imgL_path = cellfun(@(x) [x(1:end-4) '.jpg'], infolist{6}, 'UniformOutput', 0);
    bbL_cx = infolist{9};
    bbL_cy = infolist{10};
    
    bbL_tlx = infolist{12};
    bbL_tly = infolist{13};
    bbL_w = infolist{14};
    bbL_h = infolist{15};
   
    fig_handle = figure;
    scrsz = get(groot,'ScreenSize');
                   
    %montage(fullfile(in_dir, 'right', imgR_path), 'Size', [2 NaN]);
    montage(fullfile(in_dir, 'right', imgR_path));
    
    set(fig_handle, 'Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);
    
    x=1:10;
    scrollsubplot(3,1,-1), plot(x, 2+x)
      scrollsubplot(3,1,1), plot(x, 2+x)
      scrollsubplot(3,1,2), plot(x, 2+x)
      scrollsubplot(3,1,3), plot(x, 2+x)
      scrollsubplot(3,1,4), plot(x, 2+x)

% Create the figure
hFig1 = figure('Toolbar','none', 'Menubar','none', 'Name','My Image Compare Tool', 'NumberTitle','off', 'IntegerHandle','off');
hIm1 = imdisp(fullfile(in_dir, 'right', imgR_path), 'Size', [2 10])
 x=1:10;
      h(1) = subplot(3,1,1), imagesc(zeros(100))
      h(2) = subplot(3,1,2), imagesc(zeros(100))
      h(3) = subplot(3,1,3), imagesc(zeros(100))
      selectplots(h)
%cmontage(fullfile(in_dir, 'right', imgR_path), 'Size', [2 NaN]);

hFig2 = figure('Toolbar','none', 'Menubar','none', 'Name','My Image Compare Tool', 'NumberTitle','off', 'IntegerHandle','off');
hIm2 = montage(fullfile(in_dir, 'left', imgL_path), 'Size', [2 NaN]);

hSP1 = imscrollpanel(hFig1,hIm1);
set(hSP1,'Units','normalized','Position',[0 .1 1 .9]);

hSP2 = imscrollpanel(hFig2,hIm2);
set(hSP2,'Units','normalized','Position',[0 .1 1 .9]);

% Add an Overview tool
hOvPanel = imoverview(hIm1);
set(hOvPanel,'Units','Normalized', 'Position',[0 0.1 1 .3])

% Get APIs from the scroll panels 
api1 = iptgetapi(hSP1);
api2 = iptgetapi(hSP2);

% Synchronize left and right scroll panels
mag = api2.getMagnification();
api2.setMagnification(0.4);
api1.setMagnification(api2.getMagnification())
api1.setVisibleLocation(api2.getVisibleLocation())

% When magnification changes on left scroll panel, tell right scroll panel
api1.addNewMagnificationCallback(api2.setMagnification);

% When magnification changes on right scroll panel, tell left scroll panel
api2.addNewMagnificationCallback(api1.setMagnification);

% When location changes on left scroll panel, tell right scroll panel
api1.addNewLocationCallback(api2.setVisibleLocation);

% When location changes on right scroll panel, tell left scroll panel
api2.addNewLocationCallback(api1.setVisibleLocation);
    
handles = guidata(fig_handle);
    
end

% hplot = plot(x,0*x);
% h = uicontrol('style','slider','units','pixel','position',[20 20 300 20]);
% addlistener(h,'ActionEvent',@(hObject, event) makeplot(hObject, event,x,hplot));
% 
% 
% 
%     if strcmp(modality, 'cc')
%         
%         fig_handle = figure;
%         
%         handles = guidata(fig_handle);
%         
%         % store info on rectangle shape and color
%         handles.halfw = box_size;
%         handles.halfh = box_size;
%         handles.rectColor = [0 1 0];
%         handles.rectHandle = [];
%         
%         % store modality
%         handles.modality = modality;
%         
%         guidata(fig_handle, handles);
%         
%         % set callback for key press on figure
%         set(fig_handle,'KeyPressFcn',@object.getKeyPressOnFigure);
%         
%     
%     if strcmp(modality, 'manual')
%         
%         set(fig_handle, 'WindowButtonMotionFcn', @object.drawBlob, 'Interruptible', 'off', 'BusyAction', 'cancel');
%         %set(fig_handle, 'WindowButtonMotionFcn', @object.drawBlob, 'Interruptible', 'off', 'BusyAction', 'queue');
%         
%         object.BlobImageManual = cell(2,1); % blob + image_path
%         
%         object.BlobImageManual{1} = cell(object.ExampleCount,1);
%         object.BlobImageManual{2} = zeros(object.ExampleCount,3);
%         
%         object.BlobImageManualPath = out_blobimg_path;
%         
%     elseif sum(strcmp(modality, 'auto') || strcmp(modality, 'auto+manual'))
%         
%         object.BlobImageAuto = cell(2,2); % blob + image_path for left and right eye
%         
%         object.BlobImageAuto{eye_idx,1} = cell(object.ImageCount{eye_idx,1},1);
%         object.BlobImageAuto{eye_idx,2} = zeros(object.ImageCount{eye_idx,1},3);
%         
%         object.BlobImageAutoPath = out_blobimg_path;
%     end
%     
%     if sum(strcmp(modality, 'manual') || strcmp(modality, 'auto+manual'))
%         
%         % ask the user to insert an output directory for the first time
%         in_relative_path = object.Registry{1};
%         [im_path, im_name, im_ext] = fileparts(in_relative_path);
%         
%         handles = guidata(fig_handle);
%         
%         handles.outputPath = fullfile(object.RootPath, im_path);
%         handles.outputDir = [];
%         handles.outputDir = object.changeOutputDir(handles.outputPath, handles.outputDir);
%         
%         guidata(fig_handle, handles);
%         
%     end
%     
%     for idx_img = 1:object.ExampleCount
%         
%         in_relative_path = object.Registry{idx_img};
%         img_src = fullfile(object.RootPath, [in_relative_path object.Ext]);
%         
%         if sum(strcmp(modality, 'auto') || strcmp(modality, 'auto+manual'))
%             
%             t_img = object.TimestampImages{eye_idx,1}(idx_img);
%             
%             if idx_img==1
%                 t_diff = object.TimestampBlobs{eye_idx,1} - t_img;
%                 [t_blob, start_idx_blob] = min(abs(t_diff));
%             else
%                 end_idx_blob = min(start_idx_blob + time_window, length(object.TimestampBlobs{eye_idx,1}));
%                 t_diff = object.TimestampBlobs{eye_idx,1}(start_idx_blob:end_idx_blob) - t_img;
%                 flag = 1;
%                 if t_diff(1)<0 && t_diff(end)>=0
%                     [t_blob, idx_blob] = min(abs(t_diff));
%                     start_idx_blob = start_idx_blob + idx_blob;
%                     flag = 0;
%                 end
%                 if t_diff(1)>=0
%                     flag = 0;
%                 end
%                 while (t_diff(end)<0 && end_idx_blob<length(object.TimestampBlobs{eye_idx,1}))
%                     start_idx_blob = end_idx_blob;
%                     end_idx_blob = min(start_idx_blob + time_window, length(object.TimestampBlobs{eye_idx,1}));
%                     t_diff = object.TimestampBlobs{eye_idx,1}(start_idx_blob:end_idx_blob) - t_img;
%                     if t_diff(1)<0 && t_diff(end)>=0
%                         [t_blob, idx_blob] = min(abs(t_diff));
%                         start_idx_blob = start_idx_blob + idx_blob;
%                         flag = 0;
%                         break;
%                     end
%                     if t_diff(1)>=0
%                         flag = 0;
%                         break;
%                     end
%                 end
%                 if flag
%                     start_idx_blob = end_idx_blob;
%                 end
%             end
%             
%             blob_img = object.TimestampBlobs{eye_idx,2}(start_idx_blob, :);
%             
%             object.BlobImageAuto{eye_idx,1}{idx_img} = in_relative_path;
%             object.BlobImageAuto{eye_idx,2}(idx_img,:) = blob_img;
%             
%         elseif strcmp(modality, 'manual')
%             
%             blob_img = [];
%             
%         end
%         
%         if sum(strcmp(modality, 'manual') || strcmp(modality, 'auto+manual'))
%             
%             [im_path, im_name, ~] = fileparts(in_relative_path);
%             
%             handles = guidata(fig_handle);
%             
%             handles.outputPath = fullfile(out_rootpath, im_path);
%             img_dst = fullfile(handles.outputPath, handles.outputDir, [im_name object.Ext]);
%             
%             guidata(fig_handle, handles);
%             
%         elseif strcmp(modality, 'auto')
%             
%             img_dst = fullfile(object.RootPath, in_relative_path);
%             
%         end
%         
%         [blob_img, quit] = segment_image(object, modality, blob_img, img_src, img_dst, fig_handle);
%         
%         if quit==1
%             break;
%         end
%         
%         if quit==0
%             
%             if strcmp(modality,'manual')
%                 
%                 object.BlobImageManual{2}(idx_img,:) = blob_img;
%                 object.BlobImageManual{1}{idx_img} = in_relative_path;
%                 
%             elseif sum(strcmp(modality,'auto+manual') || strcmp(modality,'auto'))
%                 
%                 object.BlobImageAuto{eye_idx,2}(idx_img,:) = blob_img;
%                 object.BlobImageAuto{eye_idx,1}{idx_img} = in_relative_path;
%             end
%             
%             fprintf(fid, '%s %d %d %d\n', in_relative_path, blob_img(1), blob_img(2), blob_img(3));
%             
%         end
%         
%         disp([num2str(idx_img) '/' num2str(object.ExampleCount)]);
%         
%     end
%     
%     if sum(strcmp(modality,'auto+manual') || strcmp(modality,'manual'))
%         close(fig_handle);
%     end
%     
%     % close output file
%     fclose(fid);
%     
% end