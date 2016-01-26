function redraw(frame)
        im = imread(['AT3_1m4_' num2str(frame, '%02.0f') '.tif']);
        slice = im(210:310, 210:340);
        [ys, xs] = find(slice < 50 | slice > 100);
        pos = 210 + median([xs, ys]);
        siz = 3.5 * std([xs, ys]);
        imshow(im), hold on
        rectangle('Position',[pos - siz/2, siz], 'EdgeColor','g', 'Curvature',[1, 1])
        hold off
    end