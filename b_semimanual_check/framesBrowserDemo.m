function framesBrowserDemo()
    %# read all frames at once
    %vid = VideoReader('xylophone.mpg');
    %numImgs = get(vid, 'NumberOfFrames');
    %frames = read(vid);
    frames = rand(100,100,3,10);
    numImgs=10;
    %clear vid

    %# design GUI
    numThumbs = 5;
    mx = numImgs-numThumbs+1;
    hFig = figure('Menubar','none');
    hPanel = uipanel('Position',[0 0.04 1 0.16], 'Parent',hFig);
    uicontrol('Style','slider', 'Parent',hFig, ...
        'Callback',@slider_callback, ...
        'Units','normalized', 'Position',[0 0 1 0.04], ...
        'Value',1, 'Min',1, 'Max',mx, 'SliderStep',[1 10]./mx);

    %# main axis, and show first frame
    hAx = axes('Position',[0 0.2 1 0.8], 'Parent',hFig);
    hMainImg = imshow(frames(:,:,:,1), 'Parent',hAx);

    %# thumbnail axes
    hThumImg = zeros(numThumbs,1);
    for i=1:numThumbs
        %# create axis, show frame, hookup click callback
        hAx = axes('Parent',hPanel, ...
            'Position',[(i-1)/numThumbs 0 1/numThumbs 1]);
        hThumImg(i) = imshow(frames(:,:,:,i), 'Parent',hAx);
        set(hThumImg(i), 'ButtonDownFcn',@click_callback)
        axis(hAx, 'normal')
    end

    %# callback functions
    function slider_callback(src,~)
        val = round(get(src,'Value'));  %# starting index
        %# update the thumbnails
        for k=1:numel(hThumImg)
            set(hThumImg(k), 'CData',frames(:,:,:,k+val-1))
            drawnow
        end
    end

    function click_callback(src,~)
        %# update the main image
        set(hMainImg, 'CData',get(src,'CData'));
        drawnow
    end
end